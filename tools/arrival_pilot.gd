class_name ArrivalPilot
extends RefCounted


## Usa as mesmas intenções do jogador, incluindo a primeira escolha gratuita.
static func step(loop: Node) -> bool:
	var o: LastCart = loop.arrival
	if (
		not o.active
		or RealmLadder.stage(loop.builds) > RealmLadder.FUNDADO
		or ClockService.clock.day > 2
	):
		return false
	var r: int = loop.units.index_of(loop.king_id)
	var x: float = loop.units.xs[r]
	if o.choice == &"":
		var target := o.origin
		for offset: float in [0.0, -256.0, -83.0, 83.0, 512.0, -512.0]:
			var site := o.origin + offset
			if FoundationChoice.valid(site) and not FoundationChoice.priority_at(site):
				target = site
				break
		loop.units.set_target_x(loop.king_id, target)
		if is_equal_approx(x, target):
			loop.units.clear_target(loop.king_id)
		if FoundationChoice.ready():
			loop.intents.queue(IntentQueue.Kind.ASSUME, {})
		return true
	if not RealmLadder.founded(loop.builds):
		loop.units.set_target_x(loop.king_id, loop.core_x)
		return true
	if o.worker < 0 and not o.events.has(&"first_income") and ArrivalLabor.candidate() >= 0:
		loop.units.set_target_x(loop.king_id, loop.seat.cart_x)
		if absf(x - loop.seat.cart_x) <= Band.PASSAGE_PX:
			loop.intents.queue(IntentQueue.Kind.ASSUME, {})
		return true
	return false
