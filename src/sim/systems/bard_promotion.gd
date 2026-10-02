class_name BardPromotionRules
extends RefCounted

const LEGACY_CLOCK := -1.0


static func at(
	units: UnitSystem,
	bard: int,
	x: float,
	data: ClassData,
	bodies: Dictionary,
	phase: int,
	ability_cooldown: float = LEGACY_CLOCK
) -> int:
	var b := units.index_of(bard)
	if b < 0 or phase < 2 or not units.alive(b):
		return -1
	var cooldown := units.cooldowns[b] if ability_cooldown < 0.0 else ability_cooldown
	if cooldown > 0.0:
		return -1
	var body: UnitData = bodies.get(units.data_ids[b])
	var radius := float(body.ability_params.get(&"radius", 0.0)) if body != null else 0.0
	if absf(x - units.xs[b]) > radius:
		return -1
	var best := -1
	var gap := INF
	for id in TargetPicker.ids_por_ordem(units.ids):
		var i := units.index_of(id)
		if id == bard or not units.alive(i) or units.owners[i] != units.owners[b]:
			continue
		if units.bands[i] != units.bands[b] or absf(units.xs[i] - units.xs[b]) > radius:
			continue
		if not data.promotion_targets.has(units.data_ids[i]):
			continue
		var distance := absf(units.xs[i] - x)
		if distance < gap:
			best = i
			gap = distance
	if best < 0:
		return -1
	var upper: UnitData = bodies.get(data.promotion_targets[units.data_ids[best]])
	if upper == null:
		return -1
	var ratio := float(units.healths[best]) / maxf(1.0, float(units.max_healths[best]))
	TrainingSystem.retrain(units, best, upper)
	units.healths[best] = maxi(1, roundi(upper.max_health * ratio))
	units.job_ids[best] = UnitSystem.NENHUM
	if ability_cooldown < 0.0:
		units.cooldowns[b] = body.attack_interval
	return units.ids[best]
