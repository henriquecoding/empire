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


# ─── XIII-02: o termo dos Amargueiros na massa (§74) ─────────────────────────


func test_a_tabela_da_74_sai_do_sistema_e_nao_so_do_modelo() -> void:
	# O D-01 prova a tabela contra o modelo de referencia; isto prova que o
	# RotSystem a le igual. [dia, anonimos, nomeados, massa] — as quatro linhas
	# da §74 nas tres colunas, com zero fortalezas e zero recusas.
	var tabela := [
		[5, 0, 0, 130.0],
		[10, 0, 0, 220.0],
		[20, 0, 0, 400.0],
		[5, 3, 0, 196.0],
		[10, 3, 0, 286.0],
		[20, 3, 0, 466.0],
		[5, 8, 0, 306.0],
		[10, 8, 0, 396.0],
		[20, 8, 0, 576.0],
		[5, 5, 3, 375.0],
		[10, 5, 3, 465.0],
		[20, 5, 3, 645.0],
	]
	for linha in tabela:
		var rot := _mancha()
		rot.amargueiros = linha[1]
		rot.named_amargueiros = linha[2]
		rot.spawn(linha[0], DIREITA, LARGURA)
		var msg := "dia %d, %d + %d nomeados" % [linha[0], linha[1], linha[2]]
		assert_float(rot.mass()).override_failure_message(msg).is_equal(linha[3])
		var ref := Referencia.rot_mass(linha[0], 0, _perfil(), linha[1], linha[2])
		assert_float(rot.mass()).is_equal(ref)


func test_as_arvores_so_pesam_na_noite_seguinte() -> void:
	# §74: o Amargueiro "alimenta a noite seguinte". A massa escreve-se ao
	# crepusculo; uma arvore que nasce depois nao engorda a mancha ja no campo.
	var rot := _mancha()
	rot.spawn(20, DIREITA, LARGURA)
	rot.amargueiros = 3
	assert_float(rot.mass()).is_equal(400.0)
	rot.retreat()
	rot.spawn(20, DIREITA, LARGURA)
	assert_float(rot.mass()).is_equal(466.0)


func test_o_save_guarda_o_que_o_jogador_escreveu_de_dia() -> void:
	var rot := _mancha()
	rot.fortresses = 3
	rot.amargueiros = 5
	rot.named_amargueiros = 3
	rot.spawn(20, DIREITA, LARGURA)

	var lida := _mancha()
	lida.from_dict(rot.to_dict())
	lida.spawn(20, DIREITA, LARGURA)

	assert_int(lida.amargueiros).is_equal(5)
	assert_int(lida.named_amargueiros).is_equal(3)
	assert_float(lida.mass()).is_equal(rot.mass())
	assert_float(lida.mass()).is_equal(Referencia.rot_mass(20, 3, _perfil(), 5, 3))
