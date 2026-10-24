# tests/hud_copy_test.gd — o que cada numero da HUD quer dizer, dito (HUD-02, UX-08).
#
# A captura do dono tinha tres numeros sem rotulo: «6 / 33», «16 dias» e «1 de 2». O
# codigo diz o que sao — moedas no saco e a capacidade dele, os dias que faltam a estacao
# contando com hoje, e quantos dos lugares de uma obra tem a fonte ao alcance —, e o texto
# passa a dize-lo, sem caber pior nos cartoes.
extends GdUnitTestSuite

var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261006)
	Greybox.build()
	SimLoop.step(1.0 / 60.0)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	TranslationServer.set_locale(_locale)


func _largura(texto: String, tamanho: int) -> float:
	return HudStyle.font().get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x


func test_the_season_counts_the_days_left_and_names_the_last_one() -> void:
	var estacao := SimLoop.field.seasons
	var dias := estacao.left(1)
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		assert_str(SeasonText.of(SimLoop.field, 1)).contains(str(dias))
		assert_str(SeasonText.of(SimLoop.field, 1)).is_not_equal(
			tr(&"HUD_SEASON_LAST").format({"season": tr(SeasonText.NAMES[estacao.at(1)])})
		)
		var ultimo := dias  # o dia em que left() da 1
		assert_int(estacao.left(ultimo)).is_equal(1)
		var texto := SeasonText.of(SimLoop.field, ultimo)
		assert_str(texto).is_equal(
			tr(&"HUD_SEASON_LAST").format({"season": tr(SeasonText.NAMES[estacao.at(ultimo)])})
		)
		assert_str(texto).not_contains("1 ")


func test_the_season_detail_remains_available_in_the_realm_overview() -> void:
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		assert_str(RealmReadout.overview()).contains(
			SeasonText.of(SimLoop.field, SimLoop.state.day)
		)


func test_the_purse_says_which_number_is_the_capacity_and_fits() -> void:
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		var titulo := tr(&"HUD_PURSE_TITLE")
		assert_str(titulo).contains("/")  # «moedas / máx.»: a mesma ordem do valor
		var value := tr(&"HUD_PURSE_VALUE").format({"coins": 99, "capacity": 999})
		assert_float(_largura(value, 19)).is_less_equal(HudLayout.PURSE.size.x - 42)
		var resumo := tr(&"HUD_DETAIL_PURSE").format({"bag": 6, "cap": 33})
		assert_str(resumo).contains("6")
		assert_str(resumo).contains("33")
		assert_str(resumo).is_not_equal(tr(&"HUD_PURSE_VALUE").format({"coins": 6, "capacity": 33}))


func test_a_building_row_separates_name_count_and_condition() -> void:
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		var valores := {"name": "N", "source": "S", "ok": 1, "all": 2}
		var alguns := tr(&"TERRAIN_SITE_SOME").format(valores)
		var todos := tr(&"TERRAIN_SITE_OK").format(valores)
		var nenhum := tr(&"TERRAIN_SITE_NONE").format(valores)
		for linha: String in [alguns, todos, nenhum]:
			assert_bool(linha.begins_with("N · ")).is_true()  # o nome primeiro, e so o nome
			assert_str(linha).not_contains(";")  # uma condicao por linha, sem drama
		assert_str(alguns).contains("1")
		assert_str(alguns).contains("2")
		assert_str(alguns).not_contains(todos)
		assert_str(nenhum).not_contains(todos)
