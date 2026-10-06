# tests/forest_resume_test.gd — reabrir a partida nao muda a floresta (BUG-04).
#
# A cache das obras cujo chao ja se limpou nao vai no save. Uma arvore que nascia
# depois dentro do chao de uma obra dessas ficava de pe na partida e caia ao reabrir.
extends GdUnitTestSuite

const SEMENTE := 20261005


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(1.0 / 30.0)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _w() -> Woodland:
	return SimLoop.field.woodland


func _fundar() -> void:
	var u := SimLoop.units
	var x := SimLoop.arrival.origin - 83.0
	u.xs[u.index_of(SimLoop.king_id)] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	assert_bool(FoundationChoice.claim(x)).is_true()


## BUG-04: uma arvore que nasce depois dentro do chao de uma obra ja limpa cai na mesma
## partida, e nao so quando o save se reabre (a cache das obras limpas nao vai no save).
func test_a_tree_born_later_inside_a_built_ground_is_cleared_now_and_after_reload() -> void:
	_fundar()
	var w := _w()
	var vaga: BuildSlot
	for s in SimLoop.builds.slots:
		if s.territory == 0 and s.state == BuildSlot.State.EMPTY and s.level == 0 and s.width > 0:
			if absf(s.x - SimLoop.core_x) > 300.0:
				vaga = s
				break
	vaga.state = BuildSlot.State.SCAFFOLD
	SimLoop.step(1.0 / 30.0)
	assert_bool(w.cleared_slots.has(vaga.id)).is_true()
	w.plant(9_000_004, vaga.x, &"pine")
	assert_bool(w.cleared_slots.is_empty()).is_true()
	SimLoop.step(1.0 / 30.0)
	var continuo := w.states[w.index_of(9_000_004)]
	assert_int(continuo).is_equal(Woodland.State.CLEARED)
	var mundo := SimLoop.world()
	SimLoop.load_world(mundo)
	SimLoop.step(1.0 / 30.0)
	assert_int(_w().states[_w().index_of(9_000_004)]).is_equal(continuo)


func test_no_tree_stands_on_built_ground_after_the_lands_are_generated() -> void:
	_fundar()
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.world_width + 2000.0)
	for tick in 20 * 30:
		SimLoop.step(1.0 / 30.0)
	var w := _w()
	assert_bool(w.zones.is_empty()).is_false()
	for vaga in SimLoop.builds.slots:
		if (
			vaga.band != Band.Kind.SURFACE
			or (vaga.level == 0 and vaga.state == BuildSlot.State.EMPTY)
		):
			continue
		for i in w.count():
			if absf(w.xs[i] - vaga.x) <= vaga.width * 0.5:
				assert_bool(w.standing(i)).is_false()
