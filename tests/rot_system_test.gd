# tests/rot_system_test.gd — os seis testes do prompt 2 da §29, mais os que o
# contrato do F1-08 obriga por a aleatoriedade entrar de fora.
#
# Os numeros estao todos escritos no ticket: dia 1 a 14,9 px/s, dia 10 com duas
# fortalezas a 280 de massa, 60% da distancia sobre consagrado. Dar o numero
# calculado e o que impede uma implementacao que passa por acidente (§29).
extends GdUnitTestSuite

const Referencia := preload("res://tests/support/reference_model.gd")

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
const LARGURA := 4000.0
const ESQUERDA := -1
const DIREITA := 1


func _perfil() -> RotProfile:
	return Registry.entry(&"rot", &"default") as RotProfile


func _criaturas() -> Array[CreatureData]:
	var lista: Array[CreatureData] = []
	for r in Registry.entries(&"creatures"):
		lista.append(r as CreatureData)
	return lista


func _mancha() -> RotSystem:
	return RotSystem.new(_perfil(), _criaturas())


func _correr(rot: RotSystem, segundos: float, consagrado: Array[Vector2] = []) -> int:
	var invocadas := 0
	for _i in int(segundos / PASSO):
		if rot.needs_interval():
			var janela := _perfil().summon_interval
			rot.arm(RngService.float_range(&"rot", janela.x, janela.y))
		invocadas += rot.tick(PASSO, consagrado).size()
	return invocadas


# ─── Os seis do prompt ───────────────────────────────────────────────────────


func test_dia_1_a_velocidade_e_14_9() -> void:
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	assert_float(rot.speed()).is_equal(14.9)
	assert_float(rot.speed()).is_equal(Referencia.rot_speed(1, _perfil()))


func test_dia_10_com_duas_fortalezas_e_campo_limpo_da_280() -> void:
	var rot := _mancha()
	rot.fortresses = 2
	rot.spawn(10, DIREITA, LARGURA)
	assert_float(rot.mass()).is_equal(280.0)
	assert_float(rot.mass()).is_equal(Referencia.rot_mass(10, 2, _perfil()))


func test_sem_massa_para_a_mais_barata_nao_ha_invocacao() -> void:
	RngService.configure(SEMENTE)
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	rot.feed(rot.mass())  # o campo fica sem orcamento nenhum

	assert_int(_correr(rot, 60.0)).is_equal(0)


func test_sobre_consagrado_percorre_60_por_cento() -> void:
	RngService.configure(SEMENTE)
	var normal := _mancha()
	normal.spawn(1, DIREITA, LARGURA)
	var partida := normal.position_x()
	_correr(normal, 30.0)
	var livre := absf(normal.position_x() - partida)

	RngService.configure(SEMENTE)
	var travada := _mancha()
	travada.spawn(1, DIREITA, LARGURA)
	_correr(travada, 30.0, [Vector2(0.0, LARGURA)])
	var lenta := absf(travada.position_x() - partida)

	assert_float(lenta).is_equal_approx(livre * (1.0 - _perfil().consecrated_slowdown), 0.01)


func test_alimentar_leva_a_massa_a_zero_e_nunca_abaixo() -> void:
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	rot.feed(1000.0)
	assert_float(rot.mass()).is_equal(0.0)


func test_a_mesma_semente_da_a_mesma_sequencia_de_invocacoes() -> void:
	var correr := func() -> Array[String]:
		RngService.configure(SEMENTE)
		var rot := _mancha()
		rot.spawn(12, DIREITA, LARGURA)
		var nomes: Array[String] = []
		for _i in int(90.0 / PASSO):
			if rot.needs_interval():
				var janela := _perfil().summon_interval
				rot.arm(RngService.float_range(&"rot", janela.x, janela.y))
			for pedido in rot.tick(PASSO, []):
				nomes.append("%s@%d" % [pedido.creature_id, int(pedido.x)])
		return nomes

	var primeira: Array[String] = correr.call()
	assert_array(primeira).is_not_empty()
	assert_array(correr.call()).is_equal(primeira)


# ─── O que o contrato acrescenta ─────────────────────────────────────────────


func test_escolhe_a_mais_cara_que_cabe_e_cujo_dia_minimo_ja_passou() -> void:
	# §51: "a mais cara que cabe" produz a curva certa sem scripting por dia.
	# No dia 1 so o Rastejante tem min_day 1; o Alado so entra no dia 4.
	RngService.configure(SEMENTE)
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	var primeiro := rot.pick()
	assert_str(String(primeiro)).is_equal("crawler")

	rot.spawn(7, DIREITA, LARGURA)
	assert_str(String(rot.pick())).is_equal("brute")


func test_invocar_gasta_a_massa_da_criatura() -> void:
	RngService.configure(SEMENTE)
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	var antes := rot.mass()
	var custo := (Registry.entry(&"creatures", &"crawler") as CreatureData).mass_cost

	rot.arm(0.0)
	var pedidos := rot.tick(PASSO, [])

	assert_int(pedidos.size()).is_equal(1)
	assert_float(rot.mass()).is_equal(antes - custo)


func test_recua_ao_amanhecer_e_deixa_de_andar() -> void:
	RngService.configure(SEMENTE)
	var rot := _mancha()
	rot.spawn(1, DIREITA, LARGURA)
	_correr(rot, 10.0)
	var onde := rot.position_x()

	rot.retreat()
	_correr(rot, 10.0)

	assert_bool(rot.active()).is_false()
	assert_float(rot.position_x()).is_equal(onde)


func test_o_rasto_cobre_o_que_ela_ja_atravessou() -> void:
	# §51: o rasto persiste ate ao DAWN seguinte, e e o que o §49 le para saber
	# que um edificio nao produz nesse dia.
	RngService.configure(SEMENTE)
	var rot := _mancha()
	rot.spawn(1, ESQUERDA, LARGURA)
	_correr(rot, 20.0)

	assert_bool(rot.trail_covers(rot.position_x())).is_true()
	assert_bool(rot.trail_covers(0.0)).is_true()
	assert_bool(rot.trail_covers(LARGURA)).is_false()


# ─── XIII-02: o termo dos Amargueiros na massa (§74) ────────────────────────


func test_d01_a_tabela_da_74_sai_do_proprio_rot_system() -> void:
	# O D-01 mede o modelo de referencia; este mede o sistema que a noite usa.
	# As quatro linhas da tabela ao dia 20, e a nota das tres fortalezas.
	var linhas := [[0, 0, 0, 400.0], [0, 3, 0, 466.0], [0, 8, 0, 576.0], [0, 5, 3, 645.0]]
	linhas.append([3, 0, 0, 490.0])
	for l: Array in linhas:
		var rot := _mancha()
		rot.fortresses = l[0]
		rot.amargueiros = l[1]
		rot.named_amargueiros = l[2]
		rot.spawn(20, DIREITA, LARGURA)
		var msg := "fortalezas %d, arvores %d, nomeadas %d" % [l[0], l[1], l[2]]
		assert_float(rot.mass()).override_failure_message(msg).is_equal(l[3])
		assert_float(rot.mass()).is_equal(Referencia.rot_mass(20, l[0], _perfil(), l[1], l[2]))


func test_as_arvores_so_pesam_na_noite_seguinte_a_serem_contadas() -> void:
	# A massa escreve-se ao crepusculo: uma arvore que nasce a meio da noite
	# nao engorda a mancha que ja esta no campo — engorda a de amanha.
	var rot := _mancha()
	rot.spawn(5, DIREITA, LARGURA)
	var hoje := rot.mass()
	rot.amargueiros = 3
	assert_float(rot.mass()).is_equal(hoje)
	rot.spawn(6, DIREITA, LARGURA)
	var p := _perfil()
	assert_float(rot.mass()).is_equal(hoje + p.mass_per_day + 3 * p.mass_per_amargueiro)


func test_as_recusas_somam_ate_ao_teto_e_nunca_mais() -> void:
	# §74 e §75: min(recusas nos ultimos 5 dias, 5), e o D-04 poe-lhe o teto.
	var p := _perfil()
	var limpa := _mancha()
	limpa.spawn(10, DIREITA, LARGURA)
	for recusas in [1, 5, 30]:
		var rot := _mancha()
		rot.refusals = recusas
		rot.spawn(10, DIREITA, LARGURA)
		var esperado := minf(p.refusal_mass * mini(recusas, p.refusal_window_days), p.refusal_cap)
		assert_float(rot.mass() - limpa.mass()).is_equal(esperado)
		assert_float(rot.mass()).is_equal(Referencia.rot_mass(10, 0, p, 0, 0, recusas))


func test_o_que_o_jogador_escreveu_de_dia_sobrevive_ao_save() -> void:
	var rot := _mancha()
	rot.fortresses = 1
	rot.amargueiros = 4
	rot.named_amargueiros = 2
	rot.refusals = 3
	var copia := _mancha()
	copia.from_dict(rot.to_dict())
	copia.spawn(9, DIREITA, LARGURA)
	rot.spawn(9, DIREITA, LARGURA)
	assert_float(copia.mass()).is_equal(rot.mass())
