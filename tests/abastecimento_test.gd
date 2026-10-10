# tests/abastecimento_test.gd — as aljavas das tropas, e o reino que as repoe (Q-163, o
# dono a 30/09/2026).
#
# "As classes jogaveis nao tem recursos de batalha limitados, mas faz sentido as tropas
# terem recursos limitados [...] que tem que estar sempre a economia em dia para manter o
# armazenamento do exercito em dia." Cada tiro gasta uma flecha; com a aljava vazia o
# arqueiro nao dispara; a alvorada repoe-a, a um preco, enquanto a bolsa chegar.
extends GdUnitTestSuite

const MEU := 1

var _estado := GameState.new()
var _u := UnitSystem.new()


func before_test() -> void:
	_estado = GameState.new()
	_u = UnitSystem.new()


func _por(id: StringName) -> int:
	return _u.spawn(_estado, Registry.entry(&"units", id) as UnitData, MEU, 0.0)


func _dados(id: StringName) -> UnitData:
	return Registry.entry(&"units", id) as UnitData


func test_a_aljava_esvazia_e_o_arqueiro_para_de_disparar() -> void:
	var s := Supply.new()
	var i := _u.index_of(_por(&"archer"))
	var arco := _dados(&"archer")
	assert_int(arco.ammo).is_greater(0)
	for _k in arco.ammo:
		assert_bool(s.can_shoot(_u, i, arco)).is_true()
		s.shoot(_u, i, arco)
	assert_bool(s.can_shoot(_u, i, arco)).is_false()
	assert_int(s.left(_u, i, arco)).is_equal(0)


## O corpo da classe jogavel e o rei nao tem teto.
func test_as_classes_jogaveis_nao_tem_teto() -> void:
	var s := Supply.new()
	for id in [&"archer_hero", &"monarch"]:
		var i := _u.index_of(_por(id))
		for _k in 100:
			s.shoot(_u, i, _dados(id))
		assert_bool(s.can_shoot(_u, i, _dados(id))).is_true()


## A alvorada repoe pela ordem dos ids, `por_moeda` flechas por moeda, ate a bolsa.
func test_a_alvorada_repoe_ate_onde_a_bolsa_chega() -> void:
	var s := Supply.new()
	var a := _u.index_of(_por(&"archer"))
	var b := _u.index_of(_por(&"archer"))
	var arco := _dados(&"archer")
	for _k in 6:
		s.shoot(_u, a, arco)
		s.shoot(_u, b, arco)
	var gasto := s.restock(_u, MEU, 2, 4)  # 2 moedas, 4 flechas cada: 8 flechas
	assert_int(gasto).is_equal(2)
	assert_int(s.missing(_u, a)).is_equal(0)
	assert_int(s.missing(_u, b)).is_equal(4)
	assert_int(s.restock(_u, MEU, 10, 4)).is_equal(1)
	assert_int(s.missing(_u, b)).is_equal(0)


## Quem morreu ou deixou de ser teu nao se abastece, e esquece-se; o save guarda o resto.
func test_quem_morreu_esquece_se_e_o_save_guarda() -> void:
	var s := Supply.new()
	var a := _u.index_of(_por(&"archer"))
	var b := _u.index_of(_por(&"archer"))
	var arco := _dados(&"archer")
	s.shoot(_u, a, arco)
	s.shoot(_u, b, arco)
	_u.states[a] = UnitFsm.State.DEAD
	var copia := Supply.new()
	copia.from_dict(s.to_dict())
	assert_int(copia.missing(_u, b)).is_equal(1)
	assert_int(copia.restock(_u, MEU, 0, 4)).is_equal(0)
	assert_bool(copia.spent.has(_u.ids[a])).is_false()


## No combate: com a aljava vazia o arqueiro nao dispara nem sorteia; cheia, cada tiro
## gasta uma flecha.
func test_no_combate_a_aljava_vazia_nao_dispara() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var unidades := SimFactory.by_id(&"units")
	var postos := JobBoard.new(curva, SimFactory.by_id(&"jobs"), unidades)
	var bichos := SimFactory.by_id(&"creatures")
	var combate := CombatSystem.new(unidades, bichos, ContactQueue.new(curva), postos)
	combate.supply = Supply.new()
	var arqueiro := _por(&"archer")
	var c := CreatureSystem.new()
	c.spawn(_estado, Registry.entry(&"creatures", &"crawler") as CreatureData, 50.0, 0.0)
	var arco := _dados(&"archer")
	combate.supply.spent[arqueiro] = arco.ammo
	combate.choose(_u, c, null)
	var nada := func() -> float: return 0.0
	assert_array(combate.resolve(_u, c, null, nada)).is_empty()
	combate.supply.spent.clear()
	combate.choose(_u, c, null)
	assert_array(combate.resolve(_u, c, null, nada)).is_not_empty()
	assert_int(combate.supply.missing(_u, _u.index_of(arqueiro))).is_equal(1)


## No jogo: com a banca do arco de pe, a alvorada repoe a aljava e cobra-a ao rei.
func test_no_jogo_a_banca_repoe_na_alvorada() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260930)
	Greybox.build()
	var gastos: Array = []
	var ouvir := func(quanto: int, porque: StringName) -> void:
		if porque == &"arrows":
			gastos.append(quanto)
	EventBus.coin_spent.connect(ouvir)
	var arqueiro := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"archer"), Greybox.MEU_IMPERIO, SimLoop.core_x
	)
	for vaga in SimLoop.builds.slots:
		if vaga.kind == RulesFactory.rules().ammo_depot:
			vaga.level = 1
			vaga.state = BuildSlot.State.DONE
			vaga.health = vaga.max_health()
	SimLoop.field.supply.spent[arqueiro] = RulesFactory.rules().arrows_per_coin
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 5)
	SimLoop.step(1.0 / 30.0)  # um passo do primeiro dia: o campo fica a conhecer as obras
	SimLoop.state.day = 2  # a alvorada do segundo dia, sem a noite pelo meio
	ClockService.seek(2, 0.0)
	SimLoop.step(1.0 / 30.0)
	EventBus.flush()
	assert_bool(SimLoop.field.supply.spent.has(arqueiro)).is_false()
	assert_array(gastos).is_equal([1])
	EventBus.coin_spent.disconnect(ouvir)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
