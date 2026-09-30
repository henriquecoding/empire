# tests/mundo_segmentos_test.gd — as terras entre os povos, segmento a segmento (o
# pedido do dono de 30/09/2026; §21; ADR 0038).
#
# Cada segmento gera-se uma vez, para fora, pelo plano: nos trilhos sorteia-se o tipo
# pelos pesos e regras do segments.csv (§21), com o clima a juntar o bosque; o limiar,
# a terra, a fortaleza e a borda sao do plano. Cada trilho tem pelo menos um encontro —
# um acampamento de mendigos, de mercenarios, ou uma masmorra. O que se gerou fica.
extends GdUnitTestSuite

const SEMENTE := 20260930
const LARGURA := 3840.0
const SEGMENTO := 640.0
const TERRA := 4
const TRILHO := 5
const SAL := 99
const ALCANCE := 1280.0
const BIOMAS := [
	"ancient_forest",
	"coast",
	"canyon",
	"floodplain",
	"volcanic",
	"subterranean",
	"glacier",
	"marsh"
]
const TRILHOS := [&"empty", &"forest", &"ruin", &"vagrant_camp", &"mercenary_camp"]
const ENCONTROS := [&"ruin", &"vagrant_camp", &"mercenary_camp"]
const Z := WorldPlan.Zone


func before_test() -> void:
	RngService.configure(SEMENTE)


func _kit() -> Array[SegmentData]:
	var kit: Array[SegmentData] = []
	for recurso in Registry.entries(&"segments"):
		var s := recurso as SegmentData
		if s.people == &"enramados":
			kit.append(s)
	return kit


func _bordas() -> Dictionary:
	var saida := {}
	for id in BIOMAS:
		saida[StringName(id)] = (
			(Registry.entry(&"biomes", StringName(id)) as BiomeData).edge_subject
		)
	return saida


func _terras(povos: int = 7) -> WildSegments:
	var t := WildSegments.new(_kit())
	var fixo := func(_l: int, _j: int) -> int: return TRILHO
	t.setup(WorldPlan.draw(povos, TERRA, fixo), SEGMENTO)
	return t


func _crescer(t: WildSegments, lado: int, clima: float = 0.5) -> Dictionary:
	var k := t.count(lado)
	var sorteios := RngService.scatter(hash([SAL, lado, k]), WildSegments.SORTEIOS)
	return t.grow(lado, sorteios, clima, 0.6, PackedStringArray(BIOMAS), _bordas())


func _tudo(t: WildSegments) -> void:
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		while not t.full(lado):
			_crescer(t, lado)


func test_gera_para_fora_e_para_na_borda() -> void:
	var t := _terras()
	_tudo(t)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_int(t.count(lado)).is_equal(t.plan.size(lado))
		assert_str(String(t.at(lado, t.count(lado) - 1)[WildSegments.TIPO])).is_equal("edge")
		assert_bool(_crescer(t, lado).is_empty()).is_true()
		assert_int(t.count(lado)).is_equal(t.plan.size(lado))


func test_as_zonas_do_plano_dao_os_tipos() -> void:
	var t := _terras()
	_tudo(t)
	var tipo_da_zona := {
		Z.THRESHOLD: &"threshold", Z.LAND: &"settlement", Z.FORTRESS: &"fortress", Z.EDGE: &"edge"
	}
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in t.count(lado):
			var r := t.at(lado, k)
			var zona: int = r[WildSegments.ZONA]
			assert_int(zona).is_equal(t.plan.zone(lado, k))
			if zona == Z.TRAIL:
				assert_bool(TRILHOS.has(r[WildSegments.TIPO])).is_true()
			else:
				assert_str(String(r[WildSegments.TIPO])).is_equal(String(tipo_da_zona[zona]))


## §21: "um a cada 4–7 segmentos, nunca adjacente a base inicial" (os mercenarios), e os
## outros encontros tambem espacados, pelas regras gap= do segments.csv.
func test_os_encontros_respeitam_os_intervalos() -> void:
	var t := _terras()
	_tudo(t)
	var minimo := {&"mercenary_camp": 4, &"vagrant_camp": 4, &"ruin": 3}
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_str(String(t.at(lado, 0)[WildSegments.TIPO])).is_not_equal("mercenary_camp")
		var ultimo := {}
		for k in t.count(lado):
			var tipo: StringName = t.at(lado, k)[WildSegments.TIPO]
			if not minimo.has(tipo):
				continue
			if ultimo.has(tipo):
				assert_int(k - int(ultimo[tipo])).is_greater_equal(int(minimo[tipo]))
			ultimo[tipo] = k


func test_cada_trilho_tem_um_encontro() -> void:
	var t := _terras()
	_tudo(t)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		var achou := false
		for k in t.count(lado):
			var r := t.at(lado, k)
			if int(r[WildSegments.ZONA]) != Z.TRAIL:
				continue
			achou = achou or ENCONTROS.has(r[WildSegments.TIPO])
			var acaba := k + 1 >= t.count(lado) or t.plan.zone(lado, k + 1) != Z.TRAIL
			if acaba:
				(
					assert_bool(achou)
					. override_failure_message("trilho sem encontro em %d" % k)
					. is_true()
				)
				achou = false


func test_a_borda_e_a_do_bioma_do_ultimo_povo() -> void:
	var t := _terras()
	_tudo(t)
	var bordas := _bordas()
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		var ultimo := t.plan.last_people(lado)
		var borda := t.at(lado, t.count(lado) - 1)
		var esperado: StringName = bordas[StringName(BIOMAS[ultimo])]
		assert_str(String(borda[WildSegments.ASSUNTO])).is_equal(String(esperado))


func test_o_clima_junta_o_bosque() -> void:
	var kit := _kit()
	var humido := 0
	var seco := 0
	for n in 100:
		var u := (float(n) + 0.5) / 100.0
		humido += 1 if TrailPick.choose(kit, [], &"", 1.0, 0.6, u, 0.5).kind == &"forest" else 0
		seco += 1 if TrailPick.choose(kit, [], &"", 0.0, 0.6, u, 0.5).kind == &"forest" else 0
	assert_int(humido).is_greater(seco)


func test_a_mesma_variante_nao_se_repete_lado_a_lado() -> void:
	var t := _terras()
	_tudo(t)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in range(1, t.count(lado)):
			var a := t.at(lado, k - 1)
			var b := t.at(lado, k)
			if a[WildSegments.TIPO] == &"empty" and b[WildSegments.TIPO] == &"empty":
				assert_str(String(b[WildSegments.ID])).is_not_equal(String(a[WildSegments.ID]))


func test_limites_extensao_e_quanto_falta() -> void:
	var t := _terras()
	var oeste := t.plan.size(WorldPlan.OESTE)
	var leste := t.plan.size(WorldPlan.LESTE)
	var limites := t.limits(LARGURA)
	assert_float(limites.x).is_equal(-(oeste - 1) * SEGMENTO - WildSegments.BORDO_PX)
	assert_float(limites.y).is_equal(LARGURA + (leste - 1) * SEGMENTO + WildSegments.BORDO_PX)
	assert_that(t.extent(LARGURA)).is_equal(Vector2(0.0, LARGURA))
	assert_int(t.needed(WorldPlan.LESTE, LARGURA - 100.0, LARGURA, ALCANCE)).is_equal(2)
	assert_int(t.needed(WorldPlan.LESTE, LARGURA * 0.5, LARGURA, ALCANCE)).is_equal(0)
	assert_int(t.needed(WorldPlan.OESTE, 100.0, LARGURA, ALCANCE)).is_equal(2)
	assert_int(t.needed(WorldPlan.LESTE, 1.0e9, LARGURA, ALCANCE)).is_equal(leste)
	_crescer(t, WorldPlan.LESTE)
	_crescer(t, WorldPlan.LESTE)
	assert_that(t.extent(LARGURA)).is_equal(Vector2(0.0, LARGURA + 2.0 * SEGMENTO))


func test_acampamentos_mercenarios_e_masmorras_tem_sitio() -> void:
	var t := _terras()
	_tudo(t)
	var listas := {
		&"vagrant_camp": t.camps(LARGURA),
		&"mercenary_camp": t.mercenaries(LARGURA),
		&"ruin": t.dungeons(LARGURA)
	}
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in t.count(lado):
			var tipo: StringName = t.at(lado, k)[WildSegments.TIPO]
			var x := t.subject_x(lado, k, LARGURA)
			var de := t.x_of(lado, k, LARGURA)
			assert_float(x).is_between(de, de + SEGMENTO)
			if listas.has(tipo):
				assert_bool((listas[tipo] as PackedFloat32Array).has(x)).is_true()
	for tipo in listas:
		assert_bool((listas[tipo] as PackedFloat32Array).is_empty()).is_false()


func test_o_que_se_gerou_vai_no_save() -> void:
	var t := _terras()
	for _k in 7:
		_crescer(t, WorldPlan.LESTE)
	_crescer(t, WorldPlan.OESTE)
	var copia := WildSegments.new(_kit())
	copia.from_dict(t.to_dict())
	assert_int(copia.plan.size(WorldPlan.LESTE)).is_equal(t.plan.size(WorldPlan.LESTE))
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_int(copia.count(lado)).is_equal(t.count(lado))
		for k in t.count(lado):
			assert_dict(copia.at(lado, k)).is_equal(t.at(lado, k))
	assert_float(copia.width).is_equal(SEGMENTO)


## Um save de antes do mundo continuo nao tem terras: fica o plano de agora, e gera-se
## ao andar. E a revisao sobe sempre, para quem desenha saber quando redesenhar.
func test_um_save_sem_terras_fica_com_o_plano_de_agora() -> void:
	var t := _terras()
	_crescer(t, WorldPlan.LESTE)
	var antes := t.revision
	t.from_dict({})
	assert_int(t.count(WorldPlan.LESTE)).is_equal(0)
	assert_int(t.plan.size(WorldPlan.LESTE)).is_greater(0)
	assert_int(t.revision).is_greater(antes)
