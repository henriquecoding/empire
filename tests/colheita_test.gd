# tests/colheita_test.gd — o XIII-06: a Colheita, e as duas maneiras de acabar
# com um povo (§78).
#
# A duracao, o factor da assimilacao, os 140% e os 22 de massa do marco vem de
# economy.csv. Nenhum numero de balanceamento esta aqui.
extends GdUnitTestSuite

const POVOS := ["portuarios", "fenda", "horta", "fornalha", "sobraiz", "enramados"]


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _colheita() -> HarvestSystem:
	return HarvestSystem.new(_curva())


func _passar_dias(c: HarvestSystem, dias: int) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for _d in dias:
		eventos.append_array(c.at_dawn())
	return eventos


func test_c_e_6_mais_2_por_povo_ja_detido() -> void:
	var k := _curva()
	var c := _colheita()
	for detidos in 6:
		var esperado := k.colheita_base_days + k.colheita_per_people * detidos
		assert_int(c.duration(detidos, false)).is_equal(esperado)
	assert_int(c.duration(0, false)).is_equal(6)
	assert_int(c.duration(5, false)).is_equal(16)  # a sexta, a da Q-042


func test_por_assimilacao_e_metade_arredondada_para_cima() -> void:
	var c := _colheita()
	assert_int(c.duration(0, true)).is_equal(3)
	assert_int(c.duration(1, true)).is_equal(4)  # 8 / 2
	assert_int(c.duration(2, true)).is_equal(5)  # 10 / 2
	assert_int(c.duration(5, true)).is_equal(8)


func test_uma_de_cada_vez_e_a_segunda_entra_em_fila() -> void:
	var c := _colheita()
	c.conquer(&"portuarios", false)
	c.conquer(&"fenda", false)
	assert_str(c.people).is_equal("portuarios")
	assert_array(Array(c.queue)).is_equal(["fenda"])
	assert_float(c.production_mult(&"portuarios")).is_equal(_curva().colheita_production_mult)
	assert_float(c.production_mult(&"fenda")).is_equal(1.0)  # em fila: a 100%


func test_no_fim_decide_se_e_so_depois_comeca_a_seguinte() -> void:
	var c := _colheita()
	c.conquer(&"portuarios", false)
	c.conquer(&"fenda", false)
	var eventos := _passar_dias(c, c.days_left)
	assert_str(c.deciding).is_equal("portuarios")
	assert_str(c.people).is_empty()
	assert_int(eventos[-1][HarvestSystem.CHAVE]).is_equal(HarvestSystem.EV_DECIDIR)
	_passar_dias(c, 3)  # ninguem decide por ti: fica a espera
	assert_str(c.deciding).is_equal("portuarios")
	c.decide(HarvestSystem.Choice.RELEASE)
	assert_array(Array(c.released)).is_equal(["portuarios"])
	# A segunda comeca agora, e ja conta a primeira: 6 + 2 x 1.
	assert_str(c.people).is_equal("fenda")
	assert_int(c.days_left).is_equal(c.duration(1, false))


func test_soltar_da_uma_voz_ao_coro_e_ficar_da_um_marco_com_raiz() -> void:
	var k := _curva()
	var c := _colheita()
	for povo in ["portuarios", "fenda", "horta"]:
		c.conquer(StringName(povo), false)
		_passar_dias(c, c.days_left)
		c.decide(HarvestSystem.Choice.KEEP if povo != "fenda" else HarvestSystem.Choice.RELEASE)
	assert_int(c.voices()).is_equal(1)
	assert_int(c.landmarks()).is_equal(2)
	assert_float(c.production_mult(&"horta")).is_equal(1.0 + k.keep_production_bonus)
	assert_float(c.production_mult(&"fenda")).is_equal(1.0)
	# O marco que cria raiz pesa o mesmo que um Amargueiro (§74, §78).
	var r := Registry.entry(&"rot", &"default") as RotProfile
	assert_float(float(k.keep_landmark_mass)).is_equal(r.mass_per_amargueiro)


func test_se_a_aldeia_cai_perde_se_o_povo_sem_escolha() -> void:
	var c := _colheita()
	c.conquer(&"portuarios", false)
	c.conquer(&"fenda", false)
	_passar_dias(c, 2)
	c.fall()
	assert_array(Array(c.lost)).is_equal(["portuarios"])
	assert_str(c.deciding).is_empty()
	assert_str(c.people).is_equal("fenda")
	assert_array(Array(c.released)).is_empty()
	assert_array(Array(c.kept)).is_empty()


func test_quem_ja_foi_solto_ficado_ou_perdido_nao_se_conquista_outra_vez() -> void:
	var c := _colheita()
	c.conquer(&"portuarios", false)
	_passar_dias(c, c.days_left)
	c.decide(HarvestSystem.Choice.RELEASE)
	assert_bool(c.conquer(&"portuarios", false)).is_false()
	assert_bool(c.conquer(&"fenda", false)).is_true()
	assert_bool(c.conquer(&"fenda", false)).is_false()  # ja esta em Colheita


func test_o_save_tem_os_nomes_da_84() -> void:
	var c := _colheita()
	c.conquer(&"portuarios", true)
	c.conquer(&"fenda", false)
	_passar_dias(c, 1)
	var d := c.to_dict()
	for campo in [
		&"colheita_people",
		&"colheita_days",
		&"colheita_queue",
		&"peoples_released",
		&"peoples_kept"
	]:
		assert_bool(d.has(campo)).is_true()
	var lida := _colheita()
	lida.from_dict(d)
	assert_str(lida.people).is_equal("portuarios")
	assert_int(lida.days_left).is_equal(c.days_left)
	assert_array(Array(lida.queue)).is_equal(["fenda"])
	_passar_dias(lida, lida.days_left)
	lida.decide(HarvestSystem.Choice.KEEP)
	assert_int(lida.days_left).is_equal(lida.duration(1, false))  # a fenda nao foi assimilada
