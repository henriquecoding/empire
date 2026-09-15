# tests/build_system_test.gd — o §55: a obra existe quando uma moeda cai nela, e
# o progresso e presenca e nao tempo.
#
# Os numeros vem todos de data/: o custo e o build_work do canteiro sao os de
# buildings.csv, a escada do muro e a de walls.csv. Nenhum esta escrito aqui.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const PASSO := 1.0 / 30.0


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _canteiro() -> BuildingData:
	return Registry.entry(&"buildings", &"farm") as BuildingData


func _obras() -> BuildSystem:
	return BuildSystem.new()


func _vaga_de_canteiro(x: float) -> BuildSlot:
	var d := _canteiro()
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = d.id
	vaga.costs = PackedInt32Array([d.cost])
	vaga.works = PackedFloat32Array([d.build_work])
	vaga.healths = PackedInt32Array([d.max_health])
	vaga.width = float(d.width_px)
	return vaga


func _vaga_de_muro(x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.blocks = true
	for r in Registry.entries(&"walls"):
		var w := r as WallData
		vaga.costs.append(w.cost)
		vaga.works.append(float(w.cost))
		vaga.healths.append(w.max_health_b)
	vaga.kind = &"stakes"
	vaga.width = _canteiro().width_px
	return vaga


func _obreiro(unidades: UnitSystem, estado: GameState, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU_IMPERIO, x)


func _pagar(obras: BuildSystem, vaga: BuildSlot, quanto: int) -> Array[Dictionary]:
	var estado := GameState.new()
	var moedas := CoinSystem.new(_curva())
	for _k in quanto:
		var id := moedas.drop(estado, vaga.x, vaga.band, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1
	return obras.absorb(moedas)


func test_uma_vaga_por_construir_comeca_vazia() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))

	assert_int(vaga.id).is_equal(0)
	assert_int(vaga.state).is_equal(BuildSlot.State.EMPTY)
	assert_int(vaga.next_cost()).is_equal(_canteiro().cost)
	assert_bool(vaga.standing()).is_false()


func test_a_obra_existe_quando_uma_moeda_cai_nela() -> void:
	# §55, a frase inteira: nao ha menu de construcao, ha uma moeda no chao.
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))

	var eventos := _pagar(obras, vaga, 1)

	assert_int(vaga.paid).is_equal(1)
	assert_array(eventos).is_not_empty()
	assert_int(vaga.state).is_equal(BuildSlot.State.EMPTY)


func test_pago_o_custo_a_obra_levanta_andaime() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))

	_pagar(obras, vaga, _canteiro().cost)

	assert_int(vaga.state).is_equal(BuildSlot.State.SCAFFOLD)
	assert_int(vaga.paid).is_equal(0)


func test_o_progresso_e_presenca_e_nao_tempo() -> void:
	# "O progresso avanca enquanto ele estiver presente — nao por tempo
	# decorrido. E o que torna os construtores um recurso real." (§55)
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))
	_pagar(obras, vaga, _canteiro().cost)
	var estado := GameState.new()
	var unidades := UnitSystem.new()

	for _t in 100:
		obras.tick(PASSO, unidades)
	assert_float(vaga.progress).is_equal(0.0)

	_obreiro(unidades, estado, vaga.x)
	for _t in 100:
		obras.tick(PASSO, unidades)
	assert_float(vaga.progress).is_greater(0.0)


func test_a_obra_acaba_e_fica_de_pe_com_a_vida_do_nivel() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))
	_pagar(obras, vaga, _canteiro().cost)
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_obreiro(unidades, estado, vaga.x)

	var acabou := false
	for _t in int(_canteiro().build_work / PASSO) + 2:
		for e in obras.tick(PASSO, unidades):
			acabou = acabou or e[&"kind"] == BuildSystem.EV_COMPLETA

	assert_bool(acabou).is_true()
	assert_int(vaga.level).is_equal(1)
	assert_int(vaga.state).is_equal(BuildSlot.State.DONE)
	assert_int(vaga.health).is_equal(_canteiro().max_health)
	assert_bool(vaga.standing()).is_true()


func test_o_muro_sobe_os_cinco_niveis_da_tabela_do_10() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_muro(0.0))
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_obreiro(unidades, estado, vaga.x)

	var niveis: Array[int] = []
	for degrau in vaga.costs.size():
		_pagar(obras, vaga, vaga.next_cost())
		for _t in int(vaga.works[degrau] / PASSO) + 2:
			for e in obras.tick(PASSO, unidades):
				if e[&"kind"] == BuildSystem.EV_COMPLETA:
					niveis.append(e[&"level"])

	assert_array(niveis).is_equal([1, 2, 3, 4, 5])
	assert_int(vaga.next_cost()).is_equal(BuildSlot.NENHUM)


func test_no_topo_nao_absorve_mais_moedas() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_canteiro(100.0))
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE

	assert_array(_pagar(obras, vaga, 3)).is_empty()
	assert_int(vaga.paid).is_equal(0)


func test_o_dano_leva_a_obra_a_ruina_e_anuncia_a_brecha() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_muro(0.0))
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()

	var tocada := obras.damage(vaga.id, 1)
	assert_int(vaga.state).is_equal(BuildSlot.State.DAMAGED)
	assert_int(tocada[0][&"kind"]).is_equal(BuildSystem.EV_DANO)

	var caiu := obras.damage(vaga.id, vaga.max_health())
	assert_int(vaga.state).is_equal(BuildSlot.State.RUIN)
	assert_bool(vaga.standing()).is_false()
	var tipos: Array[int] = []
	for e in caiu:
		tipos.append(e[&"kind"])
	assert_array(tipos).contains([BuildSystem.EV_ROMPIDA])


func test_so_o_que_esta_de_pe_e_que_barra() -> void:
	# O que faz um muro valer a pena e parar quem vem: uma criatura a caminho do
	# nucleo bate no primeiro que estiver de pe entre ela e ele (§10, §50).
	var obras := _obras()
	var vaga := obras.post(_vaga_de_muro(500.0))

	assert_object(obras.barrier(1000.0, 0.0, Band.Kind.SURFACE)).is_null()

	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()

	assert_object(obras.barrier(1000.0, 0.0, Band.Kind.SURFACE)).is_same(vaga)
	assert_object(obras.barrier(0.0, 400.0, Band.Kind.SURFACE)).is_null()
	assert_object(obras.barrier(1000.0, 0.0, Band.Kind.UNDERGROUND)).is_null()


func test_esquecer_as_vagas_esvazia_o_quadro() -> void:
	var obras := _obras()
	obras.post(_vaga_de_canteiro(0.0))
	obras.post(_vaga_de_canteiro(200.0))
	assert_int(obras.count()).is_equal(2)

	obras.clear()

	assert_int(obras.count()).is_equal(0)
	assert_int(obras.index_of(0)).is_equal(BuildSlot.NENHUM)
