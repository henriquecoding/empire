class_name DungeonWatch
extends RefCounted
const SAL := 223
const ROLLS := 3
const WIDTH := 64.0


static func author(field: FieldWork, side: int, k: int, restoring: bool) -> void:
	var entry := field.wilds.at(side, k)
	if int(entry.get(WildSegments.PASSAGEM, 0)) <= 0 or entry.get(&"deserted", false):
		return
	var x := field.wilds.subject_x(side, k, SimLoop.world_width)
	if not entry.has(&"dungeon"):
		if restoring:
			return  # old saves already contain their original pile; never duplicate it
		var rolls := RngService.scatter(hash([SAL, side, k]), ROLLS)
		entry[&"dungeon"] = DungeonLoot.draw(RulesFactory.rules(), rolls[0], rolls[1], rolls[2])
	var reward: Dictionary = entry[&"dungeon"]
	if reward[&"kind"] == &"relic":
		var data := SecretData.new()
		data.id = StringName("dungeon_%s_%s" % [side, k])
		data.band = Band.Kind.UNDERGROUND
		data.reward_seeds = RulesFactory.rules().dungeon_relic_seeds
		if not SimLoop.secrets.ids.has(data.id):
			SimLoop.secrets.post(data, x, WIDTH)
	elif not restoring:
		if reward[&"kind"] == &"guardian":
			var data := Registry.entry(&"creatures", &"burrower") as CreatureData
			var id := SimLoop.creatures.spawn(SimLoop.state, data, x, x)
			var i := SimLoop.creatures.index_of(id)
			SimLoop.creatures.bands[i] = Band.Kind.UNDERGROUND
			SimLoop.creatures.coin_drops[i] = int(reward[&"coins"])
			reward[&"guardian"] = id
		else:
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
