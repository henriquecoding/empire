# tests/sucessao_test.gd — o herdeiro (AUD-05; §15, §16; Q-133).
#
# O §15: "Treino — 10 dias na Casa do Herdeiro. Custa 5 moedas/dia." O §16: "se
# houver sucessor, ele assume no amanhecer." Sem herdeiro, a morte do rei continua
# a ser a derrota (D6).
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const SACO := 100

var _gasto := {}
var _coroado := -1


func before_test() -> void:
	_gasto = {}
	_coroado = -1
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.coin_spent.connect(_gastou)
	EventBus.succession_started.connect(_coroou)
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	SimLoop.step(STEP)


func after_test() -> void:
	EventBus.coin_spent.disconnect(_gastou)
	EventBus.succession_started.disconnect(_coroou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _gastou(quanto: int, porque: StringName) -> void:
	_gasto[porque] = int(_gasto.get(porque, 0)) + quanto


func _coroou(heir_id: int) -> void:
	_coroado = heir_id


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func _casa() -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == Succession.CASA:
			return obra
	return null


func _de_pe(obra: BuildSlot) -> void:
	obra.level = 1
	obra.state = BuildSlot.State.DONE
	obra.health = obra.max_health()


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


## A alvorada do dia seguinte, pedida ao FieldWork sem esperar pela noite.
func _alvorada(dia: int) -> void:
	SimLoop.field.prepare(dia, SimLoop.core_x, SimLoop.world_width, SimLoop.units, 0, SimLoop.state)
	EventBus.flush()


func test_ha_uma_casa_do_herdeiro_por_levantar_fora_do_muro() -> void:
	var casa := _casa()
	assert_object(casa).is_not_null()
	assert_int(casa.state).is_equal(BuildSlot.State.EMPTY)
	assert_float(casa.x).is_less(SimLoop.core_x - 1300.0)


func test_sem_casa_nao_se_forma_ninguem_e_a_morte_do_rei_e_derrota() -> void:
	SimLoop.units.carried_coins[_rei()] = SACO
	_alvorada(2)
	assert_int(SimLoop.field.succession.days).is_equal(0)
	SimLoop.units.healths[_rei()] = 0
	assert_bool(Defeat.happened()).is_true()


func test_com_a_casa_de_pe_cada_alvorada_paga_um_dia_de_treino() -> void:
	_de_pe(_casa())
	SimLoop.units.carried_coins[_rei()] = SACO
	_alvorada(2)
	_alvorada(3)
	assert_int(SimLoop.field.succession.days).is_equal(2)
	assert_int(int(_gasto.get(&"heir", 0))).is_equal(2 * _curva().heir_cost_per_day)


func test_sem_moedas_o_herdeiro_nao_treina() -> void:
	_de_pe(_casa())
	SimLoop.units.carried_coins[_rei()] = _curva().heir_cost_per_day - 1
	_alvorada(2)
	assert_int(SimLoop.field.succession.days).is_equal(0)


func test_com_herdeiro_formado_a_morte_do_rei_nao_e_derrota() -> void:
	_de_pe(_casa())
	SimLoop.field.succession.days = _curva().heir_training_days
	SimLoop.units.healths[_rei()] = 0
	assert_bool(Defeat.king_fell()).is_true()
	assert_bool(Defeat.happened()).is_false()
	TranslationServer.set_locale("pt_PT")
	assert_str(GameplayGuide.goal()).contains("REI CAIU")


func test_o_herdeiro_assume_na_alvorada_no_castelo() -> void:
	var casa := _casa()
	_de_pe(casa)
	SimLoop.units.carried_coins[_rei()] = SACO
	_alvorada(2)
	SimLoop.field.succession.days = _curva().heir_training_days
	var velho := SimLoop.king_id
	SimLoop.units.healths[_rei()] = 0
	_alvorada(3)
	assert_int(SimLoop.king_id).is_not_equal(velho)
	assert_int(_coroado).is_equal(SimLoop.king_id)
	var i := _rei()
	assert_bool(SimLoop.units.alive(i)).is_true()
	assert_str(String(SimLoop.units.data_ids[i])).is_equal("monarch")
	assert_float(SimLoop.units.xs[i]).is_equal(Succession.castle(SimLoop.builds).x)
	assert_float(SimLoop.units.xs[i]).is_not_equal(casa.x)
	assert_int(SimLoop.field.succession.days).is_equal(0)
	assert_bool(Defeat.happened()).is_false()
	var perfil := Registry.entry(&"crown/greed", _curva().start_greed_profile) as GreedProfile
	assert_int(SimLoop.state.greed).is_between(perfil.greed_range.x, perfil.greed_range.y)


func test_o_treino_vai_no_save() -> void:
	_de_pe(_casa())
	SimLoop.units.carried_coins[_rei()] = SACO
	_alvorada(2)
	var copia := Succession.new(1, 1)
	copia.from_dict(SimLoop.field.to_dict()[&"succession"])
	assert_int(copia.days).is_equal(1)
	assert_int(copia.owner).is_equal(SimLoop.units.owners[_rei()])


## Q-137 (o dono, 29/09/2026): o sucessor so nasce no castelo. Formado, perder a
## casa ja nao o perde; sem castelo nao ha onde nascer, e a partida acaba.
func test_herdeiro_formado_nasce_no_castelo_mesmo_sem_casa() -> void:
	var casa := _casa()
	_de_pe(casa)
	SimLoop.field.succession.days = _curva().heir_training_days
	SimLoop.field.succession.owner = SimLoop.units.owners[_rei()]
	casa.state = BuildSlot.State.RUIN
	casa.health = 0
	SimLoop.units.healths[_rei()] = 0
	assert_bool(SimLoop.field.succession.possible(SimLoop.builds)).is_true()
	assert_bool(Defeat.happened()).is_false()
	var castelo := Succession.castle(SimLoop.builds)
	castelo.state = BuildSlot.State.RUIN
	castelo.health = 0
	assert_bool(SimLoop.field.succession.possible(SimLoop.builds)).is_false()
	assert_bool(Defeat.happened()).is_true()


func test_herdeiro_formado_com_casa_de_pe_espera_pela_alvorada() -> void:
	_de_pe(_casa())
	SimLoop.field.succession.days = _curva().heir_training_days
	SimLoop.field.succession.owner = SimLoop.units.owners[_rei()]
	var velho := SimLoop.king_id
	SimLoop.units.healths[_rei()] = 0
	assert_bool(Defeat.happened()).is_false()
	_alvorada(2)
	assert_int(SimLoop.king_id).is_not_equal(velho)
	assert_bool(Defeat.happened()).is_false()


## Q-146 (o dono, 29/09/2026): com o herdeiro pronto, quem joga escolhe. Deixar a
## coroa cair e a derrota; a escolha vai no save.
func test_com_herdeiro_pronto_quem_joga_pode_deixar_a_coroa_cair() -> void:
	SimLoop.field.succession.days = _curva().heir_training_days
	SimLoop.field.succession.owner = SimLoop.units.owners[_rei()]
	SimLoop.units.healths[_rei()] = 0
	assert_bool(PauseMenu.heir_waits()).is_true()
	SimLoop.field.succession.declined = true
	assert_bool(Defeat.happened()).is_true()
	assert_bool(PauseMenu.heir_waits()).is_false()
	var copia := Succession.new(1, 1)
	copia.from_dict(SimLoop.field.to_dict()[&"succession"])
	assert_bool(copia.declined).is_true()


func test_continuar_coroa_o_herdeiro_e_limpa_a_escolha() -> void:
	SimLoop.field.succession.days = _curva().heir_training_days
	SimLoop.field.succession.owner = SimLoop.units.owners[_rei()]
	SimLoop.units.healths[_rei()] = 0
	_alvorada(2)
	assert_bool(Defeat.king_fell()).is_false()
	assert_bool(SimLoop.field.succession.declined).is_false()
