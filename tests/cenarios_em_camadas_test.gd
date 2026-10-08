# tests/cenarios_em_camadas_test.gd — que cena pintada cobre cada troco do mundo, e que
# fundo se ve da camara (a entrega de cenarios em camadas de 08/10/2026; ADR 0081).
#
# O dono: «acesse meu google drive para ter acesso aos arquivos .zip que sao o que voce
# precisa para implementar o design que quero no meu jogo». Os oito reinos pintam o chao
# e o fundo de cada povo; as treze transicoes pintam a fronteira entre dois. §21: «a
# fronteira entre povos nunca e um fade: e um portao, uma ponte, uma falha na rocha».
extends GdUnitTestSuite

const BOSQUE := &"ancient_forest"
const PANTANO := &"marsh"
const LEZIRIA := &"floodplain"
const MATA := &"mata_encharcada"
const MEIA := Vector2(640.0, 640.0)
const SEMENTE := 20261008

const FUNDO := [&"sky", &"clouds", &"far", &"mid", &"near"]
const CHAO := [&"under", &"terrain"]


func _troco(de: float, ate: float, cena: StringName) -> Dictionary:
	return {SceneryMap.CENA: cena, SceneryMap.DE: de, SceneryMap.ATE: ate}


## A regiao de casa ao meio, um trilho do bosque a leste e a terra do pantano depois.
func _leste() -> Array[Dictionary]:
	return [_troco(-1920.0, 3840.0, BOSQUE), _troco(3840.0 + 3200.0, 12000.0, PANTANO)]


func _pares() -> Dictionary:
	return {SceneryMap.key(BOSQUE, PANTANO): {SceneryMap.CENA: MATA, SceneryMap.MEIA: MEIA}}


## Os trocos tem de se tocar para haver fronteira: aqui o bosque vai ate ao limiar.
func _encostados() -> Array[Dictionary]:
	return [_troco(-1920.0, 7040.0, BOSQUE), _troco(7040.0, 12000.0, PANTANO)]


func test_a_transicao_fica_centrada_na_fronteira_e_os_reinos_encostam_se_a_ela() -> void:
	var mapa := SceneryMap.of(_encostados(), _pares())
	var cenas: Array = mapa.stretches.map(
		func(t: Dictionary) -> StringName: return t[SceneryMap.CENA]
	)
	assert_array(cenas).is_equal([BOSQUE, MATA, PANTANO])
	var meio: Dictionary = mapa.stretches[1]
	assert_float(meio[SceneryMap.DE]).is_equal(7040.0 - 640.0)
	assert_float(meio[SceneryMap.ATE]).is_equal(7040.0 + 640.0)
	assert_float(meio[SceneryMap.ORIGEM]).is_equal(7040.0 - 640.0)
	assert_float(mapa.stretches[0][SceneryMap.ATE]).is_equal(meio[SceneryMap.DE])
	assert_float(mapa.stretches[2][SceneryMap.DE]).is_equal(meio[SceneryMap.ATE])


## Sem quadro pintado para o par, os dois reinos encontram-se na fronteira.
func test_sem_transicao_os_reinos_encontram_se_na_fronteira() -> void:
	var mapa := SceneryMap.of(_encostados(), {})
	assert_int(mapa.stretches.size()).is_equal(2)
	assert_float(mapa.stretches[0][SceneryMap.ATE]).is_equal(7040.0)
	assert_float(mapa.stretches[1][SceneryMap.DE]).is_equal(7040.0)
	assert_bool(mapa.painted_border(7040.0 + 200.0)).is_false()


## A transicao do bosque para o pantano tem o bosque a esquerda: a oeste, com o pantano a
## esquerda, nao serve, e nao se espelha (o guia da entrega: «never mirror the entire scene»).
func test_a_transicao_so_serve_com_os_lados_certos() -> void:
	var oeste: Array[Dictionary] = [
		_troco(-9000.0, -3200.0, PANTANO), _troco(-3200.0, 3840.0, BOSQUE)
	]
	var mapa := SceneryMap.of(oeste, _pares())
	assert_int(mapa.stretches.size()).is_equal(2)
	assert_int(mapa.borders.size()).is_equal(1)


func test_o_limiar_coberto_pela_transicao_sabe_que_esta_pintado() -> void:
	var mapa := SceneryMap.of(_encostados(), _pares())
	assert_bool(mapa.painted_border(7040.0 + 320.0)).is_true()
	assert_bool(mapa.painted_border(7040.0 - 320.0)).is_true()
	assert_bool(mapa.painted_border(7040.0 + 700.0)).is_false()


## O fundo e o reino de onde esta a camara; perto da fronteira, os dois misturados, e a
## mistura so cresce ao andar de um para o outro.
func test_o_fundo_mistura_os_dois_reinos_so_perto_da_fronteira() -> void:
	var mapa := SceneryMap.of(_encostados(), _pares())
	var longe := mapa.blend(1000.0)
	assert_str(String(longe[SceneryMap.A])).is_equal(String(BOSQUE))
	assert_float(longe[SceneryMap.T]).is_equal(0.0)
	var depois := mapa.blend(9000.0)
	assert_str(String(depois[SceneryMap.A])).is_equal(String(PANTANO))
	var antes := -1.0
	for x in range(7040 - 300, 7040 + 300, 20):
		var aqui := mapa.blend(float(x))
		var pantano: float = aqui[SceneryMap.T] if aqui[SceneryMap.A] == BOSQUE else 1.0
		assert_float(pantano).is_greater_equal(antes)
		antes = pantano
	assert_float(mapa.blend(7040.0)[SceneryMap.T]).is_equal_approx(0.5, 0.001)


func test_trocos_que_nao_se_tocam_nao_fazem_fronteira() -> void:
	var mapa := SceneryMap.of(_leste(), _pares())
	assert_int(mapa.borders.size()).is_equal(0)
	assert_int(mapa.stretches.size()).is_equal(2)


func test_so_os_trocos_que_tocam_a_janela() -> void:
	var mapa := SceneryMap.of(_encostados(), _pares())
	var dentro := mapa.within(0.0, 1280.0)
	assert_int(dentro.size()).is_equal(1)
	assert_int(mapa.within(6000.0, 8000.0).size()).is_equal(3)


## O mundo a serio: a regiao de casa e o que o rei gerou a andar. O trilho e da terra de onde
## se vem; a terra muda no limiar. Tudo coberto de beira a beira, sem buracos nem sobreposicoes.
func test_o_mundo_gerado_fica_coberto_de_trocos_seguidos() -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	for x in [SimLoop.world_width + 20000.0, -20000.0]:
		SimLoop.units.xs[rei] = x
		Frontier.grow(SimLoop.field, SimLoop.units, SimLoop.king_id, SimLoop.world_width)
	var terras := SimLoop.field.wilds
	var trocos := SceneryMap.runs(terras, SimLoop.world_width, Wilds.biome_now())
	assert_int(trocos.size()).is_greater(2)
	for i in range(1, trocos.size()):
		assert_float(trocos[i][SceneryMap.DE]).is_equal(trocos[i - 1][SceneryMap.ATE])
		assert_str(String(trocos[i][SceneryMap.CENA])).is_not_equal(
			String(trocos[i - 1][SceneryMap.CENA])
		)
	var limites := terras.limits(SimLoop.world_width)
	var gerado := terras.extent(SimLoop.world_width)
	var oeste := limites.x if terras.full(WorldPlan.OESTE) else gerado.x
	var leste := limites.y if terras.full(WorldPlan.LESTE) else gerado.y
	assert_float(trocos[0][SceneryMap.DE]).is_equal_approx(oeste, 0.01)
	assert_float(trocos[trocos.size() - 1][SceneryMap.ATE]).is_equal_approx(leste, 0.01)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var registo := terras.at(lado, k)
			if int(registo[WildSegments.ZONA]) == WorldPlan.Zone.TRAIL:
				var meio := terras.x_of(lado, k, SimLoop.world_width) + terras.width * 0.5
				var de := String(registo[WildSegments.DE])
				assert_str(String(_cena_em(trocos, meio))).is_equal(de)


func _cena_em(trocos: Array[Dictionary], x: float) -> StringName:
	for t in trocos:
		if x >= t[SceneryMap.DE] and x < t[SceneryMap.ATE]:
			return t[SceneryMap.CENA]
	return &""


# ─── A arte que o manifesto promete ──────────────────────────────────────────


## Um reino pintado por bioma, com o fundo e o chao todos: so assim o cenario procedural sai.
func test_cada_bioma_tem_o_seu_reino_pintado() -> void:
	assert_bool(SceneryArt.painted()).is_true()
	for id in Registry.ids(&"biomes"):
		for camada: StringName in FUNDO + CHAO:
			(
				assert_bool(SceneryArt.has(StringName(id), camada))
				. override_failure_message("%s sem %s" % [id, camada])
				. is_true()
			)


## Cada transicao liga dois biomas do jogo, com o de onde se vem a esquerda, cabe inteira no
## quadro dela, e traz o chao e o marco do limiar.
func test_cada_transicao_liga_dois_biomas_e_traz_o_marco() -> void:
	var biomas := Registry.ids(&"biomes")
	var pares := SceneryArt.pairs()
	var transicoes := 0
	for id in SceneryArt.scenes():
		transicoes += int(not biomas.has(StringName(id)))
	assert_int(pares.size()).is_equal(transicoes)
	for chave: String in pares:
		var lados := chave.split(">")
		assert_bool(biomas.has(StringName(lados[0]))).is_true()
		assert_bool(biomas.has(StringName(lados[1]))).is_true()
		var cena: StringName = pares[chave][SceneryMap.CENA]
		var meia: Vector2 = pares[chave][SceneryMap.MEIA]
		assert_float(meia.x + meia.y).is_equal(SceneryArt.width(cena))
		for camada: StringName in CHAO + [SceneryStrip.MARCO]:
			assert_bool(SceneryArt.has(cena, camada)).is_true()


## A textura importada, vezes o bloco em que foi pintada, e o retangulo do manifesto: nada se
## estica nem se encolhe a caminho do ecra.
func test_cada_camada_tem_o_tamanho_do_manifesto() -> void:
	for id in SceneryArt.scenes():
		for camada: String in ["sky", "clouds", "far", "mid", "near"] + ["under", "terrain"]:
			var dados := SceneryArt.layer(StringName(id), StringName(camada))
			if dados.is_empty():
				continue
			var tex := SceneryArt.texture(StringName(id), StringName(camada))
			assert_object(tex).is_not_null()
			var r := SceneryArt.rect_of(dados)
			var s: Array = dados[SceneryArt.ESCALA]
			assert_float(tex.get_width() * float(s[0])).is_equal(r.size.x)
			assert_float(tex.get_height() * float(s[1])).is_equal(r.size.y)


## O chao e a terra pintados tapam de y 517 ao fundo do ecra: e o que garante que o subsolo
## so se ve quando se abre (ADR 0039).
func test_a_terra_pintada_comeca_na_linha_do_chao() -> void:
	for id in SceneryArt.scenes():
		var debaixo := SceneryArt.rect_of(SceneryArt.layer(StringName(id), &"under"))
		assert_float(debaixo.position.y).is_less(float(Band.GROUND_LINE))
		var fundo := 0.0
		for camada: StringName in [&"under", &"terrain", &"water", &"foreground"]:
			var dados := SceneryArt.layer(StringName(id), camada)
			if not dados.is_empty():
				fundo = maxf(fundo, SceneryArt.rect_of(dados).end.y)
		assert_float(fundo).is_equal(float(Band.SCREEN_BOTTOM))
