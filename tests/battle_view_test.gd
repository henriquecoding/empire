# tests/battle_view_test.gd — o combate que se ve, ligado a §46 (§07, §24, §50).
#
# A ponta que os testes de unidade nao apanham: o nome e a aridade dos sinais.
# Um `attack_launched` ou um `unit_died` com outra assinatura liga sem se
# queixar e nunca chama ninguem — e o defeito so aparecia numa noite a olhar.
extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260916)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	CombatFx.reset()


## A vista, com o ImpactView ao lado com o nome que a cena de jogo lhe da.
func _vista() -> BattleView:
	var mundo: Node2D = auto_free(Node2D.new())
	var impactos := ImpactView.new()
	impactos.name = "Impactos"
	mundo.add_child(impactos)
	var vista := BattleView.new()
	mundo.add_child(vista)
	add_child(mundo)
	return vista


func _arqueiro() -> int:
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == &"archer":
			return SimLoop.units.ids[i]
	return UnitSystem.NENHUM


## O arqueiro solta uma flecha, acerte ou falhe; quem bate de perto nao solta.
func test_o_arqueiro_solta_uma_flecha_e_o_rei_nao() -> void:
	var vista := _vista()
	var arqueiro := _arqueiro()
	assert_int(arqueiro).is_not_equal(UnitSystem.NENHUM)
	var alvo := SimLoop.king_id
	EventBus.queue(&"attack_launched", [arqueiro, alvo, true])
	EventBus.queue(&"attack_launched", [arqueiro, alvo, false])
	EventBus.queue(&"attack_launched", [SimLoop.king_id, arqueiro, true])
	EventBus.flush()
	assert_int(vista.arrows().flying()).is_equal(2)
	# Quem bate de perto arma o golpe, e o golpe ve-se.
	assert_float(CombatFx.since_attack(SimLoop.king_id)).is_less(StrikePose.STRIKE_S)


## A flecha que acerta entrega o golpe ao chegar: so ai o corpo e empurrado.
func test_a_flecha_entrega_o_golpe_ao_chegar() -> void:
	var vista := _vista()
	EventBus.queue(&"attack_launched", [_arqueiro(), SimLoop.king_id, true])
	EventBus.flush()
	assert_float(CombatFx.flash(SimLoop.king_id)).is_equal(0.0)
	vista._process(Volley.VOO.y + 0.01)
	assert_int(vista.arrows().flying()).is_equal(0)
	assert_float(absf(CombatFx.recoil(SimLoop.king_id))).is_greater(0.0)


## Uma criatura que morre desfaz-se no sitio do ultimo desenho; uma tropa cai e
## levanta po.
func test_quem_morre_deixa_rasto() -> void:
	var vista := _vista()
	LastSeen.remember(999, Rect2(10, 470, 20, 30), Silhouette.Form.BRUTO, Color.RED)
	EventBus.queue(&"creature_died", [999, 20.0, int(Band.Kind.SURFACE)])
	EventBus.flush()
	assert_int(vista.bursts().pieces().size()).is_greater(0)
	var tropa := _arqueiro()
	EventBus.queue(&"unit_died", [tropa, 40.0, int(Band.Kind.SURFACE), PackedStringArray()])
	EventBus.flush()
	CombatFx.advance(CombatFx.QUEDA_S)
	assert_float(absf(CombatFx.fall(tropa))).is_greater(1.0)
