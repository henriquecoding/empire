# tests/archote_test.gd — a fogueira, o archote e o escuro (§05, Q-029).
#
# O dono aprovou a fogueira e acrescentou: "e possivel adquirir um item que o
# jogador pode carregar com ele para ajudar a explorar, esse item tem limite de
# uso, e se o jogador explora a noite sem item e muito perigoso, pois podem
# aparecer inimigos de qualquer lugar". Os numeros sao do rot.csv.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func _obra(tipo: StringName, x: float) -> BuildSlot:
	var dados := Registry.entry(&"buildings", tipo) as BuildingData
	var vaga := Greybox.slot_of(dados, x)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


# ─── A fogueira (§05: "fogueiras abrandam-na") ───────────────────────────────


func test_a_fogueira_custa_tres_e_abranda_como_o_barril() -> void:
	var fogueira := Registry.entry(&"buildings", &"campfire") as BuildingData
	var barril := Registry.entry(&"buildings", &"fire_barrel") as BuildingData
	assert_int(fogueira.cost).is_equal(3)
	assert_float(float(fogueira.effect_params[&"rot_slow"])).is_equal(
		float(barril.effect_params[&"rot_slow"])
	)


func test_a_mancha_anda_mais_devagar_por_cima_do_fogo() -> void:
	var obras := BuildSystem.new()
	obras.post(_obra(&"campfire", 500.0))
	var zonas := FireZones.of(obras)
	assert_int(zonas.size()).is_equal(1)
	assert_float(FireZones.slow(500.0, zonas)).is_equal(0.25)
	assert_float(FireZones.slow(5000.0, zonas)).is_equal(0.0)
	var rot := SimFactory.rot()
	rot.spawn(3, 1, 1000.0)
	var x0 := rot.position_x()
	rot.tick(1.0, [])
	var livre := absf(rot.position_x() - x0)
	var zona: Array[Vector3] = [Vector3(-1e6, 1e6, 0.25)]
	var x1 := rot.position_x()
	rot.tick(1.0, [], zona)
	assert_float(absf(rot.position_x() - x1)).is_equal_approx(livre * 0.75, 0.001)


func test_a_fogueira_e_mais_fraca_do_que_a_candeia() -> void:
	# §80: "as tuas fogueiras tem de ser mais fracas do que a candeia".
	var fogueira := Registry.entry(&"buildings", &"campfire") as BuildingData
	var raio := float(fogueira.effect_params[&"light_radius"])
	var forca := float(fogueira.effect_params[&"light_strength"])
	var tecto := _perfil().lantern_radius_max
	assert_bool(WorldLight.dominates(tecto, raio, forca, _perfil())).is_true()


# ─── O archote ───────────────────────────────────────────────────────────────


func test_levam_se_ate_ao_maximo() -> void:
	var t := Torchlight.new(_perfil())
	assert_int(t.buy(99)).is_equal(_perfil().torch_max)
	assert_int(t.buy(1)).is_equal(0)


func test_no_escuro_acende_se_sozinho_e_acaba() -> void:
	var t := Torchlight.new(_perfil())
	t.buy(1)
	assert_bool(t.tick(PASSO, true, true)).is_false()
	assert_bool(t.lit()).is_true()
	assert_int(t.torches).is_equal(0)
	var ardeu := 0.0
	while t.lit() and ardeu < 1000.0:
		assert_bool(t.tick(PASSO, true, true)).is_false()  # aceso, ninguem vem
		ardeu += PASSO
	assert_float(ardeu).is_equal_approx(_perfil().torch_burn_s, 0.1)


func test_no_escuro_sem_archote_vem_gente_ate_ao_teto_da_noite() -> void:
	var t := Torchlight.new(_perfil())
	var vieram := 0
	for _i in int(300.0 / PASSO):
		if t.tick(PASSO, true, true):
			vieram += 1
	assert_int(vieram).is_equal(_perfil().dark_ambush_max)


func test_a_luz_de_dia_e_dentro_das_muralhas_nao_trazem_ninguem() -> void:
	var t := Torchlight.new(_perfil())
	for _i in int(60.0 / PASSO):
		assert_bool(t.tick(PASSO, false, true)).is_false()
		assert_bool(t.tick(PASSO, true, false)).is_false()


func test_o_escuro_e_fora_do_nucleo_das_muralhas_e_das_luzes() -> void:
	var obras := BuildSystem.new()
	var muro := WallSite.slot(1300.0)
	muro.level = 1
	muro.state = BuildSlot.State.DONE
	obras.post(muro)
	obras.post(_obra(&"campfire", -1230.0))
	assert_bool(Torchlight.in_dark(100.0, obras, 0.0, 240.0)).is_false()  # nucleo
	assert_bool(Torchlight.in_dark(1100.0, obras, 0.0, 240.0)).is_false()  # atras do muro
	assert_bool(Torchlight.in_dark(1500.0, obras, 0.0, 240.0)).is_true()  # la fora
	assert_bool(Torchlight.in_dark(-1250.0, obras, 0.0, 240.0)).is_false()  # a fogueira
	assert_bool(Torchlight.in_dark(-1600.0, obras, 0.0, 240.0)).is_true()


# ─── No jogo ─────────────────────────────────────────────────────────────────


func test_uma_moeda_na_fogueira_compra_um_archote() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)
	Greybox.build()
	var fogueira: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == Campfires.FOGUEIRA:
			fogueira = vaga
	assert_object(fogueira).is_not_null()
	fogueira.level = 1
	fogueira.state = BuildSlot.State.DONE
	var largada := {
		EventRelay.ONDE: fogueira.x, EventRelay.FAIXA: int(fogueira.band), EventRelay.QUANTO: 1
	}
	assert_bool(SimLoop.night.dark.buy_at(largada, SimLoop.builds)).is_true()
	assert_int(SimLoop.night.dark.torch.torches).is_equal(1)
	var guardado := SimLoop.world()
	SimLoop.night.dark.torch.torches = 0
	SimLoop.load_world(guardado)
	assert_int(SimLoop.night.dark.torch.torches).is_equal(1)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
