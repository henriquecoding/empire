# tests/subsolo_causa_test.gd — o subsolo no jogo depois do relatorio de 05/10/2026 (ADR
# 0072): a cave real tem chao para la da escada, o bau e a subida sao alvos diferentes, a
# recompensa da masmorra nasce dentro e uma vez, e uma entrada so existe com uma causa e
# com tecto no povo dela. O contrato puro esta no subsolo_area_util_test.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SEMENTE := 20261005
const OUTRAS := 24

var r: UnderRules


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	r = UnderWatch.rules()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _sede() -> int:
	var under := SimLoop.field.under
	for k in under.count():
		if under.key_of(k) == UnderWatch.HATCH_KEY:
			return k
	return -1


func _no_subsolo(x: float) -> void:
	SimLoop.units.bands[_rei()] = Band.Kind.UNDERGROUND
	SimLoop.units.xs[_rei()] = x
	SimLoop.units.clear_target(SimLoop.king_id)


func _gerar_tudo() -> void:
	var limites := Frontier.walk_limits()
	for x in [limites.y, limites.x]:
		SimLoop.units.xs[_rei()] = x
		SimLoop.units.clear_target(SimLoop.king_id)
		SimLoop.step(PASSO)


func _ruinas() -> Array[Vector2i]:
	var saida: Array[Vector2i] = []
	var terras := SimLoop.field.wilds
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			if int(terras.at(lado, k).get(WildSegments.PASSAGEM, 0)) > 0:
				saida.append(Vector2i(lado, k))
	return saida


func test_a_cave_real_no_estagio_zero_tem_chao_para_la_da_escada() -> void:
	LastCartWatch.claim(&"road")
	var k := _sede()
	var boca := SimLoop.field.under.mouth_of(k)
	UnderWatch.enter(boca, Band.PASSAGE_PX)
	var span := SimLoop.field.under.span(k)
	assert_float(span.y - span.x).is_greater_equal(r.cellar_base_px - 0.01)
	assert_str(String(SimLoop.field.under.why(k))).is_equal(String(UnderFit.OK))
	var bau := UnderReserve.chest_x(SimLoop.field.under, k)
	assert_float(absf(bau - boca)).is_greater(Band.PASSAGE_PX * 2.0)
	assert_str(CellarWatch.chest_at(boca)).is_equal("")
	assert_str(CellarWatch.chest_at(bau)).is_equal(UnderWatch.HATCH_KEY)


func test_o_bau_e_a_subida_sao_alvos_diferentes() -> void:
	LastCartWatch.claim(&"road")
	var k := _sede()
	var boca := SimLoop.field.under.mouth_of(k)
	UnderWatch.enter(boca, Band.PASSAGE_PX)
	var bau := UnderReserve.chest_x(SimLoop.field.under, k)
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 4)
	_no_subsolo(boca)
	SimLoop.units.carried_coins[_rei()] = 0
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.bands[_rei()]).is_equal(Band.Kind.SURFACE)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(4)
	_no_subsolo(bau)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.bands[_rei()]).is_equal(Band.Kind.UNDERGROUND)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_less(4)


func test_a_escavacao_cresce_um_passo_sem_fragmentos() -> void:
	LastCartWatch.claim(&"road")
	var k := _sede()
	UnderWatch.enter(SimLoop.field.under.mouth_of(k), Band.PASSAGE_PX)
	var antes := SimLoop.field.under.span(k)
	var salas := SimLoop.field.under.rooms(k).size()
	for slot in SimLoop.builds.slots:
		if slot.kind == CellarWatch.EXCAVATION:
			slot.level = 1
	CellarWatch.sync()
	var step := LastCartWatch.rules().cellar_step_px
	var depois := SimLoop.field.under.span(k)
	assert_float(depois.y - depois.x).is_equal_approx(antes.y - antes.x + step, 0.01)
	assert_int(SimLoop.field.under.rooms(k).size()).is_equal(salas + 1)
	assert_int(SimLoop.builds.cellar_room).is_greater_equal(1)


func test_um_ladrao_leva_o_que_lhe_cabe_e_deixa_o_cair_se_morrer() -> void:
	LastCartWatch.claim(&"road")
	var k := _sede()
	UnderWatch.enter(SimLoop.field.under.mouth_of(k), Band.PASSAGE_PX)
	var bau := UnderReserve.chest_x(SimLoop.field.under, k)
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, r.thief_carry + 4)
	var dados := Registry.entry(&"creatures", &"burrower") as CreatureData
	var id := SimLoop.creatures.spawn(SimLoop.state, dados, bau, bau)
	var c := SimLoop.creatures.index_of(id)
	SimLoop.creatures.bands[c] = Band.Kind.UNDERGROUND
	var levava := SimLoop.creatures.coin_drops[c]
	CellarWatch.steal()
	CellarWatch.steal()
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(4)
	assert_int(SimLoop.creatures.coin_drops[c]).is_equal(levava + r.thief_carry)
	assert_int(SimLoop.treasury.carried_by(id)).is_equal(r.thief_carry)


func test_a_recompensa_da_masmorra_nasce_dentro_e_uma_vez() -> void:
	_gerar_tudo()
	var under := SimLoop.field.under
	var postas := 0
	for onde in _ruinas():
		var entrada := SimLoop.field.wilds.at(onde.x, onde.y)
		if not entrada.has(&"dungeon"):
			continue
		var reward: Dictionary = entrada[&"dungeon"]
		assert_bool(reward.has(DungeonWatch.POR_POR)).is_true()
		var boca := SimLoop.field.wilds.subject_x(onde.x, onde.y, SimLoop.world_width)
		var moedas := SimLoop.coins.count()
		UnderWatch.enter(boca, Band.PASSAGE_PX)
		assert_bool(reward.has(DungeonWatch.POR_POR)).is_false()
		var x := float(reward[DungeonWatch.POSTA])
		assert_float(absf(x - boca)).is_greater(r.arrival_px * 0.5 + r.clear_px)
		assert_float(x).is_between(
			under.span(under.site_at(boca)).x, under.span(under.site_at(boca)).y
		)
		var criaturas := SimLoop.creatures.count()
		var depois := SimLoop.coins.count()
		UnderWatch.enter(boca, Band.PASSAGE_PX)
		assert_int(SimLoop.coins.count()).is_equal(depois)
		assert_int(SimLoop.creatures.count()).is_equal(criaturas)
		if reward[&"kind"] == &"treasure":
			assert_int(depois).is_greater(moedas)
		postas += 1
	assert_int(postas).is_greater(0)


func test_ruinas_alem_do_tecto_ficam_sem_entrada_e_sem_tesouro() -> void:
	_gerar_tudo()
	var terras := SimLoop.field.wilds
	var bocas := UnderWatch.mouths(SimLoop.field)
	var por_povo := {}
	for onde in _ruinas():
		var entrada := terras.at(onde.x, onde.y)
		var x := terras.subject_x(onde.x, onde.y, SimLoop.world_width)
		var povo := Vector2i(onde.x, terras.plan.people(onde.x, onde.y))
		if entrada.get(DungeonWatch.ENTRADA) == DungeonWatch.FECHADA:
			assert_bool(entrada.has(&"dungeon")).is_false()
			assert_bool(Passages.near(x, bocas)).is_false()
			continue
		por_povo[povo] = int(por_povo.get(povo, 0)) + 1
	for povo: Vector2i in por_povo:
		assert_int(int(por_povo[povo])).is_less_equal(r.optional_max)


## Uma caverna so onde ha rocha que a explique: a falha de um limiar. Sem escada, sem
## tesouro, e com chao. Procura-se uma semente que a tenha.
func test_a_falha_de_rocha_abre_uma_caverna_sem_tesouro() -> void:
	var achou := false
	for s in OUTRAS:
		SimLoop.stop()
		SimLoop.start(SEMENTE + s)
		Greybox.build()
		_gerar_tudo()
		var under := SimLoop.field.under
		for k in under.count():
			if under.kind_of(k) != UndergroundSites.CAVE or not under.usable(k):
				continue
			var spec: Dictionary = under.sites[k][UndergroundSites.SPEC]
			var onde: Vector2i = spec[UndergroundSites.SEGMENT]
			var entrada := SimLoop.field.wilds.at(onde.x, onde.y)
			assert_str(String(entrada[WildSegments.ASSUNTO])).is_equal(String(UnderWatch.FALHA))
			assert_bool(entrada.has(&"dungeon")).is_false()
			UnderWatch.enter(under.mouth_of(k), Band.PASSAGE_PX)
			assert_str(String(under.why(k))).is_equal(String(UnderFit.OK))
			assert_str(String(under.rooms(k)[0][UndergroundSites.KIND])).is_not_equal("stair")
			achou = true
			break
		if achou:
			break
	assert_bool(achou).is_true()


## O item 5 da demonstracao do relatorio (§16): um save antigo com a cave de 96 px, so a
## escada, repara-se ao carregar sem mexer no dinheiro, e a segunda vez nao faz nada.
func test_um_save_antigo_com_a_cave_so_de_escada_repara_se_e_guarda_o_dinheiro() -> void:
	LastCartWatch.claim(&"road")
	var boca := SimLoop.field.under.mouth_of(_sede())
	UnderWatch.enter(boca, Band.PASSAGE_PX)
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 6)
	var mundo := SimLoop.world()
	var gravado: Dictionary = mundo[&"under"]
	var antiga := {UndergroundSites.A: boca - 48.0, UndergroundSites.B: boca + 48.0}
	antiga.merge({UndergroundSites.KIND: &"vault", UndergroundSites.ROLL: 0.5})
	gravado[UndergroundSites.LAYOUTS][UnderWatch.HATCH_KEY] = [antiga]
	gravado[UndergroundSites.META] = {}
	SimLoop.load_world(mundo)
	var k := _sede()
	var span := SimLoop.field.under.span(k)
	assert_str(String(SimLoop.field.under.why(k))).is_equal(String(UnderFit.OK))
	assert_float(span.y - span.x).is_greater_equal(r.cellar_base_px - 0.01)
	assert_float(absf(UnderReserve.chest_x(SimLoop.field.under, k) - boca)).is_greater(
		Band.PASSAGE_PX * 2.0
	)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(6)
	var salas := SimLoop.field.under.rooms(k).duplicate(true)
	SimLoop.load_world(SimLoop.world())
	assert_bool(SimLoop.field.under.rooms(_sede()) == salas).is_true()
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(6)
