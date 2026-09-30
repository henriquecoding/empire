class_name PauseSession
extends RefCounted


static func status() -> String:
	if SimLoop.state == null:
		return ""
	var phase := int(ClockService.clock.current_phase())
	var day := ClockService.clock.day
	var label := TranslationServer.translate(&"DAY_N") % day
	return "%s · %s" % [label, HudText.phase(phase)]


static func save_note() -> String:
	if SavePoint.allowed():
		return TranslationServer.translate(&"UI_MENU_SAVE_DAY")
	return TranslationServer.translate(&"UI_MENU_SAVE_NIGHT")


static func leave(node: Node, note: Label) -> void:
	if SavePoint.allowed() and SavePoint.now() < 0:
		note.text = TranslationServer.translate(&"UI_MENU_SAVE_FAILED")
		return
	if OS.has_feature("web"):
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		window.location.assign("../")
	else:
		node.get_tree().quit()
