# tests/combate_no_corpo_test.gd — o golpe acerta no corpo da criatura (Q-219).
#
# O dono, a 03/10/2026: «quero que os inimigos da podridao sigam essa logica tambem, o
# menor tem que ter um tamanho aceitavel para que o combate faca sentido em base 64x64».
# Com criaturas maiores, o golpe que lhes toca na pele tem de contar: o golpe de perto
# chega ate meia sombra para la do alcance e apanha a que lhe esta por cima; a flecha so
# vai a frente.
extends GdUnitTestSuite

const STEP := 1.0 / 60.0
const METADE := 0.5


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _hero(id: StringName) -> int:
	MonarchWatch.begin(id)
	var who := SimLoop.king_id
	HeroWatch.tick(0.0)
	for i in SimLoop.units.count():
		if SimLoop.units.ids[i] != who:
			SimLoop.units.cooldowns[i] = 99.0
	return who


func _x(who: int) -> float:
	return SimLoop.units.xs[SimLoop.units.index_of(who)]


func _enemy(x: float) -> int:
	var id := SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", &"brute"), x, SimLoop.core_x
	)
	SimLoop.creatures.cooldowns[SimLoop.creatures.index_of(id)] = 99.0
	return id


func _health(who: int) -> int:
	return SimLoop.creatures.healths[SimLoop.creatures.index_of(who)]


func _golpe(who: int) -> void:
	SimLoop.units.cooldowns[SimLoop.units.index_of(who)] = 0.0
	SimLoop.combat.manual.request(who, 1.0)
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.99
	)


func _meia() -> float:
	return (Registry.entry(&"creatures", &"brute") as CreatureData).shadow_width * METADE


func test_o_golpe_de_perto_acerta_na_pele() -> void:
	var who := _hero(&"monarch")
	var alcance: float = SimLoop.combat.manual.profile(SimLoop.units, who)[&"range"]
	var longe := _enemy(_x(who) + alcance + _meia() + 1.0)
	_golpe(who)
	assert_int(_health(longe)).is_equal(32)
	SimLoop.creatures.remove(longe)
	var pele := _enemy(_x(who) + alcance + _meia() - 1.0)
	_golpe(who)
	assert_int(_health(pele)).is_less(32)


func test_o_golpe_de_perto_apanha_a_que_esta_por_cima() -> void:
	var who := _hero(&"monarch")
	var por_cima := _enemy(_x(who) - _meia() + 1.0)
	_golpe(who)
	assert_int(_health(por_cima)).is_less(32)


func test_a_flecha_so_vai_a_frente() -> void:
	var who := _hero(&"archer_emperor")
	var atras := _enemy(_x(who) - _meia() + 1.0)
	_golpe(who)
	assert_int(_health(atras)).is_equal(32)


## O golpe de perto atinge tudo o que alcanca (ADR 0053): tambem a pele das outras.
func test_o_varrimento_tambem_chega_a_pele() -> void:
	var who := _hero(&"monarch")
	var alcance: float = SimLoop.combat.manual.profile(SimLoop.units, who)[&"range"]
	var primeira := _enemy(_x(who) + 5.0)
	var segunda := _enemy(_x(who) + alcance + _meia() - 1.0)
	_golpe(who)
	assert_int(_health(primeira)).is_less(32)
	assert_int(_health(segunda)).is_less(32)
