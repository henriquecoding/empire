# tests/legado_duravel_test.gd — o legado como uma transacao (CONT-01; §16, §62).
#
# A auditoria de 27/09 (N7, N8): uma escrita falhada do legado apagava os saves
# na mesma, e o jogo novo gastava o legado antes de ter um save seu. Cada teste
# poe o disco numa fronteira do protocolo e confere que fica exatamente uma
# maneira de continuar — e que continuar duas vezes nao da o dobro.
extends GdUnitTestSuite

const SEMENTE := 20260927
const SEMENTES := 4


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
	for caminho in [LegacyStore.PATH, LegacyStore.PATH + ".tmp"]:
		if DirAccess.dir_exists_absolute(caminho) or FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)
	LegacyStore.discard()
	LegacyStore.failed = false
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


func _legado() -> Dictionary:
	SimLoop.state.royal_seeds = SEMENTES
	return Legacy.of(SimLoop.state, SimLoop.builds, 0.4)


## Um jogo novo com o legado a espera, como o game.gd o monta.
func _jogo_novo() -> void:
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	Legacy.apply(LegacyStore.pending(), SimLoop.state, SimLoop.builds)


func test_o_legado_que_nao_se_escreve_deixa_os_saves_onde_estavam() -> void:
	SaveService.autosave(SimLoop.state)
	DirAccess.make_dir_recursive_absolute(LegacyStore.PATH)  # o rename nao cabe
	assert_bool(LegacyStore.leave(_legado())).is_false()
	assert_bool(LegacyStore.failed).is_true()
	assert_bool(FileAccess.file_exists(LegacyStore.PATH + ".tmp")).is_false()
	assert_int(SaveService.latest_slot()).is_not_equal(-1)
	assert_bool(LegacyStore.pending().is_empty()).is_true()


func test_o_temporario_que_nao_abre_deixa_os_saves_onde_estavam() -> void:
	SaveService.autosave(SimLoop.state)
	DirAccess.make_dir_recursive_absolute(LegacyStore.PATH + ".tmp")
	assert_bool(LegacyStore.leave(_legado())).is_false()
	assert_int(SaveService.latest_slot()).is_not_equal(-1)


func test_o_legado_escrito_e_o_que_se_le() -> void:
	assert_bool(LegacyStore.leave(_legado())).is_true()
	assert_bool(LegacyStore.failed).is_false()
	assert_int(int(LegacyStore.pending()[Legacy.SEMENTES])).is_equal(SEMENTES)


## Um fecho entre o rename e o apagar dos slots: o arranque acaba de os apagar,
## e o save de antes da derrota nao se retoma.
func test_um_slot_de_antes_do_legado_apaga_se_no_arranque() -> void:
	SaveService.autosave(SimLoop.state)
	var velho := FileAccess.get_file_as_bytes(SaveService.caminho(0))
	assert_bool(LegacyStore.leave(_legado())).is_true()
	var f := FileAccess.open(SaveService.caminho(0), FileAccess.WRITE)
	f.store_buffer(velho)
	f.close()
	assert_int(SaveService.latest_slot()).is_equal(0)
	LegacyStore.settle()
	assert_int(SaveService.latest_slot()).is_equal(-1)
	assert_int(int(LegacyStore.pending()[Legacy.SEMENTES])).is_equal(SEMENTES)


## Um fecho depois de aplicar e antes do primeiro save: o legado continua a
## espera, e aplica-lo outra vez a um mundo novo nao da o dobro.
func test_o_legado_so_se_gasta_com_o_primeiro_save_do_jogo_novo() -> void:
	assert_bool(LegacyStore.leave(_legado())).is_true()
	_jogo_novo()
	LegacyStore.settle()  # o arranque seguinte, sem save nenhum
	assert_bool(LegacyStore.pending().is_empty()).is_false()
	_jogo_novo()
	assert_int(SimLoop.state.royal_seeds).is_equal(SEMENTES)
	assert_int(SaveService.autosave(SimLoop.state)).is_not_equal(-1)
	LegacyStore.settle()
	assert_bool(LegacyStore.pending().is_empty()).is_true()
	assert_int(SaveService.latest_slot()).is_not_equal(-1)


func test_o_primeiro_save_do_jogo_novo_e_mais_novo_do_que_o_legado() -> void:
	for k in 3:
		SaveService.autosave(SimLoop.state)
	var antes := SaveService.latest_seq()
	assert_bool(LegacyStore.leave(_legado())).is_true()
	SaveService.autosave(SimLoop.state)
	assert_int(SaveService.latest_seq()).is_greater(antes)


func test_um_legado_de_antes_da_moldura_le_se_na_mesma() -> void:
	var f := FileAccess.open(LegacyStore.PATH, FileAccess.WRITE)
	f.store_var({Legacy.SEMENTES: SEMENTES}, false)
	f.close()
	assert_int(int(LegacyStore.pending()[Legacy.SEMENTES])).is_equal(SEMENTES)
	assert_int(LegacyStore.seq_floor()).is_equal(0)
