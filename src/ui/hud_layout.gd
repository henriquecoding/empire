class_name HudLayout
extends RefCounted

const MARGIN := 16.0
const HEADER_BOTTOM := 68.0
const CONTEXT_TOP := 80.0
const GOAL_MIN_WIDTH := 760.0
const CONTEXT_WIDTH := 520.0
const PADDING := 12.0
const GAP := 8.0
const HALF := 0.5
const MIN_SCALE := 0.01
const TOUCH_POINTS := 1.15
## O mais estreito que um texto fica para se desviar dos controlos de toque, e quantas
## vezes se reve a largura (estreitar faz o texto mais alto, e pode descer mais).
const MIN_BAND := 140.0
const ROUNDS := 2
const COMBAT_MIN_WIDTH := 960.0
const COMBAT_GAP := 40.0
const PURSE := Rect2(16, 12, 132, 56)
const CLOCK := Rect2(160, 12, 244, 56)
const GOAL := {"max_width": 520.0, "reserved": 492.0, "right": 76.0, "top": 12.0, "height": 56.0}


static func header(area: Vector2) -> Dictionary:
	var goal := Rect2()
	if area.x >= GOAL_MIN_WIDTH:
		var width := minf(GOAL.max_width, area.x - GOAL.reserved)
		goal = Rect2(area.x - GOAL.right - width, GOAL.top, width, GOAL.height)
	return {
		&"purse": PURSE,
		&"clock": CLOCK,
		&"goal": goal,
	}


static func context(area: Vector2, text_height: float) -> Rect2:
	var width := minf(CONTEXT_WIDTH, area.x - MARGIN * 2)
	return Rect2((area.x - width) * HALF, CONTEXT_TOP, width, text_height + PADDING * 2)


static func scale_for(factor: float) -> float:
	return maxf(1.0, 1.0 / maxf(MIN_SCALE, factor))


## A escala da interface para `pixels` de janela por unidade de 1280x720, num ecra com
## `density` pixeis por ponto. A interface quer pelo menos um ponto por unidade: e o
## tamanho a que foi desenhada, e no toque um pouco mais, porque o telemovel se le
## mais longe do que parece e o polegar tapa. O browser do telemovel da dois ou tres
## pixeis por ponto (o devicePixelRatio), e a conta so pelos pixeis deixava a HUD, os
## botoes e a pausa a um terco disso no iPhone — a captura do dono de 06/10/2026 (UX-06).
static func zoom_for(pixels: float, density: float, touch := false) -> float:
	var points := pixels / maxf(1.0, density)
	return scale_for(points / (TOUCH_POINTS if touch else 1.0))


## Poe um texto que se dobra centrado num ecra de `px` de largura, com `largura`
## unidades, a partir de `top` px e com pelo menos `alto` unidades de altura. No toque,
## se assim descesse por cima de um controlo, estreita para o x livre entre os controlos
## dos dois lados que lhe chegam a altura — so se ainda se ler (MIN_BAND); estreito de
## mais, fica como estava. No telemovel o contexto, o aviso e as legendas desciam por
## cima dos botoes (UX-06).
static func fit_label(
	label: Label, px: float, zoom: float, largura: float, top: float, alto := 0.0
) -> void:
	var cabe := minf(largura, px / zoom - MARGIN * 2)
	_place(label, (px - cabe * zoom) * HALF, cabe, zoom, Vector2(top, alto))
	if not TouchControls.active or TouchLayout.circles.is_empty():
		return
	for _vez in ROUNDS:
		var fundo := top + maxf(alto, text_height(label, label.size.x)) * zoom
		var livre := TouchLayout.free_between(TouchLayout.circles, px, fundo)
		var de := label.position.x
		if livre.x <= de and livre.y >= de + label.size.x * zoom:
			return
		var util := minf(largura, (livre.y - livre.x) / zoom - MARGIN * 2)
		if util < minf(largura, MIN_BAND):
			return
		_place(label, (livre.x + livre.y - util * zoom) * HALF, util, zoom, Vector2(top, alto))


## No toque, um painel que passaria o fundo do ecra (`altura` px) sobe ate caber.
static func keep_on_screen(label: Label, altura: float, alto := 0.0) -> void:
	if not TouchControls.active:
		return
	var fundo := maxf(alto, text_height(label, label.size.x)) * label.scale.y
	if label.position.y + fundo > altura:
		label.position.y = maxf(0.0, altura - fundo)


## A altura, em unidades, do texto de `label` dobrado a `largura`: o Label so a sabe no
## frame seguinte, e um painel que muda de largura tem de a saber ja.
static func text_height(label: Label, largura: float) -> float:
	var caixa := label.get_theme_stylebox(&"normal")
	var margem := caixa.get_minimum_size() if caixa != null else Vector2.ZERO
	if label.text.is_empty():
		return margem.y
	var letra := label.get_theme_font(&"font")
	var tamanho := label.get_theme_font_size(&"font_size")
	var dobra := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	var texto := letra.get_multiline_string_size(
		label.text, HORIZONTAL_ALIGNMENT_LEFT, largura - margem.x, tamanho, -1, dobra
	)
	return texto.y + margem.y


static func _place(label: Control, x: float, largura: float, zoom: float, onde: Vector2) -> void:
	label.scale = Vector2.ONE * zoom
	label.size = Vector2(largura, onde.y)
	label.position = Vector2(x, onde.x)


## A escala da interface neste ecra: um painel, um botao ou a pausa chamam isto.
static func zoom(viewport: Viewport) -> float:
	var pixels := viewport.get_final_transform().get_scale().x
	return zoom_for(pixels, DisplayServer.screen_get_scale(), TouchControls.active)
