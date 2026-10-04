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
		var target := o.origin + float(LastCartWatch.CHOICES[&"grove"])
		loop.units.set_target_x(loop.king_id, target)
		if absf(x - target) <= Band.PASSAGE_PX:
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
