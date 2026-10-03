# tests/subsolo_expedicao_test.gd — o subsolo como expedicao (AUD-04, P-I; §11,
# §06, §51; Q-130 a Q-132).
#
# A auditoria de 26/09 achou um corredor com dois segredos: nada se construia la
# em baixo, as `cavity_slots` do segments.csv nao eram lidas, e o Cavador do dia
# 10 nao tinha resposta. Passa a haver um poco em cada cavidade (as moedas dele
# caem la em baixo), uma escora em cada boca de passagem, e a mancha que nao
# gasta massa num caminho fechado.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const MINA := &"ore_pit"
const CAVADOR := &"burrower"
const BRUTO := &"brute"
const DIA_DO_CAVADOR := 10
const CHEGA := 20


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _minas() -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for obra in SimLoop.builds.slots:
		if obra.kind == MINA and obra.band == Band.Kind.UNDERGROUND:
			saida.append(obra)
	return saida


func _escora(x: float) -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == Passages.ESCORA and absf(obra.x - x) <= Band.PASSAGE_PX:
			return obra
	return null


func _de_pe(obra: BuildSlot) -> void:
	obra.level = 1
	obra.state = BuildSlot.State.DONE
	obra.health = obra.max_health()


func _ate(fase: GameClock.Phase) -> void:
	while ClockService.clock.current_phase() != fase:
		SimLoop.step(STEP)


func test_cada_cavidade_tem_um_poco_no_subsolo_mesmo_num_segmento_de_agua() -> void:
	var segmento := Registry.entry(&"segments", Greybox.SEGMENTO) as SegmentData
	assert_str(String(segmento.resource)).is_not_equal("rock")
	var minas := _minas()
	assert_int(minas.size()).is_equal(Cavities.CAVIDADES_X.size())
	assert_int(minas.size()).is_less_equal(segmento.cavity_slots * Greybox.ECRAS)
	for obra in minas:
		assert_int(obra.state).is_equal(BuildSlot.State.EMPTY)


func test_ha_uma_escora_por_construir_em_cada_boca_de_passagem() -> void:
	for x in SimLoop.passages:
		var escora := _escora(x)
		assert_object(escora).is_not_null()
		assert_int(escora.band).is_equal(Band.Kind.SURFACE)
		assert_bool(escora.blocks).is_false()
	assert_int(Passages.open(SimLoop.passages, SimLoop.builds).size()).is_equal(
		SimLoop.passages.size()
	)


func test_o_rei_la_em_baixo_paga_e_levanta_o_poco() -> void:
	var rei := _rei()
	var mina := _minas()[0]
	for muro in SimLoop.builds.slots:
		if muro.two_paths():
			muro.raise_to(2)
	SimLoop.units.xs[rei] = SimLoop.passages[0]
	assert_bool(Verbs.assume(SimLoop.units, SimLoop.king_id, SimLoop.passages)).is_true()
	SimLoop.units.xs[rei] = mina.x
	SimLoop.units.carried_coins[rei] = mina.next_cost()
	for _k in mina.next_cost():
		SimLoop.drop_coin(mina.x, Band.Kind.UNDERGROUND, 1, Verbs.JOGADOR)
	var passos := int((mina.works[0] + CHEGA) / STEP)
	for _t in passos:
		SimLoop.units.set_target_x(SimLoop.king_id, mina.x)
		SimLoop.step(STEP)
	assert_bool(mina.standing()).is_true()


func test_as_moedas_do_poco_caem_la_em_baixo() -> void:
	var mina := _minas()[0]
	_de_pe(mina)
	mina.stock = 1.0
	var eventos := SimLoop.economy.on_phase(SimLoop.builds, 0, [])
	var caiu := false
	for e in eventos:
		if e[EconomySystem.VAGA] == mina and e.has(EconomySystem.FAIXA):
			caiu = e[EconomySystem.FAIXA] == int(Band.Kind.UNDERGROUND)
	assert_bool(caiu).is_true()


func test_a_escora_fecha_a_passagem_ao_rei_e_ao_cavador() -> void:
	var x := SimLoop.passages[1]
	_de_pe(_escora(x))
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	assert_bool(Passages.near(x, abertas)).is_false()
	SimLoop.units.xs[_rei()] = x
	assert_int(Verbs.destination(SimLoop.units, SimLoop.king_id, abertas)).is_equal(Verbs.NENHUMA)
	SimLoop.step(STEP)  # a primeira alvorada dissolve quem ja la estiver
	var dados := Registry.entry(&"creatures", CAVADOR) as CreatureData
	var bicho := SimLoop.creatures.spawn(SimLoop.state, dados, x + 1.0, SimLoop.core_x)
	for _t in 3:
		SimLoop.step(STEP)
	var c := SimLoop.creatures.index_of(bicho)
	assert_int(SimLoop.creatures.bands[c]).is_equal(int(Band.Kind.UNDERGROUND))


## N4 (auditoria de 27/09; Q-138): as duas escoras de pe com o rei la em baixo
## deixavam-no sem saida. A escora fecha por cima: de baixo sobe-se na mesma, e
## o Cavador — que so sobe por uma boca aberta — continua a nao passar.
func test_as_duas_escoras_nao_prendem_o_rei_la_em_baixo() -> void:
	for x in SimLoop.passages:
		_de_pe(_escora(x))
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	assert_int(abertas.size()).is_equal(0)
	SimLoop.units.bands[_rei()] = int(Band.Kind.UNDERGROUND)
	SimLoop.units.xs[_rei()] = SimLoop.passages[0]
	var para := Verbs.destination(SimLoop.units, SimLoop.king_id, abertas)
	assert_int(para).is_equal(int(Band.Kind.SURFACE))
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	assert_int(SimLoop.units.bands[_rei()]).is_equal(int(Band.Kind.SURFACE))
	var desce := Verbs.destination(SimLoop.units, SimLoop.king_id, abertas)
	assert_int(desce).is_equal(Verbs.NENHUMA)


func test_a_mancha_nao_gasta_massa_num_subsolo_fechado() -> void:
	var rot := SimFactory.rot()
	rot.spawn(DIA_DO_CAVADOR, 1, SimLoop.world_width)
	rot.state.mass = (Registry.entry(&"creatures", CAVADOR) as CreatureData).mass_cost
	assert_str(String(rot.pick())).is_equal(String(CAVADOR))
	rot.underground_open = false
	assert_str(String(rot.pick())).is_equal(String(BRUTO))


func test_ao_crepusculo_o_lado_escorado_fecha_o_subsolo_e_o_outro_nao() -> void:
	_de_pe(_escora(SimLoop.passages[1]))
	_ate(GameClock.Phase.AFTERNOON)
	SimLoop.step(STEP)
	SimLoop.night.rot.announced = 1
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	assert_bool(SimLoop.night.rot.underground_open).is_false()
	(
		assert_bool(Passages.sealed_side(SimLoop.passages, SimLoop.builds, SimLoop.core_x, -1))
		. is_false()
	)


func test_um_poco_de_pe_chama_o_cavador_mais_cedo() -> void:
	var perfil := SimFactory.rot_profile()
	var rot := SimFactory.rot()
	var cedo := DIA_DO_CAVADOR - perfil.mine_lure_days
	rot.spawn(cedo, 1, SimLoop.world_width)
	rot.state.mass = (Registry.entry(&"creatures", CAVADOR) as CreatureData).mass_cost
	assert_str(String(rot.pick())).is_not_equal(String(CAVADOR))
	rot.lure_days = perfil.mine_lure_days
	assert_str(String(rot.pick())).is_equal(String(CAVADOR))


func test_ao_crepusculo_o_poco_de_pe_chama_e_sem_ele_nao() -> void:
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	assert_int(SimLoop.night.rot.lure_days).is_equal(0)
	SimLoop.stop()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	_de_pe(_minas()[0])
	_ate(GameClock.Phase.DUSK)
	SimLoop.step(STEP)
	assert_int(SimLoop.night.rot.lure_days).is_equal(SimFactory.rot_profile().mine_lure_days)


func test_o_guia_manda_subir_a_tarde_quem_esta_la_em_baixo() -> void:
	TranslationServer.set_locale("pt_PT")
	_ate(GameClock.Phase.AFTERNOON)
	SimLoop.step(STEP)
	SimLoop.units.bands[_rei()] = int(Band.Kind.UNDERGROUND)
	assert_str(GameplayGuide.goal()).contains("SOBE")


func test_na_boca_por_escorar_o_painel_diz_que_se_pode_escorar() -> void:
	TranslationServer.set_locale("pt_PT")
	SimLoop.units.xs[_rei()] = SimLoop.passages[0]
	var texto := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(texto).contains("escora")
	_de_pe(_escora(SimLoop.passages[0]))
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).not_contains("escora-a")
