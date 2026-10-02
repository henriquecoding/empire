class_name TemporaryScenery
extends RefCounted

const PROPS := {
	&"granary": [[&"temp_crate", -36.0], [&"temp_plant", 40.0]],
	&"saltery": [[&"temp_crate", -38.0], [&"temp_stone", 36.0]],
	&"pen": [[&"temp_fence", -40.0], [&"temp_fence", 40.0]],
	&"forge": [[&"temp_stone", -40.0], [&"temp_lever", 38.0]],
	&"kitchen": [[&"temp_mushroom", -38.0], [&"temp_crate", 40.0]],
	&"training_house": [[&"temp_flag", -42.0], [&"temp_sign", 40.0]],
	&"sawmill": [[&"temp_wood", -38.0], [&"temp_lever", 34.0]],
	&"quarry": [[&"temp_stone", -32.0], [&"temp_crate", 32.0]],
	&"mine": [[&"temp_stone", -32.0], [&"temp_sign", 34.0]],
	&"market": [[&"temp_crate", -34.0], [&"temp_flag", 34.0]],
	&"stables": [[&"temp_fence", -36.0], [&"temp_wood", 36.0]],
}
const GHOST_ALPHA := 0.18

static var _art := OriginalArt.new()


## Usa o parallax e os limites do plano existente; nunca desloca sitios de jogo.
static func forest(canvas: CanvasItem, extent: Vector2, profile: StringName, bottom: float) -> void:
	var texture := _art.texture(profile)
	var size := texture.get_size()
	var start := floori(extent.x / size.x) * size.x
	for x in range(int(start), ceili(extent.y), int(size.x)):
		canvas.draw_texture_rect(texture, Rect2(Vector2(x, bottom - size.y), size), false)


## A superficie da fila fica na linha de chao, por baixo dos pes dos actores.
static func ground(
	canvas: CanvasItem, start: float, width: float, y: float, underground: bool = false
) -> void:
	var profile := &"temp_cave" if underground else &"temp_soil"
	var texture := _art.texture(profile)
	var size := texture.get_size()
	for x in range(int(start), ceili(start + width), int(size.x)):
		canvas.draw_texture_rect(texture, Rect2(Vector2(x, y), size), false)


static func building_props(
	canvas: CanvasItem, site: BuildSlot, light: Lighting, time: float
) -> void:
	if not PROPS.has(site.kind) or site.state == BuildSlot.State.RUIN:
		return
	var stage := SiteStage.of(site, SiteMarks.working(site, time))
	var tint := light.body(Color.WHITE, site.x)
	if stage in [SiteStage.Stage.AVAILABLE, SiteStage.Stage.PAYING]:
		tint.a *= GHOST_ALPHA
	elif stage in [SiteStage.Stage.WAITING, SiteStage.Stage.WORKING]:
		tint.a *= maxf(GHOST_ALPHA, SiteStage.built(site))
	var foot := Vector2(site.x, WorldPalette.ground_of(int(site.band)))
	for prop: Array in PROPS[site.kind]:
		_art.draw_on(canvas, prop[0], foot + Vector2(prop[1], 0.0), tint)
