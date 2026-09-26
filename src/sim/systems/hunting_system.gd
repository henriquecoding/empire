class_name HuntingSystem
extends RefCounted

var day := 0
var rabbits: Array[float] = []
var intro_done := false
var _profiles: Dictionary
var _rabbit: WildlifeData


func _init(profiles: Dictionary, rabbit: WildlifeData) -> void:
	_profiles = profiles
	_rabbit = rabbit


func open_day(number: int, clearings: Array[float]) -> void:
	if number <= day:
		return
	day = number
	rabbits.assign(clearings)


## O alvo de caca cede ao combate e aos postos; nunca atravessa faixas.
func plan(units: UnitSystem, daylight: bool) -> void:
	if not daylight or rabbits.is_empty():
		return
	for id in _hunters(units):
		var i := units.index_of(id)
		if units.owners[i] == RecruitSystem.SEM_DONO or units.job_ids[i] != UnitSystem.NENHUM:
			continue
		var prey := _nearest(units.xs[i])
		var data: UnitData = _profiles[units.data_ids[i]]
		if absf(prey - units.xs[i]) > data.range_px:
			units.set_target_x(id, prey)
		else:
			units.set_target_x(id, units.xs[i])


## Um coelho, uma moeda fisica (§25); usa a cadencia da arma, nao renda por tick.
func resolve(units: UnitSystem, daylight: bool, intro_ready: bool) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if not daylight:
		return drops
	for id in _hunters(units):
		var i := units.index_of(id)
		var neutral := units.owners[i] == RecruitSystem.SEM_DONO
		if neutral and (intro_done or not intro_ready or day != 1):
			continue
		if rabbits.is_empty() or units.cooldowns[i] > 0.0:
			continue
		var prey := _nearest(units.xs[i])
		var data: UnitData = _profiles[units.data_ids[i]]
		if absf(prey - units.xs[i]) > data.range_px:
			continue
		rabbits.erase(prey)
		units.cooldowns[i] = data.attack_interval
		intro_done = intro_done or neutral
		drops.append(
			{
				&"x": prey,
				&"band": Band.Kind.SURFACE,
				&"amount": _rabbit.coin_yield,
				&"source": &"hunt"
			}
		)
	return drops


func to_dict() -> Dictionary:
	return {&"day": day, &"rabbits": rabbits.duplicate(), &"intro_done": intro_done}


func from_dict(saved: Dictionary) -> void:
	day = saved.get(&"day", 0)
	rabbits.assign(saved.get(&"rabbits", []))
	intro_done = saved.get(&"intro_done", false)


func _hunters(units: UnitSystem) -> Array[int]:
	var ids: Array[int] = []
	for i in units.count():
		var data: UnitData = _profiles.get(units.data_ids[i])
		if (
			data == null
			or not data.tags.has(&"hunter")
			or units.healths[i] <= 0
			or not units.alive(i)
		):
			continue
		if units.bands[i] != Band.Kind.SURFACE:
			continue
		if units.states[i] in [UnitFsm.State.FIGHT, UnitFsm.State.FLEE]:
			continue
		ids.append(units.ids[i])
	ids.sort()
	return ids


func _nearest(x: float) -> float:
	var nearest := rabbits[0]
	for prey in rabbits:
		if absf(prey - x) < absf(nearest - x):
			nearest = prey
	return nearest
