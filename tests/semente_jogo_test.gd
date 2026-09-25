# tests/semente_jogo_test.gd — XIII-03 pelo SimLoop: a Semente Real que o §25 da
# ao minuto 11:00, e o Verbo 1 que a larga numa arvore para a consagrar (§74).
extends GdUnitTestSuite

const SEMENTE := 20260925
const PASSO := 1.0 / 30.0


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _pousar_rei(x: float, faixa: Band.Kind) -> void:
	var i := _rei()
	SimLoop.units.xs[i] = x
	SimLoop.units.bands[i] = faixa
	SimLoop.units.clear_target(SimLoop.king_id)


## Um arqueiro teu morto longe das muralhas, e a alvorada que o levanta.
func _arvore(x: float) -> int:
	var dono := SimLoop.units.owners[_rei()]
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var morto := SimLoop.units.spawn(SimLoop.state, arqueiro, dono, x)
	SimLoop.units.states[SimLoop.units.index_of(morto)] = UnitFsm.State.DEAD
	SimLoop.night.dawn(SimLoop.state, SimLoop.units, SimLoop.builds, SimLoop.core_x)
	return SimLoop.night.trees.tree_at(x, int(Band.Kind.SURFACE))


func _largar_uma() -> void:
	var i := _rei()
	(
		SimLoop
		. intents
		. queue(
			IntentQueue.Kind.DROP_COIN,
			{
				&"x": SimLoop.units.xs[i],
				&"band": SimLoop.units.bands[i] as Band.Kind,
				&"amount": 1,
				&"source": Verbs.JOGADOR,
			}
		)
	)
	SimLoop.step(PASSO)


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_camara_atras_da_passagem_da_a_semente_ao_rei() -> void:
	assert_int(SimLoop.secrets.count()).is_greater(0)
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	var achou: Array = []
	var ouvinte := func(id: StringName) -> void: achou.append(id)
	EventBus.secret_found.connect(ouvinte)
	_pousar_rei(SimLoop.secrets.xs[0], SimLoop.secrets.bands[0] as Band.Kind)
	SimLoop.step(PASSO)
	EventBus.secret_found.disconnect(ouvinte)
	assert_int(SimLoop.state.royal_seeds).is_equal(SimLoop.secrets.seeds[0])
	assert_array(achou).is_equal([SimLoop.secrets.ids[0]])


func test_largar_numa_arvore_com_uma_semente_consagra_e_devolve_a_moeda() -> void:
	var x := SimLoop.core_x + SimLoop.world_width * 0.45
	var arvore := _arvore(x)
	assert_int(arvore).is_not_equal(AmargueiroSystem.NENHUM)
	SimLoop.state.royal_seeds = 1
	_pousar_rei(x, Band.Kind.SURFACE)
	var saco := SimLoop.units.carried_coins[_rei()]
	_largar_uma()
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(saco)
	assert_int(SimLoop.night.trees.markers().size()).is_equal(1)


func test_sem_semente_largar_numa_arvore_larga_a_moeda() -> void:
	var x := SimLoop.core_x + SimLoop.world_width * 0.45
	_arvore(x)
	_pousar_rei(x, Band.Kind.SURFACE)
	var moedas := SimLoop.coins.count()
	_largar_uma()
	assert_int(SimLoop.coins.count()).is_equal(moedas + 1)
	assert_int(SimLoop.night.trees.markers().size()).is_equal(0)
