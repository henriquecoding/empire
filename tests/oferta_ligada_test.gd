# tests/oferta_ligada_test.gd — as ofertas cujo preco nao cabe no prato, agora que o
# herdeiro, o Marco, a escora e a classe existem (§75; Q-099, o dono a 29/09/2026).
extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260929)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _de_pe(obra: BuildSlot) -> void:
	obra.level = 1
	obra.state = BuildSlot.State.DONE
	obra.health = obra.max_health()


func test_a_moeda_do_rei_no_prato_e_o_sim() -> void:
	var prato := SimFactory.offers()
	prato.open(Registry.entry(&"rot/offers", &"an_heir") as OfferData, 500.0, 1)
	var moedas := SimLoop.coins
	var alheia := SimLoop.drop_coin(500.0, Band.Kind.SURFACE, 1, &"production")
	for _t in 90:
		moedas.tick(STEP)
	var oferta := prato.offer()
	assert_dict(OfferPrice.pay(oferta, prato, moedas, SimLoop.units, {}, {})).is_empty()
	SimLoop.drop_coin(500.0, Band.Kind.SURFACE, 1, Verbs.JOGADOR)
	for _t in 90:
		moedas.tick(STEP)
	assert_dict(OfferPrice.pay(oferta, prato, moedas, SimLoop.units, {}, {})).is_not_empty()
	assert_int(moedas.index_of(alheia)).is_not_equal(CoinSystem.NENHUM)


func test_o_herdeiro_perde_o_treino_e_a_escora_cai() -> void:
	SimLoop.field.succession.days = 4
	assert_int(int(OfferToll.facts()[&"successor"])).is_equal(1)
	OfferToll.take(&"successor")
	assert_int(SimLoop.field.succession.days).is_equal(0)
	assert_bool(OfferToll.take(&"sealed_passage")).is_false()
	for obra in SimLoop.builds.slots:
		if obra.kind == Passages.ESCORA:
			_de_pe(obra)
			break
	assert_int(int(OfferToll.facts()[&"sealed"])).is_equal(1)
	assert_bool(OfferToll.take(&"sealed_passage")).is_true()
	assert_object(OfferToll.sealed()).is_null()


func test_sem_o_preco_no_mundo_a_oferta_nao_da_nada() -> void:
	# Aberta "O que enterraste" e desmontada a escora antes de pagar: nao ha divida
	# nem massa a metade so pela moeda do sim.
	var voz := SimLoop.night.voice
	var rot := SimLoop.night.rot
	voz.offers.open(Registry.entry(&"rot/offers", &"what_you_buried") as OfferData, 500.0, 1)
	assert_object(OfferToll.sealed()).is_null()
	var divida := voz.debt.debt
	var massa := rot.mass()
	voz._aceite(rot, 12)
	assert_int(voz.debt.debt).is_equal(divida)
	assert_float(rot.mass()).is_equal(massa)


func test_fica_com_o_lume_leva_a_evolucao_para_sempre() -> void:
	var classes := SimLoop.field.classes
	classes.phase = 2
	OfferToll.take(&"playable_class")
	assert_int(classes.phase).is_equal(ClassSystem.PRIMEIRA)
	assert_bool(classes.can_evolve(99)).is_false()


func test_um_herdeiro_poe_a_ganancia_a_zero_e_ela_volta() -> void:
	var voz := SimLoop.night.voice
	SimLoop.state.greed = 27
	voz.greed_kept = SimLoop.state.greed
	voz.greed_until = 5
	SimLoop.state.greed = 0
	voz.dawn(4)
	assert_int(SimLoop.state.greed).is_equal(0)
	voz.dawn(5)
	assert_int(SimLoop.state.greed).is_equal(27)


func test_a_regiao_diz_o_bioma_e_o_saco_do_rei_e_a_tesouraria() -> void:
	var factos := OfferToll.facts()
	var regioes := SimLoop.state.chapters.regions
	assert_str(String(factos[&"biome"])).is_equal(regioes[SimLoop.state.region])
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	assert_int(int(factos[&"treasury"])).is_equal(SimLoop.units.carried_coins[rei])
