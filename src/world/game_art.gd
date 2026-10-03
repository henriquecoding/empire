# src/world/game_art.gd — a caca que a ADR 0057 trouxe, em pixeis: o faisao, a raposa,
# o javali e o cervo branco. Desenhados virados para a direita, como o coelho e o
# veado do HuntView; quem os desenha espelha-os para o lado para onde olham. Formas
# lisas de placeholder, registadas em docs/ASSETS_TODO.md.
class_name GameArt
extends RefCounted

const EYE := Color("241f18")
const PHEASANT := Color("8c4a2f")
const PHEASANT_NECK := Color("2f5a4a")
const PHEASANT_RED := Color("b0362c")
const PHEASANT_BODY := Rect2(-6, -8, 11, 5)
const PHEASANT_TAIL := Rect2(-14, -8, 9, 2)
const PHEASANT_NECK_RECT := Rect2(3, -12, 3, 5)
const PHEASANT_HEAD := Rect2(4, -14, 4, 3)
const PHEASANT_WATTLE := Rect2(6, -13, 2, 2)
const PHEASANT_LEGS := [Rect2(-2, -3, 1, 3), Rect2(1, -3, 1, 3)]
const PHEASANT_EYE := Vector2(6, -14)
const FOX := Color("c0662b")
const FOX_LIGHT := Color("e8d6bc")
const FOX_DARK := Color("3b2a1e")
const FOX_BODY := Rect2(-7, -9, 14, 5)
const FOX_HEAD := Rect2(6, -11, 6, 5)
const FOX_SNOUT := Rect2(11, -9, 3, 2)
const FOX_EARS := [Rect2(7, -14, 2, 3), Rect2(10, -14, 2, 3)]
const FOX_TAIL := Rect2(-15, -9, 9, 4)
const FOX_TAIL_TIP := Rect2(-16, -9, 3, 3)
const FOX_LEGS := [Rect2(-6, -4, 2, 4), Rect2(4, -4, 2, 4)]
const FOX_EYE := Vector2(10, -10)
const BOAR := Color("4a3a2e")
const BOAR_DARK := Color("2a211b")
const BOAR_TUSK := Color("e6dcc4")
const BOAR_BODY := Rect2(-13, -15, 24, 11)
const BOAR_MANE := Rect2(-10, -17, 16, 3)
const BOAR_HEAD := Rect2(8, -13, 7, 8)
const BOAR_SNOUT := Rect2(14, -10, 2, 4)
const BOAR_TUSKS := Rect2(13, -8, 3, 1)
const BOAR_LEGS := [Rect2(-11, -4, 3, 4), Rect2(-5, -4, 3, 4), Rect2(5, -4, 3, 4)]
const BOAR_EYE := Vector2(12, -11)
## O cervo branco: o veado do HuntView, branco e com hastes maiores (ADR 0057).
const STAG := Color("e8e4d8")
const STAG_SHADE := Color("a8a294")
const STAG_GOLD := Color("d9b65a")
const STAG_ANTLERS := [
	Rect2(10, -40, 1, 10), Rect2(14, -41, 1, 11), Rect2(7, -38, 4, 1), Rect2(14, -38, 4, 1)
]


## O bicho `id` em (0, 0) do canvas, ja posto no sitio e virado. Devolve se o desenhou.
static func draw(canvas: CanvasItem, id: StringName, light: Lighting, x: float) -> bool:
	match id:
		&"pheasant":
			_faisao(canvas, light, x)
		&"fox":
			_raposa(canvas, light, x)
		&"boar":
			_javali(canvas, light, x)
		&"white_stag":
			_cervo(canvas, light, x)
		_:
			return false
	return true


static func _faisao(canvas: CanvasItem, light: Lighting, x: float) -> void:
	for perna: Rect2 in PHEASANT_LEGS:
		canvas.draw_rect(perna, light.body(EYE, x))
	canvas.draw_rect(PHEASANT_TAIL, light.body(PHEASANT, x))
	canvas.draw_rect(PHEASANT_BODY, light.body(PHEASANT, x))
	canvas.draw_rect(PHEASANT_NECK_RECT, light.body(PHEASANT_NECK, x))
	canvas.draw_rect(PHEASANT_HEAD, light.body(PHEASANT_NECK, x))
	canvas.draw_rect(PHEASANT_WATTLE, light.body(PHEASANT_RED, x))
	canvas.draw_rect(Rect2(PHEASANT_EYE, Vector2.ONE), light.body(EYE, x))


static func _raposa(canvas: CanvasItem, light: Lighting, x: float) -> void:
	for perna: Rect2 in FOX_LEGS:
		canvas.draw_rect(perna, light.body(FOX_DARK, x))
	canvas.draw_rect(FOX_TAIL, light.body(FOX, x))
	canvas.draw_rect(FOX_TAIL_TIP, light.body(FOX_LIGHT, x))
	canvas.draw_rect(FOX_BODY, light.body(FOX, x))
	canvas.draw_rect(FOX_HEAD, light.body(FOX, x))
	canvas.draw_rect(FOX_SNOUT, light.body(FOX_LIGHT, x))
	for orelha: Rect2 in FOX_EARS:
		canvas.draw_rect(orelha, light.body(FOX_DARK, x))
	canvas.draw_rect(Rect2(FOX_EYE, Vector2.ONE), light.body(EYE, x))


static func _javali(canvas: CanvasItem, light: Lighting, x: float) -> void:
	for perna: Rect2 in BOAR_LEGS:
		canvas.draw_rect(perna, light.body(BOAR_DARK, x))
	canvas.draw_rect(BOAR_BODY, light.body(BOAR, x))
	canvas.draw_rect(BOAR_MANE, light.body(BOAR_DARK, x))
	canvas.draw_rect(BOAR_HEAD, light.body(BOAR, x))
	canvas.draw_rect(BOAR_SNOUT, light.body(BOAR_DARK, x))
	canvas.draw_rect(BOAR_TUSKS, light.body(BOAR_TUSK, x))
	canvas.draw_rect(Rect2(BOAR_EYE, Vector2.ONE), light.body(EYE, x))


static func _cervo(canvas: CanvasItem, light: Lighting, x: float) -> void:
	for perna: Rect2 in HuntView.DEER_LEGS:
		canvas.draw_rect(perna, light.body(STAG_SHADE, x))
	canvas.draw_rect(HuntView.DEER_BODY, light.body(STAG, x))
	canvas.draw_rect(HuntView.DEER_NECK, light.body(STAG, x))
	canvas.draw_rect(HuntView.DEER_HEAD, light.body(STAG, x))
	for haste: Rect2 in STAG_ANTLERS:
		canvas.draw_rect(haste, light.body(STAG_GOLD, x))
	canvas.draw_rect(Rect2(HuntView.DEER_EYE, Vector2.ONE), light.body(EYE, x))
