# tests/subsolo_area_util_test.gd — o contrato de area util do subsolo, puro (o relatorio
# de 05/10/2026, §6, §15 e §17; ADR 0072). O jogo esta no subsolo_causa_test.
#
# "Nenhum subsolo acessivel pode consistir apenas na escada." Vazio e valido; uma escada
# sem chao nao e. Comeca-se pelos casos de fronteira, porque uma media boa pode esconder
# exatamente a cave problematica (§17.1).
extends GdUnitTestSuite

const BOCA := 1000.0
const SALA := Vector2(120.0, 240.0)
const SEMENTES := 1000
const SEGMENTO := 640.0
const FOLGA := 10.0
const CAMARA := 196.0

var r := UnderRules.new()


func _spec(
	entrada: StringName, extra: int, features: Array = [], obrigatorio := false
) -> Dictionary:
	return {
		UndergroundSites.ROOM: SALA,
		UndergroundSites.EXTRA: extra,
		UndergroundSites.POOL: [&"storage", &"wine"],
		UndergroundSites.ENTRANCE: entrada,
		UndergroundSites.ENTRANCE_PX: 0.0,
		UndergroundSites.FEATURES: features,
		UndergroundSites.MANDATORY: obrigatorio,
	}


func _sorteios(valor: float) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	saida.resize(UndergroundSites.ROLLS)
	saida.fill(valor)
	return saida


## Sorteios fixos por semente, sem RNG: a mesma semente da sempre o mesmo sitio.
func _variados(semente: int) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for j in UndergroundSites.ROLLS:
		saida.append(float(absi(hash([semente, j])) % 10007) / 10007.0)
	return saida


func _span(salas: Array) -> Vector2:
	return Vector2(salas.front()[UndergroundSites.A], salas.back()[UndergroundSites.B])


func _ok(salas: Array, boca: float, spec: Dictionary) -> bool:
	return UnderFit.check(_span(salas), boca, UnderLayout.blocked(spec), r) == UnderFit.OK


# ─── O que se mede ───────────────────────────────────────────────────────────


func test_a_cave_de_96_px_so_tem_a_escada_e_chumba() -> void:
	assert_float(UnderFit.envelope(r)).is_equal(272.0)
	var so_escada := Vector2(BOCA - 48.0, BOCA + 48.0)
	assert_str(String(UnderFit.check(so_escada, BOCA, [], r))).is_equal(String(UnderFit.NO_BAY))
	var com_chao := Vector2(BOCA - 48.0, BOCA + 224.0)
	assert_str(String(UnderFit.check(com_chao, BOCA, [], r))).is_equal(String(UnderFit.OK))
	var fora := Vector2(BOCA + 10.0, BOCA + 400.0)
	assert_str(String(UnderFit.check(fora, BOCA, [], r))).is_equal(String(UnderFit.MOUTH_OUTSIDE))
	assert_str(String(UnderFit.check(UnderFit.NONE, BOCA, [], r))).is_equal(String(UnderFit.EMPTY))


func test_a_largura_total_nao_chega_se_o_que_la_esta_ocupa_a_baia() -> void:
	var sitio := Vector2(BOCA - 48.0, BOCA + 400.0)
	var poco: Array = [Vector2(BOCA + 120.0, BOCA + 260.0)]
	assert_str(String(UnderFit.check(sitio, BOCA, poco, r))).is_equal(String(UnderFit.NO_BAY))
	var bocados: Array = [Vector2(BOCA + 150.0, BOCA + 170.0), Vector2(BOCA + 250.0, BOCA + 270.0)]
	assert_str(String(UnderFit.check(sitio, BOCA, bocados, r))).is_equal(String(UnderFit.NO_BAY))
	var sobrepostos: Array = [
		Vector2(BOCA + 80.0, BOCA + 200.0), Vector2(BOCA + 150.0, BOCA + 180.0)
	]
	var baia := UnderFit.bay(sitio, BOCA, sobrepostos, r)
	assert_float(baia.x).is_equal(BOCA + 200.0)
	assert_float(baia.y).is_equal(BOCA + 384.0)


# ─── O que se gera ───────────────────────────────────────────────────────────


func test_um_tecto_curto_nao_publica_a_entrada_de_um_sitio_opcional() -> void:
	var curto := Vector2(BOCA - 100.0, BOCA + 100.0)
	assert_bool(is_nan(UnderFit.plan(BOCA, Vector2(BOCA, BOCA), curto, [], r).x)).is_true()
	var sitios := UndergroundSites.new()
	sitios.post(
		"ruina", UndergroundSites.DUNGEON, BOCA, Vector2(BOCA, BOCA), curto, _spec(&"hall", 2)
	)
	assert_bool(sitios.usable(0)).is_false()
	assert_str(String(sitios.why(0))).is_equal(String(UnderFit.NO_ROOM))
	assert_int(sitios.find(BOCA, Band.PASSAGE_PX)).is_equal(UndergroundSites.NONE)
	assert_bool(sitios.mouths().is_empty()).is_true()
	assert_bool(sitios.generate(0, _sorteios(0.5))).is_false()
	assert_bool(sitios.generated(0)).is_false()


func test_um_sitio_obrigatorio_sem_chao_publica_mas_diz_porque() -> void:
	var curto := Vector2(BOCA - 100.0, BOCA + 100.0)
	var sitios := UndergroundSites.new()
	var spec := _spec(&"vault", 0, [], true)
	sitios.post("sede", UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), curto, spec)
	assert_bool(sitios.usable(0)).is_true()
	assert_str(String(sitios.why(0))).is_equal(String(UnderFit.NO_ROOM))
	assert_bool(sitios.generate(0, _sorteios(0.5))).is_true()
	assert_str(String(sitios.why(0))).is_equal(String(UnderFit.NO_BAY))


func test_sem_salas_extra_o_chao_continua_garantido() -> void:
	var cap := Vector2(0.0, 3000.0)
	for u in [0.0, 0.01, 0.2]:
		var salas := UnderLayout.lay_out(
			BOCA, Vector2(BOCA, BOCA), cap, _sorteios(u), _spec(&"stair", 0)
		)
		assert_bool(_ok(salas, BOCA, _spec(&"stair", 0))).is_true()


func test_a_boca_junto_a_cada_ponta_da_um_sitio_assimetrico_valido() -> void:
	for cap: Vector2 in [Vector2(BOCA - 48.0, BOCA + 400.0), Vector2(BOCA - 400.0, BOCA + 48.0)]:
		for u in [0.0, 0.3, 0.7, 0.99]:
			var spec := _spec(&"stair", 3)
			var salas := UnderLayout.lay_out(BOCA, Vector2(BOCA, BOCA), cap, _sorteios(u), spec)
			assert_bool(_ok(salas, BOCA, spec)).is_true()
			assert_float(_span(salas).x).is_greater_equal(cap.x)
			assert_float(_span(salas).y).is_less_equal(cap.y)


func test_o_que_la_esta_empurra_a_baia_para_o_outro_lado() -> void:
	var spec := _spec(&"stair", 0, [[BOCA + 150.0, &"mine", 140.0]])
	var cap := Vector2(BOCA - 600.0, BOCA + 300.0)
	var salas := UnderLayout.lay_out(BOCA, Vector2(BOCA, BOCA + 220.0), cap, _sorteios(0.5), spec)
	assert_bool(_ok(salas, BOCA, spec)).is_true()
	var baia := UnderFit.bay(_span(salas), BOCA, UnderLayout.blocked(spec), r)
	assert_float(baia.y).is_less_equal(BOCA)
	assert_float(_span(salas).y).is_greater_equal(BOCA + 220.0)


func test_dois_sitios_nunca_disputam_o_mesmo_chao() -> void:
	var largo := Vector2(0.0, 3000.0)
	var falhas := 0
	for semente in 200:
		var sitios := UndergroundSites.new()
		var spec := _spec(&"stair", 3)
		sitios.post("a", UndergroundSites.CELLAR, BOCA, Vector2(BOCA, BOCA), largo, spec)
		sitios.post("b", UndergroundSites.DUNGEON, BOCA + 380.0, Vector2.ONE * 1380.0, largo, spec)
		var ordem := [0, 1] if semente % 2 == 0 else [1, 0]
		for i: int in ordem:
			sitios.generate(i, _variados(semente * 2 + i))
		var a := sitios.span(0)
		var b := sitios.span(1)
		var juntos := a.y > b.x and b.y > a.x
		if juntos or sitios.why(0) != UnderFit.OK or sitios.why(1) != UnderFit.OK:
			falhas += 1
	assert_int(falhas).is_equal(0)


func test_escavar_alarga_sem_fragmentos_e_para_no_vizinho() -> void:
	var sitios := UndergroundSites.new()
	var cap := Vector2(BOCA - 48.0, BOCA + 240.0)
	sitios.post("sede", UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), cap, _spec(&"vault", 0))
	sitios.generate(0, _sorteios(0.5))
	var salas := sitios.rooms(0).size()
	assert_bool(sitios.excavate(0, Vector2(cap.x, cap.y + 20.0))).is_true()
	assert_int(sitios.rooms(0).size()).is_equal(salas)
	assert_bool(sitios.excavate(0, Vector2(cap.x, cap.y + 116.0))).is_true()
	assert_int(sitios.rooms(0).size()).is_equal(salas + 1)
	var vizinho := Vector2(BOCA + 500.0, BOCA + 1200.0)
	var x := BOCA + 600.0
	sitios.post("ruina", UndergroundSites.DUNGEON, x, Vector2(x, x), vizinho, _spec(&"hall", 0))
	assert_bool(sitios.usable(1)).is_true()
	sitios.excavate(0, Vector2(cap.x, BOCA + 2000.0))
	sitios.generate(1, _sorteios(0.5))
	assert_float(sitios.span(0).y).is_less_equal(sitios.span(1).x)
	assert_str(String(sitios.why(1))).is_equal(String(UnderFit.OK))


func test_o_bau_fica_na_baia_e_nao_no_alcance_da_subida() -> void:
	var sitios := UndergroundSites.new()
	var cap := Vector2(BOCA - 48.0, BOCA + 240.0)
	sitios.post("sede", UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), cap, _spec(&"vault", 0))
	sitios.generate(0, _sorteios(0.5))
	var bau := UnderReserve.chest_x(sitios, 0)
	assert_float(absf(bau - BOCA)).is_greater(Band.PASSAGE_PX * 2.0)
	assert_float(bau).is_between(sitios.span(0).x, sitios.span(0).y)
	var objetivo := UnderReserve.goal_x(sitios, 0)
	assert_float(absf(objetivo - BOCA)).is_greater(r.arrival_px * 0.5 + r.clear_px)
