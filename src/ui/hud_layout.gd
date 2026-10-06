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
## mais longe do que parece e o polegar tapa. O browser do telemovel da dois ou tres pixeis por ponto
## (o devicePixelRatio), e a conta so pelos pixeis deixava a HUD, os botoes e a pausa a
## um terco disso no iPhone — a captura do dono de 06/10/2026 (UX-06).
static func zoom_for(pixels: float, density: float, touch := false) -> float:
	var points := pixels / maxf(1.0, density)
	return scale_for(points / (TOUCH_POINTS if touch else 1.0))


## A escala da interface neste ecra: um painel, um botao ou a pausa chamam isto.
static func zoom(viewport: Viewport) -> float:
	var pixels := viewport.get_final_transform().get_scale().x
	return zoom_for(pixels, DisplayServer.screen_get_scale(), TouchControls.active)
