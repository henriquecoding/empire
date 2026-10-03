# tests/sucessao_monarca_test.gd — a morte e a sucessao de qualquer monarca (§15, §16;
# ADR 0052, UN-07; plano T24, T26).
#
# A coroa no chao, a morte de vez e a coroacao valem para os tres. O herdeiro nasce no
# castelo com o corpo do perfil de quem reinava (a proposta da Q-202), herda o companheiro
# que sobreviveu, e a linhagem conta mais uma geracao: a sucessora de Nia nao e a Nia.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261002)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _morrer_de_vez() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.healths[r] = 0
	SimLoop.units.states[r] = UnitFsm.State.DEAD


func _herdeiro_pronto() -> void:
	SimLoop.field.succession.days = SimFactory.curve().heir_training_days
	SimLoop.field.succession.owner = Greybox.MEU_IMPERIO


func _ate_a_alvorada() -> void:
	while ClockService.clock.day < 2:
		SimLoop.step(PASSO)
	SimLoop.step(PASSO)


func test_a_sucessora_de_nia_tem_o_perfil_dela_o_bardo_e_outra_identidade() -> void:
	MonarchWatch.begin(&"nia")
	var velha := SimLoop.king_id
	var bardo := int(SimLoop.field.monarchy.bonds[velha])
	_herdeiro_pronto()
	_morrer_de_vez()
	_ate_a_alvorada()
	assert_int(SimLoop.king_id).is_not_equal(velha)
	var r := SimLoop.units.index_of(SimLoop.king_id)
	assert_str(String(SimLoop.units.data_ids[r])).is_equal("nia")
	assert_int(SimLoop.field.monarchy.generation).is_equal(1)
	assert_int(int(SimLoop.field.monarchy.bonds[SimLoop.king_id])).is_equal(bardo)
	assert_str(MonarchHud.title()).is_not_equal(TranslationServer.translate(&"MONARCH_NIA"))


func test_o_herdeiro_do_arqueiro_traz_a_aljava_com_as_flechas_iniciais() -> void:
	MonarchWatch.begin(&"archer_emperor")
	_herdeiro_pronto()
	_morrer_de_vez()
	_ate_a_alvorada()
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var corpo := Registry.entry(&"units", &"archer_emperor") as UnitData
	assert_str(String(SimLoop.units.data_ids[r])).is_equal("archer_emperor")
	var iniciais := int(corpo.ability_params[&"start_ammo"])
	assert_int(SimLoop.field.supply.left(SimLoop.units, r, corpo)).is_equal(iniciais)
	assert_bool(SimLoop.field.supply.personal.has(SimLoop.king_id)).is_true()


## T24: sem sucessor valido, a morte de vez do monarca e a derrota — sem interregno.
func test_sem_sucessor_a_morte_de_vez_e_a_derrota() -> void:
	MonarchWatch.begin(&"archer_emperor")
	_morrer_de_vez()
	assert_bool(Defeat.happened()).is_true()


## O companheiro que morreu fica perdido: o herdeiro nao recebe outro de graca.
func test_o_companheiro_morto_nao_volta_com_o_herdeiro() -> void:
	MonarchWatch.begin(&"monarch")
	var velho := SimLoop.king_id
	var e := SimLoop.field.monarchy.companion_index(SimLoop.units, velho)
	SimLoop.units.states[e] = UnitFsm.State.DEAD
	SimLoop.step(PASSO)
	_herdeiro_pronto()
	_morrer_de_vez()
	var antes := SimLoop.units.count()
	_ate_a_alvorada()
	assert_int(SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)).is_equal(-1)
	assert_bool(SimLoop.field.monarchy.lost.has(SimLoop.king_id)).is_true()
	assert_int(SimLoop.units.data_ids.count(&"squire")).is_less_equal(antes)
