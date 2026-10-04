# tests/alado_ladrao_test.gd — o Alado rouba galinhas (AUD-04, P-J; §06, §07;
# Q-129, que fecha a Q-077).
#
# O §07 diz que o Alado "obriga a torre alta", e medido ele atravessava a
# muralha, pousava no castelo e nao fazia nada: o castelo perdia 0%. O §06 da ao
# galinheiro "galinhas roubaveis a noite" e ninguem as roubava. Passam a ser a
# mesma coisa: o Alado vai ao galinheiro, leva uma galinha e volta para a borda;
# se chegar vivo a alvorada, o galinheiro rende menos no dia seguinte.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const ALADO := &"winged"
const GALINHEIRO := &"henhouse"
const LONGE := 2000.0

var _levadas := 0


func before_test() -> void:
	_levadas = 0
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.material_consumed.connect(_levou)
	SimLoop.start(SEMENTE)
	Greybox.build()
	LastCartWatch.claim(&"road")  # esta suite mede o mundo depois da escolha territorial
	SimLoop.builds.slots[0].health = 1000000  # a pergunta sao as galinhas


func after_test() -> void:
	EventBus.material_consumed.disconnect(_levou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _levou(_obra: int, tipo: StringName, quanto: int) -> void:
	if tipo == &"animal":
		_levadas += quanto


func _galinheiros() -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for obra in SimLoop.builds.slots:
		if obra.kind == GALINHEIRO:
			obra.level = 1
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()
			saida.append(obra)
	return saida


func _alado(x: float) -> int:
	var dados := Registry.entry(&"creatures", ALADO) as CreatureData
	return SimLoop.creatures.spawn(SimLoop.state, dados, x, SimLoop.core_x)


func _planear(borda: float) -> void:
	Thieves.plan(
		SimLoop.creatures,
		SimFactory.by_id(&"creatures"),
		SimLoop.builds,
		SimFactory.by_id(&"buildings"),
		borda
	)


func _ate(fase: GameClock.Phase) -> void:
	while ClockService.clock.current_phase() != fase:
		SimLoop.step(STEP)


func test_o_alado_vai_ao_galinheiro_mais_perto_dele() -> void:
	var galinheiros := _galinheiros()
	var bicho := _alado(SimLoop.core_x + LONGE)
	_planear(SimLoop.world_width)
	var c := SimLoop.creatures.index_of(bicho)
	var mais_perto := galinheiros[0]
	for obra in galinheiros:
		if obra.x > mais_perto.x:
			mais_perto = obra
	assert_float(SimLoop.creatures.target_xs[c]).is_equal(mais_perto.x)


func test_sem_galinheiro_de_pe_segue_para_o_nucleo() -> void:
	var bicho := _alado(SimLoop.core_x + LONGE)
	_planear(SimLoop.world_width)
	var c := SimLoop.creatures.index_of(bicho)
	assert_float(SimLoop.creatures.target_xs[c]).is_equal(SimLoop.core_x)


func test_ao_chegar_leva_uma_galinha_e_volta_para_a_borda() -> void:
	var galinheiro := _galinheiros()[1]
	var bicho := _alado(galinheiro.x)
	_planear(SimLoop.world_width)
	var c := SimLoop.creatures.index_of(bicho)
	assert_int(SimLoop.creatures.loot_slots[c]).is_equal(galinheiro.id)
	assert_float(SimLoop.creatures.target_xs[c]).is_equal(SimLoop.world_width)
	# Uma galinha por Alado: passar por cima de outro galinheiro nao leva mais.
	SimLoop.creatures.xs[c] = _galinheiros()[0].x
	_planear(SimLoop.world_width)
	assert_int(SimLoop.creatures.loot_slots[c]).is_equal(galinheiro.id)
	assert_float(SimLoop.creatures.target_xs[c]).is_equal(SimLoop.world_width)


func test_quem_chega_vivo_a_alvorada_custa_a_producao_do_dia_seguinte() -> void:
	var galinheiro := _galinheiros()[1]
	galinheiro.stock = 0.0
	var bicho := _alado(galinheiro.x)
	_planear(SimLoop.world_width)
	var levadas := Thieves.escape(SimLoop.creatures, SimLoop.builds, 1.0)
	assert_int(levadas.size()).is_equal(1)
	assert_float(galinheiro.stock).is_equal(-1.0)
	assert_int(SimLoop.creatures.index_of(bicho)).is_not_equal(CreatureSystem.NENHUM)


func test_nunca_mais_do_que_um_dia_de_galinhas() -> void:
	var galinheiro := _galinheiros()[1]
	galinheiro.stock = 0.0
	for _k in 10:
		_alado(galinheiro.x)
	_planear(SimLoop.world_width)
	Thieves.escape(SimLoop.creatures, SimLoop.builds, 1.0)
	assert_float(galinheiro.stock).is_equal(-galinheiro.yield_per_day)


## O que escapa e o do lado da noite: volta para a borda de onde veio sem passar
## por cima de ninguem. O outro morre antes da alvorada, e nao leva nada.
func test_de_noite_o_que_escapa_leva_e_o_que_morre_nao() -> void:
	var galinheiros := _galinheiros()
	_ate(GameClock.Phase.NIGHT)
	var lado := SimLoop.night.rot.state.side
	var dela := galinheiros[1] if lado > 0 else galinheiros[0]
	var outro := galinheiros[0] if lado > 0 else galinheiros[1]
	var fica := _alado(dela.x)
	var morre := _alado(outro.x)
	SimLoop.step(STEP)
	var c := SimLoop.creatures.index_of(fica)
	assert_int(SimLoop.creatures.loot_slots[c]).is_equal(dela.id)
	SimLoop.creatures.damage(morre, 1000)
	_ate(GameClock.Phase.DAWN)
	SimLoop.step(STEP)
	assert_int(_levadas).is_equal(roundi(SimFactory.curve().chicken_theft_matter))
