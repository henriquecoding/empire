# tests/caca_viva_test.gd — a caca viva e os imperadores que cacam (ADR 0057).
#
# O dono, a 03/10/2026: "a caca e criaturas deve ser desenvolvida e trabalhada a serio,
# deve haver variedades e deve ser possivel fazer farm com as moedas que caem; os
# imperadores tambem devem conseguir atacar e colher esse dinheiro".
extends GdUnitTestSuite

var units: UnitSystem
var state: GameState


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()


func _bicho(id: StringName) -> WildlifeData:
	return Registry.entry(&"wildlife", id) as WildlifeData


func _caca(tocas: Array[float], bichos: PackedStringArray) -> HuntingSystem:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), _bicho(&"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	var esperas: Array[float] = []
	esperas.resize(tocas.size())
	esperas.fill(0.0)
	var fontes := PackedStringArray()
	fontes.resize(tocas.size())
	fontes.fill("bush")
	h.burrows.place(tocas, esperas, fontes, bichos)
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	return h


func _so(bicho: WildlifeData) -> Callable:
	return func(_toca: float) -> WildlifeData: return bicho


## Ha variedade: em casa e nas terras logo ao lado saem coelhos, faisoes, raposas,
## veados e o javali, e o cervo branco e o raro que sai das tocas do veado.
func test_ha_variedade_de_caca_na_regiao_de_casa() -> void:
	var bioma := SimFactory.biome_of_segment(SimFactory.SEGMENTO_DE_PARTIDA)
	var com_toca: Array[String] = []
	for dados: WildlifeData in Registry.entries(&"wildlife"):
		var tem := dados.burrows_per_region > 0 or dados.per_segment_max > 0
		if dados.biomes.has(bioma) and tem:
			com_toca.append(String(dados.id))
	for id in ["rabbit", "pheasant", "fox", "deer", "boar"]:
		assert_bool(com_toca.has(id)).override_failure_message(id).is_true()
	assert_str(String(_bicho(&"white_stag").rare_of)).is_equal("deer")
	assert_float(_bicho(&"white_stag").rare_chance).is_greater(0.0)
	assert_int(_bicho(&"white_stag").coin_yield).is_greater(_bicho(&"deer").coin_yield)


## Sem ninguem perto, o bicho pasta a volta da toca e nunca passa do terreno dele.
func test_o_bicho_pasta_a_volta_da_toca() -> void:
	var manada := Herd.new()
	var coelho := _bicho(&"rabbit")
	manada.arrive(500.0)
	assert_float(manada.where(500.0)).is_equal(500.0)
	var tocas: Array[float] = [500.0]
	var longe := 0.0
	for k in 600:
		manada.step(0.1, tocas, _so(coelho), {})
		longe = maxf(longe, absf(manada.where(500.0) - 500.0))
	assert_float(longe).is_greater(coelho.roam_px * 0.5)
	assert_float(longe).is_less_equal(coelho.roam_px + 0.01)


## Quem chega perto fa-lo fugir para o outro lado, ate ao fim do terreno, onde fica
## encurralado; e o veado da por quem chega de mais longe do que o coelho.
func test_foge_de_quem_chega_e_fica_encurralado() -> void:
	var manada := Herd.new()
	var veado := _bicho(&"deer")
	manada.arrive(500.0)
	var tocas: Array[float] = [500.0]
	manada.step(1.0, tocas, _so(veado), {7: 500.0 - veado.notice_px - 1.0})
	assert_float(manada.where(500.0)).is_less_equal(500.0 + veado.graze_speed)
	var antes := manada.where(500.0)
	manada.step(1.0, tocas, _so(veado), {7: antes - 10.0})
	assert_float(manada.where(500.0)).is_equal_approx(antes + veado.move_speed, 0.01)
	assert_float(manada.facing[500.0]).is_equal(1.0)
	for k in 20:
		manada.step(0.5, tocas, _so(veado), {7: manada.where(500.0) - 10.0})
	assert_float(manada.where(500.0)).is_equal_approx(500.0 + veado.flee_px, 0.01)
	assert_float(veado.notice_px).is_greater(_bicho(&"rabbit").notice_px)


## O javali nao foge: pasta sem medo de quem passa e, ferido, carrega contra quem
## chega e bate-lhe, com a cadencia dele.
func test_o_javali_ferido_carrega_e_bate() -> void:
	var manada := Herd.new()
	var javali := _bicho(&"boar")
	manada.arrive(500.0)
	var tocas: Array[float] = [500.0]
	var rei := units.spawn(state, Registry.entry(&"units", &"monarch"), 1, 540.0)
	var golpes: Array[Dictionary] = []
	for k in 40:
		golpes.append_array(manada.step(0.1, tocas, _so(javali), Herd.threats_of(units)))
	assert_array(golpes).is_empty()
	manada.xs[500.0] = 500.0
	manada.provoked[500.0] = true
	for k in 40:
		golpes.append_array(manada.step(0.1, tocas, _so(javali), Herd.threats_of(units)))
	assert_float(manada.where(500.0)).is_greater(500.0)
	assert_int(golpes.size()).is_greater(0)
	assert_int(golpes.size()).is_less_equal(int(4.0 / javali.attack_interval) + 1)
	assert_int(int(golpes[0][Herd.QUEM])).is_equal(rei)
	var antes := units.healths[units.index_of(rei)]
	assert_int(Herd.bite(units, [golpes[0]]).size()).is_equal(1)
	assert_int(units.healths[units.index_of(rei)]).is_equal(antes - javali.damage)


## So os teus, vivos e a superficie, assustam a caca; e o golpe num morto nao pega.
func test_quem_assusta_e_quem_leva_o_golpe() -> void:
	var meu := units.spawn(state, Registry.entry(&"units", &"archer"), 1, 10.0)
	units.spawn(state, Registry.entry(&"units", &"archer"), 0, 20.0)
	var ameacas := Herd.threats_of(units)
	assert_array(ameacas.keys()).is_equal([meu])
	units.healths[units.index_of(meu)] = 0
	assert_dict(Herd.threats_of(units)).is_empty()
	var golpe := {Herd.QUEM: meu, Herd.DANO: 3, Herd.DE: 1.0}
	assert_array(Herd.bite(units, [golpe])).is_empty()


## O save guarda onde anda cada bicho, o raro e a cadencia; um save antigo poe-nos a porta.
func test_o_save_guarda_a_manada() -> void:
	var manada := Herd.new()
	manada.arrive(10.0, &"white_stag")
	manada.xs[10.0] = 30.0
	var outra := Herd.new()
	outra.from_dict(manada.to_dict())
	assert_float(outra.where(10.0)).is_equal(30.0)
	assert_str(String(outra.variants[10.0])).is_equal("white_stag")
	assert_int(outra.born).is_equal(1)
	outra.forget(10.0)
	assert_float(outra.where(10.0)).is_equal(10.0)
	var velha := Herd.new()
	velha.from_dict({})
	assert_float(velha.where(77.0)).is_equal(77.0)


## O raro sai com o sorteio e passa a ser o bicho daquela toca ate cair.
func test_o_cervo_branco_sai_da_toca_do_veado() -> void:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), _bicho(&"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	var tocas: Array[float] = [100.0, 300.0]
	var esperas: Array[float] = [0.0, 0.0]
	h.burrows.place(
		tocas, esperas, PackedStringArray(["tree", "bush"]), PackedStringArray(["deer", "rabbit"])
	)
	h.open_day(2)
	h.grow(0.0, true, 1.0, func() -> float: return 0.0)
	assert_str(String(h.species_at(100.0).id)).is_equal("white_stag")
	assert_str(String(h.species_at(300.0).id)).is_equal("rabbit")
	var nunca := _caca([100.0], PackedStringArray(["deer"]))
	assert_str(String(nunca.species_at(100.0).id)).is_equal("deer")


## Um golpe fere; o que mata larga a caca onde o bicho estava. No chao, moeda a moeda,
## e essa nao vai para o saco de ninguem: e de quem a pisar.
func test_a_caca_cai_no_chao_moeda_a_moeda() -> void:
	var h := _caca([100.0], PackedStringArray(["deer"]))
	h.herd.xs[100.0] = 140.0
	var veado := _bicho(&"deer")
	assert_array(h.hurt(100.0, veado.max_health - 1, 5, true)).is_empty()
	assert_bool(h.herd.provoked.has(100.0)).is_true()
	var moedas := h.hurt(100.0, 1, 5, true)
	assert_int(moedas.size()).is_equal(veado.coin_yield)
	for m in moedas:
		assert_int(m[&"amount"]).is_equal(1)
		assert_float(m[&"x"]).is_equal(140.0)
	assert_bool(h.rabbits.is_empty()).is_true()
	var arqueiro := units.spawn(state, Registry.entry(&"units", &"archer"), 1, 0.0)
	moedas[0][&"hunter"] = arqueiro
	assert_int(HuntBag.bag(h.bagged, units, moedas).size()).is_equal(moedas.size())
	assert_dict(h.bagged).is_empty()


## O golpe falhado do imperador vai ao bicho a frente dele, ao alcance da arma; atras
## dele, ou longe de mais, nao.
func test_o_imperador_caca_com_o_golpe_dele() -> void:
	var h := _caca([100.0, 300.0], PackedStringArray(["rabbit", "rabbit"]))
	var golpe := {&"who": 1, &"x": 120.0, &"band": Band.Kind.SURFACE, &"range": 30.0}
	golpe[&"damage"] = 4
	golpe[&"direction"] = 1.0
	assert_array(RoyalHunt.swing(h, golpe)).is_empty()
	golpe[&"direction"] = -1.0
	var moedas := RoyalHunt.swing(h, golpe)
	assert_int(moedas.size()).is_equal(1)
	assert_bool(moedas[0].has(HuntingSystem.GROUND)).is_true()
	assert_array(h.rabbits).is_equal([300.0])
	golpe[&"band"] = Band.Kind.UNDERGROUND
	golpe[&"x"] = 290.0
	assert_array(RoyalHunt.swing(h, golpe)).is_empty()


## O imperador que ninguem conduz caca sozinho o que lhe passa ao alcance; o que se
## conduz, nao: esse caca com o golpe de quem joga.
func test_o_imperador_sem_condutor_caca_sozinho() -> void:
	var h := _caca([100.0], PackedStringArray(["rabbit"]))
	var perfis := SimFactory.by_id(&"units")
	var nia := units.spawn(state, Registry.entry(&"units", &"nia"), 1, 110.0)
	assert_array(RoyalHunt.idle(h, units, perfis, nia, true)).is_empty()
	assert_array(RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, false)).is_empty()
	var nia_dados := perfis[&"nia"] as UnitData
	var moedas: Array[Dictionary] = []
	for k in 4:
		moedas.append_array(RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true))
		units.cooldowns[units.index_of(nia)] = 0.0
	assert_int(moedas.size()).is_equal(1)
	assert_int(int(moedas[0][&"hunter"])).is_equal(nia)
	assert_float(units.cooldowns[units.index_of(nia)]).is_equal(0.0)
	assert_int(nia_dados.damage).is_greater(0)


## Os golpes falhados do PlayerStrike chegam a caca uma vez so.
func test_o_golpe_falhado_entrega_se_uma_vez() -> void:
	var golpe := PlayerStrike.new(SimFactory.by_id(&"units"), SimFactory.job_board())
	golpe.missed.append({&"x": 1.0})
	assert_int(golpe.take_missed().size()).is_equal(1)
	assert_array(golpe.take_missed()).is_empty()
