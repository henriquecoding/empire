class_name GuideHints
extends RefCounted

const PREFIXES := ["CONTEXT_", "ARRIVAL_", "GUIDE_", "FOREST_", "HUD_GOAL_", "CLASS_STATUS"]

static var _key := &""


static func context(device: Glyphs.Device) -> Dictionary:
	_key = &""
	var text := GameplayGuide.context(device)
	return {"key": _key if not text.is_empty() else &"", "text": text}


static func goal() -> Dictionary:
	_key = &""
	var text := GameplayGuide.goal()
	return {"key": _key if not text.is_empty() else &"", "text": text}


## A chave e a explicacao, nao o preco, o nome de uma pessoa ou o idioma interpolado.
static func translate(key: StringName) -> String:
	for prefix: String in PREFIXES:
		if String(key).begins_with(prefix):
			_key = key
			break
	return TranslationServer.translate(key)
