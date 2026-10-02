class_name PlayerStrike
extends RefCounted

const LEFT := -1.0
const UNSTARTED := -1.0

var controlled := UnitSystem.NENHUM
var allies: Dictionary = {}
var focus: ArcherFocus
var last: Dictionary = {}
var _requests: Dictionary = {}
var _profiles: Dictionary
var _posts: JobBoard


func _init(profiles: Dictionary, posts: JobBoard) -> void:
	_profiles = profiles
	_posts = posts


## One buffered gesture per body; changing bodies discards the old gesture.
func request(who: int, direction: float) -> void:
	if who == controlled:
		_requests[who] = {&"direction": LEFT if direction < 0.0 else 1.0, &"remaining": UNSTARTED}


func pending(who: int) -> bool:
	return _requests.has(who)


func cancel() -> void:
	_requests.clear()


func tick(delta: float) -> void:
	for who: int in _requests.keys():
		var request_data: Dictionary = _requests[who]
		if who != controlled:
			_requests.erase(who)
		elif float(request_data[&"remaining"]) >= 0.0:
			request_data[&"remaining"] = float(request_data[&"remaining"]) - delta
			if float(request_data[&"remaining"]) <= 0.0:
				_requests.erase(who)


## The same profile supplies the actual hit, the range cue and the HUD.
func profile(units: UnitSystem, who: int) -> Dictionary:
	var i := units.index_of(who)
	var data: UnitData = _profiles.get(units.data_ids[i]) if i >= 0 else null
	if data == null:
		return {}
	return {
		&"damage": int(data.ability_params.get(&"manual_damage", data.damage)),
		&"range": float(data.ability_params.get(&"manual_range", data.range_px)),
		&"interval": float(data.ability_params.get(&"manual_interval", data.attack_interval)),
		&"buffer": float(data.ability_params.get(&"manual_buffer", 0.0)),
	}


func target(units: UnitSystem, creatures: CreatureSystem, who: int, direction: float) -> int:
	var i := units.index_of(who)
	var stats := profile(units, who)
	if i < 0 or stats.is_empty() or not units.alive(i) or units.healths[i] <= 0:
		return UnitSystem.NENHUM
	var data: UnitData = _profiles[units.data_ids[i]]
	var best := UnitSystem.NENHUM
	var gap: float = stats[&"range"]
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var c := creatures.index_of(id)
		if allies.has(id) or not creatures.alive(c):
			continue
		if not Posts.reaches(_posts, units, i, data, int(creatures.bands[c])):
			continue
		var distance := (creatures.xs[c] - units.xs[i]) * direction
		if distance >= 0.0 and distance <= gap and (best < 0 or distance < gap):
			best = id
			gap = distance
	return best


## Revalidate after movement. Damage is returned for the shared combat batch.
func resolve(units: UnitSystem, creatures: CreatureSystem) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not pending(controlled):
		return events
	var who := controlled
	var i := units.index_of(who)
	var stats := profile(units, who)
	if i < 0 or not units.alive(i) or units.healths[i] <= 0 or stats.get(&"damage", 0) <= 0:
		_requests.erase(who)
		return events
	var request_data: Dictionary = _requests[who]
	if float(request_data[&"remaining"]) < 0.0:
		request_data[&"remaining"] = stats[&"buffer"]
	if units.cooldowns[i] > 0.0 and not is_zero_approx(units.cooldowns[i]):
		return events
	var direction := float(request_data[&"direction"])
	_requests.erase(who)
	var enemy := target(units, creatures, who, direction)
	units.cooldowns[i] = stats[&"interval"]
	last = {
		&"who": who,
		&"x": units.xs[i],
		&"band": units.bands[i],
		&"direction": direction,
		&"range": stats[&"range"],
		&"target": enemy,
		&"target_x":
		(
			creatures.xs[creatures.index_of(enemy)]
			if enemy >= 0
			else units.xs[i] + direction * float(stats[&"range"])
		)
	}
	events.append(
		{
			CombatSystem.CHAVE: CombatSystem.EV_ATAQUE,
			CombatSystem.DE: who,
			CombatSystem.PARA: enemy,
			CombatSystem.ACERTOU: enemy >= 0
		}
	)
	if enemy < 0:
		return events
	var hits: Array[int] = [enemy]
	if focus != null and focus.piercing.has(who):
		hits = focus.pierced(units, creatures, who, enemy)
	for hit in hits:
		events.append(
			{
				CombatSystem.CHAVE: CombatSystem.EV_DANO,
				CombatSystem.DE: who,
				CombatSystem.PARA: hit,
				CombatSystem.QUANTO: stats[&"damage"],
				CombatSystem.CRIATURA: true
			}
		)
	return events
