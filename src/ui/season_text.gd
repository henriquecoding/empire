class_name SeasonText
extends RefCounted
const NAMES := [&"SEASON_SPRING", &"SEASON_SUMMER", &"SEASON_AUTUMN", &"SEASON_WINTER"]


static func of(field: FieldWork, day: int) -> String:
	return TranslationServer.translate(&"HUD_SEASON").format(
		{
			"season": TranslationServer.translate(NAMES[field.seasons.at(day)]),
			"days": field.seasons.left(day)
		}
	)
