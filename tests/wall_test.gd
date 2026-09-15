# tests/wall_test.gd — a tabela do §10 em jogo: cinco niveis, dois caminhos.
#
# "Cada segmento oferece duas melhorias mutuamente exclusivas por nivel. Nunca
# da para ter as duas — e essa e a decisao." (§10)
#
# Os numeros sao todos de walls.csv e nenhum esta escrito aqui. O que se prova e
# a FORMA da escada — que ela sobe, que sobe por nivel e nao por id, e que os
# dois caminhos trocam vida por postos e nao dao os dois.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const PASSO := 1.0 / 30.0


func _obras() -> BuildSystem:
	return BuildSystem.new()


func _canteiro() -> BuildingData:
	return Registry.entry(&"buildings", &"farm") as BuildingData


func _vaga_de_muro(x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.blocks = true
	vaga.kind = &"stakes"
	vaga.path = BuildSlot.Path.FORTIFICACAO
	vaga.width = _canteiro().width_px
	for w in SimFactory.walls_by_level():
		vaga.costs.append(w.cost)
		vaga.works.append(float(w.cost))
		vaga.healths.append(w.max_health_b)
		vaga.healths_a.append(w.max_health_a)
		vaga.posts_a.append(w.guard_posts_a)
		vaga.posts_b.append(w.guard_posts_b)
		vaga.contacts.append(w.contact_slots)
	return vaga


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


func _obreiro(unidades: UnitSystem, estado: GameState, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU_IMPERIO, x)


func _pagar(obras: BuildSystem, vaga: BuildSlot, quanto: int) -> Array[Dictionary]:
	var estado := GameState.new()
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var moedas := CoinSystem.new(curva)
	for _k in quanto:
		var id := moedas.drop(estado, vaga.x, vaga.band, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1
	return obras.absorb(moedas)


func test_a_escada_do_muro_sai_por_nivel_e_nao_por_id() -> void:
	# O Registry devolve por id, que e ordem alfabetica: bastion, iron_wall,
	# palisade, stakes, stone_wall. Uma escada montada nessa ordem custava 65 no
	# primeiro degrau, e o §25 diz que a primeira estacaria custa 6.
	var vaga := _vaga_de_muro(0.0)
	var custos: Array[int] = []
	for nivel in SimFactory.walls_by_level():
		custos.append(nivel.cost)

	assert_array(vaga.costs).is_equal(custos)
	assert_int(vaga.costs[0]).is_equal((Registry.entry(&"walls", &"stakes") as WallData).cost)
	for k in range(1, custos.size()):
		assert_int(custos[k]).is_greater(custos[k - 1])


func test_os_dois_caminhos_do_10_sao_exclusivos() -> void:
	# §10: "cada segmento oferece duas melhorias mutuamente exclusivas por
	# nivel. Nunca da para ter as duas — e essa e a decisao."
	var obras := _obras()
	var vaga := obras.post(_vaga_de_muro(0.0))
	vaga.level = 2
	assert_bool(vaga.two_paths()).is_true()

	vaga.path = BuildSlot.Path.FORTIFICACAO
	var vida_b := vaga.max_health()
	var postos_b := vaga.posts()
	vaga.path = BuildSlot.Path.GUARNICAO
	var vida_a := vaga.max_health()
	var postos_a := vaga.posts()

	# A guarnicao poe postos e deixa o muro fragil; a fortificacao faz o inverso.
	assert_int(vida_a).is_less(vida_b)
	assert_int(postos_a).is_greater(postos_b)


func test_a_escolha_do_caminho_fecha_se_no_nivel_2() -> void:
	var obras := _obras()
	var vaga := obras.post(_vaga_de_muro(0.0))

	assert_bool(vaga.choose_path(BuildSlot.Path.GUARNICAO)).is_true()
	assert_int(vaga.path).is_equal(BuildSlot.Path.GUARNICAO)

	vaga.level = 2
	assert_bool(vaga.choose_path(BuildSlot.Path.FORTIFICACAO)).is_false()
	assert_int(vaga.path).is_equal(BuildSlot.Path.GUARNICAO)


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
