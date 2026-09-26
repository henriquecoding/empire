# tests/noite_legivel_test.gd — a noite diz-se antes de chegar, tem ritmo, aceita
# sacrificios e poe a gente no sitio (AUD-03; §05, §51; Q-125 a Q-128).
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const ASSENTAR := 45
const O_ARQUEIRO := 7
const O_VAGABUNDO := 2

var _fed := 0.0


func before_test() -> void:
	_fed = 0.0
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.rot_fed.connect(_comeu)
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.builds.slots[0].health = 1000000  # a pergunta e a noite, nao o nucleo


func after_test() -> void:
	EventBus.rot_fed.disconnect(_comeu)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## So o sacrificio de moedas (Q-127): uma oferta aceite tambem alimenta (§75).
func _comeu(massa: float, oferta: StringName) -> void:
	if oferta == &"coins":
		_fed += massa


func _ate(fase: GameClock.Phase) -> void:
	while ClockService.clock.current_phase() != fase:
		SimLoop.step(STEP)


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func test_a_tarde_diz_o_lado_e_e_o_lado_da_noite() -> void:
	_ate(GameClock.Phase.NOON)
	assert_int(SimLoop.night.rot.announced).is_equal(0)
	_ate(GameClock.Phase.AFTERNOON)
	SimLoop.step(STEP)
	var dito := SimLoop.night.rot.announced
	assert_int(absi(dito)).is_equal(1)
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	assert_int(SimLoop.night.rot.state.side).is_equal(dito)
	assert_int(SimLoop.night.rot.announced).is_equal(0)


func test_o_lado_dito_vai_no_save() -> void:
	_ate(GameClock.Phase.AFTERNOON)
	SimLoop.step(STEP)
	var copia := SimFactory.rot()
	copia.from_dict(SimLoop.night.rot.to_dict())
	assert_int(copia.announced).is_equal(SimLoop.night.rot.announced)


func test_o_guia_da_tarde_diz_o_lado() -> void:
	TranslationServer.set_locale("pt_PT")
	_ate(GameClock.Phase.AFTERNOON)
	SimLoop.step(STEP)
	var lado := "LESTE" if SimLoop.night.rot.announced > 0 else "OESTE"
	assert_str(GameplayGuide.goal()).contains(lado)


func test_de_seis_em_seis_noites_uma_funda_e_a_seguir_uma_calma() -> void:
	var rot := SimFactory.rot()
	var perfil := SimFactory.rot_profile()
	assert_float(rot.rhythm(perfil.peak_every)).is_equal(perfil.peak_mass_mult)
	assert_float(rot.rhythm(perfil.peak_every + 1)).is_equal(perfil.calm_mass_mult)
	assert_float(rot.rhythm(perfil.peak_every - 1)).is_equal(1.0)
	assert_bool(rot.deep(perfil.peak_every)).is_true()
	rot.spawn(perfil.peak_every, 1, 1000.0)
	var funda := rot.state.mass
	rot.spawn(perfil.peak_every - 1, 1, 1000.0)
	assert_float(funda).is_greater(rot.state.mass)


func test_moedas_do_rei_dentro_da_mancha_tiram_lhe_massa() -> void:
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	var rot := SimLoop.night.rot
	var antes := rot.state.mass
	var x := rot.position_x()
	for _k in 4:
		SimLoop.drop_coin(x, Band.Kind.SURFACE, 1, Verbs.JOGADOR)
	for _t in ASSENTAR:
		SimLoop.step(STEP)
	var perfil := SimFactory.rot_profile()
	assert_float(_fed).is_equal_approx(4 * perfil.sacrifice_mass_per_coin, 0.001)
	assert_float(rot.state.mass).is_less(antes)


func test_o_saque_dentro_da_mancha_nao_e_sacrificio() -> void:
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	var x := SimLoop.night.rot.position_x()
	for _k in 4:
		SimLoop.drop_coin(x, Band.Kind.SURFACE, 1, EventRelay.FONTE_MORTE)
	for _t in ASSENTAR:
		SimLoop.step(STEP)
	assert_float(_fed).override_failure_message("comeu %s" % _fed).is_equal(0.0)


func test_ao_crepusculo_quem_luta_vai_para_a_borda_do_lado_da_noite() -> void:
	var dono := SimLoop.units.owners[_rei()]
	var arqueiro := SimLoop.units.index_of(O_ARQUEIRO)
	SimLoop.units.owners[arqueiro] = dono
	SimLoop.units.owners[SimLoop.units.index_of(O_VAGABUNDO)] = dono
	_ate(GameClock.Phase.DUSK)
	for _t in 3:
		SimLoop.step(STEP)
	var rot := SimLoop.night.rot
	var nucleo := SimLoop.builds.slots[0]
	arqueiro = SimLoop.units.index_of(O_ARQUEIRO)
	var borda := nucleo.x + rot.state.side * nucleo.width * 0.5
	assert_float(SimLoop.units.target_xs[arqueiro]).is_equal_approx(borda, 1.0)
	var vagabundo := SimLoop.units.index_of(O_VAGABUNDO)
	if SimLoop.units.job_ids[vagabundo] == UnitSystem.NENHUM:
		assert_float(SimLoop.units.target_xs[vagabundo]).is_equal_approx(nucleo.x, 1.0)
