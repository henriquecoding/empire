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
	var day := checkpoint_day(
		SaveService.summaries(), SimLoop.state.seed if SimLoop.state != null else -1
	)
	return (
		TranslationServer.translate(&"CHECKPOINT_DAY").format({"day": day})
		if day > 0
		else TranslationServer.translate(&"CHECKPOINT_NONE")
	)


static func checkpoint_day(summaries: Array[Dictionary], seed_value: int) -> int:
	var day := 0
	for summary in summaries:
		if summary.get(&"exists", false) and int(summary.get(&"seed", -1)) == seed_value:
			day = maxi(day, int(summary.get(&"day", 0)))
	return day


static func exit_key(web: bool) -> StringName:
	if not SavePoint.allowed():
		return &"UI_QUIT_CHECKPOINT"
	return &"UI_MENU_EXIT_WEB" if web else &"UI_SAVE_AND_QUIT"


static func leave(node: Node, note: Label) -> void:
	if SavePoint.allowed() and SavePoint.now() < 0:
		note.text = TranslationServer.translate(&"UI_MENU_SAVE_FAILED")
		return
	if OS.has_feature("web"):
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		window.location.assign("../")
	else:
		node.get_tree().quit()
