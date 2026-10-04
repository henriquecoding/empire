class_name ArrivalLabor
extends RefCounted


static func candidate() -> int:
	var u := SimLoop.units
	var r := u.index_of(SimLoop.king_id)
	if r < 0:
		return LastCart.NONE
	for i in u.count():
		if not u.alive(i) or u.healths[i] <= 0 or u.owners[i] != u.owners[r]:
			continue
		if u.ids[i] == SimLoop.companion.worker:
			continue
		if u.data_ids[i] == &"vagrant" and u.bands[i] == Band.Kind.SURFACE:
			return u.ids[i]
	return LastCart.NONE


static func assign(task: StringName) -> bool:
	var o := SimLoop.arrival
	var who := candidate()
	if who == LastCart.NONE or (task == LastCart.RESCUE and o.cache_coins <= 0):
		return false
	if o.scar and task == LastCart.FORAGE:
		return false
	o.assign(who, task)
	return true


static func reserve() -> void:
	var o := SimLoop.arrival
	var reserved := PackedInt32Array()
	for who: int in [o.worker, SimLoop.companion.worker]:
		if who >= 0:
			reserved.append(who)
	SimLoop.jobs.excluded = reserved
	SimLoop.builds.reserved = reserved


static func plan(phase: int) -> void:
	var o := SimLoop.arrival
	var u := SimLoop.units
	var i := u.index_of(o.worker)
	if i < 0 or not u.alive(i) or u.data_ids[i] != &"vagrant":
		o.assign(LastCart.NONE, &"")
		return
	var daylight := phase < GameClock.Phase.DUSK
	var x := SimLoop.core_x
	if daylight:
		x = SimLoop.passages[0] if o.task == LastCart.SCOUT else o.cache_x
	if o.task == LastCart.RESCUE and o.progress < 0.0:
		x = SimLoop.seat.cart_x
	u.set_target_x(o.worker, x)
	u.job_ids[i] = UnitSystem.NENHUM


static func tick(delta: float, phase: int) -> void:
	var o := SimLoop.arrival
	var u := SimLoop.units
	var i := u.index_of(o.worker)
	if i < 0 or not u.alive(i) or u.bands[i] != Band.Kind.SURFACE:
		return
	if phase >= GameClock.Phase.DUSK or o.task == &"":
		return
	if o.progress < 0.0 and o.task == LastCart.RESCUE:
		if absf(u.xs[i] - SimLoop.seat.cart_x) <= RulesFactory.rules().provisions_grab_px:
			SimLoop.seat.cart_coins += o.cache_coins
			o.cache_coins = 0
			o.record(&"provisions_rescued")
			o.assign(LastCart.NONE, &"")
		return
	var target := SimLoop.passages[0] if o.task == LastCart.SCOUT else o.cache_x
	if absf(u.xs[i] - target) > RulesFactory.rules().provisions_grab_px:
		return
	if not o.work(delta, LastCartWatch.rules().worker_work_s):
		return
	match o.task:
		LastCart.SCOUT:
			o.scouted = true
			o.record(&"first_landmark_inspected", &"cellar")
			o.assign(LastCart.NONE, &"")
		LastCart.RESCUE:
			o.progress = LastCart.RETURNING
		LastCart.FORAGE:
			if o.tainted and not o.survived and not LastCartWatch.protected_cache():
				return
			if o.earned_day != ClockService.clock.day:
				o.earned_day = ClockService.clock.day
				o.earned = 0
			if not o.scar and o.earned < LastCartWatch.rules().forage_daily_cap:
				o.earned += 1
				SimLoop.drop_coin(o.cache_x, Band.Kind.SURFACE, 1, &"forage")
				o.record(&"first_income", &"forage")
