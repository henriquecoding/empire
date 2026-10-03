# tests/coroa_no_chao_test.gd — a coroa no chao, recuperavel ate a alvorada (§16, §74;
# Q-167, o dono a 30/09/2026; relatorio Kingdom, K2).
#
# "A coroa cai quando o rei cai e recupera-se ate a alvorada, se nenhuma criatura a
# apanhar; na mancha, alimenta o Lume." A criatura que lhe chega leva-a; a mancha
# come-a; quem o jogador conduz apanha-a e o rei levanta-se; e na alvorada, se ninguem
# a levou, o rei levanta-se tambem.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const X := 300.0
const ALCANCE := 24.0
const APANHA := 12.0
## O alcance da criatura e o de quem a apanha, juntos (o CrownDrop.tick).
const RAIOS := Vector2(ALCANCE, APANHA)
const SEM_MANCHA := Vector2.ZERO

var _estado := GameState.new()


func before_test() -> void:
	_estado = GameState.new()


func _caida() -> CrownDrop:
	var coroa := CrownDrop.new()
	coroa.fall(X, int(Band.Kind.SURFACE))
	return coroa


func _bicho(bichos: CreatureSystem, x: float) -> void:
	bichos.spawn(_estado, Registry.entry(&"creatures", &"crawler") as CreatureData, x, 0.0)


func test_a_criatura_que_lhe_chega_leva_a() -> void:
	var coroa := _caida()
	var bichos := CreatureSystem.new()
	var u := UnitSystem.new()
	_bicho(bichos, X + ALCANCE * 3.0)
	var fim := coroa.tick(bichos, RAIOS, SEM_MANCHA, u, CrownDrop.NENHUM)
	assert_int(fim).is_equal(CrownDrop.Fate.NONE)
	assert_bool(coroa.down).is_true()
	bichos.xs[0] = X + ALCANCE * 0.5
	fim = coroa.tick(bichos, RAIOS, SEM_MANCHA, u, CrownDrop.NENHUM)
	assert_int(fim).is_equal(CrownDrop.Fate.TAKEN)
	assert_bool(coroa.down).is_false()


## ADR 0052 (UN-11, T11 do plano): a criatura que a Nia converteu nao rouba a coroa do
## reino dela; e uma criatura morta nao leva nada.
func test_a_convertida_e_a_morta_nao_levam_a_coroa() -> void:
	var coroa := _caida()
	var bichos := CreatureSystem.new()
	var u := UnitSystem.new()
	_bicho(bichos, X)
	var convertida := {bichos.ids[0]: {&"permanent": true}}
	assert_int(coroa.tick(bichos, RAIOS, SEM_MANCHA, u, CrownDrop.NENHUM, convertida)).is_equal(
		CrownDrop.Fate.NONE
	)
	bichos.healths[0] = 0
	assert_int(coroa.tick(bichos, RAIOS, SEM_MANCHA, u, CrownDrop.NENHUM)).is_equal(
		CrownDrop.Fate.NONE
	)
	assert_bool(coroa.down).is_true()


func test_na_mancha_alimenta_o_lume() -> void:
	var coroa := _caida()
	var fim := coroa.tick(
		CreatureSystem.new(), RAIOS, Vector2(X - 50.0, X + 50.0), UnitSystem.new(), -1
	)
	assert_int(fim).is_equal(CrownDrop.Fate.CONSUMED)


func test_quem_se_conduz_apanha_a_e_o_rei_levanta_se() -> void:
	var coroa := _caida()
	var u := UnitSystem.new()
	var rei := u.spawn(_estado, Registry.entry(&"units", &"monarch") as UnitData, 1, X)
	var classe := u.spawn(
		_estado, Registry.entry(&"units", &"archer_emperor") as UnitData, 1, X + 80.0
	)
	u.healths[u.index_of(rei)] = 0
	u.states[u.index_of(rei)] = UnitFsm.State.DEAD
	var bichos := CreatureSystem.new()
	assert_int(coroa.tick(bichos, RAIOS, SEM_MANCHA, u, classe)).is_equal(CrownDrop.Fate.NONE)
	u.xs[u.index_of(classe)] = X + APANHA * 0.5
	assert_int(coroa.tick(bichos, RAIOS, SEM_MANCHA, u, classe)).is_equal(CrownDrop.Fate.RECOVERED)
	assert_bool(CrownDrop.rise(u, rei, 0.5)).is_true()
	var i := u.index_of(rei)
	assert_bool(u.alive(i)).is_true()
	assert_int(u.healths[i]).is_equal(roundi(u.max_healths[i] * 0.5))


func test_na_alvorada_sem_ninguem_a_levar_o_rei_levanta_se() -> void:
	var coroa := _caida()
	assert_int(coroa.dawn()).is_equal(CrownDrop.Fate.RECOVERED)
	assert_bool(coroa.down).is_false()
	assert_int(CrownDrop.new().dawn()).is_equal(CrownDrop.Fate.NONE)


func test_o_save_guarda_a_coroa_no_chao() -> void:
	var coroa := _caida()
	var outra := CrownDrop.new()
	outra.from_dict(coroa.to_dict())
	assert_bool(outra.down).is_true()
	assert_float(outra.x).is_equal(X)


## No jogo: o combate que mata o rei deixa a coroa no chao, e a partida ainda nao
## acabou; a alvorada levanta-o, se nenhuma criatura a levou.
func test_no_jogo_o_rei_caido_levanta_se_na_alvorada_sem_ninguem_assumir_tropa() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260930)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	var mortes: Array = []
	var ouvir := func(quem: int, _x: float, _f: int, _l: PackedStringArray) -> void:
		mortes.append(quem)
	EventBus.unit_died.connect(ouvir)
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var morte := {
		CombatSystem.CHAVE: CombatSystem.EV_MORTE,
		CombatSystem.DE: SimLoop.king_id,
		CombatSystem.ONDE: SimLoop.units.xs[r],
		CombatSystem.FAIXA: int(Band.Kind.SURFACE),
		CombatSystem.MOEDAS: 0,
		CombatSystem.CRIATURA: false,
	}
	SimLoop.units.healths[r] = 0
	SimLoop.units.states[r] = UnitFsm.State.DEAD
	EventRelay.combat([morte])
	EventBus.flush()
	assert_bool(SimLoop.field.crown_drop.down).is_true()
	assert_bool(Defeat.happened()).is_false()
	assert_array(mortes).is_empty()
	assert_int(SimLoop.units.pilot).is_equal(UnitSystem.NENHUM)  # ADR 0052: so imperadores
	while ClockService.clock.day < 2:
		SimLoop.step(1.0 / 30.0)
	SimLoop.step(1.0 / 30.0)
	r = SimLoop.units.index_of(SimLoop.king_id)
	assert_int(r).is_not_equal(UnitSystem.NENHUM)
	assert_bool(SimLoop.units.alive(r)).is_true()
	assert_bool(SimLoop.field.crown_drop.down).is_false()
	EventBus.unit_died.disconnect(ouvir)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
