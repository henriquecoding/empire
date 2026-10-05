# tests/subsolo_reparo_test.gd — os saves de antes do contrato de area util e a bateria
# de sementes (o relatorio de 05/10/2026, §15.2 e §17.1; ADR 0072). Os casos de fronteira
# estao no subsolo_area_util_test.
#
# Um sitio de um save antigo repara-se uma vez, sem mexer na boca nem no que tinha; e mil
# sementes por familia provam que nenhum sitio publicado e so a escada.
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


# ─── Os saves de antes ───────────────────────────────────────────────────────


func test_um_save_antigo_so_com_escada_repara_se_uma_vez_e_guarda_o_que_tinha() -> void:
	var antiga := {UndergroundSites.A: BOCA - 48.0, UndergroundSites.B: BOCA + 48.0}
	antiga.merge({UndergroundSites.KIND: &"vault", UndergroundSites.ROLL: 0.5})
	var gravado := {UndergroundSites.LAYOUTS: {"sede": [antiga.duplicate()]}}
	var sitios := UndergroundSites.new()
	var cap := Vector2(BOCA - 48.0, BOCA + 400.0)
	sitios.post("sede", UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), cap, _spec(&"vault", 0))
	sitios.from_dict(gravado)
	assert_str(String(UnderFit.check(sitios.span(0), BOCA, [], r))).is_equal(
		String(UnderFit.NO_BAY)
	)
	assert_int(UnderReserve.mend(sitios)).is_equal(1)
	assert_str(String(UnderFit.check(sitios.span(0), BOCA, [], r))).is_equal(String(UnderFit.OK))
	var primeira: Dictionary = sitios.rooms(0)[0]
	assert_float(primeira[UndergroundSites.A]).is_equal(BOCA - 48.0)
	assert_float(primeira[UndergroundSites.B]).is_equal(BOCA + 48.0)
	assert_str(String(primeira[UndergroundSites.KIND])).is_equal("vault")
	assert_float(absf(UnderReserve.chest_x(sitios, 0) - BOCA)).is_greater(Band.PASSAGE_PX * 2.0)
	var depois := sitios.rooms(0).duplicate(true)
	assert_int(UnderReserve.mend(sitios)).is_equal(0)
	assert_bool(sitios.rooms(0) == depois).is_true()
	var outra := UndergroundSites.new()
	outra.post("sede", UndergroundSites.HATCH, BOCA, Vector2(BOCA, BOCA), cap, _spec(&"vault", 0))
	outra.from_dict(sitios.to_dict())
	assert_int(UnderReserve.mend(outra)).is_equal(0)
	assert_bool(outra.rooms(0) == depois).is_true()


func test_um_save_antigo_recupera_a_funcao_que_a_feature_apagou() -> void:
	var spec := _spec(&"stair", 0, [[BOCA + 150.0, &"mine", 0.0]])
	var entrada := {UndergroundSites.A: 900.0, UndergroundSites.B: 1100.0}
	entrada.merge({UndergroundSites.KIND: &"stair", UndergroundSites.ROLL: 0.5})
	var galeria := {UndergroundSites.A: 1100.0, UndergroundSites.B: 1300.0}
	galeria.merge({UndergroundSites.KIND: &"mine", UndergroundSites.ROLL: 0.7})
	var sitios := UndergroundSites.new()
	sitios.post("porao", UndergroundSites.CELLAR, BOCA, Vector2(BOCA, BOCA), Vector2(0, 3000), spec)
	sitios.from_dict({UndergroundSites.LAYOUTS: {"porao": [entrada, galeria]}})
	assert_int(UnderReserve.mend(sitios)).is_equal(1)
	var salas := sitios.rooms(0)
	assert_str(String(salas[0][UndergroundSites.KIND])).is_equal("stair")
	assert_str(String(salas[1][UndergroundSites.KIND])).is_equal("wine")
	assert_bool((salas[1][UndergroundSites.FEATS] as Array).has(&"mine")).is_true()
	assert_bool((salas[0][UndergroundSites.FEATS] as Array).is_empty()).is_true()


# ─── A bateria (§17.1) ───────────────────────────────────────────────────────


## Mil sementes por familia, com a boca em todo o segmento onde o assunto pode cair: todo
## o sitio publicado tem baia, cabe no tecto, tem salas seguidas e nao passa das doze.
func test_mil_sementes_por_familia_cumprem_o_contrato() -> void:
	var familias := {
		&"cellar": [_spec(&"stair", 3, [[160.0, &"mine", 120.0]]), Vector2(-60.0, 160.0)],
		&"hatch": [_spec(&"vault", 0), Vector2.ZERO],
		&"ruin": [_spec(&"hall", 3), Vector2(-CAMARA * 0.5, CAMARA * 0.5)],
		&"cave": [_spec(&"maw", 3), Vector2.ZERO],
	}
	familias[&"ruin"][0][UndergroundSites.ENTRANCE_PX] = CAMARA
	var falhas := {}
	for familia: StringName in familias:
		var spec: Dictionary = familias[familia][0]
		var perto: Vector2 = familias[familia][1]
		falhas[familia] = 0
		for semente in SEMENTES:
			var rolls := _variados(semente)
			var boca := lerpf(SEGMENTO * 0.25, SEGMENTO * 0.75, rolls[UndergroundSites.ROLLS - 1])
			var cap := Vector2(FOLGA, SEGMENTO - FOLGA)
			var need := Vector2(boca + perto.x, boca + perto.y)
			if familia == &"cellar":
				spec[UndergroundSites.FEATURES] = [[boca + 160.0, &"mine", 120.0]]
				need.y = boca + 220.0
			var salas := UnderLayout.lay_out(boca, need, cap, rolls, spec)
			var seguidas := true
			for k in range(1, salas.size()):
				seguidas = (
					seguidas and salas[k][UndergroundSites.A] == salas[k - 1][UndergroundSites.B]
				)
			var dentro := _span(salas).x >= cap.x and _span(salas).y <= cap.y
			var poucas := salas.size() <= UndergroundSites.MAX_ROOMS
			if not (_ok(salas, boca, spec) and seguidas and dentro and poucas):
				falhas[familia] += 1
	assert_dict(falhas).is_equal({&"cellar": 0, &"hatch": 0, &"ruin": 0, &"cave": 0})


func test_o_tecto_de_entradas_opcionais_e_um_tecto_e_nao_uma_quota() -> void:
	assert_int(UnderFit.optional_budget(0.0, r)).is_equal(0)
	assert_int(UnderFit.optional_budget(r.optional_spacing_px - 1.0, r)).is_equal(0)
	assert_int(UnderFit.optional_budget(r.optional_spacing_px, r)).is_equal(1)
	assert_int(UnderFit.optional_budget(r.optional_spacing_px * 100.0, r)).is_equal(r.optional_max)


func test_recortar_nunca_passa_de_um_obstaculo_nem_cobre_a_boca() -> void:
	var cap := Vector2(0.0, 3000.0)
	var obstaculos: Array = [Vector2(200.0, 400.0), Vector2(1500.0, 1700.0), UnderFit.NONE]
	assert_vector(UnderFit.clip(cap, BOCA, obstaculos)).is_equal(Vector2(400.0, 1500.0))
	assert_bool(is_nan(UnderFit.clip(cap, BOCA, [Vector2(900.0, 1100.0)]).x)).is_true()
