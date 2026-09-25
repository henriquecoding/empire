# tests/semente_jogo_test.gd — XIII-03 pelo SimLoop: a Semente Real que o §25 da
# ao minuto 11:00, e o Verbo 1 que a larga numa arvore para a consagrar (§74).
extends GdUnitTestSuite

const SEMENTE := 20260925
const PASSO := 1.0 / 30.0
const ESCALA := 2


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _pousar_rei(x: float, faixa: Band.Kind) -> void:
	var i := _rei()
	SimLoop.units.xs[i] = x
	SimLoop.units.bands[i] = faixa
	SimLoop.units.clear_target(SimLoop.king_id)


func _largar_uma() -> void:
	var i := _rei()
	var args := {
		&"x": SimLoop.units.xs[i],
		&"band": SimLoop.units.bands[i] as Band.Kind,
		&"amount": 1,
		&"source": Verbs.JOGADOR,
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
	SimLoop.step(PASSO)


## Uma arvore de pe, das tuas, bem fora das muralhas.
func _arvore() -> int:
	var x := SimLoop.core_x - SimLoop.world_width * 0.2
	return SimLoop.night.amargueiros.plant(x, int(Band.Kind.SURFACE), ESCALA, 1, "")


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_camara_atras_da_passagem_da_a_semente_ao_rei() -> void:
	var s := SimLoop.secrets
	var k := Array(s.ids).find(&"root_chamber")
	assert_int(k).is_not_equal(-1)
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	_pousar_rei(s.xs[k], s.bands[k] as Band.Kind)
	SimLoop.step(PASSO)
	assert_int(SimLoop.state.royal_seeds).is_equal(s.seeds[k])
	assert_bool(SimLoop.state.found.has("root_chamber")).is_true()
	# Uma vez so: voltar la nao da outra.
	SimLoop.step(PASSO)
	assert_int(SimLoop.state.royal_seeds).is_equal(s.seeds[k])


func test_largar_numa_arvore_com_uma_semente_consagra_e_devolve_a_moeda() -> void:
	var i := _arvore()
	var a := SimLoop.night.amargueiros
	SimLoop.state.royal_seeds = 1
	_pousar_rei(a.xs[i], Band.Kind.SURFACE)
	var saco := SimLoop.units.carried_coins[_rei()]
	_largar_uma()
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(saco)
	assert_int(a.fates[i]).is_equal(AmargueiroSystem.Fate.MARKER)


func test_sem_semente_largar_numa_arvore_larga_a_moeda() -> void:
	var i := _arvore()
	var a := SimLoop.night.amargueiros
	_pousar_rei(a.xs[i], Band.Kind.SURFACE)
	var moedas := SimLoop.coins.count()
	_largar_uma()
	assert_int(SimLoop.coins.count()).is_equal(moedas + 1)
	assert_int(a.fates[i]).is_equal(AmargueiroSystem.Fate.STANDING)


func test_a_semente_e_os_segredos_achados_vao_no_save() -> void:
	var e := GameState.new()
	e.royal_seeds = 2
	e.conquests = PackedStringArray(["fornalha"])
	e.found = PackedStringArray(["root_chamber"])
	var copia := GameState.from_dict(e.to_dict())
	assert_int(copia.royal_seeds).is_equal(2)
	assert_array(Array(copia.conquests)).is_equal(["fornalha"])
	assert_array(Array(copia.found)).is_equal(["root_chamber"])
	var velho := GameState.from_dict({&"seed": 1})
	assert_int(velho.royal_seeds).is_equal(0)


func test_a_bifurcacao_do_capitulo_esta_a_leste() -> void:
	# §83: a bifurcacao onde cai o capitulo que a primeira oferta revela.
	var esperado := [SimLoop.core_x + Greybox.BIFURCACAO_X]
	assert_array(Array(SimLoop.secrets.chapters)).is_equal(esperado)
