extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const RACKS := [&"bow_rack", &"hammer_rack"]


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_clareira_e_uma_lareira_apagada_sem_bancas_nem_convites_do_reino() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	assert_str(String(BuildingSkins.profile(sede, Silhouette.Form.COPA))).is_equal("seat_clearing")
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO or vaga.territory > 0:
			continue
		assert_bool(RealmGrowth.visible(SimLoop.builds, vaga)).is_false()
		assert_int(CoinTarget.slot_at(SimLoop.builds, vaga.x, int(vaga.band))).is_equal(-1)


func test_pagar_a_lareira_so_publica_as_duas_bancas_quando_a_fundacao_acaba() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	_pagar(sede)
	for kind in RACKS:
		assert_bool(RealmGrowth.visible(SimLoop.builds, _site(kind))).is_false()
	for _k in ceili(sede.works[0] / STEP) + 30:
		SimLoop.step(STEP)
	assert_int(sede.level).is_equal(RealmLadder.FUNDADO)
	for kind in RACKS:
		var banca := _site(kind)
		assert_bool(banca.standing()).is_true()
		assert_bool(RealmGrowth.visible(SimLoop.builds, banca)).is_true()
		assert_int(CoinTarget.slot_at(SimLoop.builds, banca.x, int(banca.band))).is_equal(banca.id)


func test_as_bancas_cabem_inteiras_no_primeiro_recinto_sem_sobrepor_outras_obras() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	for kind in RACKS:
		var banca := _site(kind)
		var muro := _wall(signf(banca.x - sede.x) * 680.0)
		assert_float(absf(banca.x - sede.x) + banca.width * 0.5).is_less(
			absf(muro.x - sede.x) - muro.width * 0.5
		)
		for outra in SimLoop.builds.slots:
			if outra == banca or outra.band != banca.band:
				continue
			var largura := outra.widths[-1] if outra == sede else outra.width
			(
				assert_float(absf(outra.x - banca.x))
				. override_failure_message("%s / %s" % [banca.kind, outra.kind])
				. is_greater((largura + banca.width) * 0.5)
			)


func test_a_fundacao_nao_ergue_bancas_exteriores_ou_de_outro_territorio() -> void:
	var fora := SimLoop.builds.post(Greybox.slot_of(_data(&"hammer_rack"), SimLoop.core_x - 2080.0))
	var vizinha := SimLoop.builds.post(Greybox.slot_of(_data(&"bow_rack"), SimLoop.core_x + 300.0))
	vizinha.territory = 1
	var sede := RealmLadder.seat(SimLoop.builds)
	sede.raise_to(RealmLadder.FUNDADO)
	FoundationWatch.after([{BuildSystem.CHAVE: BuildSystem.EV_COMPLETA, BuildSystem.VAGA: sede}])
	assert_bool(fora.standing()).is_false()
	assert_bool(vizinha.standing()).is_false()
	assert_bool(RealmGrowth.visible(SimLoop.builds, fora)).is_false()


func test_nivel_e_frente_concluida_abrem_uma_linha_de_muralhas_por_flanco() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	sede.raise_to(1)
	var primeira := _wall(680.0)
	var segunda := _wall(1408.0)
	var terceira := _wall(1960.0)
	assert_bool(RealmGrowth.visible(SimLoop.builds, primeira)).is_true()
	primeira.state = BuildSlot.State.BUILDING
	assert_bool(RealmGrowth.visible(SimLoop.builds, segunda)).is_false()
	primeira.raise_to(1)
	assert_bool(RealmGrowth.visible(SimLoop.builds, segunda)).is_false()
	sede.raise_to(2)
	assert_bool(RealmGrowth.visible(SimLoop.builds, segunda)).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, _wall(-1408.0))).is_false()
	segunda.raise_to(1)
	assert_bool(RealmGrowth.visible(SimLoop.builds, terceira)).is_false()
	sede.raise_to(3)
	assert_bool(RealmGrowth.visible(SimLoop.builds, terceira)).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, _wall(-680.0))).is_true()


func test_evoluir_a_sede_sozinha_nao_publica_edificios_fora_das_muralhas() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(5)
	for vaga in SimLoop.builds.slots:
		if vaga.kind in RACKS or vaga.kind == BuildSlot.NUCLEO or vaga.two_paths():
			continue
		var politica := RealmGrowth.policy(vaga)
		if politica == null or politica.placement in [&"native", &"wilderness"]:
			continue
		(
			assert_bool(RealmGrowth.visible(SimLoop.builds, vaga))
			. override_failure_message(String(vaga.kind))
			. is_false()
		)


func test_construir_o_muro_revela_so_os_canteiros_do_espaco_protegido() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(2)
	var perto := SimLoop.builds.slots.filter(
		func(v: BuildSlot) -> bool: return v.kind == &"farm" and v.x > SimLoop.core_x
	)
	for vaga: BuildSlot in perto:
		assert_bool(RealmGrowth.visible(SimLoop.builds, vaga)).is_false()
	_wall(680.0).raise_to(1)
	for vaga: BuildSlot in perto:
		assert_bool(RealmGrowth.visible(SimLoop.builds, vaga)).is_equal(
			vaga.x < SimLoop.core_x + 680.0
		)
	_wall(1408.0).raise_to(1)
	for vaga: BuildSlot in perto:
		assert_bool(RealmGrowth.visible(SimLoop.builds, vaga)).is_true()


func test_guardar_e_retomar_conserva_bancas_formacao_e_expansao_sem_duplicar() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	sede.raise_to(2)
	_wall(680.0).raise_to(1)
	var banca := _site(&"hammer_rack")
	banca.raise_to(1)
	banca.paid = 2
	var id := banca.id
	var count := SimLoop.builds.count()
	var salvo := SimLoop.world()
	Greybox.region()
	SimLoop.load_world(salvo)
	assert_int(SimLoop.builds.count()).is_equal(count)
	assert_int(_site(&"hammer_rack").id).is_equal(id)
	assert_int(_site(&"hammer_rack").paid).is_equal(2)
	assert_bool(RealmGrowth.visible(SimLoop.builds, _wall(1408.0))).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, _wall(-1408.0))).is_false()


func _site(kind: StringName) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == kind:
			return vaga
	return null


func _wall(offset: float) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths() and is_equal_approx(vaga.x, SimLoop.core_x + offset):
			return vaga
	return null


func _data(kind: StringName) -> BuildingData:
	return Registry.entry(&"buildings", kind) as BuildingData


func _pagar(vaga: BuildSlot) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = vaga.x
	SimLoop.units.clear_target(SimLoop.king_id)
	for _k in vaga.next_cost():
		SimLoop.intents.queue(
			IntentQueue.Kind.DROP_COIN,
			{&"x": vaga.x, &"band": Band.Kind.SURFACE, &"amount": 1, &"source": Verbs.JOGADOR}
		)
		SimLoop.step(STEP)
