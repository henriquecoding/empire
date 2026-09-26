class_name UnitArtBatch
extends RefCounted

const HALF := 0.5
const STEP_SECONDS := 0.12
const HIT_SECONDS := 0.12
const HIT_TINT := Color(1.0, 0.82, 0.60)
const DEAD_ALPHA := 0.35
const SHADOW_HEIGHT := 6.0
const IDLE_SECONDS := 0.65
## O chapeu de quem e teu (§25, 0:20): pousa um pouco abaixo do topo da cabeca,
## e a escala e a da caixa de 48 px do ActorArt.
const HAT_DROP := 6.0
const HAT_SCALE := 48.0
const SHADOW_TEXTURE := preload("res://art/export/_placeholder/contact_shadow_18.png")

var _art := OriginalArt.new()
var _data: Dictionary = {}
var _previous: Dictionary = {}
var _health: Dictionary = {}
var _facing: Dictionary = {}
var _hit_until: Dictionary = {}
var _phase: Dictionary = {}


func draw_on(canvas: CanvasItem, band: Band.Kind, light: Lighting, time: float) -> void:
	if _data.is_empty():
		_data = SimFactory.by_id(&"units")
	var units := SimLoop.units
	var visible := PresentationBounds.of(canvas)
	var live: Dictionary = {}
	var draws: Array[Dictionary] = []
	for i in units.count():
		if units.bands[i] != int(band):
			continue
		var id := units.ids[i]
		live[id] = true
		if not _phase.has(id):
			_phase[id] = RngService.float_range(RngService.VISUAL, 0.0, IDLE_SECONDS)
		var x := Smoothing.x_of(Smoothing.Group.UNITS, id, units.xs[i])
		var old_x: float = _previous.get(id, x)
		var moving := not is_equal_approx(x, old_x)
		if moving:
			_facing[id] = signf(x - old_x)
		_previous[id] = x
		if units.healths[i] < int(_health.get(id, units.healths[i])):
			_hit_until[id] = time + HIT_SECONDS
		_health[id] = units.healths[i]
		if not visible.has_point(Vector2(x, visible.get_center().y)):
			continue
		var profile := OriginalArt.unit_profile(units.data_ids[i])
		var foot := Vector2(x, WorldPalette.ground_of(int(band)))
		if profile.is_empty():
			var data: UnitData = _data.get(units.data_ids[i])
			if data != null:
				var box := Silhouette.body_box(
					Silhouette.Form.CAIXA, x, int(band), WorldPalette.DEGRAU * data.scale_tier
				)
				ActorArt.draw_unit(
					canvas,
					box,
					data,
					units,
					i,
					light.body(WorldPalette.unit_color(units, i), x),
					time
				)
				TitleView.draw_on(canvas, box, id, light)
				if units.alive(i):
					Gauge.purse(canvas, box, units.carried_coins[i], units.coin_capacities[i])
			continue
		var bob := float(int(time / STEP_SECONDS) % 2) if moving else 0.0
		var color := light.body(Color.WHITE, x)
		if time < float(_hit_until.get(id, 0.0)):
			color = HIT_TINT
		if not units.alive(i):
			color.a = DEAD_ALPHA
			bob = 0.0
		draws.append(
			{"profile": profile, "foot": foot, "bob": bob, "color": color, "id": id, "i": i}
		)
	# Two passes keep the shared shadow texture and actor atlas batchable.
	for item in draws:
		var width := float(_art.entry(item.profile).size[0]) * HALF
		var rect := Rect2(
			item.foot - Vector2(width * HALF, SHADOW_HEIGHT * HALF), Vector2(width, SHADOW_HEIGHT)
		)
		canvas.draw_texture_rect(SHADOW_TEXTURE, rect, false, WorldPalette.SOMBRA)
	for item in draws:
		_art.draw_on(
			canvas,
			item.profile,
			item.foot - Vector2(0.0, item.bob),
			item.color,
			time + float(_phase[item.id]),
			_facing.get(item.id, 1.0)
		)
	for item in draws:
		var i: int = item.i
		var dados: UnitData = _data.get(units.data_ids[i])
		var arma: bool = dados != null and dados.weapon_kind != &"" and item.profile == &"vagrant"
		if units.alive(i) and arma:
			ActorArt.draw_weapon(
				canvas,
				_art.body_box(item.profile, item.foot - Vector2(0.0, item.bob)),
				_data[units.data_ids[i]],
				units,
				i,
				light.body(ActorArt.WOOD_LIGHT, item.foot.x),
				_facing.get(item.id, 1.0)
			)
		if units.alive(i):
			var box := _art.body_box(item.profile, item.foot)
			if item.profile == &"vagrant":
				var cabeca := Vector2(box.get_center().x, box.position.y + HAT_DROP)
				ActorArt.draw_hat(canvas, cabeca, box, units, i, box.size.y / HAT_SCALE)
			TitleView.draw_on(canvas, box, item.id, light)
			Gauge.purse(canvas, box, units.carried_coins[i], units.coin_capacities[i])
			Gauge.health(
				canvas,
				_art.box(item.profile, item.foot),
				float(units.healths[i]) / units.max_healths[i]
			)
	for id in _previous.keys():
		if not live.has(id):
			_previous.erase(id)
			_health.erase(id)
			_facing.erase(id)
			_hit_until.erase(id)
			_phase.erase(id)
