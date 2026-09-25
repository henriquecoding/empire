# tests/oferta_system_test.gd — o XIII-04, a parte que anda: uma oferta por
# noite, no prato, com o Verbo 1; 20 s e caduca como recusa (§75).
#
# A janela, o gatilho, o prato e os 20 s vem de rot.csv; os precos de
# offers.csv. A geometria da regiao de teste e a de tests/support/bosque.gd.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")


func _ofertas() -> OfferSystem:
	return SimFactory.offers()


func _oferta(id: StringName) -> OfferData:
	return Registry.entry(&"rot/offers", id) as OfferData


func _factos(extra := {}) -> Dictionary:
	var f := {
		&"gate": 0,
		&"treasury": 0,
		&"named": 0,
		&"marker": 0,
		&"peoples": 0,
		&"successor": 0,
		&"debt": 0,
		&"biome": &"",
	}
	f.merge(extra, true)
	return f


## Uma tropa tua, viva, em x, com esta fracao da vida.
func _ferido(u: UnitSystem, estado: GameState, x: float, racio: float) -> int:
	var unit_id := u.spawn(estado, Registry.entry(&"units", &"archer"), B.MEU_IMPERIO, x)
	var i := u.index_of(unit_id)
	u.healths[i] = int(floorf(u.max_healths[i] * racio))
	return unit_id


# ─── Quando fala ─────────────────────────────────────────────────────────────


func test_fala_quando_chega_a_300_px_da_muralha_e_nunca_antes_da_janela() -> void:
	var r := B.perfil()
	var o := _ofertas()
	o.dusk()
	var perto := B.MURO + r.offer_trigger_px - 1.0
	assert_bool(o.due(r.offer_window_after_dusk.x * 0.5, perto, B.MURO)).is_false()
	assert_bool(o.due(r.offer_window_after_dusk.x * 0.5, perto, B.MURO)).is_true()


func test_ao_fim_da_janela_fala_mesmo_longe() -> void:
	var r := B.perfil()
	var o := _ofertas()
	o.dusk()
	var longe := B.MURO + r.offer_trigger_px * 10.0
	assert_bool(o.due(r.offer_window_after_dusk.x, longe, B.MURO)).is_false()
	assert_bool(o.due(r.offer_window_after_dusk.y, longe, B.MURO)).is_true()


func test_d05_uma_oferta_por_noite_seja_qual_for_a_mancha_que_pergunta() -> void:
	var r := B.perfil()
	var o := _ofertas()
	o.dusk()
	assert_bool(o.due(r.offer_window_after_dusk.y, B.MURO, B.MURO)).is_true()
	o.open(_oferta(&"the_lame"), B.FORA, int(Band.Kind.SURFACE))
	# A segunda mancha do dia 12 chega depois: fica calada (§75).
	assert_bool(o.due(r.offer_window_after_dusk.y, B.MURO, B.MURO)).is_false()
	o.close_quietly()
	assert_bool(o.due(r.offer_window_after_dusk.y, B.MURO, B.MURO)).is_false()
	o.dusk()  # a noite seguinte volta a ter voz
	assert_bool(o.due(r.offer_window_after_dusk.y, B.MURO, B.MURO)).is_true()


# ─── Quem e candidata ────────────────────────────────────────────────────────


func test_so_sao_candidatas_as_que_se_podem_pagar_e_cumprir() -> void:
	var o := _ofertas()
	var ids: Array[String] = []
	for c in o.candidates(_factos({&"named": 1, &"debt": 12}), 30, PackedStringArray()):
		ids.append(String(c.id))
	assert_array(ids).contains_exactly(["give_back_whats_mine", "tell_me_a_name", "the_lame"])
	# O que falta nao esta esquecido: esta escrito, oferta a oferta.
	for c: OfferData in Registry.entries(&"rot/offers"):
		var pagavel := OfferSystem.PRECOS.has(c.price_kind)
		var cumprivel := OfferSystem.EFEITOS.has(c.effect_kind)
		assert_bool(ids.has(String(c.id)) or not (pagavel and cumprivel)).is_true()


# ─── O prato ─────────────────────────────────────────────────────────────────


func test_o_ferido_levado_ao_prato_paga_e_leva_os_outros_feridos() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var coxos := _oferta(&"the_lame")
	var no_prato := _ferido(u, estado, B.FORA, coxos.price_amount * 0.5)
	var longe := _ferido(u, estado, B.DENTRO, coxos.price_amount * 0.5)
	var inteiro := _ferido(u, estado, B.FORA, 1.0)
	var o := _ofertas()
	o.dusk()
	o.open(coxos, B.FORA, int(Band.Kind.SURFACE))
	var e := o.tick(B.PASSO, _sem_moedas(), u, {})
	assert_int(e[OfferSystem.CHAVE]).is_equal(OfferSystem.EV_ACEITE)
	assert_str(String(e[OfferSystem.OFERTA])).is_equal("the_lame")
	assert_array(Array(e[OfferSystem.SAEM])).contains_exactly([no_prato, longe])
	assert_int(u.index_of(no_prato)).is_equal(UnitSystem.NENHUM)
	assert_int(u.index_of(longe)).is_equal(UnitSystem.NENHUM)
	assert_int(u.index_of(inteiro)).is_not_equal(UnitSystem.NENHUM)


func test_o_rei_nao_e_preco_de_ninguem() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var rei := u.spawn(estado, Registry.entry(&"units", &"monarch"), B.MEU_IMPERIO, B.FORA)
	u.healths[u.index_of(rei)] = 1
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"the_lame"), B.FORA, int(Band.Kind.SURFACE))
	assert_bool(o.tick(B.PASSO, _sem_moedas(), u, {}).is_empty()).is_true()


func test_so_conta_o_que_cai_no_prato() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var r := B.perfil()
	_ferido(u, estado, B.FORA + r.offer_plate_px, 0.1)  # ao lado, nao dentro
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"the_lame"), B.FORA, int(Band.Kind.SURFACE))
	assert_bool(o.tick(B.PASSO, _sem_moedas(), u, {}).is_empty()).is_true()


func test_as_moedas_que_caem_no_prato_pagam_e_as_de_fora_ficam() -> void:
	var estado := GameState.new()
	var o := _ofertas()
	var ver := _oferta(&"just_looking")
	o.dusk()
	o.open(ver, B.FORA, int(Band.Kind.SURFACE))
	var fora := B.moedas_pousadas(estado, B.FORA + B.perfil().offer_plate_px, int(ver.price_amount))
	assert_bool(o.tick(B.PASSO, fora, UnitSystem.new(), {}).is_empty()).is_true()
	var dentro := B.moedas_pousadas(estado, B.FORA, int(ver.price_amount))
	var e := o.tick(B.PASSO, dentro, UnitSystem.new(), {})
	assert_int(e[OfferSystem.CHAVE]).is_equal(OfferSystem.EV_ACEITE)
	assert_int(e[OfferSystem.MOEDAS]).is_equal(int(ver.price_amount))
	assert_int(dentro.count()).is_equal(0)
	assert_int(fora.count()).is_equal(int(ver.price_amount))


func test_passados_20_s_o_prato_afunda_e_e_recusa() -> void:
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"the_lame"), B.FORA, int(Band.Kind.SURFACE))
	var fim := {}
	for _t in int(B.perfil().offer_seconds / B.PASSO) + 2:
		var e := o.tick(B.PASSO, _sem_moedas(), UnitSystem.new(), {})
		if not e.is_empty():
			fim = e
			break
	assert_int(fim[OfferSystem.CHAVE]).is_equal(OfferSystem.EV_CADUCA)
	assert_int(o.phase).is_equal(OfferSystem.Phase.DONE)


func test_um_nome_leva_so_a_tropa_nomeada_que_entrou() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var nomeado := _ferido(u, estado, B.FORA, 1.0)
	var outro := _ferido(u, estado, B.DENTRO, 1.0)
	var titulos := {nomeado: B.TITULO, outro: "TITLE_SECOND"}
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"tell_me_a_name"), B.FORA, int(Band.Kind.SURFACE))
	var e := o.tick(B.PASSO, _sem_moedas(), u, titulos)
	assert_array(Array(e[OfferSystem.SAEM])).contains_exactly([nomeado])
	assert_int(u.index_of(outro)).is_not_equal(UnitSystem.NENHUM)


func test_devolve_me_o_que_e_meu_leva_todos_os_nomes() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var nomeado := _ferido(u, estado, B.FORA, 1.0)
	var outro := _ferido(u, estado, B.DENTRO, 1.0)
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"give_back_whats_mine"), B.FORA, int(Band.Kind.SURFACE))
	var e := o.tick(B.PASSO, _sem_moedas(), u, {nomeado: B.TITULO, outro: "TITLE_SECOND"})
	assert_array(Array(e[OfferSystem.SAEM])).contains_exactly([nomeado, outro])


func test_a_muralha_mais_exterior_e_a_do_lado_da_mancha() -> void:
	var obras := BuildSystem.new()
	B.muro(obras, B.MURO)
	B.muro(obras, B.MURO + 200.0)
	B.muro(obras, B.NUCLEO - 400.0)
	assert_float(OfferSystem.outer_wall(obras, B.NUCLEO, 1)).is_equal(B.MURO + 200.0)
	assert_float(OfferSystem.outer_wall(obras, B.NUCLEO, -1)).is_equal(B.NUCLEO - 400.0)
	assert_float(OfferSystem.outer_wall(BuildSystem.new(), B.NUCLEO, 1)).is_equal(B.NUCLEO)


func test_o_save_leva_a_oferta_a_meio() -> void:
	var o := _ofertas()
	o.dusk()
	o.open(_oferta(&"the_lame"), B.FORA, int(Band.Kind.SURFACE))
	o.tick(B.PASSO, _sem_moedas(), UnitSystem.new(), {})
	var lido := _ofertas()
	lido.from_dict(o.to_dict())
	assert_int(lido.phase).is_equal(OfferSystem.Phase.OPEN)
	assert_str(String(lido.offer_id)).is_equal("the_lame")
	assert_float(lido.plate_x).is_equal(B.FORA)
	assert_float(lido.left).is_equal(o.left)


func _sem_moedas() -> CoinSystem:
	return CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
