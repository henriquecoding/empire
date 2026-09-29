# tests/apagar_o_lume_test.gd — o fim do ciclo pela luz (Q-156, aprovada a
# 29/09/2026): "uma expedicao a base dela, de dia, com o farol de pe e a Divida
# baixa (Uniao, §75)".
extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260929)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _farol() -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == Lume.FAROL:
			return obra
	return null


func test_longe_da_base_nao_ha_lume_para_apagar() -> void:
	var falta := Lume.refusal(SimLoop.units, SimLoop.king_id)
	assert_bool(falta == &"LUME_NOT_HERE").is_true()


func test_na_base_sem_farol_nao_se_apaga_e_com_ele_acaba_o_ciclo() -> void:
	SimLoop.units.xs[_rei()] = 0.0
	var sem := Lume.refusal(SimLoop.units, SimLoop.king_id)
	assert_bool(sem == &"LUME_NEEDS_LIGHTHOUSE").is_true()
	assert_bool(Lume.extinguish(SimLoop.units, SimLoop.king_id)).is_false()
	var farol := _farol()
	farol.level = 1
	farol.state = BuildSlot.State.DONE
	farol.health = farol.max_health()
	assert_bool(Lume.refusal(SimLoop.units, SimLoop.king_id) == &"").is_true()
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	var divida := SimLoop.night.voice.debt
	assert_bool(divida.lume_out).is_true()
	assert_bool(divida.ended).is_true()
	assert_bool(SimLoop.state.crossed).is_true()
	assert_str(String(SimLoop.night.epilogue())).is_equal(String(Epilogue.UNIAO))


func test_com_a_divida_alta_nao_se_apaga() -> void:
	SimLoop.units.xs[_rei()] = SimLoop.world_width
	var farol := _farol()
	farol.level = 1
	farol.state = BuildSlot.State.DONE
	farol.health = farol.max_health()
	SimLoop.night.voice.debt.debt = SimFactory.rot_profile().union_debt_max + 1
	var falta := Lume.refusal(SimLoop.units, SimLoop.king_id)
	assert_bool(falta == &"LUME_NEEDS_LOW_DEBT").is_true()


func test_o_legado_do_lume_acaba_a_campanha() -> void:
	var tropas := SimFactory.by_id(&"units")
	var d := Legacy.crossing(SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, 0.0)
	Legacy.end_campaign(d)
	assert_int(int(d[Legacy.REGIAO])).is_equal(0)
	assert_bool(d.has(Legacy.PLANO)).is_false()
