class_name LastCartWatch
extends RefCounted

const CHOICES := {&"road": 0.0, &"grove": -256.0}
const ENTRY_X := -440.0
const KING_X := -360.0
const CACHE_X := -520.0
const CART_X := -150.0
const NEARBY_PX := 500.0
const ARRIVAL_OFFSETS := [-70.0, 0.0, 70.0]


static func rules() -> ArrivalRules:
	return Registry.entry(&"economy", &"arrival") as ArrivalRules


static func arrive() -> void:
	var o := SimLoop.arrival
	var reserve := mini(rules().exposed_provisions, SimLoop.seat.cart_coins)
	o.begin(SimLoop.core_x, SimLoop.core_x + CACHE_X, reserve)
	CellarWatch.sync()
	SimLoop.seat.cart_coins -= reserve
	SimLoop.seat.cart_x = SimLoop.core_x + ENTRY_X
	SimLoop.seat.cart_open = false
	SimLoop.builds.foundation_committed = false
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = o.origin + KING_X
	for i in u.count():
		if u.data_ids[i] != &"vagrant" or absf(u.xs[i] - o.origin) >= NEARBY_PX:
			continue
		var target := u.xs[i]
		o.citizens.append(u.ids[i])
		u.xs[i] = o.origin + KING_X + float(ARRIVAL_OFFSETS[u.ids[i] % ARRIVAL_OFFSETS.size()])
		u.set_target_x(u.ids[i], target)


static func choice_at(x: float) -> StringName:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	return (
		&"free"
		if r >= 0 and is_equal_approx(x, SimLoop.units.xs[r]) and FoundationChoice.ready()
		else &""
	)


static func claim(id: StringName) -> bool:
	if not CHOICES.has(id) or not SimLoop.arrival.claim(id, float(CHOICES[id])):
		return false
	reanchor(SimLoop.arrival.offset)
	commit()
	return true


static func commit() -> void:
	SimLoop.builds.foundation_committed = true
	var seat := RealmLadder.seat(SimLoop.builds)
	seat.state = BuildSlot.State.SCAFFOLD
	EventBus.queue(&"build_started", [seat.id, seat.kind])
	SimLoop.seat.monarch_aim = false
	if SimLoop.arrival.free_site:
		SimLoop.seat.cart_open = true
	EventBus.queue(&"segment_entered", [SimLoop.arrival.choice, &"foundation"])


static func reanchor(shift: float, terrain := true) -> void:
	if is_zero_approx(shift):
		return
	SimLoop.core_x += shift
	for site in SimLoop.builds.slots:
		if site.territory == 0 and site.kind != AmargueiroSystem.CORTE:
			site.x += shift
	if terrain:
		for k in SimLoop.passages.size():
			SimLoop.passages[k] += shift
		for k in SimLoop.field.camps.size():
			SimLoop.field.camps[k] += shift
		for k in SimLoop.secrets.xs.size():
			SimLoop.secrets.xs[k] += shift
		for k in SimLoop.secrets.chapters.size():
			SimLoop.secrets.chapters[k] += shift
	var walls := PackedFloat32Array()
	for site in SimLoop.builds.slots:
		if site.two_paths() and site.territory == 0:
			walls.append(site.x)
	UnderWatch.author_home(SimLoop.passages, walls)
	CellarWatch.sync()
	SimLoop.jobs.clear()


static func use() -> bool:
	var u := SimLoop.units
	var r := u.index_of(SimLoop.king_id)
	if r < 0 or not u.alive(r) or u.bands[r] != Band.Kind.SURFACE:
		return false
	var o := SimLoop.arrival
	if not o.active:
		return false
	var trees := SimLoop.night.amargueiros
	for k in trees.count():
		if (
			trees.fates[k] == AmargueiroSystem.Fate.OLD
			and absf(u.xs[r] - trees.xs[k]) <= Band.PASSAGE_PX
		):
			o.record(&"first_landmark_inspected", &"black_roots")
			o.record(&"rot_first_noticed", &"black_roots")
			return true
	if absf(u.xs[r] - o.cache_x) <= Band.PASSAGE_PX:
		o.record(&"first_landmark_inspected", &"blighted_supplies")
		if o.tainted:
			o.record(&"rot_first_noticed", &"supplies")
		if o.choice == &"":
			return true
	if o.choice == &"":
		return FoundationChoice.claim(u.xs[r])
	if not SimLoop.seat.cart_open:
		return false
	if o.cache_coins > 0 and absf(u.xs[r] - o.cache_x) <= Band.PASSAGE_PX:
		return ArrivalLabor.assign(LastCart.RESCUE)
	if absf(u.xs[r] - SimLoop.seat.cart_x) > Band.PASSAGE_PX:
		return false
	return ArrivalLabor.assign(LastCart.SCOUT if o.task == LastCart.FORAGE else LastCart.FORAGE)


static func tick(delta: float, phase: int, changed: bool) -> void:
	var o := SimLoop.arrival
	if not o.active:
		return
	CaravanWatch.tick(delta)
	o.seconds += delta
	var r := SimLoop.units.index_of(SimLoop.king_id)
	if r >= 0 and absf(SimLoop.units.xs[r] - o.origin - KING_X) > 1.0:
		o.record(&"first_input")
	var target := SimLoop.core_x + CART_X
	if o.choice != &"" and not o.free_site:
		SimLoop.seat.cart_x = move_toward(SimLoop.seat.cart_x, target, rules().cart_speed * delta)
	if o.choice != &"" and is_equal_approx(SimLoop.seat.cart_x, target):
		SimLoop.seat.cart_open = true
	if changed and phase == GameClock.Phase.AFTERNOON:
		o.tainted = true
		o.record(&"rot_warning_shown")
	if changed and phase == GameClock.Phase.DUSK and ClockService.clock.day == 1:
		o.record(&"pre_night_strategy", o.task)
	if changed and phase == GameClock.Phase.DAWN and ClockService.clock.day > 1:
		if r >= 0 and SimLoop.units.alive(r) and SimLoop.units.healths[r] > 0:
			o.survived = true
			o.record(&"night_one_survived")
		o.record(&"night_one_loss_type", &"none")
		o.consolidated = RealmLadder.founded(SimLoop.builds)
	if not o.survived and phase >= GameClock.Phase.DUSK and o.cache_coins > 0:
		var rot := SimLoop.night.rot
		if rot.active() and rot.trail_covers(o.cache_x) and not protected_cache():
			o.spoil()
	ArrivalLabor.tick(delta, phase)


static func protected_cache() -> bool:
	var o := SimLoop.arrival
	var plot := BuildSlot.new()
	plot.x = o.cache_x
	if RealmGrowth.protected(SimLoop.builds, plot):
		return true
	for zone: Vector4 in SimLoop.night.dark.wards(SimLoop.builds, SimLoop.core_x):
		if o.cache_x >= zone.x and o.cache_x <= zone.y:
			return true
	return false


static func first_night_target(default_x: float) -> float:
	var o := SimLoop.arrival
	return o.cache_x if o.active and not o.survived and o.choice != &"" else default_x
