class_name CombatInput
extends Node

static var facing := 1.0
static var cursor_aim := false
static var device := Glyphs.Device.KEYBOARD

var _skill_held := false
var _attack_held := false
var _release := false


func _ready() -> void:
	EventBus.game_paused.connect(_paused)
	facing = 1.0
	cursor_aim = false
	device = Glyphs.initial()


func _paused(_value: bool) -> void:
	_release = true
	_skill_held = false
	_attack_held = false


func _unhandled_input(event: InputEvent) -> void:
	# O clique que o motor faz de cada toque tem o botao esquerdo, que e o attack: sem
	# isto, cada toque no ecra de um telemovel era um golpe (ADR 0047).
	if blocked() or _release or event.is_echo() or Glyphs.emulated(event):
		return
	if event.is_action(&"attack"):
		var held := event.is_action_pressed(&"attack")
		if held and not _attack_held:
			cursor_aim = event is InputEventMouseButton
			queue_attack(aim_direction())
		_attack_held = held
		get_viewport().set_input_as_handled()
	elif event.is_action(&"mark_target"):
		var held := event.is_action_pressed(&"mark_target")
		if held and not _skill_held:
			cursor_aim = event is InputEventMouseButton
			queue_skill(aim_x())
		_skill_held = held
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	var name := ""
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		name = Input.get_joy_name(event.device)
	device = Glyphs.device_of(event, device, name)


func _process(_delta: float) -> void:
	if _release:
		if not Input.is_action_pressed(&"attack") and not Input.is_action_pressed(&"mark_target"):
			_release = false
		return
	if blocked():
		_release = _attack_held or _skill_held
		return
	var move := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(move):
		facing = signf(move)
	if _attack_held and not Input.is_action_pressed(&"attack"):
		_attack_held = false
	# Holding is still a deliberate attack command, with the CSV weapon cadence.
	if _attack_held:
		var who := Assume.driven()
		var i := SimLoop.units.index_of(who)
		var manual := SimLoop.combat.manual
		var stats := manual.profile(SimLoop.units, who)
		if i >= 0 and not stats.is_empty() and not manual.pending(who):
			if SimLoop.units.cooldowns[i] <= float(stats[&"buffer"]):
				queue_attack(aim_direction())


static func blocked() -> bool:
	return (
		ClassSelection.active
		or TravelPanel.active
		or SiteSheet.active
		or not SimLoop.running()
		or Input.is_action_pressed(&"king_wheel")
	)


static func aim_direction() -> float:
	if not cursor_aim or SimLoop.units == null:
		return facing
	var i := SimLoop.units.index_of(Assume.driven())
	var camera := SimLoop.get_viewport().get_camera_2d()
	if i < 0 or camera == null:
		return facing
	var delta := camera.get_global_mouse_position().x - SimLoop.units.xs[i]
	return facing if is_zero_approx(delta) else signf(delta)


static func aim_x() -> float:
	var units := SimLoop.units
	var i := units.index_of(Assume.driven())
	if i < 0:
		return SimLoop.core_x
	var camera := SimLoop.get_viewport().get_camera_2d()
	if cursor_aim and camera != null:
		return camera.get_global_mouse_position().x
	var body := Registry.entry(&"units", units.data_ids[i]) as UnitData
	if Assume.king() and MonarchWatch.skill() == MonarchWatch.CANTO:  # canta o Bardo da Nia
		body = Registry.entry(&"units", MonarchWatch.data().companion) as UnitData
		var b := SimLoop.field.monarchy.companion_index(units, SimLoop.king_id)
		i = b if b >= 0 else i  # o alcance e a faixa sao os dele, de onde ele esta
	var radius := float(body.ability_params.get(&"radius", body.range_px))
	var best := -1
	var gap := radius
	for id in TargetPicker.ids_por_ordem(SimLoop.creatures.ids):
		var c := SimLoop.creatures.index_of(id)
		if not SimLoop.creatures.alive(c):
			continue
		if SimLoop.creatures.bands[c] != units.bands[i] or SimLoop.field.song.allies.has(id):
			continue
		var distance := (SimLoop.creatures.xs[c] - units.xs[i]) * facing
		if distance >= 0.0 and distance <= gap:
			best = c
			gap = distance
	return SimLoop.creatures.xs[best] if best >= 0 else units.xs[i] + facing * radius


static func queue_attack(direction: float) -> void:
	if blocked():
		return
	SimLoop.intents.queue(
		IntentQueue.Kind.ATTACK, {&"who": Assume.driven(), &"direction": direction}
	)


## A habilidade depende do perfil (ADR 0052): o Rei decreta a Vigilia, a Nia manda cantar
## o Bardo dela e o Imperador Arqueiro marca. O decreto e da coroa; o resto e intencao.
static func queue_skill(x: float) -> void:
	if blocked():
		return
	if Assume.king() and MonarchWatch.skill() == &"vigil":
		var refusal := InputRouter.impulse_refusal(&"vigil")
		if refusal.is_empty():
			SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": &"vigil"})
		else:
			SimLoop.get_tree().call_group(&"painel", &"say", refusal)
		return
	SimLoop.intents.queue(IntentQueue.Kind.MARK_TARGET, {&"who": Assume.driven(), &"x": x})
