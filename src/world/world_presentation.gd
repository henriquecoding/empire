class_name WorldPresentation
extends Node

const AFTER_SIM := 100
static var active: WorldPresentation

var units := VisualMotion.new()
var creatures := VisualMotion.new()
var _world: GameState


func _ready() -> void:
	active = self
	process_physics_priority = AFTER_SIM


func _exit_tree() -> void:
	if active == self:
		active = null


func _physics_process(_delta: float) -> void:
	if SimLoop.state == null or not SimLoop.running():
		return
	if _world != SimLoop.state:
		units = VisualMotion.new()
		creatures = VisualMotion.new()
		_world = SimLoop.state
	var u := SimLoop.units
	units.capture(Array(u.ids), Array(u.xs), Array(u.bands), _world.tick)
	var c := SimLoop.creatures
	creatures.capture(Array(c.ids), Array(c.xs), Array(c.bands), _world.tick)


static func unit_x(i: int) -> float:
	return _sample(SimLoop.units.ids[i], SimLoop.units.xs[i], false)


static func creature_x(i: int) -> float:
	return _sample(SimLoop.creatures.ids[i], SimLoop.creatures.xs[i], true)


static func _sample(id: int, fallback: float, creature: bool) -> float:
	if active == null or active._world != SimLoop.state:
		return fallback
	var track := active.creatures if creature else active.units
	if not track.has(id):
		return fallback
	var fraction := Engine.get_physics_interpolation_fraction() if SimLoop.running() else 1.0
	return track.x(id, fraction)
