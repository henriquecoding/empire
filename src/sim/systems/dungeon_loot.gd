class_name DungeonLoot
extends RefCounted
const TRIPLE := 3


static func draw(
	rules: RulesCurve, kind_roll: float, coin_roll: float, bonus_roll: float
) -> Dictionary:
	var bonus := 1
	if bonus_roll < rules.dungeon_triple_chance:
		bonus = TRIPLE
	elif bonus_roll < rules.dungeon_triple_chance + rules.dungeon_double_chance:
		bonus = 2
	var kind := &"treasure"
	if kind_roll >= 1.0 - rules.dungeon_relic_chance:
		kind = &"relic"
	elif kind_roll >= rules.dungeon_treasure_chance:
		kind = &"guardian"
	var span := rules.dungeon_coin_max - rules.dungeon_coin_min + 1
	var coins := rules.dungeon_coin_min + mini(span - 1, floori(coin_roll * span))
	return {&"kind": kind, &"coins": coins * bonus, &"bonus": bonus}
