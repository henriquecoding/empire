# tests/economy_system_test.gd — o prompt 3 da §29, e a regra que o F1-10
# escreve por cima dele: "o sistema tem de bater com o modelo de referencia, ou
# a divergencia vai a ADR".
#
# Por isso metade destes testes compara o EconomySystem com
# tests/support/reference_model.gd numero a numero. Se um dia divergirem, e aqui
# que se ve, e nao no dia da asfixia de uma partida.
extends GdUnitTestSuite

const Referencia := preload("res://tests/support/reference_model.gd")

const DIAS := 30
const DAWN := int(GameClock.Phase.DAWN)
const NOON := int(GameClock.Phase.NOON)


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _perfil(id: StringName) -> EconomyProfile:
	return Registry.entry(&"economy/profiles", id) as EconomyProfile


func _economia() -> EconomySystem:
	return EconomySystem.new(_curva(), _relogio().phase_durations.size())


func _canteiro(obras: BuildSystem, x: float) -> BuildSlot:
	var d := Registry.entry(&"buildings", &"farm") as BuildingData
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = d.id
	vaga.width = float(d.width_px)
	vaga.yield_per_day = d.yield_per_day
	vaga.razed_by_rot = d.destroyed_by_rot_trail
	vaga.costs = PackedInt32Array([d.cost])
	vaga.works = PackedFloat32Array([d.build_work])
	vaga.healths = PackedInt32Array([d.max_health])
	obras.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


# ─── Os numeros que o prompt 3 escreve ───────────────────────────────────────


func test_a_manutencao_tem_tres_escaloes() -> void:
	var e := _economia()
	assert_float(e.upkeep(8)).is_equal(0.0)
	assert_float(e.upkeep(14)).is_equal(3.0)
	assert_float(e.upkeep(25)).is_equal(13.5)


func test_a_ganancia_corta_a_percentagem_que_diz() -> void:
	assert_float(_economia().greed_cut(100.0, 28)).is_equal(28.0)


func test_sem_rotas_o_comercio_e_zero_em_qualquer_dia() -> void:
	var e := _economia()
	for d in range(1, DIAS + 1):
		assert_float(e.trade_income(0, d)).is_equal(0.0)


func test_o_dia_da_asfixia_do_perfil_equilibrado_cai_entre_9_e_14() -> void:
	# O teste mais importante do projeto (§29): nao e um teste de codigo, e um
	# teste de design, e chumba o build quando alguem mexe num numero da curva.
	var alvo := _curva().suffocation_target
	var dia := _economia().suffocation_day(_perfil(&"balanced"), DIAS)

	assert_int(dia).is_between(alvo.x, alvo.y)


func test_a_ganancia_80_antecipa_a_asfixia_em_pelo_menos_3_dias() -> void:
	var e := _economia()
	var vinte := e.suffocation_day(_perfil(&"greed_20"), DIAS)
	var oitenta := e.suffocation_day(_perfil(&"greed_80"), DIAS)

	assert_int(vinte - oitenta).is_greater_equal(3)


func test_cada_rota_adia_a_asfixia() -> void:
	var e := _economia()
	var sem := e.suffocation_day(_perfil(&"balanced"), DIAS)
	var com := e.suffocation_day(_perfil(&"two_routes"), DIAS)

	assert_int(com).is_greater(sem)


# ─── A bater com o modelo de referencia, numero a numero ─────────────────────


func test_bate_com_o_modelo_de_referencia() -> void:
	var e := _economia()
	var c := _curva()
	for id in [&"balanced", &"greed_20", &"greed_80", &"two_routes", &"everything_max"]:
		var p := _perfil(id)
		for d in range(1, DIAS + 1):
			var meu := e.net_income(p.sources, p.routes, p.troops, p.greed, d)
			var dele := Referencia.net_income(p, d, c)
			var porque := "%s no dia %d: %.4f contra %.4f" % [id, d, meu, dele]
			assert_float(meu).override_failure_message(porque).is_equal_approx(dele, 0.0001)
		assert_int(e.suffocation_day(p, DIAS)).is_equal(Referencia.suffocation_day(p, c, DIAS))


func test_o_custo_da_noite_bate_com_o_modelo() -> void:
	var e := _economia()
	for d in range(1, DIAS + 1):
		assert_float(e.night_cost(d)).is_equal_approx(Referencia.night_cost(d, _curva()), 0.0001)


# ─── A passagem por fase do §49 ──────────────────────────────────────────────


func test_uma_obra_de_pe_produz_uma_vez_por_fase() -> void:
	# Q-027: o CSV guarda por dia e o sistema divide pelas fases. Seis fases de
	# um canteiro de 2/dia dao 2 moedas, e nao 12.
	var e := _economia()
	var obras := BuildSystem.new()
	var vaga := _canteiro(obras, 100.0)
	var fases := _relogio().phase_durations.size()

	var moedas := 0
	for f in fases:
		for evento in e.on_phase(obras, f, []):
			moedas += evento[EconomySystem.QUANTO]

	assert_int(moedas).is_equal(int(vaga.yield_per_day))


func test_uma_obra_por_construir_nao_produz() -> void:
	var e := _economia()
	var obras := BuildSystem.new()
	var vaga := _canteiro(obras, 100.0)
	vaga.state = BuildSlot.State.SCAFFOLD

	assert_array(e.on_phase(obras, NOON, [])).is_empty()


func test_no_rasto_da_podridao_nao_se_produz_e_a_plantacao_e_arrasada() -> void:
	# §49: "plantacoes sao destruidas; as restantes so param. A distincao esta
	# no BuildingData, nao em `if` por tipo."
	var e := _economia()
	var obras := BuildSystem.new()
	var vaga := _canteiro(obras, 100.0)

	var eventos := e.on_phase(obras, NOON, [Vector2(0.0, 200.0)])

	var arrasadas := 0
	for evento in eventos:
		assert_int(evento[EconomySystem.CHAVE]).is_not_equal(EconomySystem.EV_MOEDA)
		if evento[EconomySystem.CHAVE] == EconomySystem.EV_ARRASADA:
			arrasadas += 1
	assert_int(arrasadas).is_equal(1)
	assert_float(vaga.stock).is_equal(0.0)


func test_a_moeda_sai_por_cima_da_obra_que_a_produziu() -> void:
	# §49: "nunca escreve um inventario do jogador. Nao existe inventario. A
	# materia vive no edificio que a produziu."
	var e := _economia()
	var obras := BuildSystem.new()
	var vaga := _canteiro(obras, 640.0)

	var onde := 0.0
	for f in _relogio().phase_durations.size():
		for evento in e.on_phase(obras, f, []):
			onde = evento[EconomySystem.ONDE]

	assert_float(onde).is_equal(vaga.x)
