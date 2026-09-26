# tests/destino_da_moeda_test.gd — uma moeda paga o que o painel promete, e so
# isso (D1 e D5 da auditoria de 26/09; §02, §55, §61).
#
# "Se o ves, funciona; se nao funciona, nao o ves" (PriceTag). Ate aqui a moeda
# pousada servia quatro leitores pela ordem do tick — obra, treino, celeiro,
# quem a foi buscar —, e nenhum sabia quem a largou nem para que. O destino passa
# a resolver-se no gesto, com a mesma conta que o painel faz, e so o jogador
# paga obras: a venda do celeiro, a caca e o saque nunca pagam nada sozinhos.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const O_VAGABUNDO := 2
const ASSENTAR := 45


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _obra(kind: StringName) -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == kind:
			return obra
	return null


func _de_pe(obra: BuildSlot) -> void:
	obra.level = 1
	obra.state = BuildSlot.State.DONE
	obra.health = obra.max_health()


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _largar_do_rei() -> void:
	var moeda := {
		&"x": SimLoop.units.xs[_rei()],
		&"band": Band.Kind.SURFACE,
		&"amount": InputRouter.UMA,
		&"source": Verbs.JOGADOR
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)


func _parado_em(x: float, passos: int) -> void:
	for _t in passos:
		SimLoop.units.set_target_x(SimLoop.king_id, x)
		SimLoop.step(STEP)


func test_o_celeiro_nao_troca_de_modo_sem_gesto() -> void:
	var celeiro := _obra(&"granary")
	_de_pe(celeiro)
	for obra in SimLoop.builds.slots:
		if obra.kind == &"farm":
			_de_pe(obra)
	var dono := SimLoop.units.owners[_rei()]
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"cook"), dono, SimLoop.core_x)
	var trocas := 0
	var modo := SimLoop.field.conversion.mode_of(celeiro)
	_parado_em(SimLoop.core_x, 0)
	for _t in int(ClockService.clock.day_seconds() * 1.5 / STEP):
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(STEP)
		if SimLoop.field.conversion.mode_of(celeiro) != modo:
			trocas += 1
			modo = SimLoop.field.conversion.mode_of(celeiro)
	assert_int(trocas).is_equal(0)
	assert_int(modo).is_equal(CraftData.Mode.COIN)


func test_a_moeda_largada_em_cima_do_vagabundo_recruta_o() -> void:
	var vagabundo := SimLoop.units.index_of(O_VAGABUNDO)
	var x := SimLoop.units.xs[vagabundo]
	SimLoop.units.xs[_rei()] = x
	var largadas := 0
	for t in ASSENTAR * 4:
		vagabundo = SimLoop.units.index_of(O_VAGABUNDO)
		if SimLoop.units.owners[vagabundo] != RecruitSystem.SEM_DONO:
			break
		if t % ASSENTAR == 0:
			_largar_do_rei()
			largadas += 1
		_parado_em(x, 1)
	assert_int(SimLoop.units.owners[vagabundo]).is_not_equal(RecruitSystem.SEM_DONO)
	# A moeda largada aos pes do rei nao lhe volta ao saco antes de o vagabundo
	# chegar a ela: uma chega.
	assert_int(largadas).is_equal(1)
	for obra in SimLoop.builds.slots:
		assert_int(obra.paid).is_equal(0)


func test_ninguem_por_recrutar_nasce_dentro_de_uma_obra() -> void:
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO:
			continue
		var alvo := CoinTarget.slot_at(SimLoop.builds, SimLoop.units.xs[i], SimLoop.units.bands[i])
		(
			assert_int(alvo)
			. override_failure_message(
				"a unidade %d nasce dentro da obra %d" % [SimLoop.units.ids[i], alvo]
			)
			. is_equal(CoinTarget.NENHUM)
		)


func test_o_rei_em_cima_de_uma_obra_paga_essa_obra() -> void:
	for obra in SimLoop.builds.slots:
		if obra.kind == BuildSlot.NUCLEO:
			continue
		var alvo := CoinTarget.slot_at(SimLoop.builds, obra.x, int(obra.band))
		assert_int(alvo).is_equal(obra.id)


func test_a_moeda_da_producao_nao_paga_a_obra_onde_cai() -> void:
	var muro: BuildSlot = null
	for obra in SimLoop.builds.slots:
		if obra.two_paths():
			muro = obra
			break
	SimLoop.drop_coin(muro.x, muro.band, 1, EventRelay.FONTE_PRODUCAO)
	_parado_em(SimLoop.core_x, ASSENTAR)
	assert_int(muro.paid).is_equal(0)
	assert_int(muro.state).is_equal(BuildSlot.State.EMPTY)


func test_a_moeda_do_jogador_em_cima_da_obra_paga_a() -> void:
	var canteiro := _obra(&"farm")
	SimLoop.units.xs[_rei()] = canteiro.x
	_largar_do_rei()
	_parado_em(canteiro.x, ASSENTAR)
	assert_int(canteiro.paid).is_equal(1)
