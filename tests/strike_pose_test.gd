# tests/strike_pose_test.gd — o golpe em tres tempos: preparar, bater, voltar.
#
# O que se prova e o contrato, e nao a curva: um corpo parado esta parado; a
# preparacao puxa para tras ANTES de o golpe cair (e o que deixa ler uma
# criatura a armar-se); o golpe vai para a frente; a recuperacao acaba em
# repouso. E que a preparacao acaba exactamente onde o golpe comeca — um salto
# entre os dois e um frame em que o corpo se teletransporta.
extends GdUnitTestSuite

const S := StrikePose.Style


func test_sem_golpe_nem_alvo_o_corpo_esta_parado() -> void:
	for estilo in [S.MELEE, S.RANGED, S.HEAVY]:
		assert_float(StrikePose.lunge(estilo, StrikePose.NUNCA, StrikePose.NUNCA)).is_equal(0.0)
		assert_float(StrikePose.swing(estilo, StrikePose.NUNCA, StrikePose.NUNCA)).is_equal(0.0)
		assert_vector(StrikePose.stretch(estilo, StrikePose.NUNCA, StrikePose.NUNCA)).is_equal(
			Vector2.ONE
		)


func test_a_preparacao_puxa_para_tras_antes_do_golpe() -> void:
	var meio := StrikePose.WINDUP_S * 0.5
	assert_int(StrikePose.phase(StrikePose.NUNCA, meio)).is_equal(StrikePose.Phase.WINDUP)
	assert_float(StrikePose.lunge(S.MELEE, StrikePose.NUNCA, meio)).is_less(0.0)
	assert_float(StrikePose.swing(S.MELEE, StrikePose.NUNCA, meio)).is_less(0.0)
	# Enrola-se: mais alto e mais estreito, o contrario do golpe.
	assert_float(StrikePose.stretch(S.MELEE, StrikePose.NUNCA, meio).y).is_greater(1.0)


func test_longe_do_golpe_nao_ha_preparacao() -> void:
	assert_int(StrikePose.phase(StrikePose.NUNCA, StrikePose.WINDUP_S * 2.0)).is_equal(
		StrikePose.Phase.REST
	)
	assert_float(StrikePose.lunge(S.HEAVY, StrikePose.NUNCA, StrikePose.WINDUP_S * 2.0)).is_equal(
		0.0
	)


func test_o_golpe_vai_para_a_frente_e_estica() -> void:
	assert_int(StrikePose.phase(StrikePose.STRIKE_S * 0.5, StrikePose.NUNCA)).is_equal(
		StrikePose.Phase.STRIKE
	)
	assert_float(StrikePose.lunge(S.MELEE, StrikePose.STRIKE_S, StrikePose.NUNCA)).is_greater(0.0)
	assert_float(StrikePose.stretch(S.MELEE, StrikePose.STRIKE_S, StrikePose.NUNCA).x).is_greater(
		1.0
	)
	assert_float(StrikePose.swing(S.MELEE, StrikePose.STRIKE_S, StrikePose.NUNCA)).is_greater(0.0)


## O arco nao avanca: solta a corda e o corpo da um coice para tras.
func test_quem_dispara_recua_ao_soltar() -> void:
	assert_float(StrikePose.lunge(S.RANGED, StrikePose.STRIKE_S, StrikePose.NUNCA)).is_less(0.0)
	assert_float(StrikePose.swing(S.RANGED, StrikePose.STRIKE_S, StrikePose.NUNCA)).is_equal(0.0)


func test_o_pesado_vai_mais_longe_do_que_o_ligeiro() -> void:
	var pesado := StrikePose.lunge(S.HEAVY, StrikePose.STRIKE_S, StrikePose.NUNCA)
	assert_float(pesado).is_greater(
		StrikePose.lunge(S.MELEE, StrikePose.STRIKE_S, StrikePose.NUNCA)
	)
	assert_float(StrikePose.hold(S.HEAVY)).is_greater(StrikePose.hold(S.MELEE))
	assert_float(StrikePose.strength(S.HEAVY)).is_greater(StrikePose.strength(S.RANGED))


## Sem salto: o ultimo instante da preparacao e o primeiro do golpe.
func test_a_preparacao_acaba_onde_o_golpe_comeca() -> void:
	for estilo in [S.MELEE, S.RANGED, S.HEAVY]:
		var fim := StrikePose.lunge(estilo, StrikePose.NUNCA, 0.0001)
		var inicio := StrikePose.lunge(estilo, 0.0, StrikePose.NUNCA)
		assert_float(fim).is_equal_approx(inicio, 0.05)


func test_a_recuperacao_acaba_em_repouso() -> void:
	var fim := StrikePose.STRIKE_S + StrikePose.RECOVER_S
	assert_int(StrikePose.phase(fim, StrikePose.NUNCA)).is_equal(StrikePose.Phase.REST)
	assert_float(StrikePose.lunge(S.HEAVY, fim, StrikePose.NUNCA)).is_equal(0.0)
	assert_vector(StrikePose.stretch(S.HEAVY, fim, StrikePose.NUNCA)).is_equal(Vector2.ONE)
	var quase := StrikePose.lunge(S.HEAVY, fim - 0.001, StrikePose.NUNCA)
	assert_float(absf(quase)).is_less(0.5)


## Uma cadencia curta poe a preparacao seguinte em cima da recuperacao: o golpe
## que ja caiu manda, e a preparacao espera que ele acabe.
func test_o_golpe_em_curso_passa_a_frente_da_preparacao() -> void:
	assert_int(StrikePose.phase(StrikePose.STRIKE_S * 0.5, StrikePose.WINDUP_S * 0.5)).is_equal(
		StrikePose.Phase.STRIKE
	)
	assert_int(StrikePose.phase(StrikePose.STRIKE_S + 0.01, StrikePose.WINDUP_S * 0.5)).is_equal(
		StrikePose.Phase.RECOVER
	)


func test_o_estilo_sai_da_arma_e_do_porte() -> void:
	assert_int(StrikePose.of_unit(Registry.entry(&"units", &"archer"))).is_equal(S.RANGED)
	assert_int(StrikePose.of_unit(Registry.entry(&"units", &"spearman"))).is_equal(S.MELEE)
	assert_int(StrikePose.of_creature(Registry.entry(&"creatures", &"crawler"))).is_equal(S.MELEE)
	assert_int(StrikePose.of_creature(Registry.entry(&"creatures", &"slime_ram"))).is_equal(S.HEAVY)
	assert_int(StrikePose.of_creature(Registry.entry(&"creatures", &"brute"))).is_equal(S.HEAVY)
	assert_int(StrikePose.of_unit(null)).is_equal(S.MELEE)


## A animacao `attack` de um sprite acompanha o golpe: comeca a armar, passa o
## impacto quando a simulacao o faz cair, e acaba em repouso.
func test_a_linha_do_golpe_vai_de_armar_a_voltar() -> void:
	var total := StrikePose.WINDUP_S + StrikePose.STRIKE_S + StrikePose.RECOVER_S
	assert_float(StrikePose.timeline(StrikePose.NUNCA, StrikePose.NUNCA)).is_equal(-1.0)
	var comeco := StrikePose.timeline(StrikePose.NUNCA, StrikePose.WINDUP_S - 0.0001)
	assert_float(comeco).is_equal_approx(0.0, 0.001)
	var impacto := StrikePose.timeline(0.0, StrikePose.NUNCA)
	assert_float(impacto).is_equal_approx(StrikePose.WINDUP_S / total, 0.001)
	assert_float(StrikePose.timeline(StrikePose.NUNCA, 0.0001)).is_equal_approx(impacto, 0.001)
	var quase := StrikePose.timeline(StrikePose.STRIKE_S + StrikePose.RECOVER_S - 0.001, 9.0)
	assert_float(quase).is_equal_approx(1.0, 0.01)
