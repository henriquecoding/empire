# tests/save_recovery_test.gd — gravar e retomar sem perder o save que havia (BUG-01, BUG-03).
#
# O relatorio de auditoria de 06/10/2026 reproduziu duas coisas: uma escrita a meio
# passava a metade do save e o `save()` dizia que correu bem; e um save mais novo sem
# mundo escondia o mais velho, que estava bom, e a retoma comecava um jogo novo.
extends GdUnitTestSuite

const SEMENTE := 20261006


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	_limpar()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	_limpar()


func _limpar() -> void:
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)
		var tmp := ProjectSettings.globalize_path(SaveService.caminho(slot) + ".tmp")
		if DirAccess.dir_exists_absolute(tmp):
			DirAccess.remove_absolute(tmp)
		elif FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)


func _partida() -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()
	LastCartWatch.claim(&"road")


func _bytes(slot: int) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(SaveService.caminho(slot))


func test_um_temporario_a_meio_nao_se_confirma() -> void:
	_partida()
	assert_bool(SaveService.save(0, SimLoop.state, {}, SimLoop.world())).is_true()
	var inteiro := _bytes(0)
	var meio := SaveService.caminho(1)
	var f := FileAccess.open(meio, FileAccess.WRITE)
	f.store_buffer(inteiro.slice(0, inteiro.size() / 2))
	f.close()
	var dados := {&"save_version": SaveService.SAVE_VERSION}
	assert_bool(SaveFile.confirmed(meio, inteiro.size(), dados)).is_false()
	assert_bool(SaveFile.confirmed(SaveService.caminho(0), inteiro.size(), dados)).is_false()


func test_uma_escrita_que_falha_deixa_o_save_anterior_e_devolve_false() -> void:
	_partida()
	assert_bool(SaveService.save(0, SimLoop.state, {}, SimLoop.world())).is_true()
	var antes := _bytes(0)
	# O temporario e uma pasta: o motor nao o consegue abrir para escrever.
	var tmp := ProjectSettings.globalize_path(SaveService.caminho(0) + ".tmp")
	DirAccess.make_dir_recursive_absolute(tmp)
	assert_bool(SaveService.save(0, SimLoop.state, {}, SimLoop.world())).is_false()
	assert_bool(_bytes(0) == antes).is_true()
	assert_object(SaveService.restore(0)).is_not_null()


func test_uma_escrita_boa_continua_a_repor_o_mesmo_estado() -> void:
	_partida()
	assert_bool(SaveService.save(0, SimLoop.state, {}, SimLoop.world())).is_true()
	assert_bool(SaveService.playable(0)).is_true()
	assert_int(SaveService.restore(0).tick).is_equal(SimLoop.state.tick)
	assert_bool(FileAccess.file_exists(SaveService.caminho(0) + ".tmp")).is_false()


func test_um_save_novo_sem_mundo_nao_esconde_o_velho_bom() -> void:
	_partida()
	var tropas := SimLoop.units.count()
	SaveService.save(0, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SaveService.save(1, SimLoop.state, RngService.snapshot(), {})
	assert_int(SaveService.latest_slot()).is_equal(1)
	assert_bool(SaveService.playable(1)).is_false()
	SimLoop.stop()
	assert_bool(Resume.latest()).is_true()
	assert_bool(Resume.recovered).is_true()
	assert_int(SimLoop.units.count()).is_equal(tropas)
	assert_bool(SaveService.has_slot(1)).is_true()  # o estragado fica, para quem o quiser ver


func test_o_save_mais_novo_bom_e_o_que_se_retoma() -> void:
	_partida()
	SaveService.save(0, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SaveService.save(1, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SimLoop.stop()
	assert_bool(Resume.latest()).is_true()
	assert_bool(Resume.recovered).is_false()


func test_sem_saves_nao_ha_retoma() -> void:
	assert_bool(Resume.latest()).is_false()
	assert_bool(Resume.recovered).is_false()


func test_uma_partida_acabada_nao_volta_atras_por_um_save_velho() -> void:
	_partida()
	SaveService.save(0, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SimLoop.state.crossed = true
	SaveService.save(1, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SimLoop.stop()
	assert_bool(Resume.latest()).is_false()


func test_um_save_novo_que_nem_se_le_tambem_avisa() -> void:
	_partida()
	SaveService.save(0, SimLoop.state, RngService.snapshot(), SimLoop.world())
	var f := FileAccess.open(SaveService.caminho(1), FileAccess.WRITE)
	f.store_buffer(PackedByteArray([1, 2, 3, 4, 5]))
	f.close()
	SimLoop.stop()
	assert_bool(Resume.latest()).is_true()
	assert_bool(Resume.recovered).is_true()
