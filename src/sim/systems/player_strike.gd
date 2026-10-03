# src/sim/systems/player_strike.gd — o golpe de quem o jogador conduz (ADR 0045), e a
# flecha do Imperador Arqueiro (ADR 0052): cada disparo gasta uma flecha da aljava dele,
# acerte ou falhe; sem flechas, um golpe de emergencia fraco e curto, sem sangramento; e o
# impacto que fez dano pode abrir uma ferida (Bleeding), com o sorteio do fluxo `combat`.
class_name PlayerStrike
extends RefCounted

const LEFT := -1.0
const UNSTARTED := -1.0

var controlled := UnitSystem.NENHUM
var allies: Dictionary = {}
var focus: ArcherFocus
## A aljava de quem a tem (Q-200) e a ferida da flecha (Q-201). Sem elas, sem teto.
var supply: Supply
var bleeding: Bleeding
## CreatureData por id: quem tem sangue.
var creature_data: Dictionary = {}
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
	var p := data.ability_params
	var stats := {
		&"damage": int(p.get(&"manual_damage", data.damage)),
		&"range": float(p.get(&"manual_range", data.range_px)),
		&"interval": float(p.get(&"manual_interval", data.attack_interval)),
		&"buffer": float(p.get(&"manual_buffer", 0.0)),
		&"arrow": data.ammo > 0 and supply != null,
	}
	if data.ammo > 0 and supply != null and not supply.can_shoot(units, i, data):
		stats[&"damage"] = int(p.get(&"emergency_damage", 0))
		stats[&"range"] = float(p.get(&"emergency_range", 0.0))
		stats[&"arrow"] = false
	return stats


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


## Revalidate after movement. Damage is returned for the shared combat batch. The wounds
## bleed first; `roll` is the `combat` stream, drawn only on an eligible arrow impact.
func resolve(
	units: UnitSystem, creatures: CreatureSystem, roll: Callable = Callable()
) -> Array[Dictionary]:
	var events := _bleeds(creatures)
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
	var data: UnitData = _profiles[units.data_ids[i]]
	if bool(stats[&"arrow"]):
		supply.shoot(units, i, data)  # a flecha disparada gasta-se, acerte ou falhe
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
	if focus != null and focus.piercing.has(who) and bool(stats[&"arrow"]):
		hits = focus.pierced(units, creatures, who, enemy)
	if bool(stats[&"arrow"]):
		for hit in hits:
			_wound(creatures, hit, who, data, roll)
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


func _wound(creatures: CreatureSystem, hit: int, who: int, data: UnitData, roll: Callable) -> void:
	var c := creatures.index_of(hit)
	var body: CreatureData = creature_data.get(creatures.data_ids[c]) if c >= 0 else null
	if bleeding == null or not roll.is_valid() or not Bleeding.bleeds(body):
		return
	if data.ability_params.has(&"bleed_chance"):
		bleeding.strike(hit, who, body, roll.call(), data.ability_params)


func _bleeds(creatures: CreatureSystem) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if bleeding == null:
		return events
	for wound in bleeding.take():
		if creatures.index_of(int(wound[Bleeding.ALVO])) < 0:
			continue
		events.append(
			{
				CombatSystem.CHAVE: CombatSystem.EV_DANO,
				CombatSystem.DE: int(wound[Bleeding.FONTE]),
				CombatSystem.PARA: int(wound[Bleeding.ALVO]),
				CombatSystem.QUANTO: int(wound[Bleeding.DANO]),
				CombatSystem.CRIATURA: true
			}
		)
	return events
