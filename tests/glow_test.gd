# tests/glow_test.gd — uma luz, o fogo que cintila e o que chega a cada coisa (ADR 0048).
#
# As contas da luz vivem no GDScript e o shader do cenario so as aplica: e aqui que
# se prova que uma fogueira alumia, que alumia em tres paragens e nunca em
# gradiente (§80), que o Lume continua a dominar o fogo que e teu (Q-078), e que de
# dia nenhuma luz se ve.
extends GdUnitTestSuite

const MEIO := 0.5
const RAIO := 96.0
const CHAO := 517.0


func _dados() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _fogo(x: float, forca: float) -> Glow:
	var cores := WorldLight.fire_stops(SimFactory.rot_profile())
	return Glow.new(Vector2(x, CHAO), int(Band.Kind.SURFACE), RAIO, forca, cores, Flicker.Kind.FIRE)


func _lume(x: float) -> Glow:
	var cores := WorldLight.stops(SimFactory.rot_profile())
	return Glow.new(Vector2(x, CHAO), int(Band.Kind.SURFACE), RAIO, 1.0, cores, Flicker.Kind.LUME)


func _noite(luzes: Array[Glow]) -> Lighting:
	var luz := Lighting.new()
	luz.set_phase(_dados(), GameClock.Phase.NIGHT, MEIO)
	luz.set_glows(luzes, CHAO)
	return luz


func test_tres_paragens_e_nada_fora() -> void:
	var fogo := _fogo(0.0, 1.0)
	assert_int(fogo.stop_at(0.0)).is_equal(2)
	assert_int(fogo.stop_at(RAIO * 0.5)).is_equal(1)
	assert_int(fogo.stop_at(RAIO * 0.9)).is_equal(0)
	assert_int(fogo.stop_at(RAIO + 1.0)).is_equal(-1)
	assert_float(fogo.light_at(Vector2(RAIO * 2.0, CHAO)).get_luminance()).is_equal(0.0)


func test_entre_paragens_nao_ha_gradiente() -> void:
	# §80: "tres paragens, nunca um gradiente". Dentro de uma paragem a luz e uma so.
	var fogo := _fogo(0.0, 1.0)
	var perto := fogo.light_at(Vector2(RAIO * 0.4, CHAO))
	var mais_longe := fogo.light_at(Vector2(RAIO * 0.6, CHAO))
	assert_bool(perto.is_equal_approx(mais_longe)).is_true()


func test_a_forca_escurece_as_paragens() -> void:
	var cheia := _fogo(0.0, 1.0).light_at(Vector2(0.0, CHAO))
	var meia := _fogo(0.0, 0.5).light_at(Vector2(0.0, CHAO))
	assert_float(meia.r).is_equal_approx(cheia.r * 0.5, 0.0001)


func test_quanto_mais_perto_mais_dentro() -> void:
	var fogo := _fogo(0.0, 0.5)
	assert_float(fogo.reach_at(Vector2(0.0, CHAO))).is_equal(1.0)
	assert_float(fogo.reach_at(Vector2(RAIO * 0.9, CHAO))).is_less(1.0)
	assert_float(fogo.reach_at(Vector2(RAIO * 0.9, CHAO))).is_greater(0.0)
	assert_float(fogo.reach_at(Vector2(RAIO * 3.0, CHAO))).is_equal(0.0)


func test_a_noite_uma_fogueira_alumia_quem_esta_perto() -> void:
	var luz := _noite([_fogo(0.0, 0.5)])
	var perto := luz.body(Color.WHITE, 0.0)
	var longe := luz.body(Color.WHITE, RAIO * 5.0)
	assert_float(perto.get_luminance()).is_greater(longe.get_luminance() * 2.0)
	# Longe de tudo ve-se a silhueta — e uma silhueta que se le, nao preto (ADR 0048).
	assert_float(longe.get_luminance()).is_greater(WorldPalette.SILHUETA.get_luminance())


func test_de_dia_as_luzes_nao_se_veem() -> void:
	var luz := Lighting.new()
	luz.set_phase(_dados(), GameClock.Phase.NOON, MEIO)
	luz.set_glows([_fogo(0.0, 0.5)], CHAO)
	assert_float(luz.dark).is_equal(0.0)
	assert_bool(luz.on(0.0).is_equal_approx(luz.on(RAIO * 5.0))).is_true()


func test_a_noite_funda_e_escuro_inteiro() -> void:
	assert_float(_noite([]).dark).is_equal_approx(1.0, 0.0001)


func test_duas_luzes_nao_queimam_a_cor() -> void:
	var luz := _noite([_lume(0.0), _lume(0.0), _fogo(0.0, 1.0)])
	var cor := luz.on(0.0)
	assert_float(maxf(cor.r, maxf(cor.g, cor.b))).is_less_equal(Lighting.TETO + 0.0001)


func test_o_lume_domina_a_fogueira_a_mesma_distancia() -> void:
	# §80 e Q-078: as tuas fogueiras sao mais fracas do que o Lume a mesma distancia.
	for d in [0.0, RAIO * 0.5, RAIO * 0.9]:
		var lume := _noite([_lume(0.0)]).on(d)
		var fogo := _noite([_fogo(0.0, 0.5)]).on(d)
		assert_float(lume.get_luminance()).is_greater(fogo.get_luminance())


func test_o_fogo_cintila_pouco_e_nunca_em_uniao() -> void:
	var a := PackedFloat32Array()
	var b := PackedFloat32Array()
	for passo in 120:
		var t := float(passo) / 30.0
		a.append(Flicker.of(Flicker.Kind.FIRE, t, 1000.0))
		b.append(Flicker.of(Flicker.Kind.FIRE, t, 1400.0))
	var diferentes := 0
	for i in a.size():
		assert_float(a[i]).is_between(0.9, 1.1)
		if not is_equal_approx(a[i], b[i]):
			diferentes += 1
	assert_int(diferentes).is_greater(a.size() / 2)


func test_sem_cintilar_e_a_luz_inteira() -> void:
	assert_float(Flicker.of(Flicker.Kind.STEADY, 3.7, 50.0)).is_equal(1.0)


func test_a_borda_cintila_aos_saltos_de_uma_celula() -> void:
	for passo in 60:
		var raio := Flicker.radius(RAIO, Flicker.Kind.FIRE, float(passo) * 0.1, 0.0, 2.0)
		assert_float(fposmod(raio, 2.0)).is_equal_approx(0.0, 0.0001)
		assert_float(raio).is_between(RAIO * 0.9, RAIO * 1.1)


func test_o_cenario_recebe_as_luzes_onde_elas_se_veem() -> void:
	var luz := _noite([_fogo(100.0, 0.5)])
	var canvas := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(-200.0, 10.0))
	var u := SceneryLight.uniforms(luz, canvas)
	var onde: Vector4 = (u[&"onde"] as PackedVector4Array)[0]
	var no_ecra := canvas * Vector2(100.0, CHAO)
	assert_float(onde.x).is_equal_approx(no_ecra.x, 0.001)
	assert_float(onde.y).is_equal_approx(no_ecra.y, 0.001)
	assert_float(onde.z).is_equal_approx(RAIO * 1.5, 0.001)
	assert_float(onde.w).is_equal_approx(0.5 * Lighting.GANHO, 0.001)
	assert_int(u[&"luzes"]).is_equal(1)
	# O shader declara dezasseis: o resto do array vai a zero.
	assert_int((u[&"onde"] as PackedVector4Array).size()).is_equal(SceneryLight.MAX_LUZES)


func test_o_cenario_nunca_recebe_mais_luzes_do_que_o_shader_le() -> void:
	var muitas: Array[Glow] = []
	for i in SceneryLight.MAX_LUZES + 5:
		muitas.append(_fogo(float(i) * 10.0, 0.5))
	var u := SceneryLight.uniforms(_noite(muitas), Transform2D.IDENTITY)
	assert_int(u[&"luzes"]).is_equal(SceneryLight.MAX_LUZES)
	assert_int((u[&"nucleo"] as PackedVector3Array).size()).is_equal(SceneryLight.MAX_LUZES)
