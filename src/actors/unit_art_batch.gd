class_name UnitArtBatch
extends RefCounted

const HALF := 0.5
const STEP_SECONDS := 0.12
const HIT_SECONDS := 0.12
const HIT_TINT := Color(1.0, 0.82, 0.60)
const SHADOW_HEIGHT := 6.0
const IDLE_SECONDS := 0.65
## O chapeu de quem e teu (§25, 0:20): pousa um pouco abaixo do topo da cabeca,
## e a escala e a da caixa de 48 px do ActorArt.
const HAT_DROP := 6.0
const HAT_SCALE := 48.0
const SHADOW_TEXTURE := preload("res://art/export/_placeholder/contact_shadow_18.png")

## Os flashes deste frame, para a camada branca do UnitCanvas os pintar com a
## forma do sprite (§24): [perfil, frame, pose, alfa].
var flashes: Array[Array] = []

var _art := OriginalArt.new()
var _fallen := FallenArt.new()
var _data: Dictionary = {}
var _previous: Dictionary = {}
var _health: Dictionary = {}
var _facing: Dictionary = {}
var _hit_until: Dictionary = {}
var _phase: Dictionary = {}
## A accao que cada unidade mostra, e desde quando: uma accao nova comeca no seu
## primeiro frame (a preparacao de um golpe nao entra a meio).
var _action: Dictionary = {}
var _since: Dictionary = {}


func draw_on(canvas: CanvasItem, band: Band.Kind, light: Lighting, time: float) -> void:
	if _data.is_empty():
		_data = SimFactory.by_id(&"units")
	flashes.clear()
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
		if id == Assume.driven():
			_facing[id] = CombatInput.aim_direction()
		if CombatView.attacks.has(id):
			_facing[id] = CombatView.attacks[id][&"direction"]
		_previous[id] = x
		if units.healths[i] < int(_health.get(id, units.healths[i])):
			_hit_until[id] = time + HIT_SECONDS
		_health[id] = units.healths[i]
		var data: UnitData = _data.get(units.data_ids[i])
		var estilo := StrikePose.of_unit(data)
		CombatFx.observe(id, units.cooldowns[i], estilo)
		var luta := units.states[i] == UnitFsm.State.FIGHT
		var manual := id == Assume.driven() or CombatView.attacks.has(id)
		if luta and not manual:  # quem se conduz aponta com a mira (ADR 0045)
			_facing[id] = CombatFx.facing(id, x, _facing.get(id, 1.0))
		var facing: float = _facing.get(id, 1.0)
		var falta := units.cooldowns[i] if luta else INF
		var pose := CombatFx.body(id, estilo, falta, facing)
		if not visible.has_point(Vector2(x, visible.get_center().y)):
			continue
		var profile := OriginalArt.unit_profile(units.data_ids[i])
		# Sem a animacao `die`, quem cai roda para o chao; com ela, e ela que cai.
		var morto := not units.alive(i) and not _art.has_action(profile, &"die")
		var angle := CombatFx.fall(id) if morto else 0.0
		var foot := Vector2(x + pose.x, WorldPalette.ground_of(int(band)))
		if profile.is_empty():
			_procedural(canvas, data, {"i": i, "foot": foot, "pose": pose}, light, time)
			continue
		var hit := time < float(_hit_until.get(id, 0.0))
		var kind := ActorAction.of(units.states[i] as UnitFsm.State, moving, hit)
		if units.alive(i) and not hit and CombatView.attacks.has(id):
			kind = ActorAction.Kind.ATTACK
		# A animacao `attack` acompanha o golpe da simulacao (CombatFx), e entre
		# dois golpes o corpo descansa: e o ritmo que diz quando vem o proximo.
		var golpe := CombatFx.attack_frame(_art, profile, id, falta)
		if kind == ActorAction.Kind.ATTACK and golpe < 0 and not CombatView.attacks.has(id):
			kind = ActorAction.Kind.WALK if moving else ActorAction.Kind.IDLE
		var shown := ActorAction.shown(_art, profile, kind)
		var frame := _frame(id, profile, kind, shown, time)
		if kind == ActorAction.Kind.ATTACK and golpe >= 0:
			frame = golpe
		# Sem ciclo de caminhada desenhado, o baloico de um pixel e o que diz que
		# anda; com ele, e a arte que o diz.
		var animated := shown in [ActorAction.Kind.WALK, ActorAction.Kind.FLEE]
		var bob := float(int(time / STEP_SECONDS) % 2) if moving and not animated else 0.0
		var color := light.on(x)  # a luz pura: a silhueta e do SpriteLighting (ADR 0048)
		if hit:
			color = HIT_TINT
		if not units.alive(i):
			color.a = FallenArt.DEAD_ALPHA
			bob = 0.0
			var corpo := {"profile": profile, "foot": foot, "frame": frame, "band": int(band)}
			corpo["angle"] = angle
			_fallen.keep(id, corpo)
		var escala := Vector2(pose.y, pose.z)
		var posed := OriginalArt.posed(foot - Vector2(0.0, bob), facing, escala, angle)
		var branco := CombatFx.flash(id)
		if branco > 0.0:
			flashes.append([profile, frame, posed, branco])
		(
			draws
			. append(
				{
					"profile": profile,
					"foot": foot,
					"bob": bob,
					"color": color,
					"id": id,
					"i": i,
					"frame": frame,
					"pose": pose,
					"posed": posed,
					"style": estilo,
				}
			)
		)
	# Two passes keep the shared shadow texture and actor atlas batchable.
	for item in draws:
		var width := _art.body_box(item.profile, Vector2.ZERO).size.x * HALF
		var rect := Rect2(
			item.foot - Vector2(width * HALF, SHADOW_HEIGHT * HALF), Vector2(width, SHADOW_HEIGHT)
		)
		canvas.draw_texture_rect(SHADOW_TEXTURE, rect, false, WorldPalette.SOMBRA)
	for item in draws:
		_art.draw_posed(canvas, item.profile, item.color, item.frame, item.posed)
	for item in draws:
		var i: int = item.i
		if not units.alive(i):
			continue
		var dados: UnitData = _data.get(units.data_ids[i])
		var box := _art.body_box(item.profile, item.foot - Vector2(0.0, item.bob))
		if (
			dados != null
			and dados.weapon_kind != &""
			and item.profile in [&"vagrant", &"royal_citizen"]
		):
			_weapon(canvas, box, dados, item, light)
		box = _art.body_box(item.profile, item.foot)
		if item.profile in [&"vagrant", &"royal_citizen"]:
			var cabeca := Vector2(box.get_center().x, box.position.y + HAT_DROP)
			ActorArt.draw_hat(canvas, cabeca, box, units, i, box.size.y / HAT_SCALE)
		TitleView.draw_on(canvas, box, item.id, light)
		_saco(canvas, box, units, i)
		Gauge.health(canvas, box, float(units.healths[i]) / units.max_healths[i])
	_fallen.draw(canvas, band, live, time)
	for id in _previous.keys():
		if not live.has(id):
			for memoria in [_previous, _health, _facing, _hit_until, _phase, _action, _since]:
				memoria.erase(id)
			CombatFx.forget(id)


## A arma de quem a tem na mao, a rodar em volta da mao com o golpe (StrikePose):
## sobe para tras a armar e passa para a frente a bater. O arqueiro nao roda o
## arco: puxa a corda, e a flecha ve-se encostada antes de sair.
func _weapon(
	canvas: CanvasItem, box: Rect2, dados: UnitData, item: Dictionary, light: Lighting
) -> void:
	var units := SimLoop.units
	var i: int = item.i
	var lado: float = _facing.get(item.id, 1.0)
	var mao := Vector2(
		box.get_center().x + lado * box.size.x * ActorArt.MAO.x,
		box.position.y + box.size.y * ActorArt.MAO.y
	)
	var pose: Vector4 = item.pose
	canvas.draw_set_transform_matrix(Transform2D(lado * pose.w, mao) * Transform2D(0.0, -mao))
	var cor := light.body(ActorArt.WOOD_LIGHT, item.foot.x)
	ActorArt.draw_weapon(canvas, box, dados, units, i, cor, lado)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	if item.style != StrikePose.Style.RANGED or units.states[i] != UnitFsm.State.FIGHT:
		return
	var falta := units.cooldowns[i]
	if StrikePose.phase(CombatFx.since_attack(item.id), falta) == StrikePose.Phase.WINDUP:
		Volley.draw_nocked(canvas, mao, lado, 1.0 - falta / StrikePose.WINDUP_S)


## Uma tropa sem arte original (ActorArt), com a mesma pose, em volta dos pes.
func _procedural(
	canvas: CanvasItem, data: UnitData, item: Dictionary, light: Lighting, time: float
) -> void:
	if data == null:
		return
	var units := SimLoop.units
	var i: int = item.i
	var foot: Vector2 = item.foot
	var pose: Vector4 = item.pose
	var box := Silhouette.body_box(
		Silhouette.Form.CAIXA, foot.x, int(units.bands[i]), WorldPalette.DEGRAU * data.scale_tier
	)
	# Sem rotacao de queda: o ActorArt ja desenha quem caiu deitado (§16).
	canvas.draw_set_transform_matrix(
		Transform2D(0.0, Vector2(pose.y, pose.z), 0.0, foot) * Transform2D(0.0, -foot)
	)
	var cor := light.body(WorldPalette.unit_color(units, i), foot.x)
	ActorArt.draw_unit(canvas, box, data, units, i, cor, time)
	if data.tags.has(&"bard"):
		BardArt.draw_on(canvas, box, float(SimLoop.field.song.cooldowns.get(units.ids[i], 0.0)))
		if data.tags.has(&"companion"):
			BardArt.banner(canvas, box)  # o Bardo da Nia leva a bandeira (ADR 0052)
	var branco := CombatFx.flash(units.ids[i])
	if branco > 0.0:
		canvas.draw_rect(box, Color(WorldPalette.FLASH, WorldPalette.FLASH.a * branco))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	TitleView.draw_on(canvas, box, units.ids[i], light)
	if units.alive(i):
		_saco(canvas, box, units, i)


## O frame que a unidade mostra: o da accao que a arte tem, contado desde que a
## accao comecou. O repouso leva a fase propria de cada unidade, para que um
## grupo parado nao respire em unissono.
func _frame(
	id: int, profile: StringName, kind: ActorAction.Kind, shown: ActorAction.Kind, time: float
) -> int:
	if _action.get(id, -1) != kind:
		_action[id] = kind
		_since[id] = time
	var elapsed := time - float(_since[id])
	if shown == ActorAction.Kind.IDLE:
		elapsed = time + float(_phase[id])
	return _art.frame_at(profile, elapsed, ActorAction.TAGS[shown], ActorAction.loops(shown))


## O saco de cada um; o do escudeiro e o escudo, que e o que ele guarda (Q-114); o
## rei traz, alem dele, o armazenamento de quem se joga (Q-153).
func _saco(canvas: CanvasItem, box: Rect2, units: UnitSystem, i: int) -> void:
	if SimLoop.field != null and units.ids[i] in [SimLoop.king_id, units.pilot]:
		var armazem := Assume.storage(units, units.ids[i], SimLoop.field)
		Gauge.kit(canvas, box, armazem.count(Storage.ARCHOTE))
	var escudeiro := SimLoop.field.classes.squire if SimLoop.field != null else null
	var dados: UnitData = _data.get(units.data_ids[i])
	if escudeiro != null and dados != null and dados.tags.has(&"collects_coins"):
		Gauge.purse(canvas, box, escudeiro.shield, escudeiro.shield_cap())
		return
	Gauge.purse(canvas, box, units.carried_coins[i], units.coin_capacities[i])
