# tests/mundo_fronteira_test.gd — o mundo gera-se ao andar e fica gravado (o pedido do
# dono de 30/09/2026; §21; ADR 0038).
#
# "O mapa deve ser gerado proceduralmente como minecraft: conforme a pessoa anda e
# gerado mapa que faz sentido, e o mapa fica salvo daquele jeito o resto da gameplay."
# E: "nesses caminhos se encontra acampamentos de mendigos, mercenarios, dungeons".
# Aqui, com o jogo inteiro: o que se ve a frente do rei gera-se, o mundo e o mesmo
# venha ele de onde vier, cada encontro faz o que diz, e o save guarda tudo.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SEMENTE := 20260930
const PASSADA := 300.0


func before_test() -> void:
	_comecar()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _comecar() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(PASSO)


func _terras() -> WildSegments:
	return SimLoop.field.wilds


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _por_o_rei(x: float) -> void:
	SimLoop.units.xs[_rei()] = x
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.step(PASSO)


func _gerar_tudo() -> void:
	var limites := Frontier.walk_limits()
	_por_o_rei(limites.y)
	_por_o_rei(limites.x)


func _mercenario_em(x: float) -> int:
	for i in SimLoop.units.count():
		var livre := SimLoop.units.owners[i] == RecruitSystem.SEM_DONO and SimLoop.units.alive(i)
		var perto := absf(SimLoop.units.xs[i] - x) <= Frontier.CAMPO_PX
		if livre and perto and SimLoop.units.data_ids[i] == &"mercenary":
			return i
	return UnitSystem.NENHUM


func _moedas_em(x: float, faixa: Band.Kind) -> int:
	var total := 0
	for i in SimLoop.coins.count():
		if absf(SimLoop.coins.xs[i] - x) < 1.0 and int(SimLoop.coins.bands[i]) == int(faixa):
			total += SimLoop.coins.amounts[i]
	return total


func _retomar(mundo: Dictionary) -> void:
	var estado := GameState.from_dict(SimLoop.state.to_dict())
	var fluxos := RngService.snapshot()
	SimLoop.stop()
	SimLoop.resume(estado, fluxos)
	Greybox.region()
	SimLoop.load_world(mundo)


## Um mundo novo tem o plano inteiro e nada gerado: o rei ainda nao foi a lado nenhum.
func test_no_inicio_ha_o_plano_e_nada_gerado() -> void:
	assert_int(_terras().count(WorldPlan.OESTE)).is_equal(0)
	assert_int(_terras().count(WorldPlan.LESTE)).is_equal(0)
	assert_int(_terras().plan.size(WorldPlan.LESTE)).is_greater(0)
	assert_float(SimLoop.wild_px).is_equal(_terras().reach(SimLoop.world_width))


func test_ao_pe_da_borda_da_regiao_gera_se_o_que_se_ve() -> void:
	_por_o_rei(SimLoop.world_width - 100.0)
	assert_int(_terras().count(WorldPlan.LESTE)).is_equal(2)
	assert_int(_terras().count(WorldPlan.OESTE)).is_equal(0)


func test_andar_ate_ao_fim_gera_ate_a_borda_e_para_na_beira() -> void:
	_gerar_tudo()
	assert_bool(_terras().full(WorldPlan.LESTE)).is_true()
	assert_bool(_terras().full(WorldPlan.OESTE)).is_true()
	var e := _terras().plan.size(WorldPlan.LESTE)
	var beira := _terras().x_of(WorldPlan.LESTE, e - 1, SimLoop.world_width)
	assert_float(Frontier.walk_limits().y).is_equal(beira + WildSegments.BORDO_PX)


## O chunk do Minecraft e o mesmo venha o jogador de onde vier: saltar para a borda e
## andar ate la aos poucos dao o mesmo mundo.
func test_o_mundo_e_o_mesmo_venha_o_rei_de_onde_vier() -> void:
	_por_o_rei(Frontier.walk_limits().y)
	var de_uma_vez: Array = _terras().to_dict()[&"east"]
	SimLoop.stop()
	_comecar()
	var x := SimLoop.core_x
	while not _terras().full(WorldPlan.LESTE):
		x += PASSADA
		_por_o_rei(x)
	assert_array(_terras().to_dict()[&"east"]).is_equal(de_uma_vez)


func test_o_acampamento_de_mendigos_recebe_o_vagabundo_da_alvorada() -> void:
	_gerar_tudo()
	var novos := _terras().camps(SimLoop.world_width)
	assert_bool(novos.is_empty()).is_false()
	for x in novos:
		assert_int(SimLoop.field.camps.count(x)).is_equal(1)
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == &"vagrant":
			SimLoop.units.owners[i] = 1  # esvaziar o teto global antes de medir reposicao
	var antes := SimLoop.units.count()
	Camps.dawn(PackedFloat32Array([novos[0]]), 2, SimLoop.units, SimLoop.state)
	assert_int(SimLoop.units.count()).is_equal(antes + 1)
	assert_float(SimLoop.units.xs[SimLoop.units.count() - 1]).is_equal(novos[0])


## Um mercenario espera em cada acampamento, ao preco dele; contratado, a alvorada traz
## outro — e so um de cada vez.
func test_o_acampamento_de_mercenarios_tem_um_a_espera() -> void:
	_gerar_tudo()
	var sitios := _terras().mercenaries(SimLoop.world_width)
	assert_bool(sitios.is_empty()).is_false()
	var m := _mercenario_em(sitios[0])
	assert_int(m).is_not_equal(UnitSystem.NENHUM)
	var preco := (Registry.entry(&"units", &"mercenary") as UnitData).recruit_cost
	assert_int(SimLoop.units.recruit_costs[m]).is_equal(preco)
	SimLoop.units.owners[m] = SimLoop.units.owners[_rei()]
	Camps.mercenaries(sitios, SimLoop.units, SimLoop.state)
	assert_int(_mercenario_em(sitios[0])).is_not_equal(UnitSystem.NENHUM)
	var antes := SimLoop.units.count()
	Camps.mercenaries(sitios, SimLoop.units, SimLoop.state)
	assert_int(SimLoop.units.count()).is_equal(antes)


## A masmorra: uma boca que o Verbo 2 desce, e um monte de moedas na camara. As bocas
## das masmorras nao entram nas passagens que a noite le (Q-132: escorar fecha o lado).
## A recompensa nasce dentro, no meio da baia, na primeira descida (ADR 0072).
func test_a_masmorra_tem_boca_e_a_recompensa_sorteada() -> void:
	var passagens := SimLoop.passages.size()
	_gerar_tudo()
	var bocas := UnderWatch.mouths(SimLoop.field)
	assert_bool(bocas.is_empty()).is_false()
	for side in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in _terras().count(side):
			var entry := _terras().at(side, k)
			if int(entry.get(WildSegments.PASSAGEM, 0)) <= 0 or not entry.has(&"dungeon"):
				continue
			var reward: Dictionary = entry[&"dungeon"]
			UnderWatch.enter(_terras().subject_x(side, k, SimLoop.world_width), Band.PASSAGE_PX)
			var x := float(reward[DungeonWatch.POSTA])
			if reward[&"kind"] == &"treasure":
				assert_int(_moedas_em(x, Band.Kind.UNDERGROUND)).is_equal(int(reward[&"coins"]))
			elif reward[&"kind"] == &"guardian":
				var i := SimLoop.creatures.index_of(int(reward[&"guardian"]))
				assert_int(i).is_greater_equal(0)
				assert_int(SimLoop.creatures.coin_drops[i]).is_equal(int(reward[&"coins"]))
			else:
				assert_str(String(reward[&"kind"])).is_equal("relic")
				(
					assert_bool(SimLoop.secrets.ids.has(StringName("dungeon_%s_%s" % [side, k])))
					. is_true()
				)
	SimLoop.units.xs[_rei()] = bocas[0]
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	var desce := Verbs.destination(SimLoop.units, SimLoop.king_id, abertas)
	assert_int(desce).is_equal(int(Band.Kind.UNDERGROUND))
	assert_int(SimLoop.passages.size()).is_equal(passagens)


func test_o_mundo_gerado_vai_no_save_e_volta_igual() -> void:
	_gerar_tudo()
	var terras := _terras().to_dict()
	var acampamentos := SimLoop.field.camps.size()
	var moedas := SimLoop.coins.count()
	_retomar(SimLoop.world())
	assert_dict(_terras().to_dict()).is_equal(terras)
	assert_int(SimLoop.field.camps.size()).is_equal(acampamentos)
	assert_int(SimLoop.coins.count()).is_equal(moedas)
	var bocas := _terras().dungeons(SimLoop.world_width)
	SimLoop.units.xs[_rei()] = bocas[0]
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	assert_int(Verbs.destination(SimLoop.units, SimLoop.king_id, abertas)).is_not_equal(-1)


func test_um_save_de_antes_do_mundo_continuo_gera_ao_andar() -> void:
	var mundo := SimLoop.world()
	mundo.erase(&"wilds")
	_retomar(mundo)
	assert_int(_terras().count(WorldPlan.LESTE)).is_equal(0)
	assert_int(_terras().plan.size(WorldPlan.LESTE)).is_greater(0)
	_por_o_rei(SimLoop.world_width - 100.0)
	assert_int(_terras().count(WorldPlan.LESTE)).is_equal(2)


## O guia diz onde o rei esta: na terra de outro povo, de quem e ela (e se e tua
## vassala); no fim do mundo, o que la ha.
func test_o_guia_diz_de_quem_e_a_terra_e_o_que_ha_no_fim() -> void:
	TranslationServer.set_locale("pt_PT")
	_gerar_tudo()
	var terras := _terras()
	var lado := WorldPlan.LESTE
	var k := 0
	while terras.plan.zone(lado, k) != WorldPlan.Zone.THRESHOLD:
		k += 1
	_por_o_rei(terras.subject_x(lado, k, SimLoop.world_width))
	var bioma := Registry.entry(&"biomes", StringName(terras.at(lado, k)[WildSegments.PARA]))
	var povo := Registry.entry(&"peoples", (bioma as BiomeData).people) as PeopleData
	var nome := TranslationServer.translate(povo.display_key)
	var texto := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(texto).contains(nome)
	SimLoop.field.realm.vassals.add(povo.id, 1, 1.0, SimLoop.state.day)
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).is_not_equal(texto).contains(nome)
	_por_o_rei(Frontier.walk_limits().y)
	var fim := terras.at(lado, terras.count(lado) - 1)
	var chave := "EDGE_" + String(fim[WildSegments.ASSUNTO]).to_upper()
	var borda := TranslationServer.translate(StringName(chave))
	assert_str(borda).is_not_equal(chave)
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).contains(borda)
