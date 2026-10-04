# tests/bardo_pago_test.gd — a ordem da Nia ao Bardo dela (ADR 0052, Q-199; plano T09, T10).
#
# "Nia nao canta no lugar do bardo. O comando do jogador solicita uma acao do companheiro,
# validando se ele esta vivo, proximo, na faixa apropriada, pronto e financiado." O que
# nao aconteceu nao se paga; o que aconteceu paga-se uma vez — do orcamento do Bardo e
# depois da bolsa dela. Os precos sao os do units.csv (bard_banner), e nenhum esta aqui.
extends GdUnitTestSuite

const PASSO := 1.0 / 60.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261002)
	Greybox.build()
	SimLoop.step(PASSO)
	MonarchWatch.begin(&"nia")
	preload("res://tests/support/sede.gd").companhia()
	HeroWatch.tick(0.0)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _nia() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _bardo() -> int:
	return SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)


func _preco(chave: StringName) -> int:
	return int((Registry.entry(&"units", &"bard_banner") as UnitData).ability_params[chave])


func _rastejante(dx: float) -> int:
	var x := SimLoop.units.xs[_nia()] + dx
	var dados := Registry.entry(&"creatures", &"crawler")
	return SimLoop.creatures.spawn(SimLoop.state, dados, x, SimLoop.core_x)


func _junto() -> void:
	SimLoop.units.xs[_bardo()] = SimLoop.units.xs[_nia()]


func test_com_o_bardo_perto_e_moedas_encanta_e_paga_uma_vez() -> void:
	_junto()
	var alvo := _rastejante(40.0)
	var bolsa := SimLoop.units.carried_coins[_nia()]
	assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)])).is_true()
	assert_bool(SimLoop.field.song.allies.has(alvo)).is_true()
	assert_int(SimLoop.units.carried_coins[_nia()]).is_equal(bolsa - _preco(&"charm_cost"))
	assert_int(int(SimLoop.field.song.allies[alvo][&"bard"])).is_equal(SimLoop.units.ids[_bardo()])


## T09: o Bardo longe ou noutra faixa nao canta, e nada se debita.
func test_o_bardo_longe_ou_noutra_faixa_nao_canta_nem_cobra() -> void:
	var alvo := _rastejante(40.0)
	var x := SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)]
	var bolsa := SimLoop.units.carried_coins[_nia()]
	SimLoop.units.xs[_bardo()] = SimLoop.units.xs[_nia()] + 2000.0
	assert_bool(HeroWatch.action(x)).is_false()
	assert_str(String(HeroWatch.feedback)).is_equal("COMBAT_BARD_AWAY")
	_junto()
	SimLoop.units.bands[_bardo()] = Band.Kind.UNDERGROUND
	assert_bool(HeroWatch.action(x)).is_false()
	assert_bool(SimLoop.field.song.allies.has(alvo)).is_false()
	assert_int(SimLoop.units.carried_coins[_nia()]).is_equal(bolsa)


## Sem moedas no orcamento nem na bolsa, nao canta e diz porque.
func test_sem_moedas_nao_canta() -> void:
	_junto()
	var alvo := _rastejante(40.0)
	SimLoop.units.carried_coins[_nia()] = 0
	assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)])).is_false()
	assert_str(String(HeroWatch.feedback)).is_equal("COMBAT_BARD_UNPAID")
	assert_bool(SimLoop.field.song.allies.has(alvo)).is_false()


## T10: sem alvo valido o canto nao acontece — e o que nao aconteceu nao se paga.
func test_sem_alvo_valido_nao_se_paga() -> void:
	_junto()
	var bruto := SimLoop.creatures.spawn(
		SimLoop.state,
		Registry.entry(&"creatures", &"brute"),
		SimLoop.units.xs[_nia()] + 40.0,
		SimLoop.core_x
	)
	var bolsa := SimLoop.units.carried_coins[_nia()]
	(
		assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(bruto)]))
		. is_false()
	)
	assert_int(SimLoop.units.carried_coins[_nia()]).is_equal(bolsa)


## O orcamento do Bardo paga antes da bolsa da imperatriz.
func test_o_orcamento_paga_antes_da_bolsa() -> void:
	_junto()
	var bardo := SimLoop.units.ids[_bardo()]
	SimLoop.field.monarchy.fund(bardo, 2, 5)
	var alvo := _rastejante(40.0)
	var bolsa := SimLoop.units.carried_coins[_nia()]
	HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)])
	assert_int(SimLoop.units.carried_coins[_nia()]).is_equal(bolsa)
	assert_int(SimLoop.field.monarchy.budget_of(bardo)).is_equal(2 - _preco(&"charm_cost"))


## Na fase base, o Bardo tem um teto de encantados de cada vez.
func test_o_bardo_tem_um_teto_de_encantados() -> void:
	_junto()
	var teto := _preco(&"max_temporary")
	for k in teto:
		var alvo := _rastejante(30.0 + k * 10.0)
		SimLoop.field.song.cooldowns.clear()
		(
			assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)]))
			. is_true()
		)
	var outro := _rastejante(90.0)
	SimLoop.field.song.cooldowns.clear()
	(
		assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(outro)]))
		. is_false()
	)
	assert_str(String(HeroWatch.feedback)).is_equal("COMBAT_BARD_LIMIT")


## Como Maestro, o teto e a massa dos convertidos de vez que estao vivos, nao a cabeca
## (Q-199, UN-12): a conversao que passa o teto e a ultima.
func test_o_maestro_tem_um_teto_de_massa_convertida() -> void:
	_junto()
	SimLoop.field.hero_progress.phases[&"bard"] = 2
	SimLoop.units.carried_coins[_nia()] = 33
	var massa := (Registry.entry(&"creatures", &"crawler") as CreatureData).mass_cost
	var cabem := ceili(float(_preco(&"max_permanent_mass")) / massa)
	for k in cabem:
		var alvo := _rastejante(20.0 + k * 8.0)
		SimLoop.field.song.cooldowns.clear()
		(
			assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)]))
			. is_true()
		)
	assert_int(SimLoop.field.song.permanent().size()).is_equal(cabem)
	var outro := _rastejante(20.0 + cabem * 8.0)
	SimLoop.field.song.cooldowns.clear()
	(
		assert_bool(HeroWatch.action(SimLoop.creatures.xs[SimLoop.creatures.index_of(outro)]))
		. is_false()
	)
	assert_str(String(HeroWatch.feedback)).is_equal("COMBAT_BARD_LIMIT")


## Sem inimigo na mira, o Bardo incentiva os teus: andam mais depressa, e paga-se uma vez.
func test_sem_inimigo_o_bardo_incentiva_os_teus() -> void:
	_junto()
	var bolsa := SimLoop.units.carried_coins[_nia()]
	assert_bool(HeroWatch.action(SimLoop.units.xs[_nia()])).is_true()
	assert_str(String(HeroWatch.feedback)).is_equal("COMBAT_ENCOURAGED")
	assert_bool(SimLoop.field.monarchy.encouraged.has(SimLoop.king_id)).is_true()
	assert_int(SimLoop.units.carried_coins[_nia()]).is_equal(bolsa - _preco(&"encourage_cost"))
	var corpo := Registry.entry(&"units", &"nia") as UnitData
	SimLoop.step(PASSO)
	assert_float(SimLoop.units.speeds[_nia()]).is_greater(corpo.move_speed)


## O Bardo de IA nao canta pela Nia: o feito da conversao e so do Bardo dela.
func test_o_bardo_de_ia_nao_faz_o_feito_da_nia() -> void:
	var tropa := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"bard"), Greybox.MEU_IMPERIO, SimLoop.core_x
	)
	_rastejante(SimLoop.units.xs[SimLoop.units.index_of(tropa)] - SimLoop.units.xs[_nia()] + 10.0)
	HeroWatch.tick(PASSO)
	assert_int(SimLoop.field.hero_progress.feat_of(&"bard")).is_equal(0)


## Como Maestro, uma tropa tua e um inimigo a mesma distancia da mira: promove-se a tropa,
## e o empate nao a troca por um encanto.
func test_no_empate_o_maestro_promove_e_nao_encanta() -> void:
	_junto()
	SimLoop.field.hero_progress.phases[&"bard"] = 2
	SimLoop.units.carried_coins[_nia()] = 10
	var x := SimLoop.units.xs[_nia()] + 30.0
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var tropa := SimLoop.units.spawn(SimLoop.state, arqueiro, Greybox.MEU_IMPERIO, x)
	var bicho := _rastejante(30.0)
	SimLoop.units.xs[SimLoop.units.index_of(tropa)] = x
	SimLoop.creatures.xs[SimLoop.creatures.index_of(bicho)] = x
	assert_bool(HeroWatch.action(x)).is_true()
	assert_str(String(SimLoop.units.data_ids[SimLoop.units.index_of(tropa)])).is_equal(
		"canopy_archer"
	)
	assert_bool(SimLoop.field.song.allies.has(bicho)).is_false()


## Sem rato, a mira do canto parte do Bardo, que pode estar a passos da Nia: o alvo e o
## que ele alcanca, nao o que ela alcancaria.
func test_a_mira_do_canto_parte_do_bardo() -> void:
	var raio := float(_preco(&"radius"))
	SimLoop.units.xs[_bardo()] = SimLoop.units.xs[_nia()] + raio * 0.75
	var alvo := _rastejante(raio * 1.5)
	var mira := CombatInput.cursor_aim
	var lado := CombatInput.facing
	CombatInput.cursor_aim = false
	CombatInput.facing = 1.0
	var x := CombatInput.aim_x()
	CombatInput.cursor_aim = mira
	CombatInput.facing = lado
	assert_float(x).is_equal_approx(SimLoop.creatures.xs[SimLoop.creatures.index_of(alvo)], 0.5)
