class_name RenewalTrees
extends RefCounted

const CROWNS := {
	&"round": &"royal_tree_oak",
	&"cone": &"royal_pine",
	&"droop": &"royal_tree_willow",
	&"low": &"royal_tree_coast_pine",
	&"roots": &"royal_tree_roots",
}
const AUTUMN := Color("dfa268")
const MIRROR := -1.0
## Onde a copa acaba e o tronco comeca, na altura do sprite: o vento so mexe a copa.
const CROWN_SHARE := 0.72
## A fita da arvore marcada para corte, a contar do pe.
const RIBBON := Rect2(-7.0, -24.0, 14.0, 4.0)
static var _art := OriginalArt.new()


static func draw(
	canvas: CanvasItem,
	foot: Vector2,
	species: FloraData,
	state: int,
	season: int,
	time: float,
	id: int,
	light: Lighting
) -> void:
	var profile: StringName = CROWNS.get(species.crown, &"royal_tree_oak")
	if TreeArt.bare(species, season):
		profile = StringName(String(profile) + "_bare")
	var factor := TreeArt.height(species) / _art.body_box(profile, Vector2.ZERO).size.y
	var facing := 1.0 if id % 2 == 0 else MIRROR
	var tint := light.on(foot.x)
	if season == Seasons.AUTUMN and not species.evergreen:
		tint *= AUTUMN
	var texture := _art.texture(profile)
	var whole := _art.box(profile, Vector2.ZERO)
	var split := floorf(whole.size.y * CROWN_SHARE)
	var wind := roundf(sin(time * TreeArt.VENTO.rad_s + id * TreeArt.VENTO.fase))
	canvas.draw_set_transform_matrix(OriginalArt.posed(foot, facing, Vector2.ONE * factor))
	var crown := Rect2(whole.position + Vector2(wind, 0.0), Vector2(whole.size.x, split))
	canvas.draw_texture_rect_region(texture, crown, Rect2(Vector2.ZERO, crown.size), tint)
	var trunk := Rect2(whole.position + Vector2(0.0, split), whole.size - crown.size * Vector2.DOWN)
	canvas.draw_texture_rect_region(texture, trunk, Rect2(Vector2(0.0, split), trunk.size), tint)
	canvas.draw_set_transform(Vector2.ZERO)
	if state == Woodland.State.MARKED:
		var ribbon := Rect2(foot + RIBBON.position, RIBBON.size)
		canvas.draw_rect(ribbon, light.body(TreeArt.FITA, foot.x))
