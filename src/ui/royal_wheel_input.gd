class_name RoyalWheelInput
extends RefCounted


static func handle(wheel: RoyalWheel, event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		wheel.close()
		wheel.get_viewport().set_input_as_handled()
		return
	if (
		event is InputEventMouseMotion
		and not Glyphs.emulated(event)
		and event.relative != Vector2.ZERO
	):
		wheel._mouse = true
		wheel._keyboard = false
	if event is InputEventJoypadMotion or event is InputEventScreenDrag:
		wheel._mouse = false
		wheel._keyboard = false
	var digit := InputRouter.wheel_choice(event, true)
	if digit >= 0:
		if wheel.impulses and digit < wheel.count():
			wheel.selected = digit
			wheel._keyboard = true
			wheel._readout()
			wheel.queue_redraw()
		else:
			wheel.choose(digit)
		wheel.get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		wheel.choose(wheel.selected)
		wheel.get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not Glyphs.emulated(event) and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var point := (wheel.get_local_mouse_position() - wheel._center) / wheel._art_scale
			var index := InputRouter.wheel_segment(point / RoyalWheelArt.INNER, wheel.count())
			wheel.choose(index if point.length() <= RoyalWheelArt.RADIUS else -1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			wheel.close()
		wheel.get_viewport().set_input_as_handled()
