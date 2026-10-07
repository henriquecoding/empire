class_name SeasonText
extends RefCounted
const NAMES := [&"SEASON_SPRING", &"SEASON_SUMMER", &"SEASON_AUTUMN", &"SEASON_WINTER"]


## A estacao e os dias que lhe faltam, hoje incluido (Seasons.left); o ultimo diz-se pelo
## nome, e nao «1 dias» (HUD-02, UX-08).
static func of(field: FieldWork, day: int) -> String:
	var faltam := field.seasons.left(day)
	var chave := &"HUD_SEASON_LAST" if faltam <= 1 else &"HUD_SEASON"
	return TranslationServer.translate(chave).format(
		{"season": TranslationServer.translate(NAMES[field.seasons.at(day)]), "days": faltam}
	)
