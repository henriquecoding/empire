# tests/obras_sprite_test.gd — toda a obra tem sprite, e o sitio vazio ve-se (ADR 0051).
#
# O dono, a 02/10/2026: "faca as casas e construcoes terem de fato sprites, agora estao
# todas invisiveis". O que se mede: que cada obra de buildings.csv e cada nivel do muro
# tem uma imagem; que as pintadas estao inteiras — do tamanho dito, assentes no chao, so
# com cores da paleta —; que o muro cresce de nivel para nivel; e que o convite de um
# sitio por construir nunca baixa do alfa a que ainda se ve.
extends GdUnitTestSuite

const F := Silhouette.Form
## Abaixo disto um fantasma le-se como nada (estava a 0.18).
const ALFA_VISIVEL := 0.3
const ESCURO := 0.05


func _forma(vaga: BuildSlot) -> Silhouette.Form:
	return Silhouette.of_slot(vaga, SimFactory.by_id(&"buildings"))


## O retangulo dos pixeis que nao sao transparentes.
func _usado(img: Image) -> Rect2i:
	return img.get_used_rect()


func test_toda_a_obra_do_csv_tem_sprite() -> void:
	for dados: BuildingData in Registry.entries(&"buildings"):
		if HearthArt.handles(dados.id):  # a fogueira e o farol sao fogo, e desenham-se
			continue
		var vaga := Greybox.slot_of(dados, 0.0)
		var skin := BuildingSkins.profile(vaga, _forma(vaga))
		var porque := "%s nao tem sprite" % dados.id
		assert_bool(skin.is_empty()).override_failure_message(porque).is_false()
		assert_float(BuildingSkins.box(skin, Vector2.ZERO).get_area()).is_greater(0.0)


func test_cada_nivel_do_muro_tem_o_seu_e_cresce() -> void:
	var muro := WallSite.slot(0.0)
	var vistos := {}
	var antes := 0
	for nivel in range(1, muro.costs.size() + 1):
		var skin := BuildingSkins.profile_at(muro, F.AMEIA, nivel)
		assert_bool(vistos.has(skin)).override_failure_message(String(skin)).is_false()
		vistos[skin] = nivel
		var alto := _usado(PaintedArt.image(skin)).size.y
		assert_int(alto).override_failure_message("nivel %d" % nivel).is_greater(antes)
		antes = alto


## §25: o sitio vazio de um muro promete o topo da escada; o que se ergue e o degrau a seguir.
func test_o_degrau_que_se_ve() -> void:
	var muro := WallSite.slot(0.0)
	assert_int(BuildingSkins.shown_level(muro)).is_equal(muro.costs.size())
	muro.state = BuildSlot.State.SCAFFOLD
	assert_int(BuildingSkins.shown_level(muro)).is_equal(1)
	muro.state = BuildSlot.State.DONE
	muro.level = 2
	assert_int(BuildingSkins.shown_level(muro)).is_equal(2)
	muro.state = BuildSlot.State.SCAFFOLD
	assert_int(BuildingSkins.shown_level(muro)).is_equal(3)


func test_as_pintadas_estao_inteiras() -> void:
	var cores := {}
	for cor: Color in PaintedArt.PALETA.values():
		cores[_em_8_bits(cor)] = true
	for id: StringName in PaintedArt._todas():
		var d: Dictionary = PaintedArt._todas()[id]
		var img := PaintedArt.image(id)
		var msg := String(id)
		assert_vector(Vector2(img.get_size())).override_failure_message(msg).is_equal(
			Vector2(d.size)
		)
		var usado := _usado(img)
		assert_bool(usado.has_area()).override_failure_message(msg).is_true()
		# Assente no chao: a ultima linha da imagem tem tinta.
		assert_int(usado.end.y).override_failure_message(msg + " flutua").is_equal(img.get_height())
		var paleta: Dictionary = cores.duplicate()
		for cor: Color in d.get("palette", {}).values():
			paleta[_em_8_bits(cor)] = true
		_so_da_paleta(img, paleta, msg)


## A cor como a imagem a guarda: 8 bits por canal, arredondados pelo motor.
func _em_8_bits(cor: Color) -> String:
	var px := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	px.set_pixel(0, 0, cor)
	return px.get_pixel(0, 0).to_html()


func _so_da_paleta(img: Image, paleta: Dictionary, msg: String) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and not paleta.has(c.to_html()):
				fail("%s: cor fora da paleta em %d,%d (%s)" % [msg, x, y, c.to_html()])
				return


func test_cada_povo_tem_casa_obra_e_defesa() -> void:
	for povo: StringName in NativeSprites.COLORS:
		for tipo: StringName in NativeSprites.TIPOS:
			var kind := StringName("%s_%s" % [povo, tipo])
			var skin := NativeSprites.profile(kind)
			assert_bool(PaintedArt.has(skin)).override_failure_message(String(kind)).is_true()
	assert_str(String(NativeSprites.profile(&"farm"))).is_empty()


## O convite respira, mas nunca baixa do que se ve — e nunca chega a parecer de pe.
func test_o_sitio_vazio_ve_se() -> void:
	for passo in 64:
		var alfa := BuildingSkins.ghost_alpha(float(passo) * 0.1)
		assert_float(alfa).is_greater_equal(ALFA_VISIVEL)
		assert_float(alfa).is_less(1.0)


func test_o_pincel_contorna_e_enche() -> void:
	var paleta := {"ink": Color.BLACK, "a": Color.RED}
	var img := PixelPainter.paint(Vector2i(10, 10), [["o", -3, -8, 6, 6, "a"]], paleta)
	assert_object(img.get_pixel(2, 2)).is_equal(Color.BLACK)
	assert_object(img.get_pixel(7, 7)).is_equal(Color.BLACK)
	assert_object(img.get_pixel(4, 4)).is_equal(Color.RED)
	assert_float(img.get_pixel(1, 1).a).is_equal(0.0)
	var tri := PixelPainter.paint(Vector2i(10, 10), [["q", [-4, 0, 0, -8, 4, 0], "a"]], paleta)
	assert_object(tri.get_pixel(5, 8)).is_equal(Color.RED)
	assert_float(tri.get_pixel(0, 1).a).is_equal(0.0)
	assert_float(tri.get_pixel(9, 1).a).is_less(ESCURO)
