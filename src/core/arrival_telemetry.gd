class_name ArrivalTelemetry
extends RefCounted


static func snapshot() -> Dictionary:
	return {
		&"schema": 1,
		&"seed": SimLoop.state.seed,
		&"day": ClockService.clock.day,
		&"choice": SimLoop.arrival.choice,
		&"elapsed_seconds": SimLoop.arrival.seconds,
		&"events": SimLoop.arrival.events.duplicate(true),
		&"loss": SimLoop.arrival.scar,
		&"battles": SimLoop.companion.battles.size(),
	}


static func export_local() -> void:
	var json := JSON.stringify(snapshot(), "\t")
	var name := "empire-opening-%d.json" % SimLoop.state.seed
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json.to_utf8_buffer(), name, "application/json")
	else:
		var file := FileAccess.open("user://" + name, FileAccess.WRITE)
		if file != null:
			file.store_string(json)
