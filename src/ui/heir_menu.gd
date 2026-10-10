class_name HeirMenu
extends RefCounted


static func open(parent: Node) -> void:
	if ClassSelection.active or not ImperialSuccession.at_house():
		return
	SimLoop.stop()
	var selector := ClassSelection.new()
	selector.succession_mode = true
	selector.selected = MonarchWatch.data().id
	selector._choose = func(id: StringName) -> void:
		if id != &"" and not ImperialSuccession.exchange(id):
			return
		selector.hide()
		selector.queue_free()
		ClassSelection.active = false
		SimLoop.set_paused(false)
		if SimLoop.autosave_enabled:
			SavePoint.now()
	parent.add_child(selector)
