# src/core/save_service.gd — o save (§62, ADR 0007).
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ NUNCA load() NEM ResourceLoader.load NESTE CAMINHO.                       ║
# ║                                                                           ║
# ║ Um .tres arbitrario pode conter script embutido. Carregar um save com     ║
# ║ load() e execucao remota de codigo disfarcada de save, e basta um save    ║
# ║ "partilhado" num forum. CACHE_MODE_IGNORE nao resolve: mexe na cache,     ║
# ║ nao na execucao de scripts (Q-036). Grava-se com store_var(dados, false)  ║
# ║ e le-se com get_var(false) — o false e o allow_objects.                   ║
# ║                                                                           ║
# ║ Ha portao a guardar isto: Rules.check_g6() e o test_g6 do architecture.   ║
# ║ Qualquer diff que toque neste ficheiro leva revisao obrigatoria.          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Escreve-se para um temporario, confirma-se e so depois se renomeia (SaveFile). Uma
# escrita a meio nao pode destruir o save anterior nem passar por sucesso (BUG-01).
extends Node

## Desde a v1, com migracoes explicitas (SaveMigrations, Q-091). Nao ha v0 (§62).
const SAVE_VERSION := SaveMigrations.CURRENT

## §54. Se mudar, o mundo e regenerado ou recusado. Ainda nao ha WorldGen; o
## campo existe desde ja porque acrescenta-lo depois obriga a uma migracao.
const WORLDGEN_VERSION := 1

## Autosave no DAWN de cada dia, em rotacao. Um save corrompido nunca e o unico.
const SLOTS := 3
const PASTA := "user://saves"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)


## Grava. Devolve false e escreve o erro se nao conseguiu — quem chama decide se
## isso e fatal; perder um autosave nao e, perder o save manual do jogador e.
##
## `mundo` sao as coleccoes da §45 — tropas, criaturas, moedas, obras, mancha —
## ja em tipos base. Sai separado do GameState porque ele e puro e nao conhece
## sistema nenhum (§70); quem os junta e quem chama, que vive em src/core/.
func save(
	slot: int, estado: GameState, rng_states: Dictionary = {}, mundo: Dictionary = {}
) -> bool:
	if not _slot_valido(slot):
		return false

	var dados := {
		&"save_version": SAVE_VERSION,
		&"worldgen_version": WORLDGEN_VERSION,
		&"created_utc": int(Time.get_unix_time_from_system()),
		&"autosave_seq": _maior_seq() + 1,
		&"seed": estado.seed,
		&"rng_states": rng_states,
		&"state": estado.to_dict(),
		&"world": mundo,
	}

	return SaveFile.write(caminho(slot), dados)


## Le. Devolve null se o slot nao existe, esta corrompido, ou nao e um save.
## Recusar em silencio seria pior: quem chama tem de poder dizer ao jogador.
func restore(slot: int) -> GameState:
	var dados := _ler_cru(slot)
	if dados.is_empty():
		return null
	return GameState.from_dict(dados[&"state"] if dados.has(&"state") else {})


## As coleccoes da §45 guardadas neste slot. Vazio num save anterior ao F1-14 —
## e um save de outra versao degrada em vez de recusar (§62).
func restore_world(slot: int) -> Dictionary:
	var dados := _ler_cru(slot)
	if not dados.has(&"world") or typeof(dados[&"world"]) != TYPE_DICTIONARY:
		return {}
	return dados[&"world"]


## O estado dos fluxos de RNG guardado neste slot. Sai separado do GameState
## porque a simulacao nao pode conhecer o RngService (§70) — quem os junta e
## quem chama, que vive em src/core/.
func restore_rng(slot: int) -> Dictionary:
	var dados := _ler_cru(slot)
	if not dados.has(&"rng_states") or typeof(dados[&"rng_states"]) != TYPE_DICTIONARY:
		return {}
	return dados[&"rng_states"]


## Grava no slot mais antigo e devolve qual foi. A rotacao sai do DISCO, nao de
## um contador em memoria: um contador reinicia com o jogo, e o primeiro autosave
## de cada sessao escrevia sempre por cima do slot 0 — que e precisamente o slot
## que a rotacao existe para nao perder.
func autosave(estado: GameState, rng_states: Dictionary = {}, mundo: Dictionary = {}) -> int:
	var slot := _slot_mais_antigo()
	return slot if save(slot, estado, rng_states, mundo) else -1


## Um slot vazio primeiro; senao o de sequencia mais baixa. A sequencia e usada
## em vez do created_utc porque este tem resolucao de um segundo, e tres
## autosaves no mesmo segundo empatavam — e um empate na rotacao e a rotacao
## deixar de existir.
func _slot_mais_antigo() -> int:
	var escolhido := 0
	var menor := -1
	for slot in SLOTS:
		var dados := _ler_cru(slot)
		if dados.is_empty():
			return slot
		var seq: int = dados.get(&"autosave_seq", 0)
		if menor < 0 or seq < menor:
			menor = seq
			escolhido = slot
	return escolhido


## A sequencia do save mais novo, e nunca abaixo da do legado a espera: o primeiro
## save do jogo novo tem de ser mais novo do que ele (LegacyStore, CONT-01).
func latest_seq() -> int:
	return _maior_seq()


func _maior_seq() -> int:
	var maior := LegacyStore.seq_floor()
	for slot in SLOTS:
		var dados := _ler_cru(slot)
		if dados.has(&"autosave_seq") and typeof(dados[&"autosave_seq"]) == TYPE_INT:
			maior = maxi(maior, dados[&"autosave_seq"])
	return maior


## O slot mais recente, ou -1 se nao ha nenhum. E a sequencia que manda, pela
## mesma razao da rotacao: o created_utc tem resolucao de um segundo e tres
## autosaves no mesmo segundo empatavam.
func latest_slot() -> int:
	var lista := by_recency()
	return lista[0] if not lista.is_empty() else -1


## Os slots cuja moldura se le, do mais novo para o mais velho: a ordem por que a
## retoma os tenta, para um save novo estragado nao esconder um velho bom (BUG-03).
func by_recency() -> Array[int]:
	var seqs := {}
	for slot in SLOTS:
		var dados := _ler_cru(slot)
		if not dados.is_empty():
			seqs[slot] = int(dados.get(&"autosave_seq", 0))
	var lista: Array[int] = []
	lista.assign(seqs.keys())
	lista.sort_custom(func(a: int, b: int) -> bool: return seqs[a] > seqs[b])
	return lista


## Se o slot traz um mundo com que se retome: tropas, e o relogio no estado. Uma
## moldura que se le mas vem sem mundo e um save estragado, e nao uma partida.
func playable(slot: int) -> bool:
	var tropas: Variant = restore_world(slot).get(&"units", {})
	if typeof(tropas) != TYPE_DICTIONARY:
		return false
	var ids: Variant = (tropas as Dictionary).get(&"ids", PackedInt32Array())
	return ids is PackedInt32Array and not (ids as PackedInt32Array).is_empty()


func has_slot(slot: int) -> bool:
	return _slot_valido(slot) and FileAccess.file_exists(caminho(slot))


func delete_slot(slot: int) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho(slot)))


func caminho(slot: int) -> String:
	return "%s/slot_%d.save" % [PASTA, slot]


## Um resumo por slot, para o menu: existe, que dia, quando foi gravado.
func summaries() -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for slot in SLOTS:
		var dados := _ler_cru(slot)
		if dados.is_empty():
			saida.append({&"slot": slot, &"exists": false})
			continue
		var estado: Dictionary = dados.get(&"state", {})
		var resumo := {
			&"slot": slot,
			&"exists": true,
			&"day": estado.get(&"day", 0),
			&"seed": dados.get(&"seed", 0),
			&"created_utc": dados.get(&"created_utc", 0),
			&"save_version": dados.get(&"save_version", 0),
		}
		saida.append(resumo)
	return saida


func _slot_valido(slot: int) -> bool:
	if slot < 0 or slot >= SLOTS:
		push_error("save: slot %d fora de [0, %d)" % [slot, SLOTS])
		return false
	return true


## Le e valida a moldura. Devolve {} em qualquer caso duvidoso — e a fronteira
## onde um ficheiro vindo de fora deixa de ser confiavel.
func _ler_cru(slot: int) -> Dictionary:
	if not has_slot(slot):
		return {}
	var f := FileAccess.open(caminho(slot), FileAccess.READ)
	if f == null:
		return {}
	var lido: Variant = f.get_var(false)  # false = allow_objects. ADR 0007.
	f.close()

	if typeof(lido) != TYPE_DICTIONARY:
		push_error("save: slot %d nao contem um dicionario" % slot)
		return {}
	var dados: Dictionary = lido
	if typeof(dados.get(&"save_version")) != TYPE_INT:
		push_error("save: slot %d sem save_version — nao e um save deste jogo" % slot)
		return {}
	if dados[&"save_version"] > SAVE_VERSION:
		# Degrada em vez de recusar: le-se o que se reconhece (§62).
		push_warning("save: slot %d e de uma versao futura (%d)" % [slot, dados[&"save_version"]])
	if typeof(dados.get(&"state")) != TYPE_DICTIONARY:
		push_error("save: slot %d sem estado" % slot)
		return {}
	return SaveMigrations.migrate(dados)  # uma por versao, por ordem (Q-091)
