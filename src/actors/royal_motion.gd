class_name RoyalMotion
extends RefCounted

var _art := OriginalArt.new()
var _clips: Dictionary = {}
var _alive: Dictionary = {}
var _shield := -1
var _song: Dictionary = {}


func listen() -> void:
	EventBus.unit_damaged.connect(_damaged)
	EventBus.unit_revived.connect(_revived)
	EventBus.coin_spent.connect(_paid)


func _play(id: int, action: StringName) -> void:
	_clips[id] = {"action": action, "since": CombatFx.clock}


func _damaged(id: int, _amount: int, _from: int) -> void:
	_play(id, &"hit")


func _revived(id: int) -> void:
	_play(id, &"rise")


func _paid(_amount: int, purpose: StringName) -> void:
	if purpose != MonarchWatch.ALJAVA or SimLoop.field == null:
		return
	if MonarchWatch.data().service != MonarchWatch.FLECHAS:
		return
	var companion := MonarchWatch.at_hand(SimLoop.units, SimLoop.king_id)
	if companion >= 0:
		_play(SimLoop.units.ids[companion], &"deliver")


## Additional authored actions observe state only; none of their markers changes the simulation.
func frame(units: UnitSystem, i: int, profile: StringName, moving: bool, fallback: int) -> int:
	var id := units.ids[i]
	var now := CombatFx.clock
	var alive := units.alive(i)
	if not alive and bool(_alive.get(id, true)):
		_play(id, &"die")
	elif alive and not bool(_alive.get(id, true)):
		_play(id, &"rise")
	_alive[id] = alive
	if alive and SimLoop.field != null:
		_observe_service(units, i, profile)
	var clip: Dictionary = _clips.get(id, {})
	if clip.is_empty():
		if alive and not moving and profile == &"royal_squire" and _shield > 0:
			return _art.frame_at(profile, now, &"block_hold")
		return fallback
	var action: StringName = clip.action
	var elapsed := now - float(clip.since)
	if not _art.has_action(profile, action):
		_clips.erase(id)
		return fallback
	if action != &"die" and elapsed >= _art.action_seconds(profile, action):
		_clips.erase(id)
		return fallback
	if moving and action in [&"play", &"deliver", &"block"]:
		_clips.erase(id)
		return fallback
	return _art.frame_at(profile, elapsed, action, false)


func _observe_service(units: UnitSystem, i: int, profile: StringName) -> void:
	var field := SimLoop.field
	if profile == &"royal_squire" and field.classes.squire_id == units.ids[i]:
		var shield := field.classes.squire.shield
		if _shield >= 0 and shield != _shield:
			_play(units.ids[i], &"block")
		_shield = shield
	if profile == &"royal_bard":
		var cooldown := float(field.song.cooldowns.get(units.ids[i], 0.0))
		if cooldown > float(_song.get(units.ids[i], cooldown)):
			_play(units.ids[i], &"play")
		_song[units.ids[i]] = cooldown


func forget(live: Dictionary) -> void:
	for memory: Dictionary in [_clips, _alive, _song]:
		for id: int in memory.keys():
			if not live.has(id):
				memory.erase(id)
