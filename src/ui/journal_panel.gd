# src/ui/journal_panel.gd — um diario achado, lido no ecra (§79; XIII-08).
#
# §79: doze fragmentos de 60 a 90 palavras, cada um um objeto fisico — uma lista,
# um manifesto, uma escala de turnos. Acham-se como os segredos do §17, e por
# isso o sinal e o `secret_found` da §46 com o id do diario: nao ha um sinal so
# para diarios no catalogo, e inventa-lo partia a regra 7.
#
# Nao pausa o jogo: o §17 pede que o lore nunca pare a partida. Fica o tempo de
# ler, e sai com o Verbo 1 ou sozinho.
class_name JournalPanel
extends PanelContainer

const TITULO := &"title"
const CORPO := &"body"
const TABELA := SimFactory.TABELA_DIARIOS

## O tempo de ler noventa palavras devagar. Nao vem do dossie: e leitura.
const DURA_S := 24.0
## Por baixo do HUD e acima do chao (§11): o rei anda no chao, e fica a vista.
const CAIXA := {"x": 340.0, "y": 100.0, "w": 600.0, "h": 280.0}
const LETRA_TITULO := 20
const LETRA_CORPO := 14
const PAPEL := Color(0.93, 0.88, 0.76, 0.96)
const TINTA := Color(0.16, 0.12, 0.09)
const MARGEM := 18

var _titulo: Label
var _corpo: Label
var _falta: float = 0.0


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
	coluna.add_child(_titulo)
	coluna.add_child(_corpo)
	EventBus.secret_found.connect(_no_achado)


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


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"verb_drop"):
		visible = false


func _rotulo(letra: int) -> Label:
	var r := Label.new()
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size.x = CAIXA.w - MARGEM * 2
	r.add_theme_font_size_override("font_size", letra)
	r.add_theme_color_override("font_color", TINTA)
	return r
