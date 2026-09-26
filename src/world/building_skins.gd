class_name BuildingSkins
extends RefCounted

## As obras com arte original: a mesma imagem, a mesma base e o mesmo sitio em
## todos os pontos do SiteStage, para que a obra se reconheca vazia, paga, a
## meio, de pe, tocada, em reparo e caida (planejamento 26/09, lote 3). Os
## estados sao desenhados por codigo por cima do unico frame que cada export tem
## — o que falta a arte esta em docs/art/RUNTIME_ART.md.

const GHOST_ALPHA := 0.18
const RUIN_HEIGHT := 0.25
const RUIN_SHADE := 0.7

static var art := OriginalArt.new()


static func profile(kind: StringName) -> StringName:
	match kind:
		BuildSlot.NUCLEO:
			return &"tree_castle"
		&"training_house":
			return &"training_house"
		&"granary", &"saltery", &"pen":
			return &"storehouse"
		&"kitchen", &"forge":
			return &"workshop"
	return &""


static func draw_on(canvas: CanvasItem, slot: BuildSlot, light: Lighting, tempo: float) -> bool:
	var skin := profile(slot.kind)
	if skin.is_empty():
		return false
	var foot := Vector2(slot.x, WorldPalette.ground_of(int(slot.band)))
	var box := art.box(skin, foot)
	var lit := light.body(Color.WHITE, slot.x)
	var trabalho := SiteMarks.working(slot, tempo)
	var stage := SiteStage.of(slot, trabalho)
	match stage:
		SiteStage.Stage.AVAILABLE, SiteStage.Stage.PAYING:
			art.draw_on(canvas, skin, foot, _ghost(lit))
		SiteStage.Stage.WAITING, SiteStage.Stage.WORKING:
			# O que ja esta erguido e cheio; o resto e fantasma, debaixo do andaime.
			var erguido := SiteStage.built(slot)
			art.draw_on(canvas, skin, foot, _ghost(lit))
			_bottom(canvas, skin, box, erguido, lit)
			SiteMarks.scaffold(canvas, box, erguido, lit, tempo, trabalho)
		SiteStage.Stage.RUIN:
			_bottom(canvas, skin, box, RUIN_HEIGHT, Color(lit * RUIN_SHADE, lit.a))
		_:
			art.draw_on(canvas, skin, foot, lit)
			if stage != SiteStage.Stage.OPERATING:
				SiteMarks.cracks(canvas, box, 1.0 - SiteStage.built(slot), lit)
			if stage == SiteStage.Stage.MENDING:
				SiteMarks.braces(canvas, box, SiteStage.built(slot), lit, tempo, trabalho)
	SiteMarks.coins(canvas, foot, slot.paid, SiteStage.cost_now(slot), lit)
	if SiteStage.operating(stage) and SimLoop.field != null:
		SiteMarks.emblem(canvas, box, SimLoop.field.conversion.status(slot), lit)
	if slot.standing():
		Gauge.health(canvas, box, float(slot.health) / maxf(1.0, slot.max_health()))
	return true


static func _ghost(lit: Color) -> Color:
	return Color(lit, lit.a * GHOST_ALPHA)


## A parte de baixo da imagem, `fraccao` da altura, no sitio dela: o que ja esta
## erguido de uma obra a meio, e o que resta de uma caida.
static func _bottom(
	canvas: CanvasItem, skin: StringName, box: Rect2, fraccao: float, cor: Color
) -> void:
	var alto := floorf(box.size.y * clampf(fraccao, 0.0, 1.0))
	if alto <= 0.0:
		return
	var tamanho := Vector2(box.size.x, alto)
	var fonte := Rect2(Vector2(0.0, box.size.y - alto), tamanho)
	canvas.draw_texture_rect_region(
		art.texture(skin), Rect2(box.end - tamanho, tamanho), fonte, cor
	)
