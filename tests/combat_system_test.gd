# tests/combat_system_test.gd — a ordem de resolucao do §50, que e a parte que o
# dossie diz ser a mais importante: "sem uma ordem fixa, a mesma noite da
# resultados diferentes e a promessa da seed morre".
#
# O sorteio entra de fora. Um que devolve sempre 0 acerta sempre; um que devolve
# sempre 1 nunca acerta — e assim a precisao de 0,34 do arqueiro testa-se sem
# correr mil noites a espera da media.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const PASSO := 1.0 / 30.0
const SEMENTE := 20260915
const NUCLEO := 0.0


func _tabela(tabela: StringName) -> Dictionary:
	var mapa := {}
	for r in Registry.entries(tabela):
		mapa[r.get(&"id")] = r
	return mapa


func _combate() -> CombatSystem:
	return CombatSystem.new(_tabela(&"units"), _tabela(&"creatures"))


func _sempre(valor: float) -> Callable:
	return func() -> float: return valor


func _arqueiro(unidades: UnitSystem, estado: GameState, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU_IMPERIO, x)


func _bicho(criaturas: CreatureSystem, estado: GameState, id: StringName, x: float) -> int:
	return criaturas.spawn(estado, Registry.entry(&"creatures", id), x, NUCLEO)


func test_em_alcance_a_tropa_bate_e_a_criatura_perde_vida() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 50.0)
	var combate := _combate()
	var dados := Registry.entry(&"units", &"archer") as UnitData

	combate.choose(unidades, criaturas, null)
	var eventos := combate.resolve(unidades, criaturas, null, _sempre(0.0))

	assert_int(combate.target_of(arqueiro)).is_equal(bicho)
	assert_int(criaturas.healths[criaturas.index_of(bicho)]).is_equal(
		(Registry.entry(&"creatures", &"crawler") as CreatureData).max_health - dados.damage
	)
	assert_array(eventos).is_not_empty()


func test_a_precisao_e_um_roll_e_nao_um_multiplicador() -> void:
	# §50: "accuracy_open = 0,34 em campo aberto nao e um multiplicador de dano —
	# e um roll". Um sorteio acima da precisao nunca acerta.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	_arqueiro(unidades, estado, 0.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 50.0)
	var dados := Registry.entry(&"creatures", &"crawler") as CreatureData
	var combate := _combate()

	combate.choose(unidades, criaturas, null)
	var eventos := combate.resolve(unidades, criaturas, null, _sempre(1.0))

	assert_int(criaturas.healths[criaturas.index_of(bicho)]).is_equal(dados.max_health)
	assert_bool(eventos[0][CombatSystem.ACERTOU]).is_false()


func test_o_intervalo_de_ataque_e_respeitado() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	_arqueiro(unidades, estado, 0.0)
	_bicho(criaturas, estado, &"crawler", 50.0)
	var combate := _combate()
	var intervalo := (Registry.entry(&"units", &"archer") as UnitData).attack_interval

	combate.choose(unidades, criaturas, null)
	var golpes := _contar_ataques(combate.resolve(unidades, criaturas, null, _sempre(1.0)))
	combate.choose(unidades, criaturas, null)
	golpes += _contar_ataques(combate.resolve(unidades, criaturas, null, _sempre(1.0)))

	assert_int(golpes).is_equal(1)

	unidades.tick_movement(intervalo)
	combate.choose(unidades, criaturas, null)
	golpes += _contar_ataques(combate.resolve(unidades, criaturas, null, _sempre(1.0)))

	assert_int(golpes).is_equal(2)


func test_a_morte_larga_o_que_transportava() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	_arqueiro(unidades, estado, 0.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 50.0)
	var dados := Registry.entry(&"creatures", &"crawler") as CreatureData
	var combate := _combate()

	var mortes := 0
	var moedas := 0
	for _t in 200:
		unidades.tick_movement(PASSO)
		combate.choose(unidades, criaturas, null)
		for e in combate.resolve(unidades, criaturas, null, _sempre(0.0)):
			if e[CombatSystem.CHAVE] == CombatSystem.EV_MORTE:
				mortes += 1
				moedas += e[CombatSystem.MOEDAS]

	assert_int(mortes).is_equal(1)
	assert_int(moedas).is_equal(dados.coin_drop)
	assert_int(criaturas.count()).is_equal(0)


func test_a_criatura_bate_no_muro_que_a_trava_e_nao_em_quem_esta_atras() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, 100.0)
	_arqueiro(unidades, estado, 90.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 110.0)
	var combate := _combate()
	var vida := muro.health

	combate.choose(unidades, criaturas, obras)
	combate.resolve(unidades, criaturas, obras, _sempre(0.0))

	var c := criaturas.index_of(bicho)
	assert_int(criaturas.target_slots[c]).is_equal(muro.id)
	assert_int(criaturas.target_ids[c]).is_equal(CreatureSystem.NENHUM)
	assert_int(muro.health).is_less(vida)


func test_ninguem_morre_e_ainda_ataca_no_mesmo_tick() -> void:
	# §50: "recolhe as mortes numa lista e so as aplica no fim do passo". Dois
	# arqueiros sobre a mesma criatura no mesmo tick: os dois disparam, e o
	# segundo nao dispara para um cadaver — dispara para quem ainda esta vivo.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	for x in [0.0, 10.0, 20.0]:
		_arqueiro(unidades, estado, x)
	_bicho(criaturas, estado, &"crawler", 50.0)
	var combate := _combate()

	combate.choose(unidades, criaturas, null)
	var eventos := combate.resolve(unidades, criaturas, null, _sempre(0.0))

	assert_int(_contar_ataques(eventos)).is_equal(3)
	assert_int(_contar_mortes(eventos)).is_equal(1)


func test_a_mesma_semente_da_a_mesma_noite() -> void:
	var correr := func() -> Array[String]:
		RngService.configure(SEMENTE)
		var estado := GameState.new()
		var unidades := UnitSystem.new()
		var criaturas := CreatureSystem.new()
		for x in [0.0, 30.0, 60.0]:
			_arqueiro(unidades, estado, x)
		for x in [80.0, 120.0, 160.0]:
			_bicho(criaturas, estado, &"crawler", x)
		var combate := _combate()
		var sorteio := func() -> float: return RngService.unit_float(&"combat")
		var registo: Array[String] = []
		for _t in 300:
			unidades.tick_movement(PASSO)
			criaturas.tick_movement(PASSO)
			combate.choose(unidades, criaturas, null)
			for e in combate.resolve(unidades, criaturas, null, sorteio):
				registo.append(str(e))
		return registo

	var primeira: Array[String] = correr.call()
	assert_array(primeira).is_not_empty()
	assert_array(correr.call()).is_equal(primeira)


func _muro(obras: BuildSystem, x: float) -> BuildSlot:
	var estacas := Registry.entry(&"walls", &"stakes") as WallData
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = estacas.id
	vaga.blocks = true
	vaga.width = 1.0
	vaga.costs = PackedInt32Array([estacas.cost])
	vaga.works = PackedFloat32Array([1.0])
	vaga.healths = PackedInt32Array([estacas.max_health_b])
	obras.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _contar_ataques(eventos: Array[Dictionary]) -> int:
	var n := 0
	for e in eventos:
		if e[CombatSystem.CHAVE] == CombatSystem.EV_ATAQUE:
			n += 1
	return n


func _contar_mortes(eventos: Array[Dictionary]) -> int:
	var n := 0
	for e in eventos:
		if e[CombatSystem.CHAVE] == CombatSystem.EV_MORTE:
			n += 1
	return n
