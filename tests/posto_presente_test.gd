# tests/posto_presente_test.gd — "a torre nao da dano — da certeza" (§07), a quem
# esta nela (D3 da auditoria de 26/09).
#
# O bonus ia com o POSTO: um arqueiro atribuido a torre disparava com 100% e +40%
# de alcance a 500 px dela — a caminho, a fugir, atras da luz da alvorada.
extends GdUnitTestSuite

const SEMENTE := 20260926
const O_ARQUEIRO := 7
const LONGE := 500.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _arqueiro_na_torre(id_torre: StringName) -> Array:
	var torre: BuildSlot = null
	for obra in SimLoop.builds.slots:
		if obra.kind == id_torre:
			torre = obra
			break
	torre.level = 1
	torre.state = BuildSlot.State.DONE
	torre.health = torre.max_health()
	var i := SimLoop.units.index_of(O_ARQUEIRO)
	SimLoop.units.owners[i] = SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	SimLoop.units.xs[i] = torre.x
	SimLoop.jobs.refresh(SimLoop.builds, SimLoop.units, GameClock.Phase.NIGHT)
	return [torre, i]


func _dados() -> UnitData:
	return Registry.entry(&"units", &"archer") as UnitData


func test_em_cima_da_torre_dispara_com_a_certeza_dela() -> void:
	var par := _arqueiro_na_torre(&"archer_tower")
	var i: int = par[1]
	SimLoop.units.xs[i] = SimLoop.jobs.slot_of(SimLoop.units.job_ids[i]).x
	assert_float(Posts.accuracy(SimLoop.jobs, SimLoop.units, i, _dados())).is_equal(1.0)
	assert_float(Posts.range_px(SimLoop.jobs, SimLoop.units, i, _dados())).is_greater(
		float(_dados().range_px)
	)


func test_longe_da_torre_dispara_como_em_campo_aberto() -> void:
	var par := _arqueiro_na_torre(&"archer_tower")
	var torre: BuildSlot = par[0]
	var i: int = par[1]
	assert_object(Posts.of(SimLoop.jobs, SimLoop.units, i)).is_not_null()
	SimLoop.units.xs[i] = torre.x + LONGE
	assert_float(Posts.accuracy(SimLoop.jobs, SimLoop.units, i, _dados())).is_equal(
		_dados().accuracy_open
	)
	assert_float(Posts.range_px(SimLoop.jobs, SimLoop.units, i, _dados())).is_equal(
		float(_dados().range_px)
	)


func test_longe_da_torre_alta_nao_chega_ao_ceu() -> void:
	var par := _arqueiro_na_torre(&"high_tower")
	var torre: BuildSlot = par[0]
	var i: int = par[1]
	var ceu := int(Band.Kind.AERIAL)
	SimLoop.units.xs[i] = SimLoop.jobs.slot_of(SimLoop.units.job_ids[i]).x
	assert_bool(Posts.reaches(SimLoop.jobs, SimLoop.units, i, _dados(), ceu)).is_true()
	SimLoop.units.xs[i] = torre.x + LONGE
	assert_bool(Posts.reaches(SimLoop.jobs, SimLoop.units, i, _dados(), ceu)).is_false()
