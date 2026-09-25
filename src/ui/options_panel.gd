# src/ui/options_panel.gd — as opcoes da pausa (§24, §26, §27).
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

var _tremor: CheckButton
var _claroes: CheckButton
var _legendas: CheckButton
var _dia: HSlider
var _dia_rotulo: Label
var _contraste: HSlider
var _contraste_rotulo: Label
var _daltonismo_rotulo: Label
var _daltonismo: OptionButton
var _idioma_rotulo: Label
var _idioma: OptionButton


func _ready() -> void:
	_tremor = _opcao(Preferences.SCREEN_SHAKE)
	_claroes = _opcao(Preferences.FLASHES)
	_legendas = _opcao(Preferences.CAPTIONS)
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	_dia_rotulo = _rotulo(self)
	_dia = _slider(relogio.day_seconds_min, relogio.day_seconds_max, PASSO_DIA_S, _no_dia)
	var gama: Dictionary = AccessibilityFilter.CONTRASTE
	_contraste_rotulo = _rotulo(self)
	_contraste = _slider(gama.min, gama.max, gama.passo, _no_contraste)
	_daltonismo_rotulo = _linha()
	_daltonismo = _escolha(_daltonismo_rotulo, MODOS.size(), _no_daltonismo)
	_idioma_rotulo = _linha()
	_idioma = _escolha(_idioma_rotulo, Preferences.LANGUAGES.size(), _no_idioma)
	refresh()


## Poe cada controlo no valor que esta gravado, sem disparar nada.
func refresh() -> void:
	var prefs := Preferences.shared()
	_tremor.set_pressed_no_signal(prefs.enabled(Preferences.SCREEN_SHAKE))
	_claroes.set_pressed_no_signal(prefs.enabled(Preferences.FLASHES))
	_legendas.set_pressed_no_signal(prefs.enabled(Preferences.CAPTIONS))
	_dia.set_value_no_signal(ClockService.clock.day_seconds())
	_contraste.set_value_no_signal(prefs.number(Preferences.CONTRAST))
	_daltonismo.select(int(prefs.number(Preferences.COLORBLIND)))
	_idioma.select(maxi(0, Preferences.LANGUAGES.find(TranslationServer.get_locale())))
	_escrever()


## Todo o texto do painel. Chamado ao abrir e sempre que o idioma muda.
func _escrever() -> void:
	_tremor.text = tr(&"OPT_SCREEN_SHAKE")
	_claroes.text = tr(&"OPT_FLASHES")
	_legendas.text = tr(&"OPT_CAPTIONS")
	_dia_rotulo.text = "%s · %d s" % [tr(&"OPT_DAY_LENGTH"), int(_dia.value)]
	_contraste_rotulo.text = "%s · %d%%" % [tr(&"OPT_CONTRAST"), roundi(_contraste.value * CEM)]
	_daltonismo_rotulo.text = tr(&"OPT_COLORBLIND")
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


func _no_daltonismo(modo: int) -> void:
	Preferences.shared().set_number(Preferences.COLORBLIND, modo)


## §27: o idioma troca ja, e fica para a proxima vez que o jogo abrir (a boot le-o).
func _no_idioma(i: int) -> void:
	Preferences.shared().set_text(Preferences.LANGUAGE, Preferences.LANGUAGES[i])
	TranslationServer.set_locale(Preferences.LANGUAGES[i])


func _opcao(preferencia: StringName) -> CheckButton:
	var opcao := CheckButton.new()
	opcao.add_theme_font_size_override("font_size", LETRA)
	opcao.add_theme_color_override("font_color", TINTA)
	opcao.toggled.connect(
		func(ligado: bool) -> void: Preferences.shared().set_enabled(preferencia, ligado)
	)
	add_child(opcao)
	return opcao


func _slider(de: float, ate: float, passo: float, ao_mudar: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = de
	slider.max_value = ate
	slider.step = passo
	slider.value_changed.connect(ao_mudar)
	add_child(slider)
	return slider


## Uma linha com o nome a esquerda e a escolha a direita. Devolve o nome.
func _linha() -> Label:
	var linha := HBoxContainer.new()
	var nome := _rotulo(linha)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(linha)
	return nome


func _escolha(nome: Label, quantas: int, ao_escolher: Callable) -> OptionButton:
	var escolha := OptionButton.new()
	for i in quantas:
		escolha.add_item("")
	escolha.item_selected.connect(ao_escolher)
	nome.get_parent().add_child(escolha)
	return escolha


func _rotulo(onde: Container) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_size_override("font_size", LETRA)
	rotulo.add_theme_color_override("font_color", TINTA)
	onde.add_child(rotulo)
	return rotulo
