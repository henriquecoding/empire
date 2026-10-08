# A pausa recebe o gesto real sem mudar a emulacao de entrada de todo o jogo.
class_name TouchScroll
extends ScrollContainer

var _finger := -1
var _origin := Vector2.ZERO
var _from := 0
var _dragging := false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or Glyphs.emulated(event):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var point := _local(touch.position)
			if _finger >= 0 or not Rect2(Vector2.ZERO, size).has_point(point):
				return
			_finger = touch.index
			_origin = point
			_from = scroll_vertical
			var focus := get_viewport().gui_get_focus_owner()
			if focus != null and is_ancestor_of(focus):
				focus.release_focus()
		elif touch.index == _finger:
			if _dragging:
				get_viewport().set_input_as_handled()
			_finish()
	elif event is InputEventScreenDrag and event.index == _finger:
		var distance := _origin.y - _local(event.position).y
		if not _dragging:
			if absf(distance) <= scroll_deadzone:
				return
			_dragging = true
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
			scroll_started.emit()
		scroll_vertical = _from + roundi(distance)
		get_viewport().set_input_as_handled()


func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _finish() -> void:
	_finger = -1
	if _dragging:
		_dragging = false
		propagate_notification(NOTIFICATION_SCROLL_END)
		scroll_ended.emit()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_finish()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_finish()
