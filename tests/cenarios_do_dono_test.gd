# tests/cenarios_do_dono_test.gd — as composicoes do dono no mundo: os reinos, as variantes
# por hora e por estacao, os sitios de agua e as transicoes (as entregas de 15 e 16/10/2026;
# ADR 0085).
#
# O dono: «Quero que implemente esses dois arquivos .zip que te enviei, o do google drive e
# essencial que aplique».
extends GdUnitTestSuite

const NOITE := GameClock.Phase.NIGHT
const CREPUSCULO := GameClock.Phase.DUSK
const TARDE := GameClock.Phase.AFTERNOON
const ALVORADA := GameClock.Phase.DAWN
const DE_NOITE := [{"view": "lua", "phases": ["night"]}]
const NO_OUTONO := [{"view": "outono", "season": "autumn"}]
const OUTONO := Vector2i(Seasons.AUTUMN, Seasons.AUTUMN)
const VERAO := Vector2i(Seasons.SUMMER, Seasons.SUMMER)


func _peso(camadas: Array[Dictionary], vista: StringName) -> float:
	for c in camadas:
		if c[OwnerScenery.VISTA] == vista:
			return c[OwnerScenery.PESO]
	return 0.0


# ─── A hora e a estacao ──────────────────────────────────────────────────────


func test_a_variante_da_noite_ve_se_toda_de_noite_e_nada_a_tarde() -> void:
	var noite := OwnerScenery.weights(&"base", DE_NOITE, NOITE, 0.3, VERAO)
	assert_float(_peso(noite, &"lua")).is_equal(1.0)
	assert_float(_peso(noite, &"base")).is_equal(0.0)
	var tarde := OwnerScenery.weights(&"base", DE_NOITE, TARDE, 0.9, VERAO)
	assert_float(_peso(tarde, &"base")).is_equal(1.0)
	assert_float(_peso(tarde, &"lua")).is_equal(0.0)


## Entra na segunda metade do crepusculo e sai na primeira da alvorada, sem saltos.
func test_a_variante_entra_e_sai_aos_poucos() -> void:
	var antes := 0.0
	for k in 11:
		var p := float(k) / 10.0
		var agora := OwnerScenery.phase_weight([NOITE], CREPUSCULO, p)
		assert_float(agora).is_greater_equal(antes)
		antes = agora
	assert_float(OwnerScenery.phase_weight([NOITE], CREPUSCULO, 0.4)).is_equal(0.0)
	assert_float(OwnerScenery.phase_weight([NOITE], ALVORADA, 0.0)).is_equal(1.0)
	assert_float(OwnerScenery.phase_weight([NOITE], ALVORADA, 0.6)).is_equal(0.0)


## Os pesos somam 1: o que se ve de uma pintura e o que falta da outra.
func test_os_pesos_somam_um() -> void:
	var regras := NO_OUTONO + DE_NOITE
	for fase in [ALVORADA, TARDE, CREPUSCULO, NOITE]:
		for p in [0.0, 0.5, 0.8]:
			var soma := 0.0
			for c in OwnerScenery.weights(&"base", regras, fase, p, OUTONO):
				soma += c[OwnerScenery.PESO]
			assert_float(soma).is_equal_approx(1.0, 0.0001)


## A variante pintada para a hora leva a luz dela; a da estacao, a do dia.
func test_so_a_variante_da_hora_traz_a_luz_pintada() -> void:
	var regras := NO_OUTONO + DE_NOITE
	for c in OwnerScenery.weights(&"base", regras, NOITE, 0.5, OUTONO):
		assert_bool(c[OwnerScenery.PINTADA]).is_equal(c[OwnerScenery.VISTA] == &"lua")


## Uma camada opaca troca-se por cima da outra; uma com buracos chega ao alfa inteiro a meio
## da troca, para o fundo nao se ver pelos dois buracos ao mesmo tempo.
func test_a_troca_de_uma_camada_com_buracos_nao_deixa_ver_o_fundo() -> void:
	var regras := DE_NOITE
	var meio := OwnerScenery.weights(&"base", regras, CREPUSCULO, 0.86, VERAO)
	for c in meio:
		var opaca := OwnerScenery.alpha(c, true)
		var buracos := OwnerScenery.alpha(c, false)
		assert_float(opaca).is_equal(c[OwnerScenery.BRUTO])
		assert_float(buracos).is_less_equal(opaca)
		assert_float(buracos).is_greater_equal(c[OwnerScenery.PESO])
	var base := meio.filter(func(c: Dictionary) -> bool: return c[OwnerScenery.VISTA] == &"base")
	var lua := meio.filter(func(c: Dictionary) -> bool: return c[OwnerScenery.VISTA] == &"lua")
	var passa := (
		(1.0 - OwnerScenery.alpha(base[0], false)) * (1.0 - OwnerScenery.alpha(lua[0], false))
	)
	assert_float(passa).is_less_equal(0.125)


## A vista pintada para uma hora tem o seu material: o ambiente da fase nao lhe cai por cima.
func test_a_vista_pintada_tem_material_proprio() -> void:
	var plano := SceneryLight.Depth.FAR
	assert_object(SceneryLight.material(plano, true)).is_not_same(SceneryLight.material(plano))
	assert_object(SceneryLight.material(plano, true)).is_same(SceneryLight.material(plano, true))


## Mas a noite e castanha (§80, ADR 0011): com a noite, o ambiente cai na vista pintada como
## no resto do mundo, e o luar azul do dono escurece com ele. Ao crepusculo, antes de a noite
## entrar, a pintada leva so a luz que traz; a noite entra e sai como uma variante dela.
func test_a_noite_cai_tambem_na_vista_pintada() -> void:
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	var luz := Lighting.new()
	var plano := SceneryLight.Depth.FAR
	luz.set_phase(dados, NOITE, 0.5)
	var mundo := SceneryLight.ambient_of(luz, dados, plano)
	var pintada := SceneryLight.ambient_of(
		luz, dados, plano, true, SceneryLight.night_weight(NOITE, 0.5)
	)
	assert_vector(mundo).is_not_equal(SceneryLight.PINTADA_AMBIENTE)
	assert_vector(pintada).is_equal_approx(mundo, Vector3.ONE * 0.001)
	luz.set_phase(dados, CREPUSCULO, 0.4)
	var cedo := SceneryLight.night_weight(CREPUSCULO, 0.4)
	assert_vector(SceneryLight.ambient_of(luz, dados, plano, true, cedo)).is_equal(
		SceneryLight.PINTADA_AMBIENTE
	)
	assert_vector(SceneryLight.ambient_of(luz, dados, plano)).is_not_equal(
		SceneryLight.PINTADA_AMBIENTE
	)
	assert_float(SceneryLight.night_weight(CREPUSCULO, 0.9)).is_greater(0.0).is_less(1.0)
	assert_float(SceneryLight.night_weight(ALVORADA, 0.6)).is_equal(0.0)


func test_a_estacao_muda_na_alvorada_do_primeiro_dia() -> void:
	var virada := Vector2i(Seasons.AUTUMN, Seasons.SUMMER)
	assert_float(OwnerScenery.season_weight(Seasons.AUTUMN, virada, ALVORADA, 0.0)).is_equal(0.0)
	assert_float(OwnerScenery.season_weight(Seasons.AUTUMN, virada, ALVORADA, 1.0)).is_equal(1.0)
	assert_float(OwnerScenery.season_weight(Seasons.AUTUMN, virada, TARDE, 0.0)).is_equal(1.0)
	assert_float(OwnerScenery.season_weight(Seasons.AUTUMN, VERAO, TARDE, 0.5)).is_equal(0.0)


# ─── Os sitios de agua ───────────────────────────────────────────────────────


func _sitio(x: float) -> Dictionary:
	return {
		SceneryMap.X: x,
		SceneryMap.CENA: &"lago_base",
		SceneryMap.MEIA: 640.0,
		SceneryMap.ANCORA: 680.0,
	}


func _troco(de: float, ate: float, cena: StringName) -> Dictionary:
	return {SceneryMap.CENA: cena, SceneryMap.DE: de, SceneryMap.ATE: ate}


## O quadro inteiro do sitio fica dentro do troco, com a agua pintada no x da fonte.
func test_o_sitio_parte_o_troco_com_a_agua_no_sitio_da_fonte() -> void:
	var trocos: Array[Dictionary] = [_troco(-1920.0, 3840.0, &"ancient_forest")]
	var com := SceneryMap.with_sites(trocos, [_sitio(1292.0)])
	assert_int(com.size()).is_equal(3)
	var lago := com[1]
	assert_str(String(lago[SceneryMap.CENA])).is_equal("lago_base")
	assert_float(lago[SceneryMap.DE]).is_equal(1292.0 - 680.0)
	assert_float(lago[SceneryMap.ATE] - lago[SceneryMap.DE]).is_equal(1280.0)
	assert_float(lago[SceneryMap.ORIGEM] + lago[SceneryMap.ANCORA]).is_equal(1292.0)
	assert_float(com[0][SceneryMap.ATE]).is_equal(lago[SceneryMap.DE])
	assert_float(com[2][SceneryMap.DE]).is_equal(lago[SceneryMap.ATE])
	var mapa := SceneryMap.of(com, {})
	assert_int(mapa.borders.size()).is_equal(2)
	assert_str(String(mapa.biome_at(1292.0))).is_equal("lago_base")


## Um sitio que nao cabe no troco nao se pinta: a agua fica a do ResourceWater.
func test_o_sitio_que_nao_cabe_fica_de_fora() -> void:
	var trocos: Array[Dictionary] = [_troco(0.0, 1000.0, &"ancient_forest")]
	assert_int(SceneryMap.with_sites(trocos, [_sitio(500.0)]).size()).is_equal(1)


# ─── O mosaico ───────────────────────────────────────────────────────────────


## Um plano cujo laco comeca mais longe do que o periodo dele (o longe da SobRaiz: 584 e 560)
## deixava uma coluna de 24 px sem quadro. Cada ponto que um quadro cobre esta nos quadros pedidos.
func test_o_mosaico_nao_deixa_colunas_por_pintar() -> void:
	for caso: Vector3 in [Vector3(584, 560, 560), Vector3(544, 1472, 2560), Vector3(0, 1280, 1280)]:
		for de in range(-3000, 3000, 37):
			var janela := Vector3(-128.0, float(de), float(de) + 300.0)
			var q := SceneryArt.tiles(janela, caso.x, caso.y, caso.z)
			for x in range(de, de + 300, 5):
				for n in range(-20, 20):
					var inicio := janela.x + float(n) * caso.z + caso.x
					if float(x) >= inicio and float(x) < inicio + caso.y:
						assert_bool(n >= q.x and n <= q.y).is_true()


# ─── O que o manifesto promete ───────────────────────────────────────────────


## Cada reino tem a sua pintura base, e cada variante e sitio a sua cena.
func test_cada_reino_e_cada_variante_tem_cena() -> void:
	var dados := OwnerScenery.manifest()
	assert_bool(dados.is_empty()).is_false()
	for bioma in Registry.ids(&"biomes"):
		assert_bool(dados.kingdoms.has(String(bioma))).is_true()
	for grupo: String in ["kingdoms", "sites"]:
		for chave: String in dados[grupo]:
			for v: Dictionary in dados[grupo][chave].variants:
				assert_bool(SceneryArt.has(StringName(v.view), &"far")).is_true()
				assert_bool(SceneryArt.has(StringName(v.view), &"terrain")).is_true()
	for bioma: StringName in OwnerScenery.sites():
		var sitio: Dictionary = OwnerScenery.sites()[bioma]
		assert_bool(SceneryArt.has(sitio[OwnerScenery.VISTA], &"under")).is_true()


## A transicao nova (Fenda e Geada) liga os dois biomas, com o chao e o marco.
func test_as_transicoes_do_dono_ligam_os_seus_biomas() -> void:
	var pares := SceneryArt.pairs()
	assert_int(OwnerScenery.manifest().transitions.size()).is_greater(0)
	for id: String in OwnerScenery.manifest().transitions:
		var t: Dictionary = OwnerScenery.manifest().transitions[id]
		var par: Dictionary = pares.get(SceneryMap.key(StringName(t.from), StringName(t.to)), {})
		assert_str(String(par.get(SceneryMap.CENA, &""))).is_equal(id)
		assert_bool(SceneryArt.has(StringName(id), &"landmark")).is_true()
