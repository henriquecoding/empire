# tests/noite_que_se_aprende_test.gd — a noite que se aprende (ADR 0071, Q-239 e Q-240).
# O escuro que se paga (Q-241) esta em tests/escuro_pago_test.gd.
#
# O dono (05/10/2026): «na primeira noite esta aparecendo diversos inimigos e inimigos
# muito fortes, isso tem que ser balanceado». A sonda (tools/noites.gd) mediu tres
# coisas: o escuro trazia seis Rastejantes de graca ao rei logo na noite 1, a nove em vez
# dos tres do §25; o que se escreve de dia (arvores, recusas, o Lume) pesava inteiro desde
# a primeira noite, e a rampa da Q-017 so valia para o calendario; e uma especie nova vinha
# toda de uma vez — a noite 4 eram nove Alados e nenhum Rastejante, a 7 sete Brutos.
extends GdUnitTestSuite

const Referencia := preload("res://tests/support/reference_model.gd")

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
const LARGURA := 4000.0
const DIREITA := 1
## Massa que nunca acaba antes da estreia: o que se mede e o teto, e nao o orcamento.
const SEM_FUNDO := 1000.0


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func _criaturas() -> Array[CreatureData]:
	var lista: Array[CreatureData] = []
	for r in Registry.entries(&"creatures"):
		lista.append(r as CreatureData)
	return lista


func _mancha() -> RotSystem:
	return RotSystem.new(_perfil(), _criaturas())


func _bicho(id: StringName) -> CreatureData:
	return Registry.entry(&"creatures", id) as CreatureData


## Invoca ate a massa nao pagar mais nada, sem esperar pelo relogio: o que a noite PAGA.
func _invocar_tudo(rot: RotSystem) -> Dictionary:
	var vieram := {}
	for _i in 300:
		rot.arm(0.0)
		var pedidos := rot.tick(PASSO, [])
		if pedidos.is_empty():
			break
		for p in pedidos:
			vieram[p.creature_id] = int(vieram.get(p.creature_id, 0)) + 1
	return vieram


# ─── Q-239: a rampa pesa tambem o que escreveste de dia ──────────────────────


func test_o_peso_do_que_escreveste_sobe_com_a_rampa() -> void:
	var p := _perfil()
	assert_float(p.written_weight(1)).is_equal(0.0)
	assert_float(p.written_weight(4)).is_equal(0.5)
	assert_float(p.written_weight(p.ramp_nights)).is_equal(1.0)
	assert_float(p.written_weight(30)).is_equal(1.0)


func test_o_ritmo_da_noite_vive_no_perfil() -> void:
	# Q-126, no RotProfile ao lado do calendario: a funda, a calma e as outras.
	var p := _perfil()
	assert_float(p.rhythm(p.first_peak_night)).is_equal(p.peak_mass_mult)
	assert_float(p.rhythm(p.first_peak_night + 1)).is_equal(p.calm_mass_mult)
	assert_float(p.rhythm(p.first_peak_night - 1)).is_equal(1.0)
	assert_float(p.rhythm(0)).is_equal(1.0)


func test_sem_a_regra_pesa_inteiro_desde_a_noite_1() -> void:
	var p := _perfil().duplicate() as RotProfile
	p.ramp_written = false
	assert_float(p.written_weight(1)).is_equal(1.0)


func test_a_noite_1_e_a_do_25_mesmo_com_arvores_de_pe() -> void:
	var rot := _mancha()
	rot.amargueiros = 3
	rot.spawn(1, DIREITA, LARGURA)
	assert_float(rot.mass()).is_equal(_perfil().opening_mass)


func test_a_meio_da_rampa_as_arvores_e_as_recusas_pesam_metade() -> void:
	var p := _perfil()
	var rot := _mancha()
	rot.amargueiros = 2
	rot.refusals = 2
	rot.spawn(4, DIREITA, LARGURA)
	var escrito := 2 * p.mass_per_amargueiro + 2 * p.refusal_mass
	assert_float(rot.written_weight()).is_equal(0.5)
	assert_float(rot.mass()).is_equal_approx(p.calendar_mass(4) + escrito * 0.5, 0.001)
	assert_float(rot.mass()).is_equal_approx(Referencia.rot_mass(4, 0, p, 2, 0, 2), 0.001)


func test_depois_da_rampa_a_tabela_da_74_nao_muda() -> void:
	var rot := _mancha()
	rot.amargueiros = 3
	var p := _perfil()
	rot.spawn(p.ramp_nights, DIREITA, LARGURA)
	assert_float(rot.mass()).is_equal(p.calendar_mass(p.ramp_nights) + 3 * p.mass_per_amargueiro)


# ─── Q-240: uma especie estreia com poucos ───────────────────────────────────


func test_a_estreia_comeca_com_um_passo_e_sobe_um_passo_por_noite() -> void:
	var p := _perfil()
	assert_int(p.debut_step).is_greater(0)
	assert_int(p.debut_cap(4, 4)).is_equal(p.debut_step)
	assert_int(p.debut_cap(6, 4)).is_equal(3 * p.debut_step)
	assert_int(p.debut_cap(3, 4)).is_equal(0)
	assert_int(p.debut_cap(9, 1)).is_equal(RotProfile.SEM_TETO)  # a da noite 1 nao estreia


func test_sem_passo_nao_ha_estreia() -> void:
	var p := _perfil().duplicate() as RotProfile
	p.debut_step = 0
	assert_int(p.debut_cap(4, 4)).is_equal(RotProfile.SEM_TETO)


func test_a_primeira_noite_sao_os_tres_rastejantes() -> void:
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	assert_dict(_invocar_tudo(rot)).is_equal({&"crawler": 3})


func test_a_noite_4_traz_os_primeiros_alados_e_o_resto_em_rastejantes() -> void:
	var rot := _mancha()
	rot.spawn(4, DIREITA, LARGURA)
	var vieram := _invocar_tudo(rot)
	assert_int(int(vieram.get(&"winged", 0))).is_equal(_perfil().debut_step)
	assert_int(int(vieram.get(&"crawler", 0))).is_greater(0)


func test_a_noite_7_traz_os_primeiros_brutos_e_nao_a_noite_inteira() -> void:
	var passo := _perfil().debut_step
	var rot := _mancha()
	rot.spawn(7, DIREITA, LARGURA)
	rot.state.mass = SEM_FUNDO
	var vieram := _invocar_tudo(rot)
	assert_int(int(vieram.get(&"brute", 0))).is_equal(passo)
	assert_int(int(vieram.get(&"winged", 0))).is_equal(4 * passo)  # a quarta noite do Alado


func test_a_estreia_conta_por_noite_e_recomeca_ao_crepusculo() -> void:
	var rot := _mancha()
	for _noite in 2:
		rot.spawn(8, DIREITA, LARGURA)
		rot.state.mass = SEM_FUNDO
		assert_int(int(_invocar_tudo(rot).get(&"brute", 0))).is_equal(2 * _perfil().debut_step)
		rot.retreat()


func test_o_cavador_chamado_pelo_poco_estreia_na_noite_em_que_abre() -> void:
	var rot := _mancha()
	rot.lure_days = _perfil().mine_lure_days
	var abre := _bicho(&"burrower").min_day - rot.lure_days
	rot.spawn(abre, DIREITA, LARGURA)
	rot.state.mass = SEM_FUNDO
	assert_int(int(_invocar_tudo(rot).get(&"burrower", 0))).is_equal(_perfil().debut_step)


func test_pagar_respeita_o_dia_a_massa_e_a_estreia() -> void:
	var rot := _mancha()
	var bruto := _bicho(&"brute")
	var dia := bruto.min_day
	assert_bool(rot.afford(bruto, dia)).is_false()  # ainda nao nasceu: nada a pagar
	rot.spawn(3, DIREITA, LARGURA)
	assert_bool(rot.afford(bruto, 3)).is_false()  # o dia dele ainda nao chegou
	rot.retreat()
	rot.spawn(dia, DIREITA, LARGURA)
	rot.state.mass = SEM_FUNDO
	for _k in _perfil().debut_step:
		assert_bool(rot.afford(bruto, dia)).is_true()
	assert_float(rot.mass()).is_equal(SEM_FUNDO - _perfil().debut_step * bruto.mass_cost)
	assert_bool(rot.afford(bruto, dia)).is_false()  # a estreia: so um passo na primeira noite
	rot.state.mass = 0.0
	assert_bool(rot.afford(_bicho(&"crawler"), dia)).is_false()


func test_o_save_guarda_quantas_ja_vieram_nesta_noite() -> void:
	var rot := _mancha()
	var bruto := _bicho(&"brute")
	rot.spawn(bruto.min_day, DIREITA, LARGURA)
	rot.state.mass = SEM_FUNDO
	for _k in _perfil().debut_step:
		assert_bool(rot.afford(bruto, bruto.min_day)).is_true()
	var lida := _mancha()
	lida.from_dict(rot.to_dict())
	assert_bool(lida.afford(bruto, bruto.min_day)).is_false()


# ─── O RotPick, peca a peca ──────────────────────────────────────────────────


func test_o_poco_abre_o_cavador_mais_cedo_e_so_a_ele() -> void:
	var cedo := _perfil().mine_lure_days
	var cavador := _bicho(&"burrower")
	assert_int(RotPick.opens(cavador, cedo)).is_equal(cavador.min_day - cedo)
	assert_int(RotPick.opens(cavador, 0)).is_equal(cavador.min_day)
	assert_int(RotPick.opens(_bicho(&"brute"), cedo)).is_equal(_bicho(&"brute").min_day)


func test_cabe_pelo_dia_pela_massa_e_pela_estreia() -> void:
	var p := _perfil()
	var bruto := _bicho(&"brute")
	var estado := RotState.new()
	estado.mass = bruto.mass_cost
	assert_bool(RotPick.fits(bruto, p, bruto.min_day - 1, estado, 0)).is_false()
	assert_bool(RotPick.fits(bruto, p, bruto.min_day, estado, 0)).is_true()
	RotPick.take(estado, bruto)
	assert_float(estado.mass).is_equal(0.0)
	assert_int(int(estado.came[bruto.id])).is_equal(1)
	estado.came[bruto.id] = p.debut_step
	estado.mass = SEM_FUNDO
	assert_bool(RotPick.fits(bruto, p, bruto.min_day, estado, 0)).is_false()  # a estreia
	assert_bool(RotPick.fits(bruto, p, bruto.min_day + 1, estado, 0)).is_true()


func test_escolhe_a_mais_cara_que_cabe_e_salta_o_subsolo_fechado() -> void:
	var tabela: Array[CreatureData] = [_bicho(&"burrower"), _bicho(&"brute"), _bicho(&"crawler")]
	var estado := RotState.new()
	estado.mass = SEM_FUNDO
	var dia := _bicho(&"burrower").min_day
	assert_str(String(RotPick.choose(tabela, _perfil(), dia, estado, 0, true).id)).is_equal(
		"burrower"
	)
	assert_str(String(RotPick.choose(tabela, _perfil(), dia, estado, 0, false).id)).is_equal(
		"brute"
	)
	estado.mass = 0.0
	assert_object(RotPick.choose(tabela, _perfil(), dia, estado, 0, true)).is_null()
