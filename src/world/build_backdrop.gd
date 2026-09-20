class_name BuildBackdrop
extends Node2D

const REFRESH := 0.1
const BANDS := [Band.Kind.AERIAL, Band.Kind.SURFACE, Band.Kind.UNDERGROUND]
var _elapsed := 0.0
var _signature := ""
var _data: Dictionary
var _clock: ClockData
var _rot: RotProfile
var _light := Lighting.new()


func _ready() -> void:
	material = SpriteLighting.material()
	_data = SimFactory.by_id(&"buildings")
	_rot = SimFactory.rot_profile()
	_clock = Registry.entry(&"economy", &"clock") as ClockData


func _process(delta: float) -> void:
	if ClockService.clock == null or SimLoop.state == null:
		return
	var clock := ClockService.clock
	_light.set_phase(_clock, int(clock.current_phase()), clock.phase_progress())
	var rot := SimLoop.night.rot
	if rot != null and rot.active():
		_light.set_lamp(
			rot.position_x(),
			WorldLight.radius(_rot, SimLoop.state.day),
			WorldLight.stops(_rot)[WorldLight.PARAGENS - 1]
		)
	else:
		_light.clear_lamp()
	_elapsed += delta
	if _elapsed < REFRESH:
		return
	_elapsed = 0.0
	var stamp := str([_light.ambient.to_rgba32(), floorf(_light.lamp_x), _light.lamp_radius])
	stamp += str(PresentationBounds.of(self).position.floor())
	for slot in SimLoop.builds.slots:
		stamp += str([slot.id, slot.state, slot.level, slot.health, slot.paid])
	if stamp != _signature:
		_signature = stamp
		queue_redraw()


func _draw() -> void:
	for band in BANDS:
		BuildView.draw_on(self, band, _data, _light)
