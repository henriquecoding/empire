# tests/target_picker_test.gd — "Escolher alvos", que e o passo do §50 com regra
# propria: marcado > atual se ainda serve > mais proximo em faixa atingivel.
#
# O termo do meio e o que se prova aqui com mais cuidado: "nunca reescolher se o
# alvo atual serve — e o que evita o desperdicio de flechas que o Kingdom tem".
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const NUCLEO := 0.0


func _tabela(tabela: StringName) -> Dictionary:
	var mapa := {}
	for r in Registry.entries(tabela):
		mapa[r.get(&"id")] = r
	return mapa


func _escolha() -> TargetPicker:
	return TargetPicker.new(_tabela(&"units"), _tabela(&"creatures"))


func _arqueiro(unidades: UnitSystem, estado: GameState, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU_IMPERIO, x)


func _bicho(criaturas: CreatureSystem, estado: GameState, id: StringName, x: float) -> int:
	return criaturas.spawn(estado, Registry.entry(&"creatures", id), x, NUCLEO)


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


func test_escolhe_o_mais_proximo_em_alcance() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var perto := _bicho(criaturas, estado, &"crawler", 30.0)
	_bicho(criaturas, estado, &"crawler", 150.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(perto)


func test_fora_de_alcance_nao_ha_alvo_nenhum() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var alcance := (Registry.entry(&"units", &"archer") as UnitData).range_px
	_bicho(criaturas, estado, &"crawler", float(alcance) * 2.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(TargetPicker.NENHUM)


func test_nao_reescolhe_enquanto_o_atual_servir() -> void:
	# Um segundo bicho mais perto NAO rouba o alvo: trocar de alvo a cada tick e
	# exatamente o desperdicio de flechas que a §50 manda evitar.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var primeiro := _bicho(criaturas, estado, &"crawler", 100.0)
	var escolha := _escolha()
	escolha.choose(unidades, criaturas, null)

	_bicho(criaturas, estado, &"crawler", 10.0)
	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(primeiro)


func test_morto_o_alvo_escolhe_outro() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var primeiro := _bicho(criaturas, estado, &"crawler", 100.0)
	var segundo := _bicho(criaturas, estado, &"crawler", 10.0)
	var escolha := _escolha()
	escolha.choose(unidades, criaturas, null)

	criaturas.remove(primeiro)
	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(segundo)


func test_o_alvo_marcado_ganha_ao_mais_proximo() -> void:
	# §24: o gatilho direito, e so o Arqueiro o tem.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	_bicho(criaturas, estado, &"crawler", 30.0)
	var longe := _bicho(criaturas, estado, &"crawler", 150.0)
	var escolha := _escolha()

	escolha.mark(arqueiro, longe)
	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(longe)


func test_esquecer_apaga_a_marca_e_o_alvo() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 30.0)
	var escolha := _escolha()
	escolha.mark(arqueiro, bicho)
	escolha.choose(unidades, criaturas, null)

	escolha.forget(arqueiro)

	assert_int(escolha.target_of(arqueiro)).is_equal(TargetPicker.NENHUM)


func test_entrar_em_combate_poe_em_fight_e_sair_devolve_a_work() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 50.0)
	var escolha := _escolha()
	var i := unidades.index_of(arqueiro)

	escolha.choose(unidades, criaturas, null)
	assert_int(unidades.states[i]).is_equal(UnitFsm.State.FIGHT)

	criaturas.remove(bicho)
	escolha.choose(unidades, criaturas, null)

	assert_int(unidades.states[i]).is_equal(UnitFsm.State.WORK)


func test_quem_luta_nao_anda() -> void:
	# A §52 poe FIGHT na tabela e diz que "nada" custa em movimento: quem esta a
	# bater fica onde esta, mesmo com um posto do outro lado do mapa.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 0.0)
	unidades.set_target_x(arqueiro, 900.0)
	_bicho(criaturas, estado, &"crawler", 50.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)
	unidades.tick_movement(1.0)

	assert_float(unidades.xs[unidades.index_of(arqueiro)]).is_equal(0.0)


func test_a_criatura_prefere_o_muro_que_a_trava() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, 100.0)
	_arqueiro(unidades, estado, 90.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 110.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, obras)

	var c := criaturas.index_of(bicho)
	assert_int(criaturas.target_slots[c]).is_equal(muro.id)
	assert_int(criaturas.target_ids[c]).is_equal(CreatureSystem.NENHUM)


func test_sem_muro_a_criatura_escolhe_a_tropa() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := _arqueiro(unidades, estado, 100.0)
	var bicho := _bicho(criaturas, estado, &"crawler", 110.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(criaturas.target_ids[criaturas.index_of(bicho)]).is_equal(arqueiro)


func test_quem_so_ataca_muralha_ignora_as_tropas() -> void:
	# O Ariete de lodo tem target_priority `walls_only` (creatures.csv): ele nao
	# olha para quem esta atras do muro, e e essa a ameaca que ele e.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	_arqueiro(unidades, estado, 100.0)
	var ariete := _bicho(criaturas, estado, &"slime_ram", 110.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(criaturas.target_ids[criaturas.index_of(ariete)]).is_equal(CreatureSystem.NENHUM)


func test_os_ids_saem_sempre_por_ordem_crescente() -> void:
	# §42: a ordem das colunas nao e estavel, e por isso nada que afete a
	# simulacao pode iterar por indice.
	var baralhados := PackedInt32Array([9, 2, 7, 1])

	assert_array(TargetPicker.ids_por_ordem(baralhados)).is_equal([1, 2, 7, 9])
	assert_array(baralhados).is_equal([9, 2, 7, 1])
