# tests/recomecar_do_zero_test.gd — recomecar do zero pela pausa (pedido do dono, 29/09).
#
# O "Novo jogo" da derrota herda o legado (§16, Q-134). Isto e o outro botao: apaga
# os tres saves e o legado — tudo ou nada —, deixa as opcoes onde estavam, e o jogo
# seguinte nasce como o primeiro (relatorio ANALISE-KINGDOM-2026-09-29, §7).
extends GdUnitTestSuite

const SEMENTE := 20260929
const SEMENTES := 4
const OUTRO := "user://recomecar_do_zero_test.cfg"
const BLOQUEIO := "trava"


class JogoFalso:
	extends Node
	var pedidos := 0

	func new_game() -> void:
		pedidos += 1


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	_limpar()


func after_test() -> void:
	_limpar()
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _limpar() -> void:
	var trava := LegacyStore.PATH + FreshStart.QUARENTENA
	if DirAccess.dir_exists_absolute(trava):
		DirAccess.remove_absolute(trava.path_join(BLOQUEIO))
		DirAccess.remove_absolute(trava)
	FreshStart.wipe()
	LegacyStore.failed = false
	if FileAccess.file_exists(OUTRO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUTRO))


func _menu() -> PauseMenu:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	return menu


func _jogo() -> JogoFalso:
	var jogo: JogoFalso = auto_free(JogoFalso.new())
	add_child(jogo)
	jogo.add_to_group(FreshStartPanel.GRUPO_JOGO)
	return jogo


## Tres autosaves e um legado escrito, como depois de uma partida longa e perdida.
func _campanha() -> void:
	for k in SaveService.SLOTS:
		SaveService.autosave(SimLoop.state)
	SimLoop.state.royal_seeds = SEMENTES
	var legado := Legacy.of(SimLoop.state, SimLoop.builds, 0.4)
	var f := FileAccess.open(LegacyStore.PATH, FileAccess.WRITE)
	f.store_var({LegacyStore.VERSAO: LegacyStore.VERSION, LegacyStore.LEGADO: legado}, false)
	f.close()


func _escrever(caminho: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_var({"x": 1}, false)
	f.close()


func test_apaga_os_tres_slots_e_o_legado() -> void:
	_campanha()
	assert_int(SaveService.latest_slot()).is_not_equal(-1)
	assert_bool(LegacyStore.pending().is_empty()).is_false()
	assert_bool(FreshStart.wipe()).is_true()
	assert_int(SaveService.latest_slot()).is_equal(-1)
	assert_bool(LegacyStore.pending().is_empty()).is_true()
	assert_bool(FreshStart.clean()).is_true()


func test_apaga_os_temporarios() -> void:
	var do_slot := SaveService.caminho(1) + FreshStart.TEMPORARIO
	var do_legado := LegacyStore.PATH + FreshStart.TEMPORARIO
	_escrever(do_slot)
	_escrever(do_legado)
	assert_bool(FreshStart.wipe()).is_true()
	assert_bool(FileAccess.file_exists(do_slot)).is_false()
	assert_bool(FileAccess.file_exists(do_legado)).is_false()


## As opcoes (§45) e tudo o que nao e do jogo ficam onde estavam.
func test_o_que_nao_e_do_jogo_fica() -> void:
	_escrever(OUTRO)
	_campanha()
	assert_bool(FreshStart.wipe()).is_true()
	assert_bool(FileAccess.file_exists(OUTRO)).is_true()


func test_apagar_duas_vezes_nao_falha() -> void:
	_campanha()
	assert_bool(FreshStart.wipe()).is_true()
	assert_bool(FreshStart.wipe()).is_true()


## Um legado que nao se gravou (CONT-01) deixa de ser anunciado num jogo limpo.
func test_um_legado_falhado_deixa_de_contar() -> void:
	LegacyStore.failed = true
	assert_bool(FreshStart.wipe()).is_true()
	assert_bool(LegacyStore.failed).is_false()


## Tudo ou nada: o legado nao entra em quarentena (ha uma pasta no lugar dela), e os
## slots que ja tinham entrado voltam ao nome de origem.
func test_uma_falha_a_meio_volta_tudo_ao_sitio() -> void:
	_campanha()
	var trava := LegacyStore.PATH + FreshStart.QUARENTENA
	DirAccess.make_dir_recursive_absolute(trava)
	_escrever(trava.path_join(BLOQUEIO))
	assert_bool(FreshStart.wipe()).is_false()
	for slot in SaveService.SLOTS:
		var fora := SaveService.caminho(slot) + FreshStart.QUARENTENA
		assert_bool(SaveService.has_slot(slot)).is_true()
		assert_bool(FileAccess.file_exists(fora)).is_false()
	assert_bool(LegacyStore.pending().is_empty()).is_false()


## Um wipe interrompido depois da quarentena deixa ficheiros que nenhum sistema le;
## o seguinte leva-os.
func test_a_quarentena_que_sobrou_sai_no_wipe_seguinte() -> void:
	var sobra := SaveService.caminho(0) + FreshStart.QUARENTENA
	_escrever(sobra)
	assert_int(SaveService.latest_slot()).is_equal(-1)
	assert_bool(FreshStart.wipe()).is_true()
	assert_bool(FileAccess.file_exists(sobra)).is_false()


## O que a sonda 4 do relatorio mediu: depois do wipe, o jogo seguinte e o primeiro.
func test_o_jogo_seguinte_nasce_do_zero() -> void:
	_campanha()
	assert_bool(FreshStart.wipe()).is_true()
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	Legacy.apply(LegacyStore.pending(), SimLoop.state, SimLoop.builds, SimLoop.field.classes)
	assert_int(ClockService.clock.day).is_equal(1)
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	assert_int(SimLoop.state.found.size()).is_equal(0)
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	assert_int(SimLoop.units.carried_coins[rei]).is_equal(SimFactory.curve().start_coins)


func test_a_pausa_e_a_derrota_oferecem_recomecar_do_zero() -> void:
	var menu := _menu()
	for perdido in [false, true]:
		menu.open(perdido)
		assert_bool(menu._zero._abrir.visible).is_true()
		assert_bool(menu._zero._pergunta.visible).is_false()
		assert_bool(menu._zero._apagar.visible).is_false()


func test_a_pergunta_abre_com_o_foco_em_cancelar() -> void:
	var menu := _menu()
	menu.open(false)
	menu._zero._abrir.pressed.emit()
	assert_bool(menu._zero._pergunta.visible).is_true()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._cancelar)


func test_cancelar_nao_apaga_e_devolve_o_foco_ao_botao() -> void:
	SaveService.autosave(SimLoop.state)
	var jogo := _jogo()
	var menu := _menu()
	menu.open(false)
	menu._zero._abrir.pressed.emit()
	menu._zero._cancelar.pressed.emit()
	assert_int(SaveService.latest_slot()).is_not_equal(-1)
	assert_int(jogo.pedidos).is_equal(0)
	assert_bool(menu._zero._pergunta.visible).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._abrir)


## Abrir a pausa outra vez fecha a pergunta que o Esc deixou a meio.
func test_reabrir_a_pausa_fecha_a_pergunta() -> void:
	var menu := _menu()
	menu.open(false)
	menu._zero._abrir.pressed.emit()
	menu.open(false)
	assert_bool(menu._zero._pergunta.visible).is_false()


func test_confirmar_apaga_e_pede_um_jogo_novo() -> void:
	_campanha()
	var jogo := _jogo()
	var menu := _menu()
	menu.open(true)
	menu._zero._abrir.pressed.emit()
	menu._zero._apagar.pressed.emit()
	assert_int(jogo.pedidos).is_equal(1)
	assert_bool(FreshStart.clean()).is_true()


func test_a_falha_diz_e_nao_recomeca() -> void:
	var jogo := _jogo()
	var menu := _menu()
	menu.open(false)
	menu._zero._abrir.pressed.emit()
	menu._zero._depois(false)
	assert_str(menu._zero._pergunta.text).is_equal(tr(&"UI_FRESH_START_FAILED"))
	assert_int(jogo.pedidos).is_equal(0)
	assert_bool(menu._zero._cancelar.disabled).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._cancelar)


## O que a pergunta diz que se perde: a partida viva; depois do fim, o legado a espera;
## e, se o legado falhou, outra vez a partida viva, que e o que os saves retidos guardam.
func test_o_que_se_perde() -> void:
	var estado := GameState.new()
	estado.royal_seeds = SEMENTES
	estado.found = PackedStringArray(["a", "b"])
	var legado := {Legacy.SEMENTES: 1, Legacy.ACHADOS: PackedStringArray(["c"])}
	var viva := FreshStartPanel.counts(estado, 7, false, legado, false)
	assert_dict(viva).is_equal({"day": 7, "seeds": SEMENTES, "found": 2})
	var herdada := FreshStartPanel.counts(estado, 7, true, legado, false)
	assert_dict(herdada).is_equal({"day": 7, "seeds": 1, "found": 1})
	var falhada := FreshStartPanel.counts(estado, 7, true, {}, true)
	assert_dict(falhada).is_equal({"day": 7, "seeds": SEMENTES, "found": 2})


## O recibo da boot diz o estado do disco: e o que o teste de fumo do site le depois
## de um F5 para saber se o recomeco persistiu no IndexedDB.
func test_a_boot_diz_o_estado_do_disco() -> void:
	var boot := load("res://src/world/boot.gd")
	assert_str(boot.disk_line()).is_equal("save: nenhum · legado: nao")
	_campanha()
	assert_str(boot.disk_line()).contains("save: dia 1").contains("legado: sim")
	FreshStart.wipe()
	assert_str(boot.disk_line()).is_equal("save: nenhum · legado: nao")


func test_o_texto_sai_de_chaves_que_existem() -> void:
	for chave in FreshStartPanel.CHAVES:
		assert_str(tr(chave)).is_not_equal(String(chave))
