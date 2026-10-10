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
const ROUNDS := 4
## O Control guarda a largura como fim menos inicio, em float, e um Label posto em 190
## pode ficar com 189,99997 e dobrar uma unidade antes. Mede-se com essa folga: nunca
## uma linha a menos do que o Label desenha.
const FOLGA := 0.01
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


## Poe um texto que se dobra centrado num `ecra` (px), com `largura` unidades, a partir
## de `top` px e com pelo menos `alto` unidades de altura. No toque, se assim tapasse um
## controlo, tenta a largura do x livre entre os controlos dos dois lados que lhe chegam a
## altura — e so a usa se, ja com a altura nova, nao tapar controlo nenhum, couber no ecra
## e se ler (MIN_BAND). Senao fica largo, como antes: nunca pior (UX-06).
static func fit_label(
	label: Label, ecra: Vector2, zoom: float, largura: float, top: float, alto := 0.0
) -> void:
	var cabe := minf(largura, ecra.x / zoom - MARGIN * 2)
	var largo := Rect2((ecra.x - cabe * zoom) * HALF, top, cabe, alto)
	_place(label, largo, zoom)
	var controlos := TouchLayout.circles
	if not TouchControls.active or controlos.is_empty() or _clear(label, largo, zoom, ecra.y):
		return
	var estreito := largo
	for _vez in ROUNDS:
		var fundo := top + maxf(alto, text_height(label, estreito.size.x)) * zoom
		var livre := TouchLayout.free_between(controlos, ecra.x, fundo)
		var util := minf(largura, (livre.y - livre.x) / zoom - MARGIN * 2)
		if util < minf(largura, MIN_BAND):
			return
		var novo := Rect2((livre.x + livre.y - util * zoom) * HALF, top, util, alto)
		if novo.is_equal_approx(estreito):
			break
		estreito = novo
	if _clear(label, estreito, zoom, ecra.y):
		_place(label, estreito, zoom)


## A altura, em unidades, do texto de `label` dobrado a `largura`: o Label so a sabe no
## frame seguinte, e um painel que muda de largura tem de a saber ja. Dobra como o Label
## dobra — a largura util em unidades inteiras (menos a FOLGA), e no WORD_SMART parte a
## palavra que nao cabe numa linha — e conta o espaco entre linhas, que a fonte nao conta.
static func text_height(label: Label, largura: float) -> float:
	var caixa := label.get_theme_stylebox(&"normal")
	var margem := caixa.get_minimum_size() if caixa != null else Vector2.ZERO
	if label.text.is_empty():
		return margem.y
	var letra := label.get_theme_font(&"font")
	var tamanho := label.get_theme_font_size(&"font_size")
	var dobra := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	if label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART:
		dobra |= TextServer.BREAK_ADAPTIVE
	var texto := letra.get_multiline_string_size(
		label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		floorf(largura - margem.x - FOLGA),
		tamanho,
		-1,
		dobra
	)
	var linhas := roundf(texto.y / maxf(1.0, letra.get_height(tamanho)))
	var entre := label.get_theme_constant(&"line_spacing") * maxf(0.0, linhas - 1.0)
	return texto.y + entre + margem.y


## Se o texto posto em `onde` (x e y em px, largura e alto em unidades) cabe no ecra de
## `altura` px e nao toca em controlo nenhum.
static func _clear(label: Label, onde: Rect2, zoom: float, altura: float) -> bool:
	var alto := maxf(onde.size.y, text_height(label, onde.size.x)) * zoom
	var caixa := Rect2(onde.position, Vector2(onde.size.x * zoom, alto))
	if caixa.end.y > altura:
		return false
	for c: Vector3 in TouchLayout.circles:
		var perto := Vector2(c.x, c.y).clamp(caixa.position, caixa.end)
		if perto.distance_to(Vector2(c.x, c.y)) < c.z:
			return false
	return true


static func _place(label: Control, onde: Rect2, zoom: float) -> void:
	label.scale = Vector2.ONE * zoom
	label.size = onde.size
	label.position = onde.position


## A escala da interface neste ecra: um painel, um botao ou a pausa chamam isto.
static func zoom(viewport: Viewport) -> float:
	var pixels := viewport.get_final_transform().get_scale().x
	return (
		zoom_for(pixels, DisplayServer.screen_get_scale(), TouchControls.active)
		* clampf(
			Preferences.shared().number(Preferences.TEXT_SCALE),
			TextScaleOption.SIZES[0],
			TextScaleOption.SIZES[-1]
		)
	)
