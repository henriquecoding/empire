class_name BuildingSkins
extends RefCounted

## As obras com sprite: a mesma imagem, a mesma base e o mesmo sitio em todos os pontos do
## SiteStage, para que a obra se reconheca vazia, paga, a meio, de pe, tocada, em reparo e
## caida (planejamento 26/09, lote 3). A imagem e a arte do dono quando ela existe, e a
## pintada (PaintedArt, ADR 0051) quando nao. Os estados sao desenhados por codigo por
## cima do unico frame que cada uma tem — o que falta a arte esta em docs/art/RUNTIME_ART.md.

## §25: "a silhueta e o convite". O sitio por construir e a obra inteira, meio
## transparente, a respirar devagar — a 18% como estava, o dono via-o invisivel (ADR 0051).
const GHOST := {"min": 0.32, "max": 0.55, "rad_s": 2.4}
const RUIN_HEIGHT := 0.25
const RUIN_SHADE := 0.7
const MEIA := 0.5

## A arte do dono, por obra; as outras vao ao PaintedArt, e o que sobra vai pela forma.
const ORIGINAIS := {
	&"training_house": &"training_house",
	&"granary": &"storehouse",
	&"saltery": &"storehouse",
	&"pen": &"storehouse",
	&"kitchen": &"workshop",
	&"forge": &"workshop",
}
## Uma obra sem sprite proprio leva o da sua forma (Silhouette): a categoria do CSV.
const POR_FORMA := {
	Silhouette.Form.TORRE: &"archer_tower",
	Silhouette.Form.MASTRO: &"high_tower",
	Silhouette.Form.TELHADO: &"stable",
	Silhouette.Form.CHAMINE: &"furnace",
	Silhouette.Form.OFICINA: &"workshop",
	Silhouette.Form.ESTANDARTE: &"training_house",
	Silhouette.Form.ABOBADA: &"manor",
}

static var art := OriginalArt.new()
static var painted := PaintedArt.new()


## O sprite desta obra no nivel que o ecra mostra agora (o muro tem um por nivel).
static func profile(slot: BuildSlot, forma: Silhouette.Form) -> StringName:
	return profile_at(slot, forma, shown_level(slot))


static func profile_at(slot: BuildSlot, forma: Silhouette.Form, nivel: int) -> StringName:
	if slot.kind == BuildSlot.NUCLEO:
		return SeatSprites.profile(nivel)  # a sede pelo estagio dela (ADR 0059)
	if ORIGINAIS.has(slot.kind):
		return ORIGINAIS[slot.kind]
	var pintada := PaintedArt.profile(slot, nivel)
	return pintada if not pintada.is_empty() else POR_FORMA.get(forma, &"")


## O degrau que se ve: o de pe, o que se ergue, o que caiu; vazio promete
## a primeira construcao, nunca o Bastiao numa Clareira (ADR 0060).
static func shown_level(slot: BuildSlot) -> int:
	match slot.state:
		BuildSlot.State.EMPTY:
			if slot.kind == BuildSlot.NUCLEO and slot.level == RealmLadder.CLAREIRA:
				return RealmLadder.CLAREIRA
			# A Clareira promete o Acampamento, e nao a Fortaleza (ADR 0059).
			return 1
		BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING:
			return slot.level if slot.mending else slot.level + 1
	return maxi(1, slot.level)


static func box(skin: StringName, foot: Vector2) -> Rect2:
	return painted.box(skin, foot) if PaintedArt.has(skin) else art.box(skin, foot)


static func texture(skin: StringName) -> Texture2D:
	return PaintedArt.texture(skin) if PaintedArt.has(skin) else art.texture(skin)


static func draw_on(
	canvas: CanvasItem, slot: BuildSlot, forma: Silhouette.Form, light: Lighting, tempo: float
) -> bool:
	var skin := profile(slot, forma)
	if skin.is_empty():
		return false
	var foot := Vector2(slot.x, WorldPalette.ground_of(int(slot.band)))
	var caixa := box(skin, foot)
	var lit := light.body(Color.WHITE, slot.x)
	var trabalho := SiteMarks.working(slot, tempo)
	var stage := SiteStage.of(slot, trabalho)
	match stage:
		SiteStage.Stage.AVAILABLE:
			_draw(canvas, skin, foot, _ghost(lit, tempo))
		SiteStage.Stage.PAYING:
			_draw(canvas, skin, foot, Color(lit, lit.a * GHOST.max))
		SiteStage.Stage.WAITING, SiteStage.Stage.WORKING:
			# O que ja esta erguido e cheio; o resto e fantasma, debaixo do andaime. Num
			# muro a subir de degrau, o de baixo continua de pe dentro do andaime (D4).
			var erguido := SiteStage.built(slot)
			_draw(canvas, skin, foot, Color(lit, lit.a * GHOST.min))
			if slot.upgrading():
				_draw(canvas, profile_at(slot, forma, slot.level), foot, lit)
			_bottom(canvas, skin, caixa, erguido, lit)
			SiteMarks.scaffold(canvas, caixa, erguido, lit, tempo, trabalho)
		SiteStage.Stage.RUIN:
			_bottom(canvas, skin, caixa, RUIN_HEIGHT, Color(lit * RUIN_SHADE, lit.a))
		_:
			_draw(canvas, skin, foot, lit)
			if stage != SiteStage.Stage.OPERATING:
				SiteMarks.cracks(canvas, caixa, 1.0 - SiteStage.built(slot), lit)
			if stage == SiteStage.Stage.MENDING:
				SiteMarks.braces(canvas, caixa, SiteStage.built(slot), lit, tempo, trabalho)
	SiteMarks.coins(canvas, foot, slot.paid, SiteStage.cost_now(slot), lit)
	if SiteStage.operating(stage) and SimLoop.field != null:
		SiteMarks.emblem(canvas, caixa, SimLoop.field.conversion.status(slot), lit)
	if slot.standing():
		Gauge.health(canvas, caixa, float(slot.health) / maxf(1.0, slot.max_health()))
	return true


## O alfa do convite neste instante do ecra: respira entre GHOST.min e GHOST.max, e nunca
## apaga — o convite que desaparece metade do tempo perde-se metade do tempo (GB-23).
static func ghost_alpha(tempo: float) -> float:
	return lerpf(GHOST.min, GHOST.max, MEIA + MEIA * sin(tempo * GHOST.rad_s))


static func _ghost(lit: Color, tempo: float) -> Color:
	return Color(lit, lit.a * ghost_alpha(tempo))


static func _draw(canvas: CanvasItem, skin: StringName, foot: Vector2, cor: Color) -> void:
	if PaintedArt.has(skin):
		painted.draw_on(canvas, skin, foot, cor)
	else:
		art.draw_on(canvas, skin, foot, cor)


## A parte de baixo da imagem, `fraccao` da altura, no sitio dela: o que ja esta
## erguido de uma obra a meio, e o que resta de uma caida.
static func _bottom(
	canvas: CanvasItem, skin: StringName, caixa: Rect2, fraccao: float, cor: Color
) -> void:
	var alto := floorf(caixa.size.y * clampf(fraccao, 0.0, 1.0))
	if alto <= 0.0:
		return
	var tamanho := Vector2(caixa.size.x, alto)
	var fonte := Rect2(Vector2(0.0, caixa.size.y - alto), tamanho)
	canvas.draw_texture_rect_region(texture(skin), Rect2(caixa.end - tamanho, tamanho), fonte, cor)
