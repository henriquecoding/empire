# tests/oferta_jogo_test.gd — XIII-04 pelo SimLoop, com o mundo montado (§75).
#
# A mancha fala na janela depois do crepusculo; uma moeda no prato aceita; nao
# fazer nada recusa, e a recusa pesa na massa da noite seguinte.
extends GdUnitTestSuite

const SEMENTE := 20260925
const PASSO := 1.0 / 30.0
const DIA := 3


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


## O relogio posto um segundo antes do crepusculo do dia pedido.
func _vespera_do_crepusculo(dia: int) -> void:
	var antes := 0.0
	for f in GameClock.Phase.DUSK:
		antes += _relogio().phase_durations[f]
	ClockService.seek(dia, antes - 1.0)
	for _i in int(2.0 / PASSO):
		SimLoop.step(PASSO)


## Uma tropa tua a 1 de vida, longe de tudo: e o preco de "Da-me o que ja nao anda".
func _ferido() -> int:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var id := SimLoop.units.spawn(
		SimLoop.state, arqueiro, SimLoop.units.owners[rei], SimLoop.core_x
	)
	SimLoop.units.healths[SimLoop.units.index_of(id)] = 1
	return id


func _ate_falar() -> bool:
	for _i in int((_perfil().offer_window_after_dusk.y + 2.0) / PASSO):
		SimLoop.step(PASSO)
		if SimLoop.night.offers.active():
			return true
	return false


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_mancha_fala_uma_vez_na_janela_depois_do_crepusculo() -> void:
	_ferido()
	_vespera_do_crepusculo(DIA)
	assert_bool(_ate_falar()).is_true()
	var t := SimLoop.night.offers.night_time
	var janela := _perfil().offer_window_after_dusk
	assert_float(t).is_between(janela.x, janela.y + PASSO)
	assert_str(String(SimLoop.night.offers.offer_id)).is_equal("the_lame")


func test_uma_moeda_no_prato_aceita_cobra_e_para_a_mancha() -> void:
	var ferido := _ferido()
	_vespera_do_crepusculo(DIA)
	_ate_falar()
	var ofertas := SimLoop.night.offers
	SimLoop.drop_coin(ofertas.dish_x, Band.Kind.SURFACE, 1, &"player")
	for _i in int(3.0 / PASSO):
		SimLoop.step(PASSO)
		if not ofertas.active():
			break
	assert_bool(ofertas.active()).is_false()
	assert_int(ofertas.debt.debt).is_equal(1)
	assert_int(SimLoop.units.index_of(ferido)).is_equal(UnitSystem.NENHUM)  # saiu e nao volta
	assert_float(SimLoop.night.rot.state.paused_for).is_greater(0.0)


func test_nao_fazer_nada_recusa_e_pesa_na_noite_seguinte() -> void:
	_ferido()
	_vespera_do_crepusculo(DIA)
	_ate_falar()
	for _i in int((_perfil().offer_seconds + 1.0) / PASSO):
		SimLoop.step(PASSO)
	assert_bool(SimLoop.night.offers.active()).is_false()
	assert_int(SimLoop.night.offers.refusals(DIA)).is_equal(1)
	assert_int(SimLoop.night.offers.debt.debt).is_equal(0)
	_vespera_do_crepusculo(DIA + 1)
	assert_int(SimLoop.night.rot.refusals).is_equal(1)
	var limpa := Registry.entry(&"rot", &"default") as RotProfile
	var sem := (
		limpa.mass_base
		+ limpa.mass_per_day * (DIA + 1)
		+ limpa.mass_per_amargueiro * SimLoop.night.trees.standing(false)
	)
	assert_float(SimLoop.night.rot.mass()).is_greater_equal(sem + limpa.refusal_mass - 0.01)


func test_com_a_divida_no_limiar_o_zelador_vem_e_ninguem_o_mata() -> void:
	SimLoop.night.offers.debt.add(_perfil().tender_from_debt)
	_vespera_do_crepusculo(DIA)
	var zelador := UnitSystem.NENHUM
	var bichos := SimLoop.creatures
	for c in bichos.count():
		if bichos.data_ids[c] == &"tender":
			zelador = bichos.ids[c]
	assert_int(zelador).is_not_equal(UnitSystem.NENHUM)
	for _i in int(_relogio().phase_durations[GameClock.Phase.DUSK] / PASSO):
		SimLoop.step(PASSO)
	assert_int(bichos.index_of(zelador)).is_not_equal(CreatureSystem.NENHUM)
	assert_bool(bichos.targetable(bichos.index_of(zelador))).is_false()


func test_sem_divida_nao_ha_zelador() -> void:
	_vespera_do_crepusculo(DIA)
	for c in SimLoop.creatures.count():
		assert_str(String(SimLoop.creatures.data_ids[c])).is_not_equal("tender")


func test_um_marco_pela_semente_real() -> void:
	# "A arvore que plantaste": o Marco sai do campo e entra uma Semente (§75).
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var x := SimLoop.core_x + SimLoop.world_width * 0.45
	var morto := SimLoop.units.spawn(SimLoop.state, arqueiro, dono, x)
	SimLoop.units.states[SimLoop.units.index_of(morto)] = UnitFsm.State.DEAD
	SimLoop.night.dawn(SimLoop.state, SimLoop.units, SimLoop.builds, SimLoop.core_x, SimLoop.jobs)
	SimLoop.night.trees.consecrate(SimLoop.night.trees.ids[0])
	_vespera_do_crepusculo(DIA)
	assert_bool(_ate_falar()).is_true()
	var ofertas := SimLoop.night.offers
	assert_str(String(ofertas.offer_id)).is_equal("the_tree_you_planted")
	SimLoop.drop_coin(ofertas.dish_x, Band.Kind.SURFACE, 1, &"player")
	for _i in int(3.0 / PASSO):
		SimLoop.step(PASSO)
	assert_int(SimLoop.night.trees.markers().size()).is_equal(0)
	assert_int(SimLoop.state.royal_seeds).is_equal(1)
	assert_int(ofertas.debt.debt).is_equal(2)


func test_o_zelador_no_nucleo_leva_o_nomeado_mais_antigo() -> void:
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var nomeado := SimLoop.units.spawn(SimLoop.state, arqueiro, dono, SimLoop.core_x)
	SimLoop.night.names.titles_of[nomeado] = &"the_counter"
	SimLoop.night.names.holders[&"the_counter"] = nomeado
	var zelador := Registry.entry(&"creatures", &"tender") as CreatureData
	SimLoop.creatures.spawn(SimLoop.state, zelador, SimLoop.core_x, SimLoop.core_x)
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.index_of(nomeado)).is_equal(UnitSystem.NENHUM)
	assert_int(SimLoop.night.names.named_count()).is_equal(0)
	for c in SimLoop.creatures.count():
		assert_str(String(SimLoop.creatures.data_ids[c])).is_not_equal("tender")
