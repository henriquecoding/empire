# src/sim/systems/monarchy.gd — quem reina, com que perfil, e o companheiro de cada
# monarca (§08, §15, §16; ADR 0052, o dono a 02/10/2026).
#
# "Numa campanha nova, o jogador escolhe o monarca que governara o seu reino [...] Cada
# escolha reune identidade, combate, autoridade da coroa e um companheiro proprio." A
# autoridade e de quem tem a coroa — o king_id do SimLoop —, e aqui guarda-se o resto:
# o perfil escolhido, a geracao da linhagem e o vinculo de cada monarca com o
# companheiro dele, por id. O companheiro deixa de ser "o primeiro coletor de moedas da
# faixa" (plano, MU-19): e quem nasceu com o monarca, ou quem um herdeiro herdou. Morto,
# fica perdido — nao nasce outro de graca.
#
# O Bardo da Nia canta pago: guarda-se o orcamento que ela lhe deu, e o prazo do
# incentivo de cada tropa (Q-199).
#
# Puro: as tropas e os dados entram ja lidos.
class_name Monarchy
extends RefCounted

const NENHUM := -1
## O perfil de um save de antes da escolha de monarca: o Rei, que era o unico.
const REI := &"monarch"
const BOOST := &"boost"
const PRAZO := &"remaining"

## O perfil de quem reina (monarchs.csv), ou &"" antes da escolha.
var profile: StringName = &""
## Quantas coroacoes houve: 0 e o primeiro monarca, 1 o primeiro herdeiro (§15, Q-202).
var generation := 0
## patrono id -> companheiro id.
var bonds: Dictionary = {}
## patrono id -> o companheiro que perdeu (plano §5.6). Nao volta por renomear o vinculo.
var lost: Dictionary = {}
## companheiro id -> as moedas que o monarca lhe deu para servir (Q-199).
var budgets: Dictionary = {}
## unit id -> {boost, remaining}: o incentivo do Bardo, o maior que vale (Q-199).
var encouraged: Dictionary = {}


func chosen() -> bool:
	return profile != &""


## O perfil em jogo: o escolhido, ou o Rei num save de antes da escolha.
func current() -> StringName:
	return profile if chosen() else REI


## A escolha, uma vez so: o corpo do rei passa ao do perfil, e o companheiro que nasceu
## com ele ao companheiro do perfil — os mesmos ids, sem nascer ninguem a mais.
func begin(
	unidades: UnitSystem,
	rei: int,
	companheiro: int,
	perfil: StringName,
	corpo: UnitData,
	companhia: UnitData
) -> bool:
	var r := unidades.index_of(rei)
	if chosen() or r == NENHUM or corpo == null:
		return false
	profile = perfil
	embody(unidades, r, corpo)
	var c := unidades.index_of(companheiro)
	if c != NENHUM and companhia != null:
		embody(unidades, c, companhia)
		bonds[rei] = companheiro
	return true


## `i` passa ao corpo `corpo`: o id dos dados e os numeros dele, com a vida na mesma
## proporcao. Sem posto: o monarca e o companheiro nao tem posto.
static func embody(unidades: UnitSystem, i: int, corpo: UnitData) -> void:
	var antes := maxf(1.0, float(unidades.max_healths[i]))
	unidades.data_ids[i] = corpo.id
	unidades.healths[i] = maxi(1, roundi(unidades.healths[i] * corpo.max_health / antes))
	unidades.max_healths[i] = corpo.max_health
	unidades.speeds[i] = corpo.move_speed
	unidades.coin_capacities[i] = corpo.coin_capacity
	unidades.recruit_costs[i] = corpo.recruit_cost
	unidades.job_ids[i] = NENHUM


## O companheiro de `patrono`, vivo, ou NENHUM: o indice nas colunas.
func companion_index(unidades: UnitSystem, patrono: int) -> int:
	var c := unidades.index_of(int(bonds.get(patrono, NENHUM)))
	return c if c != NENHUM and unidades.alive(c) else NENHUM


## O companheiro a mao de `patrono`: vivo, na faixa dele e a `alcance` px. NENHUM se nao.
func at_hand(unidades: UnitSystem, patrono: int, alcance: float) -> int:
	var c := companion_index(unidades, patrono)
	var p := unidades.index_of(patrono)
	if c == NENHUM or p == NENHUM or not unidades.alive(p):
		return NENHUM
	if unidades.bands[c] != unidades.bands[p] or absf(unidades.xs[c] - unidades.xs[p]) > alcance:
		return NENHUM
	return c


## Um tick: o companheiro que morreu ou saiu deixa o vinculo e fica perdido, com o
## orcamento dele; o incentivo conta o prazo.
func watch(unidades: UnitSystem, delta: float) -> void:
	for patrono: int in bonds.keys():
		var companheiro := int(bonds[patrono])
		var c := unidades.index_of(companheiro)
		if c == NENHUM or not unidades.alive(c):
			lost[patrono] = companheiro
			budgets.erase(companheiro)
			bonds.erase(patrono)
	for unit_id: int in encouraged.keys():
		var i := unidades.index_of(unit_id)
		var resto := float(encouraged[unit_id][PRAZO]) - delta
		if i == NENHUM or not unidades.alive(i) or resto <= 0.0:
			encouraged.erase(unit_id)
		else:
			encouraged[unit_id][PRAZO] = resto


## A coroa passa de `velho` a `novo`: o companheiro vivo segue o herdeiro, o perdido
## continua perdido, e a linhagem conta mais uma geracao (§15).
func crown(velho: int, novo: int) -> void:
	generation += 1
	for registo: Dictionary in [bonds, lost]:
		if registo.has(velho):
			registo[novo] = registo[velho]
			registo.erase(velho)


func budget_of(companheiro: int) -> int:
	return int(budgets.get(companheiro, 0))


## O monarca da `quanto` ao orcamento do companheiro, ate `teto`. Devolve o que entrou.
func fund(companheiro: int, quanto: int, teto: int) -> int:
	var entra := clampi(teto - budget_of(companheiro), 0, quanto)
	if entra > 0:
		budgets[companheiro] = budget_of(companheiro) + entra
	return entra


## Se `preco` se paga: o orcamento do companheiro e a bolsa do patrono (indice `p`).
func can_pay(unidades: UnitSystem, p: int, companheiro: int, preco: int) -> bool:
	return p != NENHUM and budget_of(companheiro) + unidades.carried_coins[p] >= preco


## Paga `preco` uma vez: primeiro o orcamento, depois a bolsa. Falso, e nada se debita,
## se nao chega.
func charge(unidades: UnitSystem, p: int, companheiro: int, preco: int) -> bool:
	if not can_pay(unidades, p, companheiro, preco):
		return false
	var do_orcamento := mini(budget_of(companheiro), preco)
	budgets[companheiro] = budget_of(companheiro) - do_orcamento
	if budget_of(companheiro) == 0:
		budgets.erase(companheiro)
	unidades.carried_coins[p] -= preco - do_orcamento
	return true


## O incentivo do bardo `b` (indice): os vivos do dono dele a `raio`, na faixa, ganham
## `boost` de passo por `segundos`. Dois incentivos nao somam: vale o maior. Devolve
## quantos apanhou.
func encourage(unidades: UnitSystem, b: int, raio: float, boost: float, segundos: float) -> int:
	var n := 0
	for i in unidades.count():
		if unidades.owners[i] != unidades.owners[b] or not unidades.alive(i):
			continue
		if unidades.bands[i] != unidades.bands[b] or absf(unidades.xs[i] - unidades.xs[b]) > raio:
			continue
		var antes: Dictionary = encouraged.get(unidades.ids[i], {})
		encouraged[unidades.ids[i]] = {
			BOOST: maxf(boost, float(antes.get(BOOST, 0.0))),
			PRAZO: maxf(segundos, float(antes.get(PRAZO, 0.0))),
		}
		n += 1
	return n


## O passo dos incentivados, por cima do que a ConversionSystem repos neste tick.
func boost(unidades: UnitSystem) -> void:
	for unit_id: int in encouraged:
		var i := unidades.index_of(unit_id)
		if i != NENHUM:
			unidades.speeds[i] *= 1.0 + float(encouraged[unit_id][BOOST])


func to_dict() -> Dictionary:
	return {
		&"profile": profile,
		&"generation": generation,
		&"bonds": bonds.duplicate(),
		&"lost": lost.duplicate(),
		&"budgets": budgets.duplicate(),
		&"encouraged": encouraged.duplicate(true),
	}


## Um save de antes da escolha de monarca nao tem nada disto: o perfil fica por escolher,
## e o current() e o Rei. A migracao v7 (SaveMigrationsV7) liga o escudeiro antigo.
func from_dict(d: Dictionary) -> void:
	profile = StringName(d.get(&"profile", &""))
	generation = int(d.get(&"generation", 0))
	bonds = _ints(d.get(&"bonds", {}))
	lost = _ints(d.get(&"lost", {}))
	budgets = _ints(d.get(&"budgets", {}))
	encouraged = {}
	var guardados: Variant = d.get(&"encouraged", {})
	for unit_id: Variant in guardados if guardados is Dictionary else {}:
		encouraged[int(unit_id)] = (guardados[unit_id] as Dictionary).duplicate()


static func _ints(valor: Variant) -> Dictionary:
	var saida := {}
	for chave: Variant in valor if valor is Dictionary else {}:
		saida[int(chave)] = int(valor[chave])
	return saida
