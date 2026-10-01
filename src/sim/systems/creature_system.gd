# src/sim/systems/creature_system.gd — as invocacoes da Podridao, em colunas.
#
# Sao uma coleccao a parte e nao tropas com outro dono, por uma razao que a §51
# escreve: "as criaturas so existem como invocacoes da Podridao". Nascem de um
# CreatureData, dissolvem-se ao amanhecer, e nunca sao recrutadas, pagas nem
# postas a trabalhar. Metade das colunas das tropas nao lhes serve de nada.
#
# As mesmas regras das tropas (§52, §63): uma criatura e um INDICE, as colunas
# sao PackedArrays, e o remove() troca com a ultima em vez de deslocar tudo — o
# que MUDA a ordem, e por isso nada que afete a simulacao itera por indice.
#
# Puro: nao e Node, nao conhece o catalogo de eventos. Quem chama e que anuncia.
class_name CreatureSystem
extends RefCounted

const NENHUM := -1
## So a superficie tem as tuas luzes (LightWard).
const SUPERFICIE := int(Band.Kind.SURFACE)

var ids: PackedInt32Array = PackedInt32Array()
var data_ids: Array[StringName] = []
var xs: PackedFloat32Array = PackedFloat32Array()
var bands: PackedByteArray = PackedByteArray()
var healths: PackedInt32Array = PackedInt32Array()
var max_healths: PackedInt32Array = PackedInt32Array()
var speeds: PackedFloat32Array = PackedFloat32Array()
## Para onde caminha AGORA. A fila de contacto do §50 escreve aqui o lugar dela,
## e por isso isto muda; o rumo nao.
var target_xs: PackedFloat32Array = PackedFloat32Array()
## O que ela veio procurar: o nucleo do imperio. Escrito no spawn e nunca mais.
## Sao duas colunas e nao uma porque a pergunta "o que e que esta entre mim e o
## que eu quero" nao pode ser respondida com o sitio onde estou a ir a seguir —
## uma vez posto na fila, o muro deixava de estar no caminho de si proprio.
var goal_xs: PackedFloat32Array = PackedFloat32Array()
## Em quem bate. NENHUM e "ainda vem a caminho".
var target_ids: PackedInt32Array = PackedInt32Array()
## Em que OBRA bate. Uma coluna propria e nao um id partilhado com o de cima:
## os ids das obras e os das tropas vem de contadores diferentes, e distingui-los
## por um flag era guardar a mesma coisa duas vezes mal.
var target_slots: PackedInt32Array = PackedInt32Array()
var cooldowns: PackedFloat32Array = PackedFloat32Array()
## Quantas moedas deixa onde morre (§25: "uma moeda no chao onde morreu um
## Rastejante"). Fria no dossie, quente aqui: le-se em cada morte.
var coin_drops: PackedInt32Array = PackedInt32Array()
## A obra de onde levou alguma coisa e ainda a leva (o Alado e as galinhas, Q-129).
var loot_slots: PackedInt32Array = PackedInt32Array()
## A massa de cada uma — o nivel dela, que diz se a tua luz a faz recuar (ADR 0034).
var masses: PackedInt32Array = PackedInt32Array()
## Segundos que ainda anda para tras, a fugir de uma luz tua.
var recoils: PackedFloat32Array = PackedFloat32Array()

var _por_id: Dictionary = {}
## As luzes deste tick (LightWard). Com underscore: nao e coluna nem vai no save.
var _luzes: Array[Vector4] = []
var _recuo := 0.0


func count() -> int:
	return ids.size()


func index_of(creature_id: int) -> int:
	return _por_id.get(creature_id, NENHUM)


func alive(i: int) -> bool:
	return healths[i] > 0


## Ja esta a bater em alguem ou em alguma coisa. Quem esta engajado nao anda:
## parar a bater e a leitura que o §50 defende, e sem isto uma criatura
## atravessa quem esta a atacar.
func engaged(i: int) -> bool:
	return target_ids[i] != NENHUM or target_slots[i] != NENHUM


## Nasce uma criatura. `rumo` e o x para onde ela caminha — o nucleo do imperio
## ameacado. O id vem do contador do GameState, como tudo o resto (§45).
func spawn(estado: GameState, dados: CreatureData, x: float, rumo: float) -> int:
	var creature_id := estado.take_id()
	ids.append(creature_id)
	data_ids.append(dados.id)
	xs.append(x)
	bands.append(int(dados.band))
	healths.append(dados.max_health)
	max_healths.append(dados.max_health)
	speeds.append(dados.move_speed)
	target_xs.append(rumo)
	goal_xs.append(rumo)
	target_ids.append(NENHUM)
	target_slots.append(NENHUM)
	cooldowns.append(0.0)
	coin_drops.append(dados.coin_drop)
	loot_slots.append(NENHUM)
	masses.append(dados.mass_cost)
	recoils.append(0.0)
	_por_id[creature_id] = ids.size() - 1
	return creature_id


func remove(creature_id: int) -> bool:
	var i := index_of(creature_id)
	if i == NENHUM:
		return false
	var ultimo := ids.size() - 1
	if i != ultimo:
		_copiar(ultimo, i)
		_por_id[ids[i]] = i
	_encolher()
	_por_id.erase(creature_id)
	return true


func damage(creature_id: int, quanto: int) -> void:
	var i := index_of(creature_id)
	if i != NENHUM:
		healths[i] = maxi(0, healths[i] - quanto)


func set_target_x(creature_id: int, x: float) -> void:
	var i := index_of(creature_id)
	if i != NENHUM:
		target_xs[i] = x


## Passo 5 do §43. Quem ja esta engajado nao anda: parar a bater e a leitura que
## o §50 defende — sem isto uma criatura atravessa quem esta a atacar.
func tick_movement(delta: float) -> void:
	for i in ids.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
		if engaged(i) or healths[i] <= 0:
			continue
		var luz := (
			LightWard.at(xs[i], masses[i], _luzes) if bands[i] == SUPERFICIE else Vector2.ZERO
		)
		if luz.x > 0.0 and recoils[i] <= 0.0:
			recoils[i] = _recuo  # entrou numa luz que a aguenta: recua (ADR 0034)
		if recoils[i] > 0.0:
			recoils[i] = maxf(0.0, recoils[i] - delta)
			xs[i] -= signf(goal_xs[i] - xs[i]) * speeds[i] * delta
			continue
		xs[i] = move_toward(xs[i], target_xs[i], speeds[i] * delta * (1.0 - luz.y))


## As tuas luzes de pe para o movimento deste tick, e quanto recua quem entra
## numa que a aguenta (rot.csv, light_recoil_s). Quem chama e o NightWatch.
func set_lights(zonas: Array[Vector4], recuo: float) -> void:
	_luzes = zonas
	_recuo = recuo


## O amanhecer (§51): a mancha recua e as criaturas vivas dissolvem-se. Devolve
## os ids levados, por ordem crescente, para quem chama anunciar cada uma — uma
# criatura que desaparece em silencio e um defeito que ninguem consegue ler.
func dissolve(keep := PackedInt32Array()) -> PackedInt32Array:
	var removed := PackedInt32Array()
	var ordered := ids.duplicate()
	ordered.sort()
	for id in ordered:
		if keep.has(id) and healths[index_of(id)] > 0:
			continue
		remove(id)
		removed.append(id)
	return removed


## As colunas em tipos base, para o save (§62). Sem Object nenhum.
func to_dict() -> Dictionary:
	return Columns.to_dict(self)


## Repoe do save. Reindexa no fim: o dicionario de ids e derivado das colunas e
## nao vem no ficheiro — guarda-lo era guardar duas vezes a mesma coisa.
func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)
	# Um save anterior ao roubo (AUD-04) nao traz a coluna: ninguem levava nada.
	var antes := loot_slots.size()
	loot_slots.resize(ids.size())
	for k in range(antes, ids.size()):
		loot_slots[k] = NENHUM
	masses.resize(ids.size())  # um save anterior a ADR 0034: ninguem recua
	recoils.resize(ids.size())
	_reindexar()


func _copiar(de: int, para: int) -> void:
	ids[para] = ids[de]
	data_ids[para] = data_ids[de]
	xs[para] = xs[de]
	bands[para] = bands[de]
	healths[para] = healths[de]
	max_healths[para] = max_healths[de]
	speeds[para] = speeds[de]
	target_xs[para] = target_xs[de]
	goal_xs[para] = goal_xs[de]
	target_ids[para] = target_ids[de]
	target_slots[para] = target_slots[de]
	cooldowns[para] = cooldowns[de]
	coin_drops[para] = coin_drops[de]
	loot_slots[para] = loot_slots[de]
	masses[para] = masses[de]
	recoils[para] = recoils[de]


func _encolher() -> void:
	var n := ids.size() - 1
	ids.resize(n)
	data_ids.resize(n)
	xs.resize(n)
	bands.resize(n)
	healths.resize(n)
	max_healths.resize(n)
	speeds.resize(n)
	target_xs.resize(n)
	goal_xs.resize(n)
	target_ids.resize(n)
	target_slots.resize(n)
	cooldowns.resize(n)
	coin_drops.resize(n)
	loot_slots.resize(n)
	masses.resize(n)
	recoils.resize(n)


func _reindexar() -> void:
	_por_id.clear()
	for i in ids.size():
		_por_id[ids[i]] = i
