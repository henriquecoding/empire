class_name RiftWatch
extends RefCounted
const SAL := 227


static func spawn(night: NightWatch, state: GameState, world: Vector2) -> void:
	var day := state.day
	var roll := RngService.scatter(hash([SAL, day]), 1)[0]
	var both := RiftPlan.two(
		day, roll, RulesFactory.rules(), SimFactory.rot_profile().two_sided_from_day
	)
	if not both:
		return
	var rot := night.rot
	var other := night.other_rot
	other.amargueiros = rot.amargueiros
	other.named_amargueiros = rot.named_amargueiros
	other.fortresses = rot.fortresses
	other.refusals = rot.refusals
	other.lure_days = rot.lure_days
	other.underground_open = not Passages.sealed_side(
		SimLoop.passages, SimLoop.builds, world.x, -rot.state.side
	)
	other.spawn(day, -rot.state.side, world.y)
	RealmFrame.place(other)
	var shares := RiftPlan.shares(rot.mass(), true)
	rot.state.mass = shares.x
	other.state.mass = shares.y
	EventBus.queue(
		&"rot_spawned", [other.position_x(), other.state.width, other.mass(), other.state.side]
	)


static func tick(
	night: NightWatch, delta: float, state: GameState, creatures: CreatureSystem, core: float
) -> void:
	var other := night.other_rot
	if not night.rot.active():
		other.retreat()
		return
	if not other.active():
		return
	if other.needs_interval():
		var interval := SimFactory.rot_window()
		other.arm(RngService.float_range(&"rot", interval.x, interval.y))
	for request in other.tick(delta, night.amargueiros.consecrated(), FireZones.of(SimLoop.builds)):
		request.x = NightWatch.door(other, request, core)  # a porta (ADR 0071)
		creatures.spawn(state, Registry.entry(&"creatures", request.creature_id), request.x, core)
		EventRelay.summoned(request, other.mass())
