# src/core/dungeon_watch.gd — a masmorra de cada ruina e a caverna de cada falha: se ha
# entrada, e o que la esta (Q-170–182, Q-186; ADR 0072).
#
# O relatorio de 05/10/2026: o lugar vem antes do sorteio. Uma ruina ou uma falha de rocha
# so tem interior se o povo dela ainda tem tecto de entradas opcionais (§7.3) — uma ruina
# sem cave e um resultado valido. A recompensa sorteia-se quando o segmento nasce, mas e
# so uma intencao: materializa-se uma vez, no meio da baia, na primeira descida (SUB-11),
# e nunca mais. Os saves de antes ja a tinham posto na boca, e ficam como estao.
class_name DungeonWatch
extends RefCounted
const SAL := 223
const ROLLS := 3
const WIDTH := 64.0
const ABERTA := &"open"
const FECHADA := &"none"
const ENTRADA := &"under"
const POR_POR := &"pending"
const POSTA := &"placed"


static func author(field: FieldWork, side: int, k: int, restoring: bool) -> void:
	var entry := field.wilds.at(side, k)
	var gruta: bool = entry.get(WildSegments.ASSUNTO) == UnderWatch.FALHA
	if int(entry.get(WildSegments.PASSAGEM, 0)) <= 0 and not gruta:
		return
	var aberta := _open(field, side, k, restoring)
	UnderWatch.author_dungeon(field, side, k, &"" if aberta else UnderFit.BUDGET)
	if gruta or not aberta or entry.get(&"deserted", false):
		return  # a caverna nao guarda tesouro; uma ruina sem interior, tambem nao
	if not entry.has(&"dungeon"):
		if restoring:
			return  # old saves already contain their original pile; never duplicate it
		var rolls := RngService.scatter(hash([SAL, side, k]), ROLLS)
		entry[&"dungeon"] = DungeonLoot.draw(RulesFactory.rules(), rolls[0], rolls[1], rolls[2])
		entry[&"dungeon"][POR_POR] = true
	var reward: Dictionary = entry[&"dungeon"]
	if reward.has(POR_POR):
		return
	if not reward.has(POSTA):
		reward[POSTA] = field.wilds.subject_x(side, k, SimLoop.world_width)  # um save de antes
	if reward[&"kind"] == &"relic":
		_relic(side, k, float(reward[POSTA]))


## A primeira descida a masmorra `i` do subsolo: a recompensa nasce no meio da baia.
static func place(field: FieldWork, i: int) -> void:
	var spec: Dictionary = field.under.sites[i][UndergroundSites.SPEC]
	var onde: Vector2i = spec.get(UndergroundSites.SEGMENT, Vector2i(0, -1))
	if onde.y < 0 or onde.y >= field.wilds.count(onde.x):
		return
	var reward: Dictionary = field.wilds.at(onde.x, onde.y).get(&"dungeon", {})
	if not reward.has(POR_POR):
		return
	var x := UnderReserve.goal_x(field.under, i)
	reward.erase(POR_POR)
	reward[POSTA] = x
	match reward[&"kind"]:
		&"relic":
			_relic(onde.x, onde.y, x)
		&"guardian":
			var data := Registry.entry(&"creatures", &"burrower") as CreatureData
			var id := SimLoop.creatures.spawn(SimLoop.state, data, x, x)
			var c := SimLoop.creatures.index_of(id)
			SimLoop.creatures.bands[c] = Band.Kind.UNDERGROUND
			SimLoop.creatures.coin_drops[c] = int(reward[&"coins"])
			reward[&"guardian"] = id
		_:
			for _coin in int(reward[&"coins"]):
				SimLoop.coins.drop(SimLoop.state, x, Band.Kind.UNDERGROUND, 1, 0.0)
			EventBus.queue(
				&"coin_dropped", [x, int(Band.Kind.UNDERGROUND), int(reward[&"coins"]), &"dungeon"]
			)


static func guardians(field: FieldWork) -> PackedInt32Array:
	var result := PackedInt32Array()
	for side in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in field.wilds.count(side):
			var reward: Dictionary = field.wilds.at(side, k).get(&"dungeon", {})
			if reward.has(&"guardian"):
				result.append(int(reward[&"guardian"]))
	return result


## Se o segmento tem interior: decide-se uma vez, quando nasce, pelo tecto do povo dele, e
## fica gravado. Um save de antes ja tinha decidido: as ruinas tinham, as falhas nao.
static func _open(field: FieldWork, side: int, k: int, restoring: bool) -> bool:
	var entry := field.wilds.at(side, k)
	if not entry.has(ENTRADA):
		if restoring:
			return int(entry.get(WildSegments.PASSAGEM, 0)) > 0
		var plano := field.wilds.plan
		var povo := plano.people(side, k) if k < plano.size(side) else WorldPlan.CASA
		var elegivel := 0.0
		for j in plano.size(side):
			var zona := plano.zone(side, j)
			if (
				plano.people(side, j) == povo
				and zona in [WorldPlan.Zone.TRAIL, WorldPlan.Zone.THRESHOLD]
			):
				elegivel += field.wilds.width
		var abertas := 0
		for j in k:
			var outro := field.wilds.at(side, j)
			if (
				outro.get(ENTRADA) == ABERTA
				and j < plano.size(side)
				and plano.people(side, j) == povo
			):
				abertas += 1
		var tecto := UnderFit.optional_budget(elegivel, UnderWatch.rules())
		entry[ENTRADA] = ABERTA if abertas < tecto else FECHADA
	return entry[ENTRADA] == ABERTA


static func _relic(side: int, k: int, x: float) -> void:
	var data := SecretData.new()
	data.id = StringName("dungeon_%s_%s" % [side, k])
	data.band = Band.Kind.UNDERGROUND
	data.reward_seeds = RulesFactory.rules().dungeon_relic_seeds
	if not SimLoop.secrets.ids.has(data.id):
		SimLoop.secrets.post(data, x, WIDTH)
