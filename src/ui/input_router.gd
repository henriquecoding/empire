class_name InputRouter
extends Node

## Entrada visualmente imediata: o destino da tropa é atualizado no frame de
## render, e o tick da simulação apenas consome esse comando depois.
const UMA := 1
const FONTE := &"player"
const DROP_REPEAT_SECONDS := 0.12

var _drop_timer := 0.0


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pause"):
		SimLoop.set_paused(not SimLoop.paused)
		get_viewport().set_input_as_handled()
		return
	if not SimLoop.running:
		return
	if evento.is_action_pressed(&"verb_assume"):
		SimLoop.commands.queue(
			&"ASSUME", {"source": FONTE, "target_id": SimLoop.king_id}
		)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed(&"mark_target"):
		SimLoop.commands.queue(
			&"MARK_TARGET", {"source": FONTE, "target_id": _rato_em_x()}
		)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not SimLoop.running:
		return
	_andar(Input.get_axis(&"move_left", &"move_right"))
	_drop_timer = maxf(0.0, _drop_timer - delta)
	if Input.is_action_pressed(&"verb_drop") and _drop_timer <= 0.0:
		_largar()
		_drop_timer = DROP_REPEAT_SECONDS


func _andar(direcao: float) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i < 0 or is_zero_approx(direcao):
		if i >= 0:
			SimLoop.units.target_xs[i] = SimLoop.units.xs[i]
		return
	SimLoop.units.target_xs[i] = clampf(
		SimLoop.units.xs[i] + direcao * WorldPalette.DEGRAU * 2.0,
		0.0, SimLoop.world_width
	)


func _largar() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i < 0:
		return
	SimLoop.commands.queue(
		&"DROP_COIN",
		{
			"source": FONTE,
			"amount": UMA,
			"x": SimLoop.units.xs[i],
			"band": SimLoop.units.bands[i],
		}
	)


func _rato_em_x() -> int:
	var rato := get_viewport().get_camera_2d().get_global_mouse_position()
	return SimLoop.nearest_target(rato.x, int(SimLoop.units.bands[SimLoop.units.index_of(SimLoop.king_id)]))
