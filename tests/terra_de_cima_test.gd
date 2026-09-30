# tests/terra_de_cima_test.gd — em baixo e so paisagem, ate o rei descer (o pedido do dono
# de 30/09/2026; §11; ADR 0039).
#
# "O subsolo so fica aparente ao acessa-lo: quero que tenha vegetacao aparente sempre, ou
# lagos, caminhos, dentre outras coisas, mas o subsolo so aparece ao acessar." E a §11:
# "a tela e dividida ao meio, em baixo e so paisagem", e "uma cavidade nao descoberta
# desenha-se como terra normal; ao encontrar a entrada, a terra dissolve-se com o shader
# de dither e revela o interior".
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SEMENTE := 20260930
const OUTRA := 20261001
const CENA := "res://scenes/game.tscn"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(PASSO)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _por_o_rei(x: float) -> void:
	SimLoop.units.xs[_rei()] = x
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.step(PASSO)


## O mundo inteiro gerado, de uma beira a outra.
func _gerar_tudo() -> void:
	var limites := Frontier.walk_limits()
	_por_o_rei(limites.y)
	_por_o_rei(limites.x)


func _terra() -> Dictionary:
	var terras := SimLoop.field.wilds
	var regiao := SimLoop.state.region
	return Lowland.of(terras, SimLoop.world_width, regiao, Wilds.biome_now(), Lowland.avoided())


# ─── A terra dissolve-se so quando o rei desce ───────────────────────────────


func test_com_o_rei_a_superficie_o_subsolo_esta_tapado() -> void:
	var revelar := SoilReveal.new()
	revelar.step(PASSO, false)
	revelar.step(SoilReveal.SEGUNDOS, false)
	assert_float(revelar.progress).is_equal(0.0)
	assert_bool(revelar.closed()).is_true()


func test_ao_descer_a_terra_dissolve_se_e_ao_subir_volta() -> void:
	var revelar := SoilReveal.new()
	revelar.step(PASSO, false)
	revelar.step(SoilReveal.SEGUNDOS * 0.5, true)
	assert_float(revelar.progress).is_between(0.4, 0.6)
	assert_bool(revelar.open() or revelar.closed()).is_false()
	revelar.step(SoilReveal.SEGUNDOS, true)
	assert_bool(revelar.open()).is_true()
	revelar.step(SoilReveal.SEGUNDOS, false)
	assert_bool(revelar.closed()).is_true()


## Um save retomado com o rei la em baixo abre ja, sem se ver a terra a ir-se.
func test_o_primeiro_passo_nao_anima() -> void:
	var revelar := SoilReveal.new()
	revelar.step(PASSO, true)
	assert_bool(revelar.open()).is_true()


func test_so_o_rei_em_baixo_abre_o_subsolo() -> void:
	var i := _rei()
	assert_bool(SoilReveal.wants_open(SimLoop.units, SimLoop.king_id)).is_false()
	SimLoop.units.bands[i] = int(Band.Kind.UNDERGROUND)
	assert_bool(SoilReveal.wants_open(SimLoop.units, SimLoop.king_id)).is_true()
	assert_bool(SoilReveal.wants_open(SimLoop.units, UnitSystem.NENHUM)).is_false()


## O dither da §60 (dither_reveal: progress, matrix): dezasseis limiares, um por
## quadrado, todos diferentes — cada passo do progresso tira um quadrado e nao uma faixa.
func test_o_dither_tem_dezasseis_limiares_diferentes_entre_zero_e_um() -> void:
	var limiares := SoilReveal.thresholds()
	assert_int(limiares.size()).is_equal(SoilReveal.LADO * SoilReveal.LADO)
	var vistos := {}
	for t in limiares:
		assert_float(t).is_greater(0.0)
		assert_float(t).is_less(1.0)
		vistos[t] = true
	assert_int(vistos.size()).is_equal(limiares.size())
	var matriz := SoilReveal.matrix()
	assert_int(matriz.get_width()).is_equal(SoilReveal.LADO)
	assert_int(matriz.get_height()).is_equal(SoilReveal.LADO)


## Com a terra por cima, a passagem e so a boca; aberta, e o poco ate ao chao de baixo.
func test_a_passagem_tapada_e_so_a_boca() -> void:
	var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	var topo := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	assert_float(PassageArt.bottom(0.0)).is_equal(topo + PassageArt.BOCA)
	assert_float(PassageArt.bottom(1.0)).is_equal(fundo)


## A terra desenha-se depois do subsolo (tapa-o) e antes da superficie (quem anda em cima
## dela, e a boca da passagem, ficam por cima).
func test_a_terra_esta_entre_o_subsolo_e_a_superficie() -> void:
	var cena: Node = auto_free((load(CENA) as PackedScene).instantiate())
	var mundo := cena.get_node("Mundo")
	var subsolo := mundo.get_node("Subsolo").get_index()
	var terra := mundo.get_node("Terra")
	assert_object(terra).is_instanceof(SoilCover)
	assert_int(terra.get_index()).is_greater(subsolo)
	assert_int(terra.get_index()).is_less(mundo.get_node("Superficie").get_index())
	assert_int(terra.get_index()).is_greater(mundo.get_node("Fauna").get_index())


# ─── O que ha na terra ───────────────────────────────────────────────────────


func test_a_mesma_semente_da_a_mesma_terra() -> void:
	_gerar_tudo()
	var primeira := _terra()
	assert_array(_terra()[Lowland.PLANTAS]).is_equal(primeira[Lowland.PLANTAS])
	assert_array(_terra()[Lowland.LAGOS]).is_equal(primeira[Lowland.LAGOS])
	RngService.configure(OUTRA)
	assert_array(_terra()[Lowland.PLANTAS]).is_not_equal(primeira[Lowland.PLANTAS])
	RngService.configure(SEMENTE)


func test_ha_vegetacao_lagos_e_caminhos() -> void:
	_gerar_tudo()
	var terra := _terra()
	assert_int((terra[Lowland.LAGOS] as Array).size()).is_greater(3)
	assert_int((terra[Lowland.CAMINHOS] as Array).size()).is_greater(3)
	var tipos := {}
	for plantas: PackedFloat32Array in terra[Lowland.PLANTAS]:
		for i in range(0, plantas.size(), Wilds.PLANTA):
			tipos[int(plantas[i])] = true
	assert_int(tipos.size()).is_greater(3)
	assert_int((terra[Lowland.PLANTAS] as Array).size()).is_equal(
		(terra[Lowland.TROCOS] as Array).size()
	)


## Nao ha buraco nenhum: a terra vai de uma beira a outra, sem falhas entre trocos.
func test_a_terra_cobre_o_mundo_de_beira_a_beira() -> void:
	_gerar_tudo()
	var trocos: Array = _terra()[Lowland.TROCOS]
	trocos.sort_custom(
		func(p: Dictionary, q: Dictionary) -> bool: return p[Lowland.A] < q[Lowland.A]
	)
	var limites := Frontier.walk_limits()
	assert_float(trocos[0][Lowland.A]).is_equal_approx(limites.x, 0.01)
	assert_float(trocos[trocos.size() - 1][Lowland.B]).is_equal_approx(limites.y, 0.01)
	for k in range(1, trocos.size()):
		assert_float(trocos[k][Lowland.A]).is_equal_approx(trocos[k - 1][Lowland.B], 0.01)


func test_nenhum_lago_esta_num_caminho_nem_noutro_lago() -> void:
	_gerar_tudo()
	var terra := _terra()
	var lagos: Array = terra[Lowland.LAGOS]
	for lago: Vector4 in lagos:
		for caminho: Vector3 in terra[Lowland.CAMINHOS]:
			for y in [lago.y - lago.w, lago.y, lago.y + lago.w]:
				var longe := (
					absf(LowlandLayout.path_x(caminho, y) - lago.x) - LowlandLayout.path_half(y)
				)
				assert_float(longe).is_greater(lago.z)
		for outro: Vector4 in lagos:
			if outro != lago:
				assert_float(absf(outro.x - lago.x)).is_greater(outro.z + lago.z)


## A vegetacao nao sobe acima da linha onde se anda, nao nasce na agua nem no caminho, e
## os caminhos nao saem da boca de uma passagem.
func test_as_plantas_ficam_na_terra_e_fora_da_agua_e_dos_caminhos() -> void:
	_gerar_tudo()
	var terra := _terra()
	for plantas: PackedFloat32Array in terra[Lowland.PLANTAS]:
		var fila := Lowland.FUNDOS
		for i in range(0, plantas.size(), Wilds.PLANTA):
			var tipo := int(plantas[i])
			var pe := Lowland.foot(plantas[i + 1], plantas[i + 2])
			var topo := pe.y - FloraArt.height(tipo) * Lowland.scale_of(plantas[i + 2])
			assert_float(topo).is_greater_equal(float(Band.GROUND_LINE))
			var no_caminho := LowlandLayout.blocked(
				pe, terra[Lowland.CAMINHOS], terra[Lowland.LAGOS]
			)
			assert_bool(no_caminho).is_false()
			# De tras para a frente, fila a fila: e a ordem em que se desenham.
			var desta := mini(int(plantas[i + 2] * Lowland.FUNDOS), Lowland.FUNDOS - 1)
			assert_int(desta).is_less_equal(fila)
			fila = desta
	for caminho: Vector3 in terra[Lowland.CAMINHOS]:
		for boca in Lowland.avoided():
			assert_float(absf(caminho.x - boca)).is_greater(LowlandLayout.CAMINHO.margem)


## Os troços guardam-se: gerar mais mundo so faz os novos, e da o mesmo que fazer tudo.
func test_a_terra_feita_aos_poucos_e_a_mesma_que_feita_de_uma_vez() -> void:
	var cache := {}
	var terras := SimLoop.field.wilds
	var bocas := Lowland.avoided()
	Lowland.of(terras, SimLoop.world_width, SimLoop.state.region, Wilds.biome_now(), bocas, cache)
	_gerar_tudo()
	var regiao := SimLoop.state.region
	var aos_poucos := Lowland.of(
		terras, SimLoop.world_width, regiao, Wilds.biome_now(), bocas, cache
	)
	assert_array(aos_poucos[Lowland.PLANTAS]).is_equal(_terra()[Lowland.PLANTAS])
	assert_array(aos_poucos[Lowland.LAGOS]).is_equal(_terra()[Lowland.LAGOS])
	assert_int(cache.size()).is_less((aos_poucos[Lowland.TROCOS] as Array).size() * 2)
