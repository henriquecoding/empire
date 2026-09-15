# tests/posts_test.gd — "a torre nao da dano — da certeza" (§07).
#
# O criterio do F1-07 e uma tabela: o tempo ate matar do arqueiro em campo
# aberto e em torre, contra as cinco criaturas do §07. O que isto prova e que a
# diferenca entre os dois vem do POSTO e nao de dois arqueiros diferentes — o
# mesmo UnitData, o mesmo dano, e so o sitio a mudar.
extends GdUnitTestSuite

const Referencia := preload("res://tests/support/reference_model.gd")

const MEU_IMPERIO := 7
## §07, a tabela do tempo ate matar: campo aberto contra torre, no Rastejante.
const TOLERANCIA := 0.03


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _tabela(tabela: StringName) -> Dictionary:
	var mapa := {}
	for r in Registry.entries(tabela):
		mapa[r.get(&"id")] = r
	return mapa


func _quadro() -> JobBoard:
	return JobBoard.new(_curva(), _tabela(&"jobs"), _tabela(&"units"))


func _torre(obras: BuildSystem, id: StringName, x: float) -> BuildSlot:
	var dados := Registry.entry(&"buildings", id) as BuildingData
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = dados.id
	vaga.width = float(dados.width_px)
	vaga.job_id = &"tower"
	vaga.job_slots = dados.job_slots
	vaga.effects = dados.effect_params
	vaga.costs = PackedInt32Array([dados.cost])
	vaga.works = PackedFloat32Array([dados.build_work])
	vaga.healths = PackedInt32Array([dados.max_health])
	obras.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _arqueiro(unidades: UnitSystem, estado: GameState, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU_IMPERIO, x)


func _dados() -> UnitData:
	return Registry.entry(&"units", &"archer") as UnitData


func test_em_campo_aberto_dispara_com_a_accuracy_open() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_arqueiro(unidades, estado, 0.0)
	var quadro := _quadro()

	assert_float(Posts.accuracy(quadro, unidades, 0, _dados())).is_equal(_dados().accuracy_open)
	assert_object(Posts.of(quadro, unidades, 0)).is_null()


func test_numa_torre_dispara_com_a_precisao_da_torre() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var torre := _torre(obras, &"archer_tower", 0.0)
	_arqueiro(unidades, estado, torre.x)
	var quadro := _quadro()

	quadro.publish(obras)
	quadro.assign(unidades, int(GameClock.Phase.NIGHT))

	var precisao := Posts.accuracy(quadro, unidades, 0, _dados())
	assert_float(precisao).is_equal(_curva().tower_accuracy)
	assert_float(precisao).is_greater(_dados().accuracy_open)


func test_a_torre_de_arqueiros_estica_o_alcance_em_40_por_cento() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var torre := _torre(obras, &"archer_tower", 0.0)
	_arqueiro(unidades, estado, torre.x)
	var quadro := _quadro()
	quadro.publish(obras)
	quadro.assign(unidades, int(GameClock.Phase.NIGHT))

	var bonus: float = torre.effects.get(&"range_bonus", 0.0)
	var esperado := float(_dados().range_px) * (1.0 + bonus)

	assert_float(Posts.range_px(quadro, unidades, 0, _dados())).is_equal_approx(esperado, 0.01)
	assert_float(bonus).is_greater(0.0)


func test_a_torre_nao_da_dano() -> void:
	# A frase inteira do §07. Se um dia a torre passar a somar dano, e aqui que
	# se ve — e a lição de posicionamento morre com ela.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var torre := _torre(obras, &"archer_tower", 0.0)
	var arqueiro := _arqueiro(unidades, estado, torre.x)
	var quadro := _quadro()
	quadro.publish(obras)
	quadro.assign(unidades, int(GameClock.Phase.NIGHT))

	assert_bool(torre.effects.has(&"damage")).is_false()
	assert_int(unidades.index_of(arqueiro)).is_equal(0)


func test_do_chao_o_arqueiro_nao_chega_ao_alado() -> void:
	# Q-006, fechada pela geometria: "um arqueiro no chao nao chega aos 200 px do
	# topo com 200 px de alcance; em muro ou torre de arqueiros tambem nao — SO a
	# torre alta". Os dados ja dizem targets_bands = SURFACE|AERIAL no arqueiro;
	# o que decide e o posto. Sem isto o Alado nao obriga a nada (§07).
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_arqueiro(unidades, estado, 0.0)
	var quadro := _quadro()
	var aerea := int(Band.Kind.AERIAL)

	assert_bool(_dados().targets_bands.has(aerea)).is_true()
	assert_bool(Posts.reaches(quadro, unidades, 0, _dados(), aerea)).is_false()


func test_de_uma_torre_de_arqueiros_tambem_nao() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var torre := _torre(obras, &"archer_tower", 0.0)
	_arqueiro(unidades, estado, torre.x)
	var quadro := _quadro()
	quadro.publish(obras)
	quadro.assign(unidades, int(GameClock.Phase.NIGHT))

	assert_bool(Posts.reaches(quadro, unidades, 0, _dados(), int(Band.Kind.AERIAL))).is_false()


func test_da_torre_alta_chega() -> void:
	# §10: "Torre alta — 30 — atinge a camada aerea — Alados — obrigatoria a
	# partir do dia 4". O hits_aerial esta no effect_params e em mais lado nenhum.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var obras := BuildSystem.new()
	var torre := _torre(obras, &"high_tower", 0.0)
	_arqueiro(unidades, estado, torre.x)
	var quadro := _quadro()
	quadro.publish(obras)
	quadro.assign(unidades, int(GameClock.Phase.NIGHT))

	assert_bool(torre.effects.has(&"hits_aerial")).is_true()
	assert_bool(Posts.reaches(quadro, unidades, 0, _dados(), int(Band.Kind.AERIAL))).is_true()
	# E continua a chegar ao chao onde esta: a torre acrescenta, nao troca.
	assert_bool(Posts.reaches(quadro, unidades, 0, _dados(), int(Band.Kind.SURFACE))).is_true()


func test_o_tempo_ate_matar_em_torre_bate_com_a_tabela_do_07() -> void:
	# O "Feito" do F1-07, em valor esperado e nao numa corrida unica — o §50
	# avisa que assertar sobre uma corrida da um teste que falha de forma
	# intermitente e acaba desligado.
	var arqueiro := _dados()
	var alvos := ["crawler", "winged", "brute", "burrower", "slime_ram"]
	var tabela := [4.2, 5.6, 11.2, 9.8, 32.2]
	for k in alvos.size():
		var bicho := Registry.entry(&"creatures", StringName(alvos[k])) as CreatureData
		var medido := Referencia.ttk(arqueiro, bicho.max_health, _curva().tower_accuracy)
		var alvo: float = tabela[k]
		var porque := "%s em torre: %.2f s, a tabela do §07 diz %.2f s" % [alvos[k], medido, alvo]
		assert_float(medido).override_failure_message(porque).is_equal_approx(
			alvo, alvo * TOLERANCIA
		)


func test_em_campo_aberto_demora_tres_vezes_mais() -> void:
	# "Um arqueiro em campo aberto acerta 1/3 das flechas; dentro de torre,
	# 100%." A razao entre as duas colunas da tabela e a propria precisao.
	var arqueiro := _dados()
	var bicho := Registry.entry(&"creatures", &"crawler") as CreatureData
	var torre := Referencia.ttk(arqueiro, bicho.max_health, _curva().tower_accuracy)
	var campo := Referencia.ttk(arqueiro, bicho.max_health, arqueiro.accuracy_open)

	assert_float(campo / torre).is_equal_approx(1.0 / arqueiro.accuracy_open, 0.01)
