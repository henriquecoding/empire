# tests/harvest_system_test.gd — XIII-06: a Colheita (§78).
#
# C = 6 + 2 x povos ja detidos; por assimilacao, metade para cima; uma de cada
# vez; soltar ou ficar no fim; e a aldeia que cai perde o povo. Os numeros vem
# do economy.csv, e o marco que enraiza do peoples.csv.
extends GdUnitTestSuite

const POVOS := [&"portuarios", &"fenda", &"horta", &"fornalha", &"sobraiz"]


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func _ate_decidir(h: HarvestSystem) -> void:
	for _d in 64:
		if not h.at_dawn().is_empty():
			return


func test_a_primeira_colheita_dura_o_termo_base_e_a_sexta_mais() -> void:
	var h := SimFactory.harvest()
	var c := _curva()
	assert_int(h.duration(false)).is_equal(c.colheita_base_days)
	for k in POVOS.size():
		var ev := h.conquer(POVOS[k], false)
		var esperado := c.colheita_base_days + c.colheita_per_people * k
		assert_int(ev[HarvestSystem.DIAS]).is_equal(esperado)
		_ate_decidir(h)
		h.decide(POVOS[k], k % 2 == 0)
	# Com cinco detidos, a sexta dura base + 5 x por_povo — 16 com os dados de hoje.
	assert_int(h.duration(false)).is_equal(c.colheita_base_days + c.colheita_per_people * 5)


func test_por_assimilacao_e_metade_arredondada_para_cima() -> void:
	var h := SimFactory.harvest()
	var c := _curva()
	assert_int(h.duration(true)).is_equal(
		ceili(c.colheita_base_days * c.colheita_assimilation_factor)
	)


func test_a_colheita_anda_na_alvorada_e_acaba_numa_decisao() -> void:
	var h := SimFactory.harvest()
	var ev := h.conquer(&"portuarios", false)
	var dias: int = ev[HarvestSystem.DIAS]
	for _d in dias - 1:
		assert_array(h.at_dawn()).is_empty()
	var fim := h.at_dawn()
	assert_int(fim[0][HarvestSystem.CHAVE]).is_equal(HarvestSystem.EV_DECIDIR)
	assert_int(h.state_of(&"portuarios")).is_equal(HarvestSystem.Estado.A_DECIDIR)


func test_uma_de_cada_vez_e_a_segunda_espera_em_fila() -> void:
	var h := SimFactory.harvest()
	h.conquer(&"portuarios", false)
	var ev := h.conquer(&"fenda", false)
	assert_int(ev[HarvestSystem.CHAVE]).is_equal(HarvestSystem.EV_EM_FILA)
	assert_float(h.production_mult(&"fenda")).is_equal(1.0)  # em fila produz o normal
	_ate_decidir(h)
	var depois := h.decide(&"portuarios", true)
	assert_int(depois[-1][HarvestSystem.CHAVE]).is_equal(HarvestSystem.EV_COMECA)
	assert_int(h.state_of(&"fenda")).is_equal(HarvestSystem.Estado.EM_COLHEITA)


func test_so_se_decide_no_fim() -> void:
	var h := SimFactory.harvest()
	h.conquer(&"portuarios", false)
	assert_array(h.decide(&"portuarios", false)).is_empty()


func test_a_aldeia_que_cai_perde_o_povo() -> void:
	var h := SimFactory.harvest()
	h.conquer(&"portuarios", false)
	h.conquer(&"fenda", false)
	var ev := h.fall(&"portuarios")
	assert_int(ev[0][HarvestSystem.CHAVE]).is_equal(HarvestSystem.EV_PERDIDO)
	assert_int(h.state_of(&"fenda")).is_equal(HarvestSystem.Estado.EM_COLHEITA)
	assert_int(h.released() + h.kept()).is_equal(0)


func test_producao_em_colheita_e_depois_de_ficar() -> void:
	var h := SimFactory.harvest()
	var c := _curva()
	h.conquer(&"horta", false)
	assert_float(h.production_mult(&"horta")).is_equal(c.colheita_production_mult)
	_ate_decidir(h)
	h.decide(&"horta", false)
	assert_float(h.production_mult(&"horta")).is_equal_approx(1.0 + c.keep_production_bonus, 0.0001)


func test_ficar_enraiza_o_marco_e_pesa_na_noite() -> void:
	var h := SimFactory.harvest()
	h.conquer(&"portuarios", false)
	_ate_decidir(h)
	h.decide(&"portuarios", false)
	var farol := Registry.entry(&"peoples", &"portuarios") as PeopleData
	var esperado := _curva().keep_landmark_mass if farol.landmark_roots else 0.0
	assert_float(h.landmark_mass()).is_equal(esperado)
	assert_int(h.kept()).is_equal(1)


func test_a_colheita_sobrevive_ao_save() -> void:
	var h := SimFactory.harvest()
	h.conquer(&"portuarios", true)
	h.conquer(&"fenda", false)
	h.at_dawn()
	var copia := SimFactory.harvest()
	copia.from_dict(h.to_dict())
	assert_array(Array(copia.peoples)).is_equal(Array(h.peoples))
	assert_array(Array(copia.days_left)).is_equal(Array(h.days_left))
	assert_int(copia.state_of(&"fenda")).is_equal(HarvestSystem.Estado.EM_FILA)


func test_o_epilogo_le_os_povos_da_colheita() -> void:
	# §79: ficar com quatro povos fecha o Dominio, mesmo sem Divida.
	var noite := NightWatch.new()
	assert_str(String(noite.epilogue())).is_equal(String(Epilogue.TURNO))
	var perfil := SimFactory.rot_profile()
	for k in perfil.dominion_peoples_kept:
		noite.harvest.conquer(POVOS[k], false)
		_ate_decidir(noite.harvest)
		noite.harvest.decide(POVOS[k], false)
	assert_str(String(noite.epilogue())).is_equal(String(Epilogue.DOMINIO))
