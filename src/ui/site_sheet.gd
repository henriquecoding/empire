# src/ui/site_sheet.gd — a ficha do sitio de fundacao, aberta pelo Interagir (UX-08, ADR 0078).
#
# O plano mestre da HUD de 07/10/2026 (§8) tira o relatorio do meio do ecra: parado num sitio
# livre, o contexto diz uma linha, e o Interagir abre esta ficha — se aqui se funda, o que a
# fundacao faz, o que a clareira leva e o que o territorio permite —, com a mesma conta que a
# confirmacao usa (FoundationGuide). Abrir nao gasta nem funda. Fundar e o Interagir outra
# vez, ou o botao: sai pela intencao de sempre, e a simulacao volta a validar o sitio (ADR
# 0066). Voltar, a pausa, ou o sitio deixar de valer fecham-na sem mudar nada. Aberta, o
# mundo nao recebe ordens, como na viagem; o relogio continua.
class_name SiteSheet
extends PanelContainer

const WIDTH := 420.0
const FONTS := {"title": 20, "body": 15, "small": 13, "button": 16}
const GAP := 8
const HALF_GAP := 4
## Os espacos entre o titulo, as linhas, o corpo e os botoes (o da nota conta a parte).
const SEPARATIONS := 3
const BUTTON_HEIGHT := 48.0
## Abaixo desta altura (unidades de interface) a ficha sobe por cima do cabecalho: e um
## ecra dedicado, e nao ha que encaixar um relatorio entre os polegares (§7.4 do plano).
const LOW_HEIGHT := 420.0
const FOCUS_WIDTH := 2

static var active := false

var device := Glyphs.Device.KEYBOARD
var _title: Label
var _body: VBoxContainer
var _scroll: ScrollContainer
var _hint: Label
var _found: Button
var _back: Button
var _labels: Array[Label] = []


## Se o Interagir aqui abre a ficha: o monarca titular parado num sitio onde se pode fundar,
## e a ficha ainda fechada. Aberta, o Interagir seguinte confirma.
static func asks() -> bool:
	return not active and _here()


static func _here() -> bool:
	if SimLoop.units == null or SimLoop.arrival == null or not Assume.king():
		return false
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return i >= 0 and LastCartWatch.choice_at(SimLoop.units.xs[i]) != &""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"site_sheet")
	add_theme_stylebox_override("panel", Atlas.folio())
	device = Glyphs.initial()
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", GAP)
	add_child(rows)
	_title = _label(rows, FONTS.title, Atlas.INK)
	rows.add_child(AtlasRule.new())
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", HALF_GAP)
	_scroll.add_child(_body)
	_hint = _label(rows, FONTS.small, Atlas.INK_SOFT)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", GAP)
	rows.add_child(botoes)
	_found = _button(botoes, confirm, Atlas.FIELD, Atlas.TEXT)
	_back = _button(botoes, close, Atlas.FOLIO, Atlas.INK)


func open() -> void:
	if not _here():
		return
	active = true
	visible = true
	_fill()
	_place()
	# O foco seguro e o Voltar: o Espaco (ui_accept) larga moedas neste jogo, e por habito
	# nao deve fundar. Fundar e o Interagir, ou o clique no botao.
	_back.grab_focus()


func close() -> void:
	active = false
	visible = false


## Funda: so se o sitio ainda vale, e pela fila de intencoes, como o Interagir sempre fez.
func confirm() -> void:
	if not active:
		return
	var vale := _here()
	close()
	if vale:
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME)


## O texto todo da ficha, pela ordem em que se le.
func text() -> String:
	var partes := PackedStringArray([_title.text])
	for filho in _body.get_children():
		partes.append((filho as Label).text)
	if _hint.visible:
		partes.append(_hint.text)
	partes.append(_found.text)
	partes.append(_back.text)
	return "\n".join(partes)


func _input(event: InputEvent) -> void:
	if not active:
		return
	var nome := ""
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		nome = Input.get_joy_name(event.device)
	device = Glyphs.device_of(event, device, nome)
	if event.is_action_pressed(&"verb_assume"):
		confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not active:
		return
	if not _here():  # o sitio deixou de valer: fecha, e nao se funda nada
		close()
		return
	_place()


func _exit_tree() -> void:
	active = false


func _fill() -> void:
	for filho in _body.get_children():
		_body.remove_child(filho)
		filho.queue_free()
	_labels.assign([_title, _hint])
	_title.text = tr(&"SHEET_FOUND_TITLE")
	var x := SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)]
	var partes := FoundationGuide.sections(x)
	_line(tr(&"SHEET_FOUND_CAN"), FONTS.body, Atlas.INK)
	_line(tr(&"SHEET_FOUND_EFFECT"), FONTS.small, Atlas.INK_SOFT)
	_section(&"SHEET_CLEARING", partes[FoundationGuide.CLEARS], &"SHEET_CLEARING_NONE")
	for linha: String in partes[FoundationGuide.KEEPS]:
		_line(linha, FONTS.body, Atlas.INK)
	_section(&"SHEET_TERRITORY", partes[FoundationGuide.TERRITORY], &"SHEET_TERRITORY_NONE")
	var botoes: Array = Glyphs.BOTOES[device]
	_hint.visible = device != Glyphs.Device.TOUCH
	_hint.text = (
		tr(&"SHEET_FOUND_HINT")
		. format(
			{
				"assume": _tecla(botoes[Glyphs.ACCOES.find(&"HINT_ASSUME")]),
				"back": _tecla(botoes[Glyphs.ACCOES.find(&"HINT_PAUSE")]),
			}
		)
	)
	_found.text = tr(&"SHEET_FOUND_CONFIRM")
	_back.text = tr(&"SHEET_BACK")


func _section(cabeca: StringName, linhas: PackedStringArray, vazio: StringName) -> void:
	_line(tr(cabeca), FONTS.small, Atlas.INK_SOFT)
	if linhas.is_empty():
		_line(tr(vazio), FONTS.body, Atlas.INK)
	for linha: String in linhas:
		_line(linha, FONTS.body, Atlas.INK)


func _line(texto: String, tamanho: int, cor: Color) -> void:
	var label := _label(_body, tamanho, cor)
	label.text = texto


## A ficha encostada a direita, fora do centro onde a camara poe o monarca; o corpo
## rola se nao couber. As alturas medem-se como o Label dobra (HudLayout.text_height).
func _place() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	var area := get_viewport_rect().size / zoom
	var largura := minf(WIDTH, area.x - HudLayout.MARGIN * 2)
	var topo := HudLayout.HEADER_BOTTOM + HudLayout.PADDING
	if area.y < LOW_HEIGHT:
		topo = HudLayout.MARGIN
	var margem := get_theme_stylebox(&"panel").get_minimum_size()
	var dentro := largura - margem.x
	var corpo := 0.0
	for label: Label in _labels:
		label.custom_minimum_size = Vector2(dentro, 0)
		if label.visible:
			label.custom_minimum_size.y = HudLayout.text_height(label, dentro)
			if label.get_parent() == _body:
				corpo += label.custom_minimum_size.y + HALF_GAP
	var fixo := margem.y + _title.custom_minimum_size.y + Atlas.RULE_HEIGHT + BUTTON_HEIGHT
	fixo += (_hint.custom_minimum_size.y + GAP if _hint.visible else 0.0) + GAP * SEPARATIONS
	var cabe := maxf(0.0, area.y - topo - HudLayout.MARGIN - fixo)
	_scroll.custom_minimum_size = Vector2(dentro, minf(corpo, cabe))
	scale = Vector2.ONE * zoom
	size = Vector2(largura, fixo + _scroll.custom_minimum_size.y)
	position = Vector2(area.x - HudLayout.MARGIN - largura, topo) * zoom


## O nome do botao do dispositivo: uma chave a traduzir, ou o nome tal e qual (Glyphs).
func _tecla(botao: Variant) -> String:
	return tr(botao) if botao is StringName else String(botao)


func _label(pai: Node, tamanho: int, cor: Color) -> Label:
	var label := HudStyle.label(pai, tamanho, cor)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_labels.append(label)
	return label


func _button(pai: Node, accao: Callable, fundo: Color, tinta: Color) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size.y = BUTTON_HEIGHT
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.add_theme_font_override("font", HudStyle.font())
	botao.add_theme_font_size_override("font_size", FONTS.button)
	for estado: StringName in [&"normal", &"hover", &"pressed"]:
		botao.add_theme_stylebox_override(estado, Atlas.card(fundo, Atlas.INK_SOFT, 1.0))
	var foco := Atlas.card(fundo, Atlas.COIN, 1.0)
	foco.set_border_width_all(FOCUS_WIDTH)
	botao.add_theme_stylebox_override(&"focus", foco)
	for cor: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		botao.add_theme_color_override(cor, tinta)
	botao.add_theme_color_override(&"font_focus_color", tinta)
	botao.pressed.connect(accao)
	pai.add_child(botao)
	return botao
