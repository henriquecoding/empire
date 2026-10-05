# tests/subsolo_delimitado_test.gd — o desenho de um sitio do subsolo, puro (o pedido do
# dono de 02/10/2026; §11, §21; Q-186, ADR 0046). O jogo esta no subsolo_sitios_test.
#
# "O subsolo nao e infinito acompanhando o piso de cima, e sempre algo delimitado, pode
# ser grande, mas nunca infinito, e gerado proceduralmente e a primeira vez que e acedido
# naquela jogatina e algo distinto, o local onde aparece e aleatorio, mas coerente com o
# local; nos imperios e comum ter subsolos com locais onde se pode armazenar coisas ou
# com uma sala secreta no imperador."
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SALA := Vector2(100.0, 200.0)
const BOCA := 1000.0
const LONGE := 5000.0
const SEGUNDOS := 30.0
const TESTE := "teste"


func _spec(extra: int, features: Array = []) -> Dictionary:
	return {
		UndergroundSites.ROOM: SALA,
		UndergroundSites.EXTRA: extra,
		UndergroundSites.POOL: [&"storage", &"wine"],
		UndergroundSites.ENTRANCE: &"stair",
		UndergroundSites.ENTRANCE_PX: 0.0,
		UndergroundSites.FEATURES: features,
	}


func _sorteios(valor: float) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	saida.resize(UndergroundSites.ROLLS)
	saida.fill(valor)
	return saida


# ─── O desenho de um sitio: puro ─────────────────────────────────────────────


func test_um_sitio_cobre_o_que_precisa_e_nunca_sai_do_tecto() -> void:
	var cap := Vector2(600.0, 1400.0)
	for u in [0.0, 0.3, 0.7, 0.99]:
		var salas := UnderLayout.lay_out(BOCA, Vector2(850.0, 1150.0), cap, _sorteios(u), _spec(3))
		var a: float = salas.front()[UndergroundSites.A]
		var b: float = salas.back()[UndergroundSites.B]
		assert_float(a).is_less_equal(850.0)
		assert_float(b).is_greater_equal(1150.0)
		assert_float(a).is_greater_equal(cap.x)
		assert_float(b).is_less_equal(cap.y)
		assert_int(salas.size()).is_less_equal(UndergroundSites.MAX_ROOMS)


func test_as_salas_sao_seguidas_e_a_boca_fica_na_da_entrada() -> void:
	var salas := UnderLayout.lay_out(
		BOCA, Vector2(BOCA, BOCA), Vector2(0.0, 3000.0), _sorteios(0.6), _spec(3)
	)
	assert_int(salas.size()).is_greater(1)
	for k in range(1, salas.size()):
		assert_float(salas[k][UndergroundSites.A]).is_equal(salas[k - 1][UndergroundSites.B])
	var entrada := -1
	for k in salas.size():
		if salas[k][UndergroundSites.KIND] == &"stair":
			entrada = k
	assert_int(entrada).is_not_equal(-1)
	assert_float(salas[entrada][UndergroundSites.A]).is_less_equal(BOCA)
	assert_float(salas[entrada][UndergroundSites.B]).is_greater_equal(BOCA)


func test_sem_tecto_largo_o_sitio_continua_delimitado() -> void:
	var salas := UnderLayout.lay_out(
		BOCA, Vector2(BOCA, BOCA), Vector2(-INF, INF), _sorteios(0.99), _spec(100)
	)
	assert_int(salas.size()).is_less_equal(UndergroundSites.MAX_ROOMS)
	var largura: float = salas.back()[UndergroundSites.B] - salas.front()[UndergroundSites.A]
	assert_float(largura).is_less_equal(SALA.y * UndergroundSites.MAX_ROOMS)


func test_sorteios_diferentes_dao_sitios_diferentes_e_os_mesmos_o_mesmo() -> void:
	var cap := Vector2(0.0, 3000.0)
	var um := UnderLayout.lay_out(BOCA, Vector2(BOCA, BOCA), cap, _sorteios(0.2), _spec(3))
	var outro := UnderLayout.lay_out(BOCA, Vector2(BOCA, BOCA), cap, _sorteios(0.8), _spec(3))
	var igual := UnderLayout.lay_out(BOCA, Vector2(BOCA, BOCA), cap, _sorteios(0.2), _spec(3))
	assert_bool(um == outro).is_false()
	assert_bool(um == igual).is_true()


## O que esta la entra nas features da sala e ja nao lhe apaga a funcao (ADR 0072, SUB-10).
func test_o_que_esta_la_fica_na_sala_sem_lhe_apagar_a_funcao() -> void:
	var features := [[1180.0, &"mine"]]
	var salas := UnderLayout.lay_out(
		BOCA, Vector2(BOCA, 1200.0), Vector2(0.0, 3000.0), _sorteios(0.5), _spec(0, features)
	)
	var achou := false
	for sala: Dictionary in salas:
		if sala[UndergroundSites.A] <= 1180.0 and sala[UndergroundSites.B] >= 1180.0:
			achou = (sala[UndergroundSites.FEATS] as Array).has(&"mine")
			assert_str(String(sala[UndergroundSites.KIND])).is_not_equal("mine")
			assert_bool([&"stair", &"storage", &"wine"].has(sala[UndergroundSites.KIND])).is_true()
	assert_bool(achou).is_true()


# ─── O registo: autorado, gerado na primeira vez, gravado ────────────────────


func test_um_sitio_so_se_gera_quando_se_entra_e_fica_gerado() -> void:
	var sitios := UndergroundSites.new()
	sitios.post(
		TESTE, UndergroundSites.CELLAR, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), _spec(2)
	)
	assert_int(sitios.count()).is_equal(1)
	var i := sitios.find(BOCA + 10.0, Band.PASSAGE_PX)
	assert_int(i).is_equal(0)
	assert_int(sitios.find(BOCA + 100.0, Band.PASSAGE_PX)).is_equal(-1)
	assert_bool(sitios.generated(i)).is_false()
	assert_bool(is_nan(sitios.span(i).x)).is_true()
	assert_int(sitios.site_at(BOCA)).is_equal(-1)
	assert_bool(sitios.generate(i, _sorteios(0.4))).is_true()
	assert_bool(sitios.generated(i)).is_true()
	var antes := sitios.rooms(i).duplicate(true)
	assert_bool(sitios.generate(i, _sorteios(0.9))).is_false()
	assert_bool(sitios.rooms(i) == antes).is_true()
	assert_int(sitios.site_at(BOCA)).is_equal(i)
	assert_str(String(sitios.kind_of(i))).is_equal(String(UndergroundSites.CELLAR))
	assert_float(sitios.mouth_of(i)).is_equal(BOCA)


func test_o_save_guarda_o_que_se_gerou_e_nao_apaga_o_autorado() -> void:
	var sitios := UndergroundSites.new()
	sitios.post(
		TESTE, UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), _spec(1)
	)
	sitios.generate(0, _sorteios(0.3))
	var gravado := sitios.to_dict()
	var outro := UndergroundSites.new()
	outro.post(TESTE, UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), _spec(1))
	outro.from_dict(gravado)
	assert_bool(outro.generated(0)).is_true()
	assert_bool(outro.rooms(0) == sitios.rooms(0)).is_true()
	assert_float(outro.hatches()[0]).is_equal(BOCA)
	var vazio := UndergroundSites.new()
	vazio.post(TESTE, UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), _spec(1))
	vazio.from_dict({})
	assert_int(vazio.count()).is_equal(1)
	assert_bool(vazio.generated(0)).is_false()


func test_quem_esta_la_em_baixo_nao_passa_das_paredes_do_sitio() -> void:
	var sitios := UndergroundSites.new()
	sitios.post(
		TESTE, UndergroundSites.CELLAR, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), _spec(2)
	)
	sitios.generate(0, _sorteios(0.5))
	var limites := sitios.span(0)
	var unidades := UnitSystem.new()
	var dados := Registry.entry(&"units", &"monarch") as UnitData
	var estado := GameState.new()
	var baixo := unidades.spawn(estado, dados, 1, BOCA)
	var cima := unidades.spawn(estado, dados, 1, BOCA)
	unidades.bands[unidades.index_of(baixo)] = int(Band.Kind.UNDERGROUND)
	unidades.set_target_x(baixo, LONGE)
	unidades.set_target_x(cima, LONGE)
	for _t in int(SEGUNDOS / PASSO):
		sitios.confine(unidades)
		unidades.tick_movement(PASSO, baixo)
	assert_float(unidades.xs[unidades.index_of(baixo)]).is_equal_approx(limites.y, 0.01)
	assert_bool(unidades.walking(unidades.index_of(baixo), baixo)).is_false()
	assert_float(unidades.xs[unidades.index_of(cima)]).is_greater(limites.y)


# ─── A terra abre-se so por cima do sitio ────────────────────────────────────


func test_a_janela_da_terra_e_a_do_sitio_e_cresce_com_o_dither() -> void:
	var sitio := Vector2(800.0, 1200.0)
	var janela := SoilReveal.site_window(sitio, 0.5)
	assert_float(janela.x).is_equal(1000.0)
	assert_float(janela.y).is_equal(400.0)
	assert_float(janela.z).is_greater(0.0)
	assert_float(janela.w).is_equal(0.5)
