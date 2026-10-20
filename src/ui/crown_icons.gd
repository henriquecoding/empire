class_name CrownIcons
extends RefCounted

const SIZE := 12
const SCALE := 2.0

const PATTERNS := {
	&"build":
	[
		"............",
		".aa.aa.aa...",
		".aaaaaaaa...",
		".abbbbbba...",
		"..abbbba....",
		"..abbaba....",
		"..abbbba....",
		"..abbbba....",
		"..abbaaa....",
		"..abb..a....",
		".aaaa..aa...",
		"............"
	],
	&"recruit":
	[
		"............",
		"....aaa.....",
		"....aba.....",
		"....aaa.....",
		".aa..a..aa..",
		".aa.aaa.aa..",
		"..aaaaaaaa..",
		".aabbbbaaaa.",
		".aabbbbaa.a.",
		".a.a..a.a.a.",
		"...a..a.....",
		"............"
	],
	&"craft":
	[
		"............",
		"..aaaa......",
		"..abbba.....",
		"..aaaab.....",
		".....ab..a..",
		"..a...aba...",
		"..aa..ba....",
		"...abba.....",
		"...abba.....",
		"..ab..ba....",
		"..a....a....",
		"............"
	],
	&"crown":
	[
		"............",
		".....aa.....",
		".....ab.....",
		".aa..aa..aa.",
		".abaaaaaaba.",
		"..ababbaba..",
		"..ababbaba..",
		"..abbbbbba..",
		"..aaaaaaaa..",
		"..abbbbbba..",
		"..aaaaaaaa..",
		"............"
	],
	&"expedition":
	[
		"............",
		"..aaaaaaa...",
		"..abbbbbba..",
		"..abbbba....",
		"..abbbbbba..",
		"..aaaaaaa...",
		"..a.........",
		"..a....aa...",
		"..a...a..a..",
		"..a..a....a.",
		".aaaa.......",
		"............"
	],
	&"heir":
	[
		"............",
		".a.a.a......",
		".aaaaa......",
		".abbba......",
		".aaaaa......",
		".....aa.....",
		"......a.....",
		"......a.a.a.",
		"......aaaaa.",
		"......abbba.",
		"......aaaaa.",
		"............"
	],
	&"purse":
	[
		"............",
		"...abbbba...",
		"....abba....",
		"....aaaa....",
		"...abbbba...",
		"..abbbabbb..",
		"..abbbaabb..",
		"..abbababb..",
		"..abbbaabb..",
		"...abbbba...",
		"....aaaa....",
		"............"
	],
	&"sun":
	[
		".....aa.....",
		"..a..aa..a..",
		"...a....a...",
		"....aaaa....",
		"...abbbba...",
		"aa.abbbba.aa",
		"aa.abbbba.aa",
		"...abbbba...",
		"....aaaa....",
		"...a....a...",
		"..a..aa..a..",
		".....aa....."
	],
	&"pause":
	[
		"............",
		"............",
		"...aa..aa...",
		"...ab..ab...",
		"...ab..ab...",
		"...ab..ab...",
		"...ab..ab...",
		"...ab..ab...",
		"...aa..aa...",
		"............",
		"............",
		"............"
	],
}

static var _textures := {}


static func texture(id: StringName) -> Texture2D:
	if not _textures.has(id):
		var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		var rows: Array = PATTERNS.get(id, PATTERNS[&"crown"])
		for y in rows.size():
			for x in rows[y].length():
				var pixel: String = rows[y][x]
				if pixel != ".":
					image.set_pixel(x, y, Atlas.COIN if pixel == "a" else Color("f4dd9c"))
		_textures[id] = ImageTexture.create_from_image(image)
	return _textures[id]


static func draw(ci: CanvasItem, id: StringName, center: Vector2, zoom: float = SCALE) -> void:
	var extent := Vector2.ONE * SIZE * zoom
	ci.draw_texture_rect(texture(id), Rect2((center - extent / 2).round(), extent), false)
