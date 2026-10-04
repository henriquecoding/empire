# tests/classe_assumida_no_jogo_test.gd — so imperadores se jogam, pelo SimLoop (§08, §24;
# ADR 0052, o dono a 02/10/2026).
#
# Ate a ADR 0052 este ficheiro provava que o Verbo 2 do rei ao pe de um arqueiro teu fazia
# dele o corpo conduzido. O dono: "somente imperadores sao controlaveis [...] tropas,
# oficios, diplomatas e companheiros permanecem sob IA". Prova-se agora o contrario (T03
# do plano): ao pe de um arqueiro, de um bardo ou de um diplomata teus, o Verbo 2 nao
# assume ninguem; o guia nao o oferece; o monarca nao tem trela; e paga ao companheiro.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const SEMENTE := 20260930
const PASSO := 1.0 / 30.0
const LADO := 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _ao_lado(id: StringName) -> int:
	var dados := Registry.entry(&"units", id) as UnitData
	var x := SimLoop.units.xs[_rei()] + LADO
	return SimLoop.units.spawn(SimLoop.state, dados, Greybox.MEU_IMPERIO, x)


func test_o_verbo_2_ao_pe_de_uma_tropa_tua_nao_a_assume() -> void:
	for id: StringName in [&"archer", &"bard", &"diplomat"]:
		var tropa := _ao_lado(id)
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
		SimLoop.step(PASSO)
		assert_int(Assume.driven()).is_equal(SimLoop.king_id)
		assert_int(SimLoop.units.pilot).is_equal(UnitSystem.NENHUM)
		var i := SimLoop.units.index_of(tropa)
		assert_str(String(SimLoop.units.data_ids[i])).is_equal(String(id))


## O texto de assumir uma tropa deixou de existir: o guia nao o pode oferecer.
func test_o_guia_nao_oferece_assumir_uma_tropa() -> void:
	_ao_lado(&"archer")
	GameplayGuide.context(Glyphs.Device.KEYBOARD)
	for chave: StringName in [&"CONTEXT_ASSUME", &"CONTEXT_BACK_TO_KING", &"CONTEXT_KING_LEASH"]:
		assert_str(TranslationServer.translate(chave)).is_equal(String(chave))


## MU-02: todos os monarcas exploram ate as bordas reais — a trela do rei (Q-150) saiu.
func test_o_monarca_nao_tem_trela() -> void:
	assert_bool(Assume.limits(SimLoop.king_id) == Frontier.walk_limits()).is_true()
	var limites := Assume.limits(SimLoop.king_id)
	var trela := SimFactory.curve().king_leash_px
	assert_bool(limites.y > SimLoop.world_width + trela or limites.x < -trela).is_true()


## O Verbo 2 sem mais nada onde pegar paga ao companheiro: o escudeiro do Rei arma o escudo.
func test_o_verbo_2_paga_ao_companheiro() -> void:
	MonarchWatch.begin(&"monarch")
	Sede.companhia()
	var e := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	SimLoop.units.xs[e] = SimLoop.units.xs[_rei()]
	var bolsa := SimLoop.units.carried_coins[_rei()]
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(bolsa - 1)
	assert_int(SimLoop.field.classes.squire.shield).is_greater(0)


## A Nia da uma moeda ao orcamento do Bardo dela, ate ao teto.
func test_a_nia_paga_ao_bardo_dela() -> void:
	MonarchWatch.begin(&"nia")
	Sede.companhia()
	var b := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	SimLoop.units.xs[b] = SimLoop.units.xs[_rei()]
	var bolsa := SimLoop.units.carried_coins[_rei()]
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(bolsa - 1)
	assert_int(SimLoop.field.monarchy.budget_of(SimLoop.units.ids[b])).is_equal(1)


## O escudeiro do Arqueiro vende um lote por uma moeda da bolsa dele; sem moedas, nada.
func test_o_arqueiro_compra_flechas_so_com_moedas_dele() -> void:
	MonarchWatch.begin(&"archer_emperor")
	Sede.companhia()
	var e := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	SimLoop.units.xs[e] = SimLoop.units.xs[_rei()]
	var corpo := Registry.entry(&"units", &"archer_emperor") as UnitData
	var antes := SimLoop.field.supply.left(SimLoop.units, _rei(), corpo)
	SimLoop.units.carried_coins[_rei()] = 0
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	assert_int(SimLoop.field.supply.left(SimLoop.units, _rei(), corpo)).is_equal(antes)
	SimLoop.units.carried_coins[_rei()] = 1
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	var lote := MonarchWatch.squire_lot(SimLoop.units.data_ids[e])  # 6, Q-200
	assert_int(SimLoop.field.supply.left(SimLoop.units, _rei(), corpo)).is_equal(antes + lote)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(0)


## MU-04: o monarca tambem viaja, de dia, para destino seguro — e o companheiro que esta a
## mao vai com ele. Sem destino alem de casa, nao ha portao.
func test_o_monarca_viaja_com_o_companheiro_a_mao() -> void:
	MonarchWatch.begin(&"nia")
	Sede.companhia()
	var r := _rei()
	var b := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	SimLoop.units.xs[r] = SimLoop.secrets.chapters[0]
	SimLoop.units.xs[b] = SimLoop.secrets.chapters[0]
	assert_bool(TravelWatch.at_gate()).is_false()
	var bioma := StringName(SimLoop.state.chapters.regions[1])
	var povo := StringName(RulesFactory.biome_peoples()[bioma])
	SimLoop.field.realm.vassals.add(povo, 4, 100.0, 1)
	assert_bool(TravelWatch.at_gate()).is_true()
	assert_bool(TravelWatch.go(1)).is_true()
	var destino := float(SimLoop.field.settlements.records[1][&"x"])
	assert_float(SimLoop.units.xs[_rei()]).is_equal_approx(destino, 0.5)
	b = SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	assert_float(SimLoop.units.xs[b]).is_equal_approx(destino, 0.5)
