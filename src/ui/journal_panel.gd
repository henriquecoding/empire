# src/ui/journal_panel.gd — um diario achado, lido no ecra (§79; XIII-08).
#
# §79: doze fragmentos de 60 a 90 palavras, cada um um objeto fisico — uma lista,
# um manifesto, uma escala de turnos. Acham-se como os segredos do §17, e por
# isso o sinal e o `secret_found` da §46 com o id do diario: nao ha um sinal so
# para diarios no catalogo, e inventa-lo partia a regra 7.
#
# Nao pausa o jogo: o §17 pede que o lore nunca pare a partida. Fica o tempo de
# ler, e sai sozinho ou quando se quer: ESPACO, E, ESC ou um clique fecham-no, e o
# rodape da folha di-lo. O pedido do dono de 30/09/2026 ("fica muito tempo e nao
# da para fechar manualmente"): o gesto e apanhado no `_input`, antes do painel da
# obra e do rei, que o comiam — e por isso fechar nao larga moeda nem pausa.
class_name JournalPanel
extends PanelContainer

const TITULO := &"title"
const CORPO := &"body"
const TABELA := SimFactory.TABELA_DIARIOS

## O tempo de ler noventa palavras a ritmo normal. Nao vem do dossie: e leitura.
const DURA_S := 14.0
## Os gestos que fecham a folha antes do tempo, como o registo de ecras os da
## (docs/ux/SCREEN_REGISTER.csv, `journal`): os dois verbos, o B do comando, o Esc do
## teclado e um clique; a roda do rato rola. O Start do comando nao: pausa sempre.
const FECHAM := [&"verb_drop", &"verb_assume"]
const CLIQUES := [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
## O que o rodape diz que fecha, por dispositivo: o nome, ou a chave a traduzir.
const BOTOES := {
	Glyphs.Device.KEYBOARD: [&"KEY_SPACE", "E", "ESC"],
	Glyphs.Device.XBOX: ["A", "X", "B"],
	Glyphs.Device.PLAYSTATION: [&"PAD_CROSS", &"PAD_SQUARE", &"PAD_CIRCLE"],
}
const RODAPE := &"UI_JOURNAL_CLOSE"
const ENTRE := " / "
## Por baixo do HUD e acima do chao (§11): o rei anda no chao, e fica a vista.
const CAIXA := {"x": 340.0, "y": 100.0, "w": 600.0, "h": 280.0}
const LETRA_TITULO := 20
const LETRA_CORPO := 14
const LETRA_RODAPE := 12
const PAPEL := Color(0.93, 0.88, 0.76, 0.96)
const TINTA := Color(0.16, 0.12, 0.09)
const MARGEM := 18

## O Verbo 1 que fechou a folha continua premido: ate o largarem, nao larga moeda.
static var _preso := false

var _titulo: Label
var _corpo: Label
var _rodape: Label
var _falta: float = 0.0
var _dispositivo := Glyphs.Device.KEYBOARD


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(CAIXA.x, CAIXA.y)
	custom_minimum_size = Vector2(CAIXA.w, CAIXA.h)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = PAPEL
	fundo.set_content_margin_all(MARGEM)
	add_theme_stylebox_override("panel", fundo)
	var coluna := VBoxContainer.new()
	add_child(coluna)
	_titulo = _rotulo(LETRA_TITULO)
	_corpo = _rotulo(LETRA_CORPO)
	_rodape = _rotulo(LETRA_RODAPE)
	coluna.add_child(_titulo)
	coluna.add_child(_corpo)
	coluna.add_child(_rodape)
	EventBus.secret_found.connect(_no_achado)
	var comandos := Input.get_connected_joypads()
	if not comandos.is_empty():
		_dispositivo = Glyphs.pad_of(Input.get_joy_name(comandos[0]))


## O titulo e o corpo de um diario, ja traduzidos; vazio se o id nao e de um
## diario (a camara, a estatua — esses dizem-se noutro sitio).
static func text_of(id: StringName) -> Dictionary:
	if not Registry.has_entry(TABELA, id):
		return {}
	var d := Registry.entry(TABELA, id) as JournalData
	return {
		TITULO: TranslationServer.translate(d.title_key),
		CORPO: TranslationServer.translate(d.body_key),
	}


func show_journal(id: StringName) -> void:
	var texto := text_of(id)
	if texto.is_empty():
		return
	_titulo.text = texto[TITULO]
	_corpo.text = texto[CORPO]
	_rodape.text = close_hint(_dispositivo)
	_falta = DURA_S
	visible = true


func _no_achado(id: StringName) -> void:
	show_journal(id)


func _process(delta: float) -> void:
	if not visible:
		return
	_falta -= delta
	if _falta <= 0.0:
		visible = false


## Se este gesto fecha a folha: um dos verbos, o B, o Esc ou um clique (e nao a roda).
static func closes(evento: InputEvent) -> bool:
	if evento is InputEventMouseButton:
		return evento.pressed and evento.button_index in CLIQUES
	if evento is InputEventJoypadButton:
		if evento.pressed and evento.button_index == JOY_BUTTON_B:
			return true
	if evento is InputEventKey and evento.is_action_pressed(&"pause"):
		return true
	for accao: StringName in FECHAM:
		if evento.is_action_pressed(accao):
			return true
	return false


## O rodape: os botoes que fecham, os do dispositivo activo (§26), e a palavra.
static func close_hint(dispositivo: Glyphs.Device) -> String:
	var nomes := PackedStringArray()
	for botao: Variant in BOTOES[dispositivo]:
		var nome: Variant = TranslationServer.translate(botao) if botao is StringName else botao
		nomes.append(String(nome))
	return "%s %s" % [ENTRE.join(nomes), TranslationServer.translate(RODAPE)]


## Se o Verbo 1 que fechou a folha ainda esta premido: o InputRouter nao larga.
static func holds_drop() -> bool:
	if _preso and not Input.is_action_pressed(&"verb_drop"):
		_preso = false
	return _preso


func _input(evento: InputEvent) -> void:
	var nome := ""
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
		nome = Input.get_joy_name(evento.device)
	var novo := Glyphs.device_of(evento, _dispositivo, nome)
	if novo != _dispositivo:
		_dispositivo = novo
		_rodape.text = close_hint(novo)
	if visible and closes(evento):
		visible = false
		_preso = evento.is_action_pressed(&"verb_drop")
		get_viewport().set_input_as_handled()


func _rotulo(letra: int) -> Label:
	var r := Label.new()
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size.x = CAIXA.w - MARGEM * 2
	r.add_theme_font_size_override("font_size", letra)
	r.add_theme_color_override("font_color", TINTA)
	return r
