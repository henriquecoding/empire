extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _bench() -> BuildSlot:
	for slot in SimLoop.builds.slots:
		if slot.kind == &"hammer_rack":
			return slot
	return null


func _wall() -> BuildSlot:
	for slot in SimLoop.builds.slots:
		if slot.two_paths() and slot.x == SimLoop.core_x + Greybox.MUROS_X[1]:
			return slot
	return null


func _steps(count: int) -> void:
	for _tick in count:
		SimLoop.step(STEP)


func _drop(slot: BuildSlot, amount: int) -> void:
	for _coin in amount:
		var id := SimLoop.drop_coin(slot.x, slot.band, 1, Verbs.JOGADOR)
		SimLoop.coins.settled[SimLoop.coins.index_of(id)] = 1
	_steps(1)


func test_a_banca_do_martelo_esta_pronta_so_depois_da_fundacao() -> void:
	var bench := _bench()
	assert_bool(bench.standing()).is_false()
	var seat := RealmLadder.seat(SimLoop.builds)
	seat.raise_to(RealmLadder.FUNDADO)
	FoundationWatch.after(
		[{BuildSystem.CHAVE: BuildSystem.EV_COMPLETA, BuildSystem.VAGA: seat}]
	)
	assert_bool(bench.standing()).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, bench)).is_true()
	assert_float(absf(bench.x - SimLoop.core_x)).is_less(absf(Greybox.MUROS_X[1]))
	assert_int(bench.paid).is_equal(0)

func test_sem_construtor_o_rei_nao_paga_nem_constroi_a_muralha() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(RealmLadder.FUNDADO)
	var wall := _wall()
	var king := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[king] = wall.x
	_drop(wall, wall.next_cost())
	_steps(60)
	assert_int(wall.paid).is_equal(0)
	assert_int(wall.level).is_equal(0)
	assert_float(wall.progress).is_equal(0.0)


func test_um_trabalhador_sem_martelo_nao_constroi_andaime_pago() -> void:
	var wall := _wall()
	wall.state = BuildSlot.State.SCAFFOLD
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), 1, wall.x)
	_steps(60)
	assert_float(wall.progress).is_equal(0.0)
	assert_int(wall.level).is_equal(0)
	for job in SimLoop.jobs.slots:
		if job.job_id == &"build":
			assert_int(job.unit_id).is_equal(JobSlot.NENHUM)


func test_o_construtor_de_outro_reino_nao_paga_nem_constroi_a_muralha() -> void:
	var builds := BuildSystem.new()
	var units := UnitSystem.new()
	var wall := builds.post(WallSite.slot(300.0))
	units.spawn(GameState.new(), Registry.entry(&"units", &"builder"), 2, wall.x)
	builds.workforce = units
	builds.crew_owner = 1
	assert_bool(builds.can_climb(wall, null, null)).is_false()
	wall.state = BuildSlot.State.SCAFFOLD
	builds.tick(STEP, units)
	assert_float(wall.progress).is_equal(0.0)


func test_o_construtor_vai_ate_a_muralha_paga_e_constroi_sem_o_rei() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(RealmLadder.FUNDADO)
	var wall := _wall()
	var builder := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"builder"), 1, SimLoop.core_x
	)
	_drop(wall, wall.next_cost())
	assert_bool(wall.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]).is_true()
	for _tick in 900:
		if wall.standing():
			break
		_steps(1)
	assert_int(wall.level).is_equal(1)
	assert_bool(wall.standing()).is_true()
	assert_float(SimLoop.units.xs[SimLoop.units.index_of(builder)]).is_equal(wall.x)
	assert_int(wall.next_cost()).is_greater(wall.costs[0])


func test_perder_o_construtor_pausa_a_obra_e_outro_retoma() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(RealmLadder.FUNDADO)
	var wall := _wall()
	var builder := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"builder"), 1, wall.x
	)
	_drop(wall, wall.next_cost())
	_steps(6)
	var progress := wall.progress
	SimLoop.units.damage(builder, SimLoop.units.max_healths[SimLoop.units.index_of(builder)])
	_steps(60)
	assert_float(wall.progress).is_equal(progress)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), 1, wall.x)
	_steps(6)
	assert_float(wall.progress).is_greater(progress)


func _walk(x: float) -> void:
	for _tick in 1200:
		var i := SimLoop.units.index_of(SimLoop.king_id)
		if SimLoop.units.xs[i] == x:
			return
		SimLoop.units.set_target_x(SimLoop.king_id, x)
		_steps(1)
	assert_float(SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)]).is_equal(x)


func _pay_here(amount: int) -> void:
	for _coin in amount:
		var i := SimLoop.units.index_of(SimLoop.king_id)
		SimLoop.intents.queue(
			IntentQueue.Kind.DROP_COIN,
			{
				&"x": SimLoop.units.xs[i],
				&"band": Band.Kind.SURFACE,
				&"amount": 1,
				&"source": Verbs.JOGADOR
			}
		)
		_steps(20)


func test_recrutar_comprar_martelo_e_erguer_o_primeiro_muro_so_com_gestos() -> void:
	_walk(SimLoop.seat.cart_x)
	var seat := RealmLadder.seat(SimLoop.builds)
	_walk(seat.x)
	_pay_here(seat.next_cost())
	_steps(180)
	assert_bool(seat.standing()).is_true()
	var id := UnitSystem.NENHUM
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == &"vagrant" and SimLoop.units.xs[i] < seat.x:
			if absf(SimLoop.units.xs[i] - seat.x) < 640.0:
				id = SimLoop.units.ids[i]
	assert_int(id).is_not_equal(UnitSystem.NENHUM)
	var worker := SimLoop.units.index_of(id)
	_walk(SimLoop.units.xs[worker] + 70.0)
	_pay_here(1)
	_steps(60)
	assert_int(SimLoop.units.owners[worker]).is_equal(1)
	var bench := _bench()
	_walk(bench.x)
	_pay_here(int(bench.effects[&"craft_cost"]))
	_steps(180)
	assert_str(String(SimLoop.units.data_ids[worker])).is_equal("builder")
	var wall := _wall()
	_walk(wall.x)
	_pay_here(wall.next_cost())
	_walk(SimLoop.core_x)
	for _tick in 900:
		if wall.standing():
			break
		_steps(1)
	assert_bool(wall.standing()).is_true()
	assert_int(wall.level).is_equal(1)
	var people := SimLoop.units.count()
	SimLoop.load_world(SimLoop.world())
	assert_int(SimLoop.units.count()).is_equal(people)
	assert_str(String(SimLoop.units.data_ids[worker])).is_equal("builder")
	assert_bool(wall.standing()).is_true()
	assert_bool(_bench().standing()).is_true()


func test_retomar_nao_ressuscita_a_banca_destruida() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(RealmLadder.FUNDADO)
	FoundationWatch.founded_tools()
	var bench := _bench()
	SimLoop.builds.damage(bench.id, bench.max_health())
	SimLoop.load_world(SimLoop.world())
	assert_int(bench.state).is_equal(BuildSlot.State.RUIN)


func test_o_guia_diz_que_falta_construtor_e_nomeia_o_proximo_degrau() -> void:
	RealmLadder.seat(SimLoop.builds).raise_to(2)
	var wall := _wall()
	var values := {"name": "Muralha", "cost": wall.next_cost(), "drop": "Espaço", "assume": "E"}
	assert_str(WallGuide.offer(wall, values)).is_equal(
		TranslationServer.translate(&"CONTEXT_WALL_BUILDER").format(values)
	)
	assert_str(WallGuide.building(wall, values)).is_equal(
		TranslationServer.translate(&"CONTEXT_WALL_WAITING").format(values)
	)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), 1, SimLoop.core_x)
	wall.raise_to(1)
	values["cost"] = wall.next_cost()
	var offer := WallGuide.offer(wall, values)
	assert_str(offer).contains(TranslationServer.translate(&"WALL_PALISADE"))
	assert_str(WallGuide.building(wall, values)).is_equal(
		TranslationServer.translate(&"CONTEXT_WALL_BUILDING").format(values)
	)
