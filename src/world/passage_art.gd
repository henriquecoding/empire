# src/world/passage_art.gd — a passagem da regiao: o poco com a escada (§11, §25).
#
# Com a terra por cima do corte de solo (SoilCover), ve-se so a boca: a moldura e os
# primeiros degraus a descer para o escuro. Com o rei la em baixo o poco abre ate ao
# chao do subsolo, ao ritmo da terra a ir-se (ADR 0039).
class_name PassageArt
extends RefCounted

const SIDES := [-1.0, 1.0]
const WIDTH := 28.0
const HALF := 0.5
const RUNG := 8
const RAIL := 3.0
## O fundo da boca, abaixo da linha do chao, com a terra por cima.
const BOCA := 26.0
const WOOD := Color("b29965")
const SHAFT := Color("171912")
const FRAME := Color("716143")


static func draw_on(canvas: CanvasItem, light: Lighting) -> void:
	var top := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var fundo := bottom(SoilCover.opened())
	for x in SimLoop.passages:
		var rect := Rect2(x - WIDTH * HALF, top, WIDTH, fundo - top)
		canvas.draw_rect(rect.grow(RAIL), light.body(FRAME, x))
		canvas.draw_rect(rect, light.body(SHAFT, x))
		for side in SIDES:
			var rail_x: float = x + side * (WIDTH * HALF - RAIL)
			canvas.draw_line(
				Vector2(rail_x, top), Vector2(rail_x, fundo), light.body(WOOD, x), RAIL
			)
		for y in range(int(top), int(fundo), RUNG):
			canvas.draw_line(
				Vector2(rect.position.x, y), Vector2(rect.end.x, y), light.body(WOOD, x), RAIL
			)


## Ate onde desce o poco: a boca com a terra por cima (`aberto` 0), o chao do subsolo
## com ela ida (1).
static func bottom(aberto: float) -> float:
	var top := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	return lerpf(top + BOCA, fundo, clampf(aberto, 0.0, 1.0))
