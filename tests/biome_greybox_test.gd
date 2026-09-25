# tests/biome_greybox_test.gd — GB-02: seis greybox, uma por bioma, com a linha
# do chao e as tres faixas marcadas.
extends GdUnitTestSuite

const LARGURA := 1280.0


func _biomas() -> Array:
	return Array(Registry.ids(&"biomes"))


func _com(formas: Array[Dictionary], chave: StringName) -> Array:
	return formas.filter(func(f: Dictionary) -> bool: return f.has(chave))


func test_ha_seis_biomas_e_cada_um_tem_a_sua_greybox() -> void:
	assert_int(_biomas().size()).is_equal(6)
	for id in _biomas():
		assert_array(BiomeGreybox.shapes(StringName(id), LARGURA)).is_not_empty()


func test_a_linha_do_chao_e_as_tres_faixas_estao_marcadas() -> void:
	for id in _biomas():
		var formas := BiomeGreybox.shapes(StringName(id), LARGURA)
		var chao := _com(formas, &"mark").filter(
			func(f: Dictionary) -> bool: return f[&"mark"] == &"ground"
		)
		assert_int(chao.size()).is_equal(1)
		assert_float(chao[0][&"from"].y).is_equal(float(Band.GROUND_LINE))
		var faixas := _com(formas, &"band").map(
			func(f: Dictionary) -> String: return String(f[&"band"])
		)
		assert_array(faixas).contains(["AERIAL", "SURFACE", "UNDERGROUND"])


func test_os_planos_do_11_cobrem_o_ecra_sem_buracos() -> void:
	var formas := BiomeGreybox.shapes(&"coast", LARGURA)
	var y := 0.0
	for camada in range(BiomeGreybox.Camada.CEU, BiomeGreybox.Camada.FRENTE):
		var plano: Dictionary = formas[camada - 1]
		assert_int(plano[&"layer"]).is_equal(camada)
		assert_float(plano[&"rect"].position.y).is_equal(y)
		y = plano[&"rect"].end.y
	assert_float(y).is_equal(float(Band.SCREEN_BOTTOM))


func test_aberto_clareia_o_fundo_e_fechado_escurece() -> void:
	# §11 e parallax_layers.csv: o value_delta do ceu e positivo no aberto e
	# negativo no fechado. A greybox tem de o mostrar.
	var aberto := BiomeGreybox.shapes(&"coast", LARGURA)
	var fechado := BiomeGreybox.shapes(&"ancient_forest", LARGURA)
	var ceu := BiomeGreybox.Camada.CEU - 1
	var jogo := BiomeGreybox.Camada.JOGO - 1
	assert_float(aberto[ceu][&"color"].v).is_greater(aberto[jogo][&"color"].v)
	assert_float(fechado[ceu][&"color"].v).is_less(fechado[jogo][&"color"].v)


func test_cada_bioma_mostra_os_seus_recursos_e_o_marco_do_povo() -> void:
	for id in _biomas():
		var dados := Registry.entry(&"biomes", StringName(id)) as BiomeData
		var formas := BiomeGreybox.shapes(dados.id, LARGURA)
		var recursos := _com(formas, &"resource").map(
			func(f: Dictionary) -> StringName: return f[&"resource"]
		)
		assert_array(recursos).is_equal(Array(dados.resources))
		var povo := Registry.entry(&"peoples", dados.people) as PeopleData
		var marco := _com(formas, &"landmark")
		assert_int(marco.size()).is_equal(1)
		assert_str(String(marco[0][&"landmark"])).is_equal(String(povo.landmark))


func test_o_poco_do_sob_raiz_desce_em_vez_de_subir() -> void:
	var marco: Dictionary = _com(BiomeGreybox.shapes(&"subterranean", LARGURA), &"landmark")[0]
	assert_float(marco[&"rect"].position.y).is_equal(float(Band.GROUND_LINE))
