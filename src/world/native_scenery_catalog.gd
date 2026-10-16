class_name NativeSceneryCatalog
extends RefCounted

const MANIFEST := "res://art/export/scenery_native/manifest.json"
static var _data: Dictionary = {}


static func manifest() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(MANIFEST):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func variant(id: String) -> Dictionary:
	return manifest().get("variants", {}).get(id, {})


static func family(id: String) -> Dictionary:
	return manifest().get("families", {}).get(id, {})


static func ids() -> PackedStringArray:
	return PackedStringArray(manifest().get("variants", {}).keys())


static func spans(id: String, band: Band.Kind) -> Array:
	return [[0, 1280]] if band == Band.Kind.SURFACE else family(id).get("lower_spans", [])


static func supports(id: String, x: float, band: Band.Kind, margin: float = 0.0) -> bool:
	for span: Array in spans(id, band):
		if x - margin >= float(span[0]) and x + margin <= float(span[1]):
			return true
	return false


static func passage_at(id: String, x: float) -> bool:
	for mouth: float in family(id).get("passages", []):
		if absf(mouth - x) <= Band.PASSAGE_PX:
			return true
	return false


static func patch_legacy(legacy: Dictionary) -> void:
	for id: String in manifest().get("families", {}):
		var data := family(id)
		var campaign: Dictionary = data.get("campaign_layers", {})
		var biome := String(data.get("biome", ""))
		if campaign.is_empty() or not legacy.get("scenes", {}).has(biome):
			continue
		var scene: Dictionary = legacy.scenes[biome]
		for layer: String in campaign:
			scene.layers[layer] = campaign[layer]
