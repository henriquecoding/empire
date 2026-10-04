extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261003)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_so_tres_vagabundos_recrutaveis_perto_do_marco_sem_servos_prontos() -> void:
	var perto := 0
	var servos := 0
	for i in SimLoop.units.count():
		var dados := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		if dados.tags.has(&"king") or dados.tags.has(&"follows_king"):
			continue
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO:
			servos += 1
		if absf(SimLoop.units.xs[i] - SimLoop.core_x) < 640.0:
			perto += 1
			assert_str(String(dados.id)).is_equal("vagrant")
			assert_int(SimLoop.units.owners[i]).is_equal(RecruitSystem.SEM_DONO)
	assert_int(perto).is_equal(3)
	assert_int(servos).is_equal(0)


func test_demais_vagabundos_nascem_so_nos_acampamentos() -> void:
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] != &"vagrant":
			continue
		if absf(SimLoop.units.xs[i] - SimLoop.core_x) < 640.0:
			continue
		assert_bool(SimLoop.field.camps.has(SimLoop.units.xs[i])).is_true()


func test_obra_futura_nao_captura_moeda_do_recrutamento() -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == &"training_house":
			assert_int(CoinTarget.slot_at(SimLoop.builds, vaga.x, int(vaga.band))).is_equal(
				CoinTarget.NENHUM
			)


func test_convite_do_muro_e_a_primeira_estacaria() -> void:
	var muro := WallSite.slot(1000.0)
	assert_int(BuildingSkins.shown_level(muro)).is_equal(1)


func test_arqueiro_tem_corpo_de_64_pixels_em_base_64_por_64() -> void:
	var arte := OriginalArt.new()
	assert_float(arte.body_box(&"temp_archer", Vector2.ZERO).size.y).is_equal(64.0)
	var rei := arte.body_box(&"monarch", Vector2.ZERO)
	var classe := arte.body_box(&"temp_archer_hero", Vector2.ZERO)
	assert_float(classe.size.y).is_greater(64.0)
	assert_float(rei.size.y).is_greater(classe.size.y)
