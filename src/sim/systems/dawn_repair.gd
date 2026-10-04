class_name DawnRepair
extends RefCounted


## Agenda trabalho na sede; a vida só volta quando o construtor chega.
static func plan(builds: BuildSystem) -> void:
	var seat := RealmLadder.seat(builds)
	if seat != null and seat.state == BuildSlot.State.DAMAGED and not seat.mending:
		seat.mending = true
		seat.progress = 0.0
