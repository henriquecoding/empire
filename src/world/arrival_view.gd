class_name ArrivalView
extends RefCounted

const GOLD := Color("e3c877")
const ROOT := Color("312b36")
const LEAF := Color("769b86")
## Geometria provisoria dos marcos, em pixels; nunca altera as regras da simulacao.
const SCAR_LABEL := Vector2(-128, -64)
const ROOT_COUNT := 5
const ROOT_STEP := Vector2(10, 0)
const ROOT_START := Vector2(-20, 0)
const ROOT_TIP := Vector2(-8, -12)
const ROOT_BRANCH := [Vector2(-4, -6), Vector2(7, -10)]
const STROKE := 3.0
const THIN := 2.0
const SUPPLIES := Rect2(-18, -25, 36, 22)
const SUPPLIES_ROPE := [Vector2(-18, -23), Vector2(18, -5)]
const SUPPLIES_LABEL := Vector2(-17, -36)
const LOSS_LABEL := Vector2(-24, -25)
const CLOSED_CART := Rect2(-28, -49, 56, 27)
const CART_ROPE := [Vector2(-28, -47), Vector2(28, -24)]
const OPEN_CART := Rect2(-21, -44, 42, 9)
const FLAG_TOP := -88.0
const FOUNDED_TOP := -118.0
const WAVE := 2.0
const CLOTH := [Vector2(32, 4), Vector2(26, 28), Vector2(0, 25)]
const EMBLEM := Vector2(13, 13)
const EMBLEM_RADIUS := 5.0
const EMBLEM_STEM := [Vector2(13, 18), Vector2(18, 23)]
const FLAG_LABEL := Vector2(-45, -15)
const DAWN_RIBBON := [Vector2(0, 36), Vector2(28, 40)]
const POST_TOP := Vector2(0, -56)
const SHIELD := [
	Vector2(-16, -44), Vector2(16, -44), Vector2(12, -20), Vector2(0, -12), Vector2(-12, -20)
]
const SHIELD_MARK := [Vector2(0, -40), Vector2(0, -19)]
const CHEST := Rect2(-18, -25, 36, 25)
const CHEST_LID := Rect2(-20, -28, 40, 8)
const CHEST_LOCK := Rect2(-3, -21, 6, 8)
const FONT_PX := 13


static func draw(canvas: CanvasItem, band: int, light: Lighting, time: float) -> void:
	if band == Band.Kind.UNDERGROUND:
		_chests(canvas, light)
		return
	if band != Band.Kind.SURFACE or not SimLoop.arrival.active:
		return
	var o := SimLoop.arrival
	var ground := WorldPalette.ground_of(band)
	var trees := SimLoop.night.amargueiros
	for k in trees.count():
		if trees.fates[k] == AmargueiroSystem.Fate.OLD:
			_label(canvas, Vector2(trees.xs[k], ground) + SCAR_LABEL, &"ARRIVAL_OLD_SCAR")
	if o.choice != &"":
		_flag(canvas, Vector2(SimLoop.core_x, ground), o.choice, time, light, true)
	var foot := Vector2(o.cache_x, ground)
	var color := ROOT if o.scar or o.tainted else LEAF
	for k in ROOT_COUNT:
		var p := foot + ROOT_START + ROOT_STEP * k
		canvas.draw_line(p, p + ROOT_TIP, light.body(color, p.x), STROKE)
		canvas.draw_line(p + ROOT_BRANCH[0], p + ROOT_BRANCH[1], light.body(color, p.x), THIN)
	if o.cache_coins > 0:
		canvas.draw_rect(
			Rect2(foot + SUPPLIES.position, SUPPLIES.size), light.body(Color("80664b"), foot.x)
		)
		canvas.draw_line(
			foot + SUPPLIES_ROPE[0], foot + SUPPLIES_ROPE[1], light.body(color, foot.x), STROKE
		)
		_label(canvas, foot + SUPPLIES_LABEL, &"ARRIVAL_SUPPLIES")
	elif o.scar:
		_label(canvas, foot + LOSS_LABEL, &"ARRIVAL_SCAR_LABEL")
	var cart := Vector2(SimLoop.seat.cart_x, ground)
	if not SimLoop.seat.cart_open:
		canvas.draw_rect(
			Rect2(cart + CLOSED_CART.position, CLOSED_CART.size),
			light.body(Color("645851"), cart.x)
		)
		canvas.draw_line(cart + CART_ROPE[0], cart + CART_ROPE[1], light.body(GOLD, cart.x), STROKE)
	else:
		canvas.draw_rect(Rect2(cart + OPEN_CART.position, OPEN_CART.size), light.body(LEAF, cart.x))
	_companion(canvas, ground, light)


static func _flag(
	canvas: CanvasItem,
	foot: Vector2,
	id: StringName,
	time: float,
	light: Lighting,
	founded := false
) -> void:
	var top := foot + Vector2(0, FOUNDED_TOP if founded else FLAG_TOP)
	var gold := light.body(GOLD, foot.x)
	canvas.draw_line(foot, top, gold, STROKE)
	var wave := Vector2(0, sin(time * WAVE) * WAVE)
	var cloth := PackedVector2Array(
		[top, top + CLOTH[0] + wave, top + CLOTH[1] + wave, top + CLOTH[2]]
	)
	canvas.draw_colored_polygon(
		cloth, light.body(LEAF if id == &"grove" else Color("8b788f"), foot.x)
	)
	canvas.draw_circle(top + EMBLEM, EMBLEM_RADIUS, gold, false, THIN)
	canvas.draw_line(top + EMBLEM_STEM[0], top + EMBLEM_STEM[1], gold, THIN)
	if not founded:
		_label(canvas, top + FLAG_LABEL, &"ARRIVAL_FLAG_" + String(id).to_upper())
	elif SimLoop.arrival.survived:
		canvas.draw_line(top + DAWN_RIBBON[0], top + DAWN_RIBBON[1], gold, STROKE)


static func _companion(canvas: CanvasItem, ground: float, light: Lighting) -> void:
	var post := CompanionWatch.site()
	if post == null or not post.standing():
		return
	var foot := Vector2(post.x, ground)
	canvas.draw_line(foot, foot + POST_TOP, light.body(GOLD, foot.x), STROKE)
	var shield := PackedVector2Array()
	for point: Vector2 in SHIELD:
		shield.append(foot + point)
	canvas.draw_colored_polygon(shield, light.body(LEAF, foot.x))
	canvas.draw_line(foot + SHIELD_MARK[0], foot + SHIELD_MARK[1], light.body(GOLD, foot.x), THIN)


static func _chests(canvas: CanvasItem, light: Lighting) -> void:
	var under := SimLoop.field.under
	var ground := WorldPalette.ground_of(Band.Kind.UNDERGROUND)
	for k in under.count():
		var x := UnderReserve.chest_x(under, k)
		if under.kind_of(k) != UndergroundSites.HATCH or not under.generated(k) or is_nan(x):
			continue
		var foot := Vector2(x, ground)  # na baia, e nao na boca: outro alvo (SUB-12)
		canvas.draw_rect(
			Rect2(foot + CHEST.position, CHEST.size), light.body(Color("81694b"), foot.x)
		)
		canvas.draw_rect(Rect2(foot + CHEST_LID.position, CHEST_LID.size), light.body(GOLD, foot.x))
		canvas.draw_rect(
			Rect2(foot + CHEST_LOCK.position, CHEST_LOCK.size), light.body(ROOT, foot.x)
		)


static func _label(canvas: CanvasItem, at: Vector2, key: StringName) -> void:
	canvas.draw_string(
		ThemeDB.fallback_font,
		at,
		TranslationServer.translate(key),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_PX,
		GOLD
	)
