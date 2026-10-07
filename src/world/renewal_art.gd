class_name RenewalArt
extends RefCounted

## ADR 0075: explicit production profiles, separate from the archived originals.
const ROOT := "res://art/export/renewal/"
const UNITS := {
	&"monarch": &"royal_king",
	&"nia": &"royal_nia",
	&"archer_emperor": &"royal_archer",
	&"archer_hero": &"royal_archer",
	&"squire": &"royal_squire",
	&"vagrant": &"royal_citizen",
	&"builder": &"royal_smith",
	&"smith": &"royal_smith",
	&"war_smith": &"royal_smith",
	&"bard_banner": &"royal_bard",
	&"bard": &"royal_bard",
	&"bard_hero": &"royal_bard",
	&"quiver_squire": &"royal_quiver",
	&"buried_knight": &"royal_knight",
	&"sealed_knight": &"royal_knight",
	&"mercenary": &"royal_knight",
	&"cook": &"royal_cook",
	&"archer": &"royal_bowman",
	&"canopy_archer": &"royal_bowman",
	&"reed_stalker": &"royal_bowman",
	&"spearman": &"royal_spearman",
	&"ice_warden": &"royal_spearman",
}
const BUILDINGS := {
	&"training_house": &"royal_training",
	&"granary": &"royal_granary",
	&"saltery": &"royal_granary",
	&"kitchen": &"royal_kitchen",
	&"forge": &"royal_forge",
}
const SEATS := [
	&"royal_encampment", &"royal_hamlet", &"royal_village", &"royal_walled", &"royal_tree_castle"
]
const CREATURES := {
	Silhouette.Form.ARIETE: &"royal_ram",
	Silhouette.Form.COLOSSO: &"royal_devourer",
	Silhouette.Form.ZELADOR: &"royal_tender",
	Silhouette.Form.RASTEJO: &"royal_crawler",
	Silhouette.Form.ASA: &"royal_winged",
	Silhouette.Form.BROCA: &"royal_burrower",
	Silhouette.Form.BRUTO: &"royal_brute",
}
static var _assets: Dictionary = {}


static func entry(id: StringName) -> Dictionary:
	if not String(id).begins_with("royal_"):
		return {}
	if _assets.is_empty():
		var manifest: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(ROOT + "manifest.json")
		)
		_assets = manifest.assets
	return _assets.get(String(id), {})


static func unit_profile(id: StringName) -> StringName:
	return UNITS.get(id, &"")
