# tests/oferta_noite_test.gd — a Oferta ligada a noite (§75, XIII-04): as recusas
# pesam no crepusculo, o prato abre-se a borda da mancha, e aceitar paga-se e da.
#
# Corre pela NightWatch, que e o passo 2 do §43. Os sistemas puros tem os seus
# testes; aqui prova-se a ligacao.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")
const Model := preload("res://tests/support/reference_model.gd")

const SEMENTE := 20260925
const DIA := 5


func _mundo() -> Vector2:
	return Vector2(B.NUCLEO, B.LARGURA)


func _virar(noite: NightWatch, fase: GameClock.Phase, estado: GameState) -> void:
	noite.tick(B.PASSO, int(fase), true, estado, CreatureSystem.new(), _mundo())


func _noite_ate_ao_prato(noite: NightWatch, estado: GameState) -> void:
	for _t in int(B.perfil().offer_window_after_dusk.y / B.PASSO) + 2:
		if noite.voice.offers.phase != OfferSystem.Phase.WAITING:
			return
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)


func before_test() -> void:
	RngService.configure(SEMENTE)
	EventBus.reset()


func test_as_recusas_das_ultimas_noites_pesam_no_crepusculo() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	for d in [DIA - 3, DIA - 2, DIA - 1]:
		noite.voice.debt.refuse(d)
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_float(noite.rot.mass()).is_equal(Model.rot_mass(DIA, 0, B.perfil(), 0, 0, 3))


func test_a_oferta_abre_o_prato_a_borda_da_mancha_do_lado_do_imperio() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	_noite_ate_ao_prato(noite, estado)
	var o := noite.voice.offers
	assert_int(o.phase).is_equal(OfferSystem.Phase.OPEN)
	# A primeira da campanha e sempre a do §83, a mais barata.
	assert_str(String(o.offer_id)).is_equal(String(OfferWatch.PRIMEIRA))
	var rumo := signf(B.NUCLEO - noite.rot.position_x())
	assert_float(signf(o.plate_x - noite.rot.position_x())).is_equal(rumo)


func test_aceitar_sobe_a_divida_apaga_as_recusas_e_para_a_mancha() -> void:
	var u := UnitSystem.new()
	var noite := B.noite(u, BuildSystem.new())
	noite.voice.debt.refuse(DIA - 1)
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	var coxos := Registry.entry(&"rot/offers", &"the_lame") as OfferData
	noite.voice.offers.open(coxos, noite.rot.position_x(), int(Band.Kind.SURFACE))
	var ferido := u.spawn(
		estado, Registry.entry(&"units", &"archer"), B.MEU_IMPERIO, noite.voice.offers.plate_x
	)
	u.healths[u.index_of(ferido)] = 1
	noite.tick(B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo())
	assert_int(noite.voice.debt.debt).is_equal(coxos.debt_delta)
	assert_int(noite.voice.debt.refusals(DIA + 1)).is_equal(0)
	assert_int(u.index_of(ferido)).is_equal(UnitSystem.NENHUM)
	var onde := noite.rot.position_x()
	for _t in int(coxos.effect_value / B.PASSO) - 2:
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)
	assert_float(noite.rot.position_x()).is_equal(onde)  # parada os 25 s


func test_quem_nao_paga_recusa() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	_noite_ate_ao_prato(noite, estado)
	for _t in int(B.perfil().offer_seconds / B.PASSO) + 2:
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)
	assert_int(noite.voice.debt.refusals(DIA + 1)).is_equal(1)
	assert_int(noite.voice.debt.debt).is_equal(0)


func test_depois_da_decima_segunda_ela_nao_volta_a_nascer() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	noite.voice.debt.ended = true
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_bool(noite.rot.active()).is_false()


func test_o_que_e_permanente_pesa_em_todas_as_noites() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	noite.voice.debt.mass_mult_permanent = 0.85
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_float(noite.rot.mass()).is_equal_approx(Model.rot_mass(DIA, 0, B.perfil()) * 0.85, 0.01)


func test_com_a_divida_no_limiar_o_zelador_nasce_com_ela_e_vai_se_na_alvorada() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	var estado := GameState.new()
	estado.day = DIA
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_bool(noite.voice.tender.active).is_false()
	noite.voice.debt.incur(B.perfil().tender_from_debt)
	_virar(noite, GameClock.Phase.DAWN, estado)
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_bool(noite.voice.tender.active).is_true()
	# Nasce onde ela nasce; ela anda no mesmo tick, e ele fica atras.
	var passo := noite.rot.speed() * B.PASSO
	assert_float(noite.voice.tender.x).is_equal_approx(noite.rot.position_x(), passo)
	_virar(noite, GameClock.Phase.DAWN, estado)
	assert_bool(noite.voice.tender.active).is_false()
