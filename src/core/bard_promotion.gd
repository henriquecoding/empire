class_name BardPromotion
extends RefCounted


static func at(who: int, x: float) -> bool:
	var field := SimLoop.field
	var phase := field.hero_progress.phase_of(&"bard")
	if phase < 2:
		return false
	var units := SimLoop.units
	var data := Registry.entry(&"classes", &"bard") as ClassData
	var b := units.index_of(who)
	if b < 0:
		return false
	# O cursor sobre um inimigo continua a cantar para ele, mesmo com tropa ao lado.
	var enemy_gap := INF
	for c in SimLoop.creatures.count():
		if (
			SimLoop.creatures.alive(c)
			and SimLoop.creatures.bands[c] == units.bands[b]
			and not field.song.allies.has(SimLoop.creatures.ids[c])
		):
			enemy_gap = minf(enemy_gap, absf(SimLoop.creatures.xs[c] - x))
	var target_gap := INF
	for i in units.count():
		if (
			units.alive(i)
			and units.owners[i] == units.owners[b]
			and units.bands[i] == units.bands[b]
		):
			if data.promotion_targets.has(units.data_ids[i]):
				target_gap = minf(target_gap, absf(units.xs[i] - x))
	if target_gap >= enemy_gap:
		return false
	var old: Dictionary = {}
	for i in units.count():
		old[units.ids[i]] = units.data_ids[i]
	var cooldown := float(field.song.cooldowns.get(who, 0.0))
	var promoted := BardPromotionRules.at(
		units, who, x, data, SimFactory.by_id(&"units"), phase, cooldown
	)
	if promoted < 0:
		return false
	var body := Registry.entry(&"units", units.data_ids[b]) as UnitData
	field.song.cooldowns[who] = body.attack_interval
	EventBus.queue(
		&"unit_promoted", [promoted, old[promoted], units.data_ids[units.index_of(promoted)]]
	)
	return true
