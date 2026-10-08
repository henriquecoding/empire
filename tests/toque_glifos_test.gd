# tests/toque_glifos_test.gd — o toque e o quarto dispositivo dos glifos (ADR 0047, §26).
#
# O rodape, o guia, o diario, o painel de combate e a ajuda da pausa dizem os botoes da
# mao que esta a jogar (GB-15). O toque tem os seus, e o rato que o motor faz de cada
# toque nao e um rato. Os eventos constroem-se e nao se injectam (ADR 0009).
extends GdUnitTestSuite


func _toque(premido: bool = true) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = premido
	return e


func test_um_toque_e_o_toque() -> void:
	var t := Glyphs.Device.TOUCH
	assert_int(Glyphs.device_of(_toque(), Glyphs.Device.KEYBOARD, "")).is_equal(t)
	assert_int(Glyphs.device_of(InputEventScreenDrag.new(), Glyphs.Device.XBOX, "")).is_equal(t)
	var tecla := InputEventKey.new()
	tecla.pressed = true
	assert_int(Glyphs.device_of(tecla, t, "")).is_equal(Glyphs.Device.KEYBOARD)


## O motor converte cada toque num clique de rato com device -1, e manda-o ANTES do
## toque (medido). Esse clique nao e um rato: nao troca os glifos, nao ataca.
func test_o_rato_emulado_do_toque_nao_e_um_rato() -> void:
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.device = InputEvent.DEVICE_ID_EMULATION
	assert_bool(Glyphs.emulated(clique)).is_true()
	assert_int(Glyphs.device_of(clique, Glyphs.Device.TOUCH, "")).is_equal(Glyphs.Device.TOUCH)
	clique.device = InputEvent.DEVICE_ID_MOUSE
	assert_bool(Glyphs.emulated(clique)).is_false()
	assert_int(Glyphs.device_of(clique, Glyphs.Device.TOUCH, "")).is_equal(Glyphs.Device.KEYBOARD)


func test_o_toque_emulado_do_rato_nao_troca_o_dispositivo() -> void:
	var touch := _toque()
	touch.device = InputEvent.DEVICE_ID_EMULATION
	assert_bool(Glyphs.emulated(touch)).is_true()
	assert_int(Glyphs.device_of(touch, Glyphs.Device.KEYBOARD, "")).is_equal(Glyphs.Device.KEYBOARD)


func test_o_toque_tem_um_nome_por_accao_e_esconde_o_rodape() -> void:
	var nomes: Array = Glyphs.BOTOES[Glyphs.Device.TOUCH]
	assert_int(nomes.size()).is_equal(Glyphs.ACCOES.size())
	for nome: StringName in nomes:
		assert_str(tr(nome)).override_failure_message(String(nome)).is_not_equal(String(nome))
	assert_str(Glyphs.hint(Glyphs.Device.TOUCH)).is_empty()
	assert_int(JournalPanel.BOTOES[Glyphs.Device.TOUCH].size()).is_greater(0)
	assert_int(CombatGlyphs.buttons(Glyphs.Device.TOUCH).size()).is_equal(2)
	assert_str(PauseHelp.hint(Glyphs.Device.TOUCH)).is_equal(tr(&"UI_MENU_HINT_TOUCH"))


## Um toque fora dos botoes nao fecha o diario: fecham-no MOEDA e INTERAGIR, como no comando.
func test_o_rato_emulado_nao_fecha_o_diario() -> void:
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.device = InputEvent.DEVICE_ID_EMULATION
	assert_bool(JournalPanel.closes(clique)).is_false()
	clique.device = InputEvent.DEVICE_ID_MOUSE
	assert_bool(JournalPanel.closes(clique)).is_true()
