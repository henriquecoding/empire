class_name CaravanWatch
extends RefCounted


static func plan() -> void:
	var o := SimLoop.arrival
	if not o.active or o.choice != &"":
		return
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	if king < 0 or not u.alive(king):
		return
	var curve := SimFactory.curve()
	for k in o.citizens.size():
		var i := u.index_of(o.citizens[k])
		if i >= 0 and u.alive(i):
			u.set_target_x(
				u.ids[i], SimLoop.seat.cart_x + Retinue.spot(k) * curve.follow_spacing_px
			)


static func tick(delta: float) -> void:
	var o := SimLoop.arrival
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	if o.choice != &"" or king < 0 or not u.alive(king):
		return
	var moving := u.walking(king, SimLoop.king_id)
	o.stationary_s = 0.0 if moving else o.stationary_s + delta
	if moving:
		o.facing = signf(u.target_xs[king] - u.xs[king])
	var target := u.xs[king] - o.facing * SimFactory.curve().follow_distance_px
	SimLoop.seat.cart_x = move_toward(
		SimLoop.seat.cart_x, target, LastCartWatch.rules().cart_speed * delta
	)
