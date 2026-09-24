# tests/pause_menu_test.gd — "Pausa / opcoes", e o fim da partida (§24, §26, §16).
#
# GB-13: o Esc e o Start abrem as duas opcoes que o §26 marca como obrigatorias.
# GB-16: com o castelo-arvore caido, o ecra deixa de dizer "ESC para continuar" —
# o Esc nao fazia nada — e oferece o que o §16 da: um jogo novo.
extends GdUnitTestSuite

const FICHEIRO := "user://pause_menu_test.cfg"


func after_test() -> void:
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
	assert_bool(menu._tremor.button_pressed).is_false()
	assert_bool(menu._claroes.button_pressed).is_true()


## Mudar uma opcao grava-a — e vale ja, porque quem treme pergunta a cada vez.
func test_desligar_na_pausa_vale_ja() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))
	var menu := _menu()
	menu.open(false)
	menu._claroes.button_pressed = false
	assert_bool(Preferences.on(Preferences.FLASHES)).is_false()
	assert_bool(Preferences.new(FICHEIRO).enabled(Preferences.FLASHES)).is_false()


## O texto e todo por chave (AGENTS.md), e as chaves ja estavam no strings.csv
## a espera deste ecra: nenhuma e inventada aqui.
func test_o_texto_sai_de_chaves_que_existem() -> void:
	for chave in [&"UI_PAUSED", &"UI_CROWN_FALLEN", &"UI_RESUME", &"UI_NEW_GAME"]:
		assert_str(tr(chave)).is_not_equal(String(chave))
	for chave in [&"OPT_SCREEN_SHAKE", &"OPT_FLASHES"]:
		assert_str(tr(chave)).is_not_equal(String(chave))
