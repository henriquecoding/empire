class_name CreatureSkins
extends RefCounted

const PROFILES := {
	&"crawler": &"temp_crawler",
	&"winged": &"temp_winged",
	&"brute": &"temp_brute",
	&"burrower": &"temp_burrower",
}
const HIT_SECONDS := 0.12
const DEAD_ALPHA := 0.35

var _art := OriginalArt.new()
var _positions: Dictionary = {}
var _health: Dictionary = {}
var _hit_until: Dictionary = {}
var _facing: Dictionary = {}
var _action: Dictionary = {}
var _since: Dictionary = {}


static func action_for(alive: bool, moving: bool, engaged: bool, hit: bool) -> ActorAction.Kind:
	if not alive:
		return ActorAction.Kind.DIE
	if hit:
		return ActorAction.Kind.HIT
	if engaged:
		return ActorAction.Kind.ATTACK
	return ActorAction.Kind.WALK if moving else ActorAction.Kind.IDLE


func draw_on(
	canvas: CanvasItem, creatures: CreatureSystem, i: int, view: Dictionary, time: float
) -> bool:
	var profile: StringName = PROFILES.get(creatures.data_ids[i], &"")
	if profile.is_empty():
		return false
	var id := creatures.ids[i]
	var foot: Vector2 = view.foot
	var previous: float = _positions.get(id, foot.x)
	var moving := not is_equal_approx(foot.x, previous)
	if moving:
		_facing[id] = signf(foot.x - previous)
	_positions[id] = foot.x
	if creatures.healths[i] < int(_health.get(id, creatures.healths[i])):
		_hit_until[id] = time + HIT_SECONDS
	_health[id] = creatures.healths[i]
	var hit := time < float(_hit_until.get(id, 0.0))
	var kind := action_for(creatures.alive(i), moving, creatures.engaged(i), hit)
	var shown := ActorAction.shown(_art, profile, kind)
	if _action.get(id, -1) != kind:
		_action[id] = kind
		_since[id] = time
	var elapsed := time - float(_since[id])
	var frame := _art.frame_at(profile, elapsed, ActorAction.TAGS[shown], ActorAction.loops(shown))
	var facing: float = _facing.get(id, signf(creatures.target_xs[i] - foot.x))
	if is_zero_approx(facing):
		facing = 1.0
	var tint: Color = view.lit if view.revealed else view.hidden_tint
	if not creatures.alive(i):
		tint.a *= DEAD_ALPHA
	if view.revealed:
		_art.draw_on(canvas, profile, foot, tint, frame, facing)
	else:
		_art.mask_on(canvas, profile, foot, tint, frame, facing)
	return true


func forget_except(ids: PackedInt32Array) -> void:
	for id in _positions.keys():
		if id not in ids:
			for cache: Dictionary in [_positions, _health, _hit_until, _facing, _action, _since]:
				cache.erase(id)
