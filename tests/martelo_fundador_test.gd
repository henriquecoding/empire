extends GdUnitTestSuite


func test_martelo_converte_um_recrutado_sem_criar_gente_e_reabre_quando_ele_cai() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var dados := Registry.entry(&"buildings", &"hammer_rack") as BuildingData
	var banca := obras.post(Greybox.slot_of(dados, 0.0))
	banca.raise_to(1)
	var treino := SimFactory.training()
	var moedas := CoinSystem.new(SimFactory.curve())
	var quem := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), 1, 0.0)
	var outro := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), 1, 10.0)
	var custo := int(banca.effects[&"craft_cost"])
	assert_bool(treino.cap_reached(banca, unidades)).is_false()
	assert_int(treino.owed(banca, unidades)).is_equal(custo)
	var id := moedas.drop(estado, 0.0, Band.Kind.SURFACE, custo, 0.0)
	moedas.settled[moedas.index_of(id)] = 1
	treino.absorb(moedas, obras, unidades)
	treino.tick(1.0 / 30.0, unidades, obras, 360.0)
	assert_int(unidades.count()).is_equal(2)
	assert_str(String(unidades.data_ids[unidades.index_of(quem)])).is_equal("builder")
	assert_str(String(unidades.data_ids[unidades.index_of(outro)])).is_equal("vagrant")
	assert_bool(treino.cap_reached(banca, unidades)).is_true()
	assert_int(treino.owed(banca, unidades)).is_equal(0)
	unidades.states[unidades.index_of(quem)] = UnitFsm.State.DEAD
	assert_bool(treino.cap_reached(banca, unidades)).is_false()
	assert_int(treino.owed(banca, unidades)).is_equal(custo)


func test_treino_retomado_segue_a_banca_no_sitio_atual() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var dados := Registry.entry(&"buildings", &"hammer_rack") as BuildingData
	var banca := obras.post(Greybox.slot_of(dados, 0.0))
	banca.raise_to(1)
	var quem := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), 1, 500.0)
	var anterior := SimFactory.training()
	anterior.trainees[quem] = [banca.id, 0.0, 500.0]
	var treino := SimFactory.training()
	treino.from_dict(anterior.to_dict())
	treino.tick(1.0 / 30.0, unidades, obras, 360.0)
	treino.plan(unidades)
	var i := unidades.index_of(quem)
	assert_float(unidades.target_xs[i]).is_equal(banca.x)
	assert_int(treino.trainees.size()).is_equal(1)
	unidades.tick_movement(absf(500.0 - banca.x) / unidades.speeds[i] + 1.0)
	treino.tick(1.0 / 30.0, unidades, obras, 360.0)
	assert_str(String(unidades.data_ids[i])).is_equal("builder")
	assert_int(unidades.owners[i]).is_equal(1)
	assert_int(unidades.count()).is_equal(1)
	assert_dict(treino.trainees).is_empty()
