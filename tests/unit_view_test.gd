# tests/unit_view_test.gd — os cinco slots do §58 e o shader dos dois uniforms.
#
# A arte definitiva e do ART-01 e a rampa e do ART-02. O que se prova aqui e o
# mecanismo: que os slots existem pela ordem certa, que a sombra sai do .tres e
# nao de um numero escrito a mao, e que o shader tem os uniforms que o catalogo
# da §60 lhe da — nem mais, nem com outro nome.
extends GdUnitTestSuite

const SHADER := "res://shaders/palette_lut.gdshader"
const ARTE := preload("res://art/export/_placeholder/unit_scale2_placeholder.png")


func _vista() -> UnitView:
	var v: UnitView = auto_free(UnitView.new())
	add_child(v)
	return v


func test_sao_cinco_slots_pela_ordem_do_58() -> void:
	assert_array(UnitView.SLOTS).is_equal([&"body", &"head", &"face", &"weapon", &"overlay"])

	var vista := _vista()
	for i in UnitView.SLOTS.size():
		var sprite := vista.slot(UnitView.SLOTS[i])
		var porque := "falta o slot %s" % UnitView.SLOTS[i]
		assert_object(sprite).override_failure_message(porque).is_not_null()
		# O indice na lista E o z_index: body por baixo, overlay por cima.
		assert_int(sprite.z_index).is_equal(i)


func test_a_sombra_fica_debaixo_de_tudo_e_e_multiplicativa() -> void:
	# §22 degrau 1: "o maior salto isolado do documento". Castanha-quente e
	# multiplicativa — nunca preta, nunca a tapar.
	var vista := _vista()
	var sombra: Sprite2D = vista.get_node("Sombra")

	assert_int(sombra.z_index).is_equal(UnitView.Z_SHADOW)
	assert_bool(sombra.z_index < 0).is_true()
	assert_object(sombra.texture).is_not_null()
	var material: CanvasItemMaterial = sombra.material
	assert_int(material.blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_MUL)


func test_a_largura_da_sombra_vem_do_tres_e_nao_do_codigo() -> void:
	# §58: "shadow_width — obrigatorio". Duas unidades com larguras diferentes
	# tem de dar sombras diferentes, senao o campo nao serve para nada.
	var vagabundo: UnitData = Registry.entry(&"units", &"vagrant")
	var ariete: UnitData = Registry.entry(&"units", &"counterweight_ram")
	assert_int(vagabundo.shadow_width).is_not_equal(ariete.shadow_width)

	var a := _vista()
	a.apply_data(vagabundo)
	var b := _vista()
	b.apply_data(ariete)

	assert_float(a.get_node("Sombra").scale.x).is_not_equal(b.get_node("Sombra").scale.x)
	var esperado := float(ariete.shadow_width) / UnitView.SOMBRA_BASE_PX
	assert_float(b.get_node("Sombra").scale.x).is_equal_approx(esperado, 0.0001)


func test_um_slot_que_a_unidade_nao_usa_fica_escondido() -> void:
	# O vagabundo nao tem arma: layer_slots e body|head|face|overlay.
	var vagabundo: UnitData = Registry.entry(&"units", &"vagrant")
	assert_bool(&"weapon" in vagabundo.layer_slots).is_false()

	var vista := _vista()
	vista.apply_data(vagabundo)

	assert_bool(vista.slot(&"body").visible).is_true()
	assert_bool(vista.slot(&"weapon").visible).is_false()


func test_por_uma_arma_num_slot_que_a_unidade_nao_usa_nao_a_mostra() -> void:
	var vista := _vista()
	vista.apply_data(Registry.entry(&"units", &"vagrant"))
	vista.set_slot(&"weapon", ARTE)

	# O .tres manda: um vagabundo nao ganha arma por alguem lhe pousar uma.
	assert_bool(vista.slot(&"weapon").visible).is_false()


func test_o_arqueiro_ja_mostra_a_arma() -> void:
	var arqueiro: UnitData = Registry.entry(&"units", &"archer")
	assert_bool(&"weapon" in arqueiro.layer_slots).is_true()

	var vista := _vista()
	vista.apply_data(arqueiro)
	vista.set_slot(&"weapon", ARTE)

	assert_bool(vista.slot(&"weapon").visible).is_true()


func test_o_shader_tem_os_dois_uniforms_do_catalogo_e_so_esses() -> void:
	# §60: "palette_lut | lut: Texture2D, mix: float". Um shader, quatro
	# trabalhos — se aparecer aqui um terceiro uniform, alguem transformou um
	# trabalho num shader novo.
	var shader: Shader = load(SHADER)
	var nomes := PackedStringArray()
	for u in shader.get_shader_uniform_list():
		nomes.append(u["name"])
	nomes.sort()

	assert_array(nomes).is_equal(["lut", "mix"])


func test_os_cinco_slots_partilham_o_mesmo_material() -> void:
	# Um material por slot seria cinco vezes o custo de mudar a hora do dia.
	var vista := _vista()
	var primeiro := vista.slot(UnitView.SLOTS[0]).material
	assert_object(primeiro).is_not_null()
	for nome in UnitView.SLOTS:
		assert_object(vista.slot(nome).material).is_same(primeiro)


func test_a_rampa_por_omissao_nao_muda_nada() -> void:
	# Sem LUT ligada, mix fica a zero: o shader nunca e um requisito para ver
	# arte. A rampa e do ART-02 e ainda nao existe.
	var vista := _vista()
	assert_float(vista.palette_mix()).is_equal(0.0)

	vista.set_palette(null, 0.7)
	assert_float(vista.palette_mix()).is_equal_approx(0.7, 0.0001)
	vista.set_palette(null, 5.0)
	assert_float(vista.palette_mix()).is_equal(1.0)


func test_o_desfasamento_da_animacao_vem_do_fluxo_visual() -> void:
	# §58: sem desfasamento, 300 aldeoes respiram em unissono. E tem de vir do
	# fluxo VISUAL — uma variante de animacao nao pode mexer no que a semente
	# reproduz (§42).
	var vista := _vista()
	RngService.configure(20260915)
	var antes := RngService.snapshot()

	var vistos := {}
	for _i in 200:
		vistos[vista.animation_offset(8)] = true

	assert_int(vistos.size()).override_failure_message("sempre o mesmo frame").is_greater(1)
	for chave in vistos:
		assert_bool(chave >= 0 and chave < 8).is_true()
	# Os cinco fluxos deterministas ficaram exatamente onde estavam.
	assert_dict(RngService.snapshot()).is_equal(antes)


func test_uma_animacao_de_um_frame_nao_se_desfasa() -> void:
	assert_int(_vista().animation_offset(1)).is_equal(0)
	assert_int(_vista().animation_offset(0)).is_equal(0)


func test_fora_do_ecra_para_de_animar_mas_continua_a_existir() -> void:
	# §58: "continua a simular, para de animar".
	var vista := _vista()
	assert_bool(vista.on_screen()).is_true()

	vista.set_on_screen(false)
	assert_bool(vista.on_screen()).is_false()
	assert_bool(vista.get_node("Animacao").active).is_false()

	vista.set_on_screen(true)
	assert_bool(vista.get_node("Animacao").active).is_true()
