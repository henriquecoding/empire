# tests/price_tag_test.gd — o preco daquilo em cima de que estas (GB-05).
#
# O que se prova aqui nao e o desenho: sao as duas perguntas que o desenho faz
# antes de desenhar. "Quanto falta pagar para isto andar mais um degrau" e
# "quanto falta a esta pessoa para passar a ser minha" tem uma resposta so cada,
# e ela tem de ser a MESMA que o BuildSystem e o RecruitSystem usam — uma
# etiqueta que diz 6 numa obra que aceita 4 e pior do que nao ter etiqueta.
#
# Os numeros vem todos de data/: o custo do canteiro e de buildings.csv, a
# escada do muro e de walls.csv, o preco do arqueiro e de units.csv.
extends GdUnitTestSuite


func _canteiro() -> BuildingData:
	return Registry.entry(&"buildings", &"farm") as BuildingData


func _vaga_de_canteiro() -> BuildSlot:
	var d := _canteiro()
	var vaga := BuildSlot.new()
	vaga.kind = d.id
	vaga.costs = PackedInt32Array([d.cost])
	vaga.works = PackedFloat32Array([d.build_work])
	vaga.healths = PackedInt32Array([d.max_health])
	vaga.width = float(d.width_px)
	return vaga


func _vaga_de_muro() -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.path = BuildSlot.Path.FORTIFICACAO
	for w in SimFactory.walls_by_level():
		vaga.costs.append(w.cost)
		vaga.works.append(float(w.cost))
		vaga.healths.append(w.max_health_b)
		vaga.healths_a.append(w.max_health_a)
		vaga.width = maxf(vaga.width, float(w.shadow_width))
	return vaga


func _com(id: StringName, saco: int) -> UnitSystem:
	var sistema := UnitSystem.new()
	var unit_id := sistema.spawn(
		GameState.new(), Registry.entry(&"units", id) as UnitData, RecruitSystem.SEM_DONO, 0.0
	)
	sistema.carried_coins[sistema.index_of(unit_id)] = saco
	return sistema


func test_um_sitio_vazio_pede_o_primeiro_degrau_inteiro() -> void:
	assert_int(PriceTag.owed_by(_vaga_de_canteiro())).is_equal(_canteiro().cost)


func test_o_que_ja_foi_pago_desconta_do_que_falta() -> void:
	var vaga := _vaga_de_canteiro()
	vaga.paid = 1
	assert_int(PriceTag.owed_by(vaga)).is_equal(_canteiro().cost - 1)


## §55: "uma obra a meio nao aceita moeda — pagar mais nao a faz andar mais
## depressa". Nao aceitando, tambem nao tem preco que mostrar.
func test_uma_obra_em_andaime_nao_pede_nada() -> void:
	var vaga := _vaga_de_canteiro()
	vaga.state = BuildSlot.State.SCAFFOLD
	assert_int(PriceTag.owed_by(vaga)).is_equal(0)
	vaga.state = BuildSlot.State.BUILDING
	assert_int(PriceTag.owed_by(vaga)).is_equal(0)


## §10: os cinco degraus do muro. De pe no nivel 1, o preco e o do nivel 2.
func test_um_muro_de_pe_pede_o_degrau_seguinte() -> void:
	var vaga := _vaga_de_muro()
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	assert_int(PriceTag.owed_by(vaga)).is_equal(vaga.costs[1])


func test_no_topo_da_escada_nao_ha_preco() -> void:
	var vaga := _vaga_de_muro()
	vaga.level = vaga.costs.size()
	vaga.state = BuildSlot.State.DONE
	assert_int(PriceTag.owed_by(vaga)).is_equal(0)


## O nucleo tem custo zero e ja nasce de pe (§10): nunca pede moeda nenhuma.
func test_o_castelo_arvore_nunca_pede_moeda() -> void:
	var vaga := BuildSlot.new()
	vaga.kind = BuildSlot.NUCLEO
	vaga.costs = PackedInt32Array([0])
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	assert_int(PriceTag.owed_by(vaga)).is_equal(0)


## O preco aparece onde o gesto pega: dentro da largura da obra, que e o raio
## com que o BuildSystem absorve uma moeda caida (§55).
func test_o_preco_so_aparece_onde_a_moeda_cairia_na_obra() -> void:
	var vaga := _vaga_de_canteiro()
	var meia := vaga.width * 0.5
	assert_bool(PriceTag.over(vaga, meia - 1.0)).is_true()
	assert_bool(PriceTag.over(vaga, -meia + 1.0)).is_true()
	assert_bool(PriceTag.over(vaga, meia + 1.0)).is_false()


## §07: um arqueiro custa 3 e um vagabundo 1. O RecruitSystem compara o SACO com
## o recruit_cost, e a etiqueta tem de contar a mesma conta.
func test_o_preco_de_quem_ainda_nao_e_de_ninguem_desconta_o_saco() -> void:
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	assert_int(PriceTag.owed_by_unit(_com(&"archer", 0), 0)).is_equal(arqueiro.recruit_cost)
	assert_int(PriceTag.owed_by_unit(_com(&"archer", 1), 0)).is_equal(arqueiro.recruit_cost - 1)


func test_quem_ja_tem_o_preco_no_saco_nao_leva_etiqueta() -> void:
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	assert_int(PriceTag.owed_by_unit(_com(&"archer", arqueiro.recruit_cost), 0)).is_equal(0)


## Q-108: tocada ou em ruina, o preco e o da reparacao, e nao o do degrau
## seguinte — que ela nao aceita. Paga, deixa de pedir.
func test_uma_obra_tocada_ou_em_ruina_pede_a_reparacao() -> void:
	var vaga := _vaga_de_muro()
	vaga.level = 1
	vaga.state = BuildSlot.State.DAMAGED
	vaga.health = vaga.max_health() / 2
	assert_int(PriceTag.owed_by(vaga)).is_equal(vaga.repair_cost())
	vaga.paid = 1
	assert_int(PriceTag.owed_by(vaga)).is_equal(vaga.repair_cost() - 1)
	vaga.mending = true
	assert_int(PriceTag.owed_by(vaga)).is_equal(0)
	vaga.mending = false
	vaga.paid = 0
	vaga.state = BuildSlot.State.RUIN
	assert_int(PriceTag.owed_by(vaga)).is_equal(vaga.costs[0])
