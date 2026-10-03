# tests/flechas_imperiais_test.gd — a flecha do Imperador Arqueiro no combate manual (ADR
# 0052; Q-200, Q-201; plano T15, T16, T20, T21).
extends GdUnitTestSuite

const STEP := 1.0 / 60.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _hero(_id: StringName) -> int:
	MonarchWatch.begin(&"archer_emperor")
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


func _resolve() -> Array[Dictionary]:
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	return SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.99
	)


func _attack(who: int, direction: float = 1.0) -> void:
	SimLoop.combat.manual.request(who, direction)


## ADR 0052 (Q-200): cada disparo do Imperador Arqueiro gasta uma flecha, acerte ou falhe.
func test_cada_disparo_gasta_uma_flecha_da_aljava() -> void:
	var who := _hero(&"archer")
	var i := SimLoop.units.index_of(who)
	var data := Registry.entry(&"units", &"archer_emperor") as UnitData
	var antes := SimLoop.field.supply.left(SimLoop.units, i, data)
	_attack(who, -1.0)  # para tras, onde nao ha ninguem: falha, e gasta
	_resolve()
	assert_int(SimLoop.field.supply.left(SimLoop.units, i, data)).is_equal(antes - 1)


## T15/T16 do plano: sem flechas nao ha flecha — um golpe de emergencia fraco e curto, que
## nao fura a coluna nem faz sangrar.
func test_sem_flechas_so_ha_o_golpe_de_emergencia() -> void:
	var who := _hero(&"archer")
	var i := SimLoop.units.index_of(who)
	var data := Registry.entry(&"units", &"archer_emperor") as UnitData
	SimLoop.field.supply.arm(SimLoop.units, i, data, 0)
	var longe := _enemy(_x(who) + 100.0)
	_attack(who)
	_resolve()
	assert_int(_health(longe)).is_equal(32)
	var perto := _enemy(_x(who) + 10.0)
	SimLoop.units.cooldowns[i] = 0.0
	_attack(who)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	assert_int(_health(perto)).is_equal(32 - int(data.ability_params[&"emergency_damage"]))
	assert_bool(SimLoop.field.bleeding.wounds.has(perto)).is_false()


## Q-201: a flecha que fez dano, com o sorteio abaixo da chance, abre a ferida; e a ferida
## sangra pelo lote comum do combate.
func test_a_flecha_faz_sangrar_e_a_ferida_tira_vida_aos_poucos() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	_attack(who)
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	assert_int(_health(enemy)).is_equal(28)
	assert_bool(SimLoop.field.bleeding.wounds.has(enemy)).is_true()
	SimLoop.field.bleeding.tick(1.0, SimLoop.creatures, SimLoop.field.song.allies)
	_resolve()
	assert_int(_health(enemy)).is_equal(27)


## Sem sorte, nao ha ferida: o sorteio de 0,99 fica acima da chance.
func test_sem_sorte_a_flecha_nao_faz_sangrar() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	_attack(who)
	_resolve()
	assert_bool(SimLoop.field.bleeding.wounds.has(enemy)).is_false()


## UN-15: a ferida e a flecha que matam no mesmo tick dao uma morte so — e uma recompensa.
func test_golpe_e_ferida_no_mesmo_tick_dao_uma_morte_so() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	_attack(who)
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	SimLoop.creatures.healths[SimLoop.creatures.index_of(enemy)] = 2
	SimLoop.field.bleeding.tick(1.0, SimLoop.creatures, SimLoop.field.song.allies)
	SimLoop.units.cooldowns[SimLoop.units.index_of(who)] = 0.0
	_attack(who)
	var mortes := 0
	for evento in _resolve():
		if evento[CombatSystem.CHAVE] == CombatSystem.EV_MORTE and evento[CombatSystem.DE] == enemy:
			mortes += 1
	assert_int(mortes).is_equal(1)
	assert_int(SimLoop.creatures.index_of(enemy)).is_equal(-1)
