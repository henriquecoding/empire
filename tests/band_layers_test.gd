# tests/band_layers_test.gd — a matriz do §53, e a fisica a confirma-la.
#
# O F0-05 tinha por contrato "o aereo nao colide com o subsolo" e o unico teste
# que existia comparava constantes. Isto e o que faltava: a matriz deduzida do
# BandLayers, e depois a mesma pergunta feita ao motor de fisica, que e quem
# manda no fim.
extends GdUnitTestSuite

const CENA := "res://scenes/tests/bands.tscn"
const FAIXAS: Array[Band.Kind] = [Band.Kind.AERIAL, Band.Kind.SURFACE, Band.Kind.UNDERGROUND]
const LADO := 40.0


func _coluna(faixa: Band.Kind, x: float) -> StaticBody2D:
	var corpo: StaticBody2D = auto_free(StaticBody2D.new())
	var forma := CollisionShape2D.new()
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(LADO, LADO)
	forma.shape = caixa
	corpo.add_child(forma)
	corpo.position = Vector2(x, 0.0)
	BandLayers.apply_terrain(corpo, faixa)
	add_child(corpo)
	return corpo


func _andarilho(faixa: Band.Kind, x: float) -> CharacterBody2D:
	var corpo: CharacterBody2D = auto_free(CharacterBody2D.new())
	var forma := CollisionShape2D.new()
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(LADO / 2, LADO / 2)
	forma.shape = caixa
	corpo.add_child(forma)
	corpo.position = Vector2(x, 0.0)
	BandLayers.apply_body(corpo, faixa)
	add_child(corpo)
	return corpo


# ─── A matriz, sem fisica ────────────────────────────────────────────────────


func test_cada_faixa_vive_no_seu_bit() -> void:
	assert_int(BandLayers.bit(Band.Kind.AERIAL)).is_equal(Band.L_AERIAL)
	assert_int(BandLayers.bit(Band.Kind.SURFACE)).is_equal(Band.L_SURFACE)
	assert_int(BandLayers.bit(Band.Kind.UNDERGROUND)).is_equal(Band.L_UNDER)


func test_so_colide_quem_partilha_a_faixa() -> void:
	for a in FAIXAS:
		for b in FAIXAS:
			var esperado := a == b
			var porque := "%d contra %d devia ser %s" % [a, b, esperado]
			var deu := BandLayers.collide(a, b)
			assert_bool(deu).override_failure_message(porque).is_equal(esperado)


func test_a_faixa_aerea_ignora_tudo_o_que_e_de_solo() -> void:
	# §53: "Voadoras. Ignoram tudo o que e de solo." Nao levam L_BUILDING.
	var mascara := BandLayers.body_mask(Band.Kind.AERIAL)
	assert_int(mascara & Band.L_UNDER).is_equal(0)
	assert_int(mascara & Band.L_SURFACE).is_equal(0)
	assert_int(mascara & Band.L_BUILDING).is_equal(0)


func test_um_edificio_e_atacavel_da_superficie_e_do_subsolo() -> void:
	# §53: "L_BUILDING | 16 | Superficie e subsolo | So o que e atacavel."
	assert_int(BandLayers.body_mask(Band.Kind.SURFACE) & Band.L_BUILDING).is_not_equal(0)
	assert_int(BandLayers.body_mask(Band.Kind.UNDERGROUND) & Band.L_BUILDING).is_not_equal(0)
	assert_int(BandLayers.body_mask(Band.Kind.AERIAL) & Band.L_BUILDING).is_equal(0)


func test_o_terreno_nao_procura_ninguem() -> void:
	# E quem anda que o encontra: mascara a zero evita 300 corpos a testar
	# colisao contra o mapa inteiro em cada tick.
	assert_int(BandLayers.terrain_mask()).is_equal(0)
	for faixa in FAIXAS:
		assert_int(BandLayers.terrain_layer(faixa) & Band.L_TERRAIN).is_not_equal(0)
		assert_int(BandLayers.terrain_layer(faixa) & BandLayers.bit(faixa)).is_not_equal(0)


func test_ninguem_apanha_moedas_por_colisao() -> void:
	# §53: "L_COIN | 32 | Nada — e apanha por proximidade."
	for faixa in FAIXAS:
		assert_int(BandLayers.body_mask(faixa) & Band.L_COIN).is_equal(0)


# ─── A mesma pergunta, feita ao motor de fisica ──────────────────────────────


func test_a_fisica_confirma_a_diagonal() -> void:
	var colunas := {}
	var x := 0.0
	for faixa in FAIXAS:
		colunas[faixa] = _coluna(faixa, x)
		x += LADO * 4
	await await_idle_frame()

	for corpo_faixa in FAIXAS:
		for coluna_faixa in FAIXAS:
			var coluna: StaticBody2D = colunas[coluna_faixa]
			var andarilho := _andarilho(corpo_faixa, coluna.position.x - LADO)
			await await_idle_frame()
			var bateu := andarilho.move_and_collide(Vector2(LADO, 0.0), true) != null

			var esperado := corpo_faixa == coluna_faixa
			var porque := (
				"corpo %d contra coluna %d: bateu=%s, esperado=%s"
				% [corpo_faixa, coluna_faixa, bateu, esperado]
			)
			assert_bool(bateu).override_failure_message(porque).is_equal(esperado)


func test_o_aereo_atravessa_o_subsolo_no_mesmo_sitio() -> void:
	# O contrato do F0-05, literalmente, e com os dois corpos na mesma posicao —
	# que e a unica forma de "atravessa" significar alguma coisa.
	var coluna := _coluna(Band.Kind.UNDERGROUND, 0.0)
	await await_idle_frame()

	var subterraneo := _andarilho(Band.Kind.UNDERGROUND, coluna.position.x - LADO)
	var aereo := _andarilho(Band.Kind.AERIAL, coluna.position.x - LADO)
	await await_idle_frame()

	assert_object(subterraneo.move_and_collide(Vector2(LADO, 0.0), true)).is_not_null()
	assert_object(aereo.move_and_collide(Vector2(LADO, 0.0), true)).is_null()


# ─── A cena do ticket ────────────────────────────────────────────────────────


func test_a_cena_do_f0_10_existe_e_tem_uma_coluna_por_faixa() -> void:
	assert_bool(ResourceLoader.exists(CENA)).is_true()
	var cena: Node = auto_free((load(CENA) as PackedScene).instantiate())

	var faixas_vistas: Array[int] = []
	for coluna in cena.get_node("Terreno").get_children():
		var porque := "%s nao diz a que faixa pertence" % coluna.name
		assert_bool(coluna.has_meta(&"band")).override_failure_message(porque).is_true()
		faixas_vistas.append(coluna.get_meta(&"band"))
	faixas_vistas.sort()

	assert_array(faixas_vistas).is_equal([0, 1, 2])
