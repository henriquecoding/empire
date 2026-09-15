# tests/minuto_0_20_test.gd — o "Feito" do F1-04, que e uma frase do dossie.
#
#   "O vagabundo segue-te. Largas uma moeda perto dele. Ele apanha-a e ganha um
#    chapeu. Nada mais e preciso dizer."   (§25, §83)
#
# Corre a sequencia inteira pelo SimLoop, ao passo fixo, como o jogo a corre. As
# pecas em separado estao no tests/recruit_system_test.gd.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
## §63, e e o unico orcamento que o dossie da que sirva aqui: a simulacao
## inteira, tick completo. Este passo nao tem linha propria porque nem existe no
## §43, e inventar-lhe um numero era inventar.
const ORCAMENTO_TICK_US := 4000
const TROPAS := 300
const MOEDAS := 60
## O imperio do jogador. Um id qualquer que nao seja o SEM_DONO serve — o que se
## testa e que ele muda de dono, nao qual e o numero.
const MEU_IMPERIO := 7


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _vagabundo() -> UnitData:
	return Registry.entry(&"units", &"vagrant")


func _monarca() -> UnitData:
	return Registry.entry(&"units", &"monarch")


func _correr(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		SimLoop.step(PASSO)


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


# ─── O minuto 0:20 ───────────────────────────────────────────────────────────


func test_o_minuto_0_20_do_25_funciona() -> void:
	SimLoop.start(SEMENTE)
	var eu := SimLoop.units.spawn(SimLoop.state, _monarca(), MEU_IMPERIO, 0.0)
	SimLoop.king_id = eu
	var ele := SimLoop.units.spawn(SimLoop.state, _vagabundo(), RecruitSystem.SEM_DONO, 40.0)
	var i := SimLoop.units.index_of(ele)
	var gasto: Array = []
	var ouvinte := func(quanto: int, porque: StringName) -> void: gasto.append([quanto, porque])
	EventBus.coin_spent.connect(ouvinte)

	# "Largas uma moeda perto dele." Perto: ao lado, nao em cima.
	SimLoop.drop_coin(60.0, Band.Kind.SURFACE, 1, &"player")
	_correr(4.0)

	# "Ele apanha-a" — e a moeda saiu do chao.
	(
		assert_int(SimLoop.units.carried_coins[i])
		. override_failure_message("a moeda ficou no chao: ele nao foi buscar ou nao chegou")
		. is_equal(1)
	)
	assert_int(SimLoop.coins.count()).is_equal(0)

	# "...e ganha um chapeu": deixou de ser de ninguem e passou a ser meu. O
	# chapeu e o que o ecra mostra disto; a arte e ART-02 e ainda nao existe.
	(
		assert_int(SimLoop.units.owners[i])
		. override_failure_message("apanhou a moeda e continuou a nao ser de ninguem")
		. is_equal(MEU_IMPERIO)
	)
	# §46: o coin_spent e de "Build, recrutamento", e este e o recrutamento.
	assert_array(gasto).is_equal([[_vagabundo().recruit_cost, &"recruit"]])
	EventBus.coin_spent.disconnect(ouvinte)

	# "O vagabundo segue-te." Ando para longe; ele vem atras e para a distancia
	# da fila, e nao em cima de mim.
	SimLoop.units.xs[SimLoop.units.index_of(eu)] = 400.0
	_correr(30.0)

	var curva := _curva()
	assert_float(SimLoop.units.xs[i]).is_equal(400.0 - curva.follow_distance_px)


func test_o_minuto_0_20_da_o_mesmo_com_a_mesma_semente() -> void:
	# A promessa do §21 sobre um caminho que agora tem mais um sistema dentro.
	var correr := func() -> Dictionary:
		SimLoop.start(SEMENTE)
		var eu := SimLoop.units.spawn(SimLoop.state, _monarca(), MEU_IMPERIO, 0.0)
		SimLoop.king_id = eu
		SimLoop.units.spawn(SimLoop.state, _vagabundo(), RecruitSystem.SEM_DONO, 40.0)
		SimLoop.drop_coin(60.0, Band.Kind.SURFACE, 1, &"player")
		_correr(6.0)
		return SimLoop.units.to_dict()

	var primeira: Dictionary = correr.call()
	var segunda: Dictionary = correr.call()

	assert_dict(segunda).is_equal(primeira)


func test_sem_rei_a_moeda_apanha_se_e_nao_compra_ninguem() -> void:
	# O §25 nao desenha este caso, mas ele existe: um vagabundo apanha a moeda
	# que encontra. Nao ficar de ninguem e o que impede um vagabundo neutro de
	# se recrutar sozinho a si proprio.
	SimLoop.start(SEMENTE)
	var ele := SimLoop.units.spawn(SimLoop.state, _vagabundo(), RecruitSystem.SEM_DONO, 40.0)
	var i := SimLoop.units.index_of(ele)

	SimLoop.drop_coin(60.0, Band.Kind.SURFACE, 1, &"player")
	_correr(4.0)

	assert_int(SimLoop.units.carried_coins[i]).is_equal(1)
	assert_int(SimLoop.units.owners[i]).is_equal(RecruitSystem.SEM_DONO)


# ─── O orcamento ─────────────────────────────────────────────────────────────


func test_um_tick_inteiro_com_300_unidades_e_moedas_no_chao() -> void:
	# O §63 da UM numero que serve aqui: 4,0 ms para a simulacao inteira. Este
	# passo nao tem linha propria — nem existe no §43 — e por isso nao se lhe
	# inventa um orcamento: mede-se o tick completo contra o numero que esta
	# escrito, e o custo da procura vai para o registo ao lado, para ser lido.
	#
	# O pior caso e este: TODOS por recrutar, porque quem ja tem dono nem entra
	# no ciclo das moedas. No jogo do §25 sao um vagabundo e uma moeda.
	SimLoop.start(SEMENTE)
	var eu := SimLoop.units.spawn(SimLoop.state, _monarca(), MEU_IMPERIO, 0.0)
	SimLoop.king_id = eu
	var dados := _vagabundo()
	for i in TROPAS:
		SimLoop.units.spawn(SimLoop.state, dados, RecruitSystem.SEM_DONO, float(i) * 10.0)
	for i in MOEDAS:
		SimLoop.drop_coin(float(i) * 50.0 + 5000.0, Band.Kind.SURFACE, 1, &"player")
	_correr(2.0)  # longe de toda a gente, e ja pousadas

	var voltas := 60
	var t0 := Time.get_ticks_usec()
	for _v in voltas:
		SimLoop.step(PASSO)
	var us := float(Time.get_ticks_usec() - t0) / float(voltas)

	var t1 := Time.get_ticks_usec()
	for v in voltas:
		SimLoop.recruits.seek_coins(SimLoop.units, SimLoop.coins, v)
	var procura := float(Time.get_ticks_usec() - t1) / float(voltas)

	print(
		(
			"F1-04: tick com %d unidades e %d moedas = %.1f us (§63: 4000) · a procura sozinha %.1f us"
			% [TROPAS, MOEDAS, us, procura]
		)
	)
	var porque := "%.1f us contra os 4000 us da simulacao inteira (§63)" % us
	assert_bool(us < ORCAMENTO_TICK_US).override_failure_message(porque).is_true()
