# tests/abertura_test.gd — os primeiros vinte minutos, com a candeia la dentro
# (§83, XIII-10, GB-01).
#
# "O Amargueiro esta la desde o segundo zero": ao minuto 0:00 e cenario
# estranho; ao minuto 13:00 e a coisa mais assustadora do jogo. E a primeira
# oferta e a mais barata, de proposito: "Nada. So quero ver." — uma moeda.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")

const SEMENTE := 20260925


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_ao_minuto_zero_ha_um_amargueiro_velho_fora_do_muro_a_esquerda() -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()
	var bosque := SimLoop.night.amargueiros
	assert_int(bosque.count()).is_equal(1)
	assert_int(bosque.fates[0]).is_equal(AmargueiroSystem.Fate.OLD)
	# "Fora do muro": para la da primeira muralha a esquerda do nucleo — a
	# estacaria do minuto 3:30 (§25) —, e na mesma regiao.
	var primeiro_muro := 0.0
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths() and vaga.x < SimLoop.core_x:
			primeiro_muro = maxf(primeiro_muro, vaga.x - vaga.width * BuildSystem.METADE)
	assert_float(bosque.xs[0]).is_less(primeiro_muro)
	assert_float(bosque.xs[0]).is_greater(0.0)


func test_o_amargueiro_velho_nao_e_teu_nao_pesa_e_nao_se_serra() -> void:
	# §25: a noite 1 e ganha de certeza. A arvore velha e cenario (Q-104).
	var bosque := SimFactory.amargueiros()
	var o := BuildSystem.new()
	bosque.plant_old(100.0, int(Band.Kind.SURFACE), 2)
	assert_int(bosque.anonymous()).is_equal(0)
	for dia in range(1, 5):
		bosque.at_dawn(dia, UnitSystem.new(), o, B.NUCLEO, B.LARGURA)
	assert_int(o.count()).is_equal(0)
	assert_bool(bosque.consecrate(0, o)).is_false()


func test_a_primeira_oferta_da_campanha_e_nada_so_quero_ver() -> void:
	var u := UnitSystem.new()
	var noite := B.noite(u, BuildSystem.new())
	var estado := GameState.new()
	estado.day = 3  # o dia 3 ja tem as duas: a dos coxos e esta
	RngService.configure(SEMENTE)
	noite.tick(B.PASSO, int(GameClock.Phase.DUSK), true, estado, CreatureSystem.new(), _mundo())
	for _t in int(B.perfil().offer_window_after_dusk.y / B.PASSO) + 2:
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)
	var voz := noite.voice
	assert_str(String(voz.offers.offer_id)).is_equal("just_looking")
	assert_int(voz.spoken).is_equal(1)


func test_na_noite_2_a_voz_ainda_esta_calada() -> void:
	# ADR 0023: o §83 poe a primeira oferta ao 17:00, crepusculo do dia 3.
	var u := UnitSystem.new()
	var noite := B.noite(u, BuildSystem.new())
	var estado := GameState.new()
	estado.day = 2
	RngService.configure(SEMENTE)
	noite.tick(B.PASSO, int(GameClock.Phase.DUSK), true, estado, CreatureSystem.new(), _mundo())
	for _t in int(B.perfil().offer_window_after_dusk.y / B.PASSO) + 2:
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)
	assert_int(noite.voice.spoken).is_equal(0)


func test_pagar_a_primeira_revela_um_capitulo_e_a_noite_corre_igual() -> void:
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	var noite := B.noite(UnitSystem.new(), BuildSystem.new(), moedas)
	var estado := GameState.new()
	estado.day = 3
	RngService.configure(SEMENTE)
	noite.tick(B.PASSO, int(GameClock.Phase.DUSK), true, estado, CreatureSystem.new(), _mundo())
	var ver := Registry.entry(&"rot/offers", &"just_looking") as OfferData
	noite.voice.offers.open(ver, B.FORA, int(Band.Kind.SURFACE))
	var massa := noite.rot.mass()
	B.pousar(moedas, estado, B.FORA, int(ver.price_amount))
	noite.tick(B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo())
	assert_int(noite.voice.reveals).is_equal(1)
	assert_int(noite.voice.debt.debt).is_equal(ver.debt_delta)
	assert_float(noite.rot.mass()).is_equal(massa)  # "a noite 3 corre igual"


func _mundo() -> Vector2:
	return Vector2(B.NUCLEO, B.LARGURA)
