class_name HintCue
extends RefCounted

const STOP_SECONDS := 0.5
const READ_SECONDS := 6.0

var _still := 0.0
var _exposure: Dictionary = {}


## So o tempo legivel conta: andar ou abrir um menu interrompe sem perder a explicacao.
func present(key: StringName, stopped: bool, delta: float) -> bool:
	if not stopped:
		_still = 0.0
		return false
	_still += delta
	if _still < STOP_SECONDS or key == &"" or HintMemory.shared().seen(key):
		return false
	var read := float(_exposure.get(key, 0.0))
	read += minf(delta, maxf(0.0, _still - STOP_SECONDS))
	_exposure[key] = read
	if read >= READ_SECONDS:
		HintMemory.shared().remember(key)
		return false
	return true
