class_name CombatGlyphs
extends RefCounted


static func buttons(device: Glyphs.Device) -> PackedStringArray:
	match device:
		Glyphs.Device.XBOX:
			return ["RB", "RT"]
		Glyphs.Device.PLAYSTATION:
			return ["R1", "R2"]
	return [TranslationServer.translate(&"KEY_ATTACK"), TranslationServer.translate(&"KEY_SKILL")]


static func attack_name(current: StringName) -> StringName:
	match current:
		&"monarch":
			return &"COMBAT_SWORD"
		&"archer":
			return &"COMBAT_ARROW"
		&"bard":
			return &"COMBAT_LUTE"
	return &"HINT_ATTACK"


static func skill_name(current: StringName) -> StringName:
	match current:
		&"monarch":
			return &"IMPULSE_VIGIL"
		&"archer":
			return &"COMBAT_MARK"
		&"bard":
			return &"COMBAT_CHARM"
	return &"HINT_SKILL"


static func skill_help(current: StringName) -> StringName:
	match current:
		&"monarch":
			return &"COMBAT_VIGIL_HELP"
		&"archer":
			return &"COMBAT_MARK_HELP"
	return &"COMBAT_CHARM_HELP"
