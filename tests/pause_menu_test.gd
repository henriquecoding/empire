# tests/pause_menu_test.gd — "Pausa / opcoes", e o fim da partida (§24, §26, §16).
#
# GB-13: o Esc e o Start abrem as duas opcoes que o §26 marca como obrigatorias.
# GB-16: com o castelo-arvore caido, o ecra deixa de dizer "ESC para continuar" —
# o Esc nao fazia nada — e oferece o que o §16 da: um jogo novo.
extends GdUnitTestSuite

const FICHEIRO := "user://pause_menu_test.cfg"

var _idioma := ""


func before_test() -> void:
	_idioma = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_idioma)
	Preferences.set_shared(null)
	for f in [FICHEIRO, FICHEIRO + ".tmp"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))


func _menu() -> PauseMenu:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	return menu


func test_comeca_fechado() -> void:
	assert_bool(_menu().visible).is_false()


func test_a_pausa_oferece_retomar() -> void:
	var menu := _menu()
	menu.open(false)
	assert_bool(menu.visible).is_true()
	assert_str(menu._titulo.text).is_equal(tr(&"UI_PAUSED"))
	assert_bool(menu._retomar.visible).is_true()
	assert_bool(menu._novo.visible).is_false()


## O §16: perder nao se desfaz. Nao ha "retomar" num jogo que acabou.
func test_a_derrota_oferece_um_jogo_novo_e_nao_retomar() -> void:
	var menu := _menu()
	menu.open(true)
	assert_str(menu._titulo.text).is_equal(tr(&"UI_CROWN_FALLEN"))
	assert_bool(menu._retomar.visible).is_false()
	assert_bool(menu._novo.visible).is_true()


## O que se ve e o que esta gravado: abrir a pausa nao liga nada sozinho.
func test_as_opcoes_mostram_o_que_esta_gravado() -> void:
	var minhas := Preferences.new(FICHEIRO)
	minhas.set_enabled(Preferences.SCREEN_SHAKE, false)
	Preferences.set_shared(minhas)
	var menu := _menu()
	menu.open(false)
	assert_bool(menu._opcoes._tremor.button_pressed).is_false()
	assert_bool(menu._opcoes._claroes.button_pressed).is_true()
	assert_bool(menu._opcoes._legendas.button_pressed).is_false()


## Mudar uma opcao grava-a — e vale ja, porque quem treme pergunta a cada vez.
func test_desligar_na_pausa_vale_ja() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))
	var menu := _menu()
	menu.open(false)
	menu._opcoes._claroes.button_pressed = false
	assert_bool(Preferences.on(Preferences.FLASHES)).is_false()
	assert_bool(Preferences.new(FICHEIRO).enabled(Preferences.FLASHES)).is_false()


## O texto e todo por chave (AGENTS.md), e as chaves ja estavam no strings.csv
## a espera deste ecra: nenhuma e inventada aqui.
func test_o_texto_sai_de_chaves_que_existem() -> void:
	for chave in [&"UI_PAUSED", &"UI_CROWN_FALLEN", &"UI_RESUME", &"UI_NEW_GAME"]:
		assert_str(tr(chave)).is_not_equal(String(chave))
	var chaves: Array = [&"OPT_SCREEN_SHAKE", &"OPT_FLASHES", &"OPT_CAPTIONS", &"OPT_DAY_LENGTH"]
	for chave in chaves + [&"OPT_CONTRAST", &"OPT_COLORBLIND"] + OptionsPanel.MODOS:
		assert_str(tr(chave)).is_not_equal(String(chave))


## O slider do dia tem os limites do §26, e mexer nele nao mexe no relogio: pede
## pela fila (§61), e o tick seguinte e que muda o dia (GB-24).
func test_o_slider_do_dia_pede_pela_fila() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))
	SimLoop.intents.clear()
	var menu := _menu()
	menu.open(false)
	assert_float(menu._opcoes._dia.min_value).is_equal(240.0)
	assert_float(menu._opcoes._dia.max_value).is_equal(540.0)
	var antes := ClockService.clock.day_seconds()
	menu._opcoes._dia.value = 300.0
	assert_float(ClockService.clock.day_seconds()).is_equal(antes)
	assert_int(SimLoop.intents.pending()).is_equal(1)
	assert_float(Preferences.shared().number(Preferences.DAY_SECONDS)).is_equal(300.0)
	SimLoop.intents.clear()


## O contraste e o daltonismo gravam-se nas preferencias e o filtro le-as ja:
## sao de quem ve, e nao da partida (GB-25, GB-26).
func test_contraste_e_daltonismo_gravam_nas_preferencias() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))
	var menu := _menu()
	menu.open(false)
	menu._opcoes._contraste.value = 1.2
	menu._opcoes._daltonismo.item_selected.emit(AccessibilityFilter.Mode.TRITANOPIA)
	assert_float(Preferences.shared().number(Preferences.CONTRAST)).is_equal_approx(1.2, 0.001)
	assert_int(int(Preferences.shared().number(Preferences.COLORBLIND))).is_equal(3)
	assert_int(OptionsPanel.MODOS.size()).is_equal(AccessibilityFilter.Mode.size())


## §27: o idioma troca na pausa e o que ja esta escrito troca com ele — o titulo,
## os botoes e as opcoes (GB-28). Fica gravado para a boot da proxima vez.
func test_trocar_de_idioma_reescreve_o_menu_e_fica_gravado() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))
	TranslationServer.set_locale("pt_PT")
	var menu := _menu()
	menu.open(false)
	assert_str(menu._titulo.text).is_equal("Pausa")
	menu._opcoes._idioma.item_selected.emit(Preferences.LANGUAGES.find("en"))
	assert_str(TranslationServer.get_locale()).is_equal("en")
	assert_str(menu._titulo.text).is_equal("Paused")
	assert_str(menu._opcoes._tremor.text).is_equal("Screen Shake")
	assert_str(Preferences.shared().text(Preferences.LANGUAGE)).is_equal("en")


## A boot usa o escolhido; sem escolha, ou com uma que o jogo nao tem, faz o que
## sempre fez: o do sistema quando e um dos dois, senao PT-PT.
func test_a_boot_usa_o_idioma_escolhido() -> void:
	var boot := load("res://src/world/boot.gd")
	assert_str(boot.language("en")).is_equal("en")
	assert_str(boot.language("pt_PT")).is_equal("pt_PT")
	assert_bool(boot.language("") in Preferences.LANGUAGES).is_true()
	assert_bool(boot.language("klingon") in Preferences.LANGUAGES).is_true()
