# src/ui/pause_menu.gd — "Pausa / opcoes", e o fim da partida (§24, §26, §16).
#
# O mapa de comando do §24 da ao Start e ao Esc a linha "Pausa / opcoes —
# Sempre". A pausa ja existia; as opcoes nao, e o §26 tem duas que marca como
# obrigatorias: desligar o tremor de ecra e os claroes (GB-13). Vivem aqui
# porque e aqui que o §24 as pos, e gravam-se nas Preferences (§45).
#
# A derrota passa pelo mesmo ecra (GB-16). Antes, com o castelo-arvore caido, o
# veu dizia "JOGO EM PAUSA — ESC para continuar", e o Esc nao fazia nada: era a
# unica frase do jogo que mentia. O §16 diz o que e perder — "decay em vez de
# reset", e nao um save que se recarrega — e por isso o que se oferece e um jogo
# NOVO, e nao a ultima alvorada.
#
# Navega-se com o comando sem codigo nenhum para isso: sao Controls do motor, e
# as accoes ui_up, ui_down e ui_accept ja trazem o D-pad e o botao A (§26: "a
# configuracao por omissao da acesso a todo o conteudo").
#
# O texto e todo por chave de data/i18n/strings.csv (AGENTS.md).
class_name PauseMenu
extends Control

## Quem recomeca a partida e a cena de jogo, e ela esta noutra camada (§70): o
## pedido vai pelo grupo e nao por um import.
const GRUPO_JOGO := &"jogo"
const RECOMECAR := &"new_game"

const FUNDO := Color(0.02, 0.02, 0.03, 0.62)
const PAPEL := Color(0.20, 0.16, 0.13, 0.96)
const OURO := Color(0.95, 0.67, 0.27)
const TINTA := Color(0.96, 0.92, 0.81)
## §26: "nenhum caracter abaixo de 9 px... recomendado 12 px". Isto e titulo e
## menu, lidos a um metro de um Steam Deck.
const LETRA := {"titulo": 30, "item": 20}
const MOLDURA := {"borda": 3, "canto": 4, "margem": 28, "entre": 14}
const LARGURA := 380.0
## De quanto em quanto anda o slider do dia: onze paragens entre 240 e 540 s.
const PASSO_DIA_S := 30.0
const CEM := 100.0
## Os modos para daltonismo, pela ordem do AccessibilityFilter.Mode.
const MODOS := [&"OPT_COLORBLIND_OFF", &"OPT_PROTANOPIA", &"OPT_DEUTERANOPIA", &"OPT_TRITANOPIA"]

var _titulo: Label
var _tremor: CheckButton
var _claroes: CheckButton
var _legendas: CheckButton
var _dia: HSlider
var _dia_rotulo: Label
var _contraste: HSlider
var _contraste_rotulo: Label
var _daltonismo: OptionButton
var _retomar: Button
var _novo: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.color = FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size.x = LARGURA
	caixa.add_theme_constant_override("separation", MOLDURA.entre)
	centro.add_child(_painel(caixa))
	_titulo = _rotulo(caixa)
	_tremor = _opcao(caixa, &"OPT_SCREEN_SHAKE", Preferences.SCREEN_SHAKE)
	_claroes = _opcao(caixa, &"OPT_FLASHES", Preferences.FLASHES)
	_legendas = _opcao(caixa, &"OPT_CAPTIONS", Preferences.CAPTIONS)
	_duracao(caixa)
	_visao(caixa)
	_retomar = _botao(caixa, &"UI_RESUME", _ao_retomar)
	_novo = _botao(caixa, &"UI_NEW_GAME", _ao_recomecar)
	hide()
	EventBus.game_paused.connect(_na_pausa)


## O ecra abre com a pausa e fecha com ela. A derrota tambem pausa (game.gd), e e
## entao que ele muda de titulo e de botao.
func _na_pausa(pausado: bool) -> void:
	if pausado:
		open(defeated())
	else:
		_fechar()


## Abre o ecra, de pausa ou de derrota. Publico para se poder medir sem montar
## uma partida e deixa-la cair.
func open(perdido: bool) -> void:
	_titulo.text = tr(&"UI_CROWN_FALLEN") if perdido else tr(&"UI_PAUSED")
	_retomar.visible = not perdido
	_novo.visible = perdido
	_tremor.set_pressed_no_signal(Preferences.on(Preferences.SCREEN_SHAKE))
	_claroes.set_pressed_no_signal(Preferences.on(Preferences.FLASHES))
	_legendas.set_pressed_no_signal(Preferences.on(Preferences.CAPTIONS))
	_dia.set_value_no_signal(ClockService.clock.day_seconds())
	_mostrar_dia(_dia.value)
	_contraste.set_value_no_signal(Preferences.shared().number(Preferences.CONTRAST))
	_mostrar_contraste(_contraste.value)
	_daltonismo.select(int(Preferences.shared().number(Preferences.COLORBLIND)))
	show()
	(_novo if perdido else _retomar).grab_focus()


## §10: "se cair, cai a partida". E a unica pausa de onde nao se volta.
static func defeated() -> bool:
	return SimLoop.state != null and SimLoop.builds.fallen(BuildSlot.NUCLEO)


## Quem fecha solta o foco: um botao escondido com foco continuava a ouvir o
## Espaco, e o Espaco e o Verbo 1.
func _fechar() -> void:
	var com_foco := get_viewport().gui_get_focus_owner()
	if com_foco != null and is_ancestor_of(com_foco):
		com_foco.release_focus()
	hide()


func _ao_retomar() -> void:
	if not defeated():
		SimLoop.set_paused(false)


func _ao_recomecar() -> void:
	_fechar()
	get_tree().call_group(GRUPO_JOGO, RECOMECAR)


func _painel(conteudo: Control) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = PAPEL
	estilo.border_color = OURO
	estilo.set_border_width_all(MOLDURA.borda)
	estilo.set_corner_radius_all(MOLDURA.canto)
	estilo.set_content_margin_all(MOLDURA.margem)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo)
	painel.add_child(conteudo)
	return painel


func _rotulo(caixa: VBoxContainer) -> Label:
	var rotulo := Label.new()
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", LETRA.titulo)
	rotulo.add_theme_color_override("font_color", OURO)
	caixa.add_child(rotulo)
	return rotulo


func _opcao(caixa: VBoxContainer, chave: StringName, preferencia: StringName) -> CheckButton:
	var opcao := CheckButton.new()
	opcao.text = tr(chave)
	opcao.add_theme_font_size_override("font_size", LETRA.item)
	opcao.add_theme_color_override("font_color", TINTA)
	opcao.toggled.connect(
		func(ligado: bool) -> void: Preferences.shared().set_enabled(preferencia, ligado)
	)
	caixa.add_child(opcao)
	return opcao


## §26: "slider de duracao do dia (240–540 s)". Os limites sao os do clock.csv. O
## que se escolhe fica nas preferencias para os jogos novos, e chega a este pela
## fila de intencoes (§61): a pausa nao mexe no relogio (GB-24).
func _duracao(caixa: VBoxContainer) -> void:
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	_dia_rotulo = Label.new()
	_dia_rotulo.add_theme_font_size_override("font_size", LETRA.item)
	_dia_rotulo.add_theme_color_override("font_color", TINTA)
	caixa.add_child(_dia_rotulo)
	_dia = HSlider.new()
	_dia.min_value = dados.day_seconds_min
	_dia.max_value = dados.day_seconds_max
	_dia.step = PASSO_DIA_S
	_dia.value = dados.day_seconds
	_dia.value_changed.connect(_no_dia)
	caixa.add_child(_dia)
	_mostrar_dia(_dia.value)


func _no_dia(segundos: float) -> void:
	_mostrar_dia(segundos)
	Preferences.shared().set_number(Preferences.DAY_SECONDS, segundos)
	SimLoop.intents.queue(IntentQueue.Kind.DAY_LENGTH, {&"seconds": segundos})


func _mostrar_dia(segundos: float) -> void:
	_dia_rotulo.text = "%s · %d s" % [tr(&"OPT_DAY_LENGTH"), int(segundos)]


## §26: contraste e modos para daltonismo (GB-25, GB-26). Sao preferencias de
## quem ve, e nao estado de jogo: gravam-se e o filtro le-as ja.
func _visao(caixa: VBoxContainer) -> void:
	var gama: Dictionary = AccessibilityFilter.CONTRASTE
	_contraste_rotulo = _rotulo_item(caixa)
	_contraste = HSlider.new()
	_contraste.min_value = gama.min
	_contraste.max_value = gama.max
	_contraste.step = gama.passo
	_contraste.value = 1.0
	_contraste.value_changed.connect(_no_contraste)
	caixa.add_child(_contraste)
	_mostrar_contraste(_contraste.value)
	var linha := HBoxContainer.new()
	var nome := _rotulo_item(linha)
	nome.text = tr(&"OPT_COLORBLIND")
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daltonismo = OptionButton.new()
	for chave: StringName in MODOS:
		_daltonismo.add_item(tr(chave))
	_daltonismo.item_selected.connect(_no_daltonismo)
	linha.add_child(_daltonismo)
	caixa.add_child(linha)


func _no_contraste(valor: float) -> void:
	_mostrar_contraste(valor)
	Preferences.shared().set_number(Preferences.CONTRAST, valor)


func _no_daltonismo(modo: int) -> void:
	Preferences.shared().set_number(Preferences.COLORBLIND, modo)


func _mostrar_contraste(valor: float) -> void:
	_contraste_rotulo.text = "%s · %d%%" % [tr(&"OPT_CONTRAST"), roundi(valor * CEM)]


func _rotulo_item(onde: Container) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_size_override("font_size", LETRA.item)
	rotulo.add_theme_color_override("font_color", TINTA)
	onde.add_child(rotulo)
	return rotulo


func _botao(caixa: VBoxContainer, chave: StringName, ao_premir: Callable) -> Button:
	var botao := Button.new()
	botao.text = tr(chave)
	botao.add_theme_font_size_override("font_size", LETRA.item)
	botao.pressed.connect(ao_premir)
	caixa.add_child(botao)
	return botao
