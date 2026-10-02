# tests/light_field_test.gd — as luzes do mundo, juntas (ADR 0034, ADR 0048).
#
# O que acende e o que ja acendia — fogueiras, farol, o archote e o Lume — e a
# lareira do nucleo, que o Torchlight ja contava como "nao e escuro". Aqui prova-se
# que todas chegam ao mesmo sitio, cada uma na sua faixa, e que a lareira alumia
# exactamente o que a regra do escuro ja dizia que nao e escuro.
extends GdUnitTestSuite

const SEMENTE := 20261002


func before_test() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)
	Greybox.build()
	LightField.reset()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	LightField.reset()


func _nucleo() -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga
	return null


func _perto(luzes: Array[Glow], x: float) -> Glow:
	for luz in luzes:
		if absf(luz.center.x - x) < 1.0:
			return luz
	return null


func test_a_lareira_alumia_o_que_o_escuro_ja_poupava() -> void:
	var nucleo := _nucleo()
	var lareira := _perto(LightField.of(int(Band.Kind.SURFACE)), nucleo.x)
	assert_object(lareira).is_not_null()
	var meia := nucleo.width * BuildSystem.METADE
	# A meia largura do nucleo e onde o Torchlight diz que o escuro acaba.
	assert_float(lareira.radius).is_between(meia * 0.9, meia * 1.1)
	var forca: float = LightField.LAREIRA.forca  # a cintilar, a volta da forca dela
	assert_float(lareira.strength).is_between(forca * 0.9, forca * 1.1)
	var obras := SimLoop.builds
	assert_bool(Torchlight.in_dark(nucleo.x + meia * 0.9, obras, nucleo.x, meia)).is_false()


func test_a_fogueira_de_pe_alumia_com_o_raio_do_csv() -> void:
	var fogueira: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == HearthArt.FOGUEIRA:
			fogueira = vaga
			break
	assert_object(_perto(LightField.of(int(Band.Kind.SURFACE)), fogueira.x)).is_null()
	fogueira.level = 1
	fogueira.state = BuildSlot.State.DONE
	fogueira.health = fogueira.max_health()
	LightField.reset()
	var luz := _perto(LightField.of(int(Band.Kind.SURFACE)), fogueira.x)
	assert_object(luz).is_not_null()
	var raio := WorldLight.hearth_radius(fogueira)
	assert_float(luz.radius).is_between(raio * 0.9, raio * 1.1)
	assert_float(luz.strength).is_less(1.0)  # mais fraca do que o Lume (Q-078)
	assert_int(luz.kind).is_equal(Flicker.Kind.FIRE)


func test_as_tuas_luzes_ficam_na_faixa_delas() -> void:
	for luz in LightField.of(int(Band.Kind.UNDERGROUND)):
		assert_int(luz.kind).is_equal(Flicker.Kind.LUME)


func test_o_mesmo_frame_da_a_mesma_lista() -> void:
	var a := LightField.of(int(Band.Kind.SURFACE))
	var b := LightField.of(int(Band.Kind.SURFACE))
	assert_int(a.size()).is_equal(b.size())
	for i in a.size():
		assert_object(a[i]).is_same(b[i])
