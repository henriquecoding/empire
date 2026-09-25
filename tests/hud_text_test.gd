# tests/hud_text_test.gd — o painel fala por chave, nos dois idiomas (§27; GB-27).
#
# O §27: "usa a importacao de traducao por CSV desde o primeiro texto" e "nunca
# componhas frases por concatenacao". O GameHud tinha doze frases em portugues
# escritas no codigo.
extends GdUnitTestSuite

const PAINEL := "res://src/ui/game_hud.gd"
var _antes := ""


func before_test() -> void:
	_antes = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_antes)


func test_o_relogio_diz_se_nos_dois_idiomas() -> void:
	TranslationServer.set_locale("pt_PT")
	assert_str(HudText.clock(3, GameClock.Phase.DUSK, 0.5)).is_equal("DIA 03 · CREPÚSCULO · 50%")
	TranslationServer.set_locale("en")
	assert_str(HudText.clock(3, GameClock.Phase.DUSK, 0.5)).is_equal("DAY 03 · DUSK · 50%")


func test_os_recursos_levam_os_zeros_de_sempre() -> void:
	TranslationServer.set_locale("pt_PT")
	var texto := HudText.resources(6, 33, 2, 100)
	assert_str(texto).is_equal("SACO 06/33   ·   TROPAS 02   ·   NÚCLEO 100%")


## Todas as fases do enum tem chave nos dois idiomas: o nome sai do enum, e uma
## fase nova sem chave aparecia no ecra como "PHASE_QUALQUERCOISA".
func test_cada_fase_do_relogio_tem_nome_nos_dois_idiomas() -> void:
	for locale in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		for fase in GameClock.Phase.values():
			assert_str(HudText.phase(fase)).not_contains("PHASE_")


## O painel nao tem frase nenhuma escrita a mao: cada chave que ele pede existe
## nos dois idiomas. As chaves leem-se do proprio codigo, e por isso uma chave
## nova sem traducao chumba aqui sem ninguem a acrescentar a uma lista.
func test_cada_chave_do_painel_existe_nos_dois_idiomas() -> void:
	var fonte := (
		FileAccess.get_file_as_string(PAINEL)
		+ FileAccess.get_file_as_string("res://src/ui/hud_text.gd")
	)
	var chaves := RegEx.create_from_string('&"([A-Z][A-Z0-9_]+)"')
	var achadas := 0
	for locale in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		for m in chaves.search_all(fonte):
			var chave := m.get_string(1)
			if chave.begins_with("HUD_") or chave.begins_with("TOAST_") or chave == "GAME_CODENAME":
				achadas += 1
				assert_str(tr(chave)).override_failure_message(chave).is_not_equal(chave)
	assert_int(achadas).is_greater(0)


func test_nao_sobra_frase_em_portugues_no_codigo_do_painel() -> void:
	var fonte := FileAccess.get_file_as_string(PAINEL)
	for frase in ['"DIA ', "SACO ", "OBRA CONCL", "MURALHA ROMP", "JOGO RETOM", "ALVORADA"]:
		assert_str(fonte).override_failure_message(frase).not_contains(frase)
