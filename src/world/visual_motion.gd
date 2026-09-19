class_name VisualMotion
extends RefCounted

## Presentation snapshots; never written back into simulation columns.
const TELEPORT_PX := 32.0

var _current: Dictionary = {}
var _previous: Dictionary = {}
var _bands: Dictionary = {}
var _tick := -1


func capture(ids: Array, positions: Array, bands: Array, tick: int) -> void:
	var next: Dictionary = {}
	var previous: Dictionary = {}
	var next_bands: Dictionary = {}
	for i in ids.size():
		var id: int = ids[i]
		var value: float = positions[i]
		var old: float = _current.get(id, value)
		var continuous: bool = tick == _tick + 1 and _bands.get(id, bands[i]) == bands[i]
		previous[id] = old if continuous and absf(value - old) <= TELEPORT_PX else value
		next[id] = value
		next_bands[id] = bands[i]
	_current = next
	_previous = previous
	_bands = next_bands
	_tick = tick


func x(id: int, fraction: float) -> float:
	return lerpf(_previous[id], _current[id], clampf(fraction, 0.0, 1.0))


func has(id: int) -> bool:
	return _current.has(id)
