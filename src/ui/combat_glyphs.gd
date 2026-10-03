class_name CombatGlyphs
extends RefCounted

## A habilidade de cada monarca (monarchs.csv, `skill`), e a ajuda dela (ADR 0052).
const SKILLS := {&"vigil": &"IMPULSE_VIGIL", &"song": &"COMBAT_ROYAL_SONG", &"mark": &"COMBAT_MARK"}
const HELPS := {
	&"vigil": &"COMBAT_VIGIL_HELP", &"song": &"COMBAT_ROYAL_SONG_HELP", &"mark": &"COMBAT_MARK_HELP"
}


static func buttons(device: Glyphs.Device) -> PackedStringArray:
	match device:
		Glyphs.Device.XBOX:
			return ["RB", "RT"]
		Glyphs.Device.PLAYSTATION:
			return ["R1", "R2"]
		Glyphs.Device.TOUCH:
			return [
				TranslationServer.translate(&"TOUCH_ATTACK"),
				TranslationServer.translate(&"TOUCH_SKILL"),
			]
	return [TranslationServer.translate(&"KEY_ATTACK"), TranslationServer.translate(&"KEY_SKILL")]


## O nome do ataque de `current`. A classe do monarca diz o dele (ADR 0052): a espada do
## Rei, o golpe rapido da Nia, a flecha do Arqueiro.
static func attack_name(current: StringName) -> StringName:
	if current == MonarchWatch.skill_class():
		return StringName(MonarchWatch.data().attack_key)
	match current:
		&"monarch":
			return &"COMBAT_SWORD"
		&"archer":
			return &"COMBAT_ARROW"
		&"bard":
			return &"COMBAT_LUTE"
	return &"HINT_ATTACK"


static func skill_name(current: StringName) -> StringName:
	if current == MonarchWatch.skill_class():
		return SKILLS.get(MonarchWatch.skill(), &"HINT_SKILL")
	match current:
		&"monarch":
			return &"IMPULSE_VIGIL"
		&"archer":
			return &"COMBAT_MARK"
		&"bard":
			return &"COMBAT_CHARM"
	return &"HINT_SKILL"


static func skill_help(current: StringName) -> StringName:
	if current == MonarchWatch.skill_class():
		return HELPS.get(MonarchWatch.skill(), &"COMBAT_CHARM_HELP")
	match current:
		&"monarch":
			return &"COMBAT_VIGIL_HELP"
		&"archer":
			return &"COMBAT_MARK_HELP"
	return &"COMBAT_CHARM_HELP"
