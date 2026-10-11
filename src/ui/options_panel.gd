#
# Sairam do PauseMenu quando ele chegou as 250 linhas do §28: o menu e a
# moldura, o titulo e os dois botoes; isto e o que se escolhe. Cada opcao grava
# nas Preferences (§45) e vale ja — menos a duracao do dia, que muda a partida e
# por isso vai pela fila de intencoes (§61, GB-24).
#
# O texto e todo por chave, e volta a escrever-se quando o idioma muda: o motor
# avisa cada no com NOTIFICATION_TRANSLATION_CHANGED (§27, GB-28).
class_name OptionsPanel
extends VBoxContainer

## §26: "recomendado 12 px". Lido a um metro de um Steam Deck.
const LETRA := 20
const TINTA := Color(0.96, 0.92, 0.81)
## De quanto em quanto anda o slider do dia: onze paragens entre 240 e 540 s.
const PASSO_DIA_S := 30.0
const CEM := 100.0
## Os modos para daltonismo, pela ordem do AccessibilityFilter.Mode.
const MODOS := [&"OPT_COLORBLIND_OFF", &"OPT_PROTANOPIA", &"OPT_DEUTERANOPIA", &"OPT_TRITANOPIA"]
## O nome de cada idioma de Preferences.LANGUAGES, nele proprio (§27).
const NOMES_IDIOMA := [&"LANG_PT_PT", &"LANG_EN"]
## Os separadores, pela ordem: o terceiro so aparece onde ha toque (ADR 0047).
const SEPARADORES := [&"UI_ACCESSIBILITY", &"UI_MENU_GAME", &"UI_MENU_TOUCH"]
const TOQUE := 2
## De quanto em quanto anda o tamanho dos controlos de toque.
const PASSO_TOQUE := 0.1
const TABS_WIDTH := 540
const SLIDER_HEIGHT := 44
const CHOICE_SIZE := Vector2(160, 48)

var _tremor: CheckButton
var _claroes: CheckButton
var _legendas: CheckButton
var _roda: CheckButton
var _som: CheckButton
var _dia: HSlider
var _dia_rotulo: Label
var _contraste: HSlider
var _contraste_rotulo: Label
var _daltonismo_rotulo: Label
var _daltonismo: OptionButton
var _idioma_rotulo: Label
var _idioma: OptionButton
var _access: VBoxContainer
var _game: VBoxContainer
var _touch: VBoxContainer
var _toque_rotulo: Label
var _toque: HSlider
var _canhoto: CheckButton
var _vibrar: CheckButton
var _fixa: CheckButton
var _tabs: Array[Button] = []
var _tab := 0
var _tab_row: BoxContainer


func _ready() -> void:
	_tab_row = BoxContainer.new()
	add_child(_tab_row)
	for i in SEPARADORES.size():
		var tab := PauseTheme.button(_tab_row, SEPARADORES[i], show_tab.bind(i))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggle_mode = true
		_tabs.append(tab)
	_access = VBoxContainer.new()
	add_child(_access)
	_game = VBoxContainer.new()
	add_child(_game)
	_touch = VBoxContainer.new()
	add_child(_touch)
	_tremor = _opcao(Preferences.SCREEN_SHAKE)
	_claroes = _opcao(Preferences.FLASHES)
	_legendas = _opcao(Preferences.CAPTIONS)
	_access.add_child(TextScaleOption.new())
	var gama: Dictionary = AccessibilityFilter.CONTRASTE
	_contraste_rotulo = _rotulo(_access)
	_contraste = _slider(_access, gama.min, gama.max, gama.passo, _no_contraste)
	_daltonismo_rotulo = _linha(_access)
	_daltonismo = _escolha(_daltonismo_rotulo, MODOS.size(), _no_daltonismo)
	_roda = _opcao(Preferences.WHEEL_SLOWDOWN, _game)
	_som = _opcao(Preferences.SOUND, _game)
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	_dia_rotulo = _rotulo(_game)
	_dia = _slider(_game, relogio.day_seconds_min, relogio.day_seconds_max, PASSO_DIA_S, _no_dia)
	_idioma_rotulo = _linha(_game)
	_idioma = _escolha(_idioma_rotulo, Preferences.LANGUAGES.size(), _no_idioma)
	var escala: Dictionary = TouchLayout.ESCALA
	_toque_rotulo = _rotulo(_touch)
	_toque = _slider(_touch, escala.min, escala.max, PASSO_TOQUE, _no_toque)
	_canhoto = _opcao(Preferences.TOUCH_LEFT, _touch)
	_vibrar = _opcao(Preferences.TOUCH_HAPTICS, _touch)
	_fixa = _opcao(Preferences.TOUCH_FIXED, _touch)
	show_tab(0)
	refresh()
	resized.connect(_fit_tabs)
	_fit_tabs()


func _fit_tabs() -> void:
	_tab_row.vertical = size.x < TABS_WIDTH


func show_tab(index: int) -> void:
	_tab = index
	_access.visible = index == 0
	_game.visible = index == 1
	_touch.visible = index == TOQUE
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == index)


func focus_first() -> void:
	_tabs[_tab].grab_focus()


## Poe cada controlo no valor que esta gravado, sem disparar nada.
func refresh() -> void:
	var prefs := Preferences.shared()
	_tremor.set_pressed_no_signal(prefs.enabled(Preferences.SCREEN_SHAKE))
	_claroes.set_pressed_no_signal(prefs.enabled(Preferences.FLASHES))
	_legendas.set_pressed_no_signal(prefs.enabled(Preferences.CAPTIONS))
	_roda.set_pressed_no_signal(prefs.enabled(Preferences.WHEEL_SLOWDOWN))
	_som.set_pressed_no_signal(prefs.enabled(Preferences.SOUND))
	_dia.set_value_no_signal(ClockService.clock.day_seconds())
	_contraste.set_value_no_signal(prefs.number(Preferences.CONTRAST))
	_daltonismo.select(int(prefs.number(Preferences.COLORBLIND)))
	_idioma.select(maxi(0, Preferences.LANGUAGES.find(TranslationServer.get_locale())))
	_toque.set_value_no_signal(prefs.number(Preferences.TOUCH_SCALE))
	_canhoto.set_pressed_no_signal(prefs.enabled(Preferences.TOUCH_LEFT))
	_vibrar.set_pressed_no_signal(prefs.enabled(Preferences.TOUCH_HAPTICS))
	_fixa.set_pressed_no_signal(prefs.enabled(Preferences.TOUCH_FIXED))
	# O separador do toque so onde ha toque: num teclado era uma pagina que nao faz nada.
	_tabs[TOQUE].visible = TouchControls.active or DisplayServer.is_touchscreen_available()
	if _tab == TOQUE and not _tabs[TOQUE].visible:
		show_tab(0)
	_escrever()


## Todo o texto do painel. Chamado ao abrir e sempre que o idioma muda.
func _escrever() -> void:
	for i in SEPARADORES.size():
		_tabs[i].text = tr(SEPARADORES[i])
	_tremor.text = tr(&"OPT_SCREEN_SHAKE")
	_claroes.text = tr(&"OPT_FLASHES")
	_legendas.text = tr(&"OPT_CAPTIONS")
	_roda.text = tr(&"OPT_WHEEL_SLOWDOWN")
	_som.text = tr(&"OPT_SOUND")
	_dia_rotulo.text = "%s · %d s" % [tr(&"OPT_DAY_LENGTH"), int(_dia.value)]
	_contraste_rotulo.text = "%s · %d%%" % [tr(&"OPT_CONTRAST"), roundi(_contraste.value * CEM)]
	_daltonismo_rotulo.text = tr(&"OPT_COLORBLIND")
	_toque_rotulo.text = "%s · %d%%" % [tr(&"OPT_TOUCH_SIZE"), roundi(_toque.value * CEM)]
	_canhoto.text = tr(&"OPT_TOUCH_LEFT")
	_vibrar.text = tr(&"OPT_TOUCH_HAPTICS")
	_fixa.text = tr(&"OPT_TOUCH_FIXED")
	_idioma_rotulo.text = tr(&"UI_LANGUAGE")
	for i in MODOS.size():
		_daltonismo.set_item_text(i, tr(MODOS[i]))
	for i in Preferences.LANGUAGES.size():
		_idioma.set_item_text(i, tr(NOMES_IDIOMA[i]))
	_daltonismo.text = _daltonismo.get_item_text(maxi(0, _daltonismo.selected))
	_idioma.text = _idioma.get_item_text(maxi(0, _idioma.selected))


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSLATION_CHANGED and _idioma != null:
		_escrever()


func _no_dia(segundos: float) -> void:
	Preferences.shared().set_number(Preferences.DAY_SECONDS, segundos)
	SimLoop.intents.queue(IntentQueue.Kind.DAY_LENGTH, {&"seconds": segundos})
	_escrever()


func _no_contraste(valor: float) -> void:
	Preferences.shared().set_number(Preferences.CONTRAST, valor)
	_escrever()


func _no_toque(valor: float) -> void:
	Preferences.shared().set_number(Preferences.TOUCH_SCALE, valor)
	_escrever()


func _no_daltonismo(modo: int) -> void:
	Preferences.shared().set_number(Preferences.COLORBLIND, modo)


## §27: o idioma troca ja, e fica para a proxima vez que o jogo abrir (a boot le-o).
func _no_idioma(i: int) -> void:
	Preferences.shared().set_text(Preferences.LANGUAGE, Preferences.LANGUAGES[i])
	TranslationServer.set_locale(Preferences.LANGUAGES[i])


func _opcao(preferencia: StringName, parent: VBoxContainer = null) -> CheckButton:
	if parent == null:
		parent = _access
	var opcao := CheckButton.new()
	PauseTheme.follow_pointer(opcao)
	opcao.custom_minimum_size.y = PauseTheme.BUTTON_HEIGHT
	opcao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opcao.add_theme_color_override("font_color", TINTA)
	opcao.toggled.connect(
		func(ligado: bool) -> void: Preferences.shared().set_enabled(preferencia, ligado)
	)
	parent.add_child(opcao)
	return opcao


func _slider(parent: Node, de: float, ate: float, passo: float, ao_mudar: Callable) -> HSlider:
	var slider := HSlider.new()
	PauseTheme.follow_pointer(slider)
	slider.custom_minimum_size.y = SLIDER_HEIGHT
	slider.min_value = de
	slider.max_value = ate
	slider.step = passo
	slider.value_changed.connect(ao_mudar)
	parent.add_child(slider)
	return slider


## Uma linha com o nome a esquerda e a escolha a direita. Devolve o nome.
func _linha(parent: Node) -> Label:
	var linha := HBoxContainer.new()
	var nome := _rotulo(linha)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(linha)
	return nome


func _escolha(nome: Label, quantas: int, ao_escolher: Callable) -> OptionButton:
	var escolha := OptionButton.new()
	PauseTheme.follow_pointer(escolha)
	escolha.custom_minimum_size = CHOICE_SIZE
	escolha.fit_to_longest_item = false
	for i in quantas:
		escolha.add_item("")
	escolha.item_selected.connect(ao_escolher)
	nome.get_parent().add_child(escolha)
	return escolha


func _rotulo(onde: Container) -> Label:
	var rotulo := Label.new()
	rotulo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", LETRA)
	rotulo.add_theme_color_override("font_color", TINTA)
	onde.add_child(rotulo)
	return rotulo
