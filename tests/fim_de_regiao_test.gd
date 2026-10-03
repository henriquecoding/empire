# tests/fim_de_regiao_test.gd — a bifurcacao e o fim do ciclo (AUD-05, P-K; §13,
# §16, §79; Q-135, Q-146, ADR 0035).
#
# A auditoria de 26/09: "nao ha objetivo depois do dia 3". A bifurcacao a leste
# (§83) abre a partir do dia `crossing_day`. Desde o painel de 29/09 o rei nao sai
# do reino (Q-146): o Verbo 2 la manda a marcha conquistar o povo seguinte, e o
# ciclo acaba quando todos te pagam ou o Lume se apaga — com o legado de sempre.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const LONGE := 1000.0

var _tipo := &""


func before_test() -> void:
	_tipo = &""
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.segment_entered.connect(_entrou)
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	SimLoop.step(STEP)


func after_test() -> void:
	EventBus.segment_entered.disconnect(_entrou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	LegacyStore.discard()


func _entrou(_segmento: StringName, tipo: StringName) -> void:
	_tipo = tipo


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _na_bifurcacao() -> void:
	SimLoop.units.xs[_rei()] = SimLoop.secrets.chapters[0]
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.secrets.chapters[0])


func _no_dia(dia: int) -> void:
	ClockService.seek(dia, 0.0)
	SimLoop.state.day = dia
	SimLoop.step(STEP)


func _verbo_2() -> void:
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	EventBus.flush()


func test_antes_do_dia_a_bifurcacao_so_diz_quando_abre() -> void:
	TranslationServer.set_locale("pt_PT")
	_na_bifurcacao()
	_verbo_2()
	assert_bool(SimLoop.field.realm.march.marching()).is_false()
	var texto := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(texto).contains("sai no dia %d" % SimFactory.curve().crossing_day)


## Q-146: o rei nunca sai do reino. A marcha vai; a regiao nao acaba.
func test_no_dia_da_marcha_o_verbo_2_manda_os_teus_e_o_rei_fica() -> void:
	_no_dia(SimFactory.curve().crossing_day)
	_na_bifurcacao()
	var dono := SimLoop.units.owners[_rei()]
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	for _k in SimFactory.curve().march_min_party:
		SimLoop.units.spawn(SimLoop.state, arqueiro, dono, SimLoop.units.xs[_rei()])
	var antes := SimLoop.units.count()
	_verbo_2()
	assert_bool(SimLoop.field.realm.march.marching()).is_true()
	assert_int(SimLoop.units.count()).is_equal(antes - SimFactory.curve().march_min_party)
	assert_bool(SimLoop.state.crossed).is_false()
	assert_str(String(_tipo)).is_equal("march")
	assert_bool(SimLoop.units.alive(_rei())).is_true()


func test_sem_gente_que_chegue_a_marcha_nao_sai() -> void:
	TranslationServer.set_locale("pt_PT")
	_no_dia(SimFactory.curve().crossing_day)
	_na_bifurcacao()
	_verbo_2()
	assert_bool(SimLoop.field.realm.march.marching()).is_false()
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).contains("pelo menos")


func test_longe_da_bifurcacao_o_verbo_2_nao_manda_ninguem() -> void:
	_no_dia(SimFactory.curve().crossing_day)
	SimLoop.units.xs[_rei()] = SimLoop.secrets.chapters[0] - LONGE
	_verbo_2()
	assert_bool(SimLoop.field.realm.march.marching()).is_false()


func test_o_guia_diz_que_a_marcha_pode_sair() -> void:
	TranslationServer.set_locale("pt_PT")
	_no_dia(SimFactory.curve().crossing_day)
	assert_str(GameplayGuide.goal()).contains("MARCHA")


func test_o_rei_leva_o_saco_quem_esta_perto_e_quem_espera_sem_posto() -> void:
	# Q-063: ninguem anda atras do rei, e quem espera no nucleo sem posto embarca
	# com ele, como a tripulacao do barco do Kingdom: New Lands. Quem tem posto
	# fica na regiao que se deixa.
	var r := _rei()
	var dono := SimLoop.units.owners[r]
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var lanceiro := Registry.entry(&"units", &"spearman") as UnitData
	SimLoop.units.spawn(SimLoop.state, arqueiro, dono, SimLoop.units.xs[r])
	var de_posto := SimLoop.units.spawn(SimLoop.state, lanceiro, dono, SimLoop.units.xs[r] + LONGE)
	SimLoop.units.job_ids[SimLoop.units.index_of(de_posto)] = 1
	SimLoop.units.spawn(SimLoop.state, arqueiro, dono, SimLoop.units.xs[r] + LONGE)
	SimLoop.units.carried_coins[r] = 9
	var legado := Legacy.crossing(
		SimLoop.state,
		SimLoop.units,
		SimFactory.by_id(&"units"),
		SimLoop.king_id,
		SimFactory.curve().crossing_party_px
	)
	# Os dois sem funcao do inicio (Q-110) e o construtor pioneiro (ADR 0059) esperam no
	# nucleo, e tambem vao.
	var comitiva := ["vagrant", "vagrant", "builder", "archer", "archer"]
	assert_array(Array(legado[Legacy.COMITIVA])).is_equal(comitiva)
	assert_int(int(legado[Legacy.SACO])).is_equal(9)
	assert_int(int(legado[Legacy.REGIAO])).is_equal(1)
	assert_array(legado[Legacy.OBRAS]).is_empty()


func test_a_regiao_seguinte_recebe_a_comitiva_e_o_saco() -> void:
	var legado := {
		Legacy.REGIAO: 1,
		Legacy.COMITIVA: PackedStringArray(["archer", "spearman"]),
		Legacy.SACO: 7,
	}
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	var antes := SimLoop.units.carried_coins[_rei()]
	var tropas := SimFactory.by_id(&"units")
	Legacy.apply(legado, SimLoop.state, SimLoop.builds)
	var chegaram := Legacy.arrive(
		legado, SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, SimLoop.core_x
	)
	assert_int(SimLoop.state.region).is_equal(1)
	assert_int(chegaram.size()).is_equal(2)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(antes + 7)
	for id in chegaram:
		var i := SimLoop.units.index_of(id)
		assert_int(SimLoop.units.owners[i]).is_equal(SimLoop.units.owners[_rei()])


func test_depois_da_ultima_regiao_vem_o_epilogo() -> void:
	TranslationServer.set_locale("pt_PT")
	SimLoop.state.region = SimLoop.state.chapters.regions.size() - 1
	var legado := Legacy.crossing(
		SimLoop.state, SimLoop.units, SimFactory.by_id(&"units"), SimLoop.king_id, 0.0
	)
	assert_int(int(legado[Legacy.REGIAO])).is_equal(0)
	assert_bool(legado.has(Legacy.PLANO)).is_false()
	var fim := String(SimLoop.night.epilogue()).to_upper()
	var titulo := PauseMenu.crossing_title(legado)
	assert_str(titulo).contains("Fim da campanha")
	assert_str(titulo).contains(tr(StringName("EPILOGUE_" + fim)))


func test_a_regiao_vai_no_save() -> void:
	SimLoop.state.region = 2
	assert_int(GameState.from_dict(SimLoop.state.to_dict()).region).is_equal(2)


## A pausa do fim nao refaz o save que o fim do ciclo apagou (Q-135).
func test_depois_do_fim_do_ciclo_nao_se_grava() -> void:
	_no_dia(SimFactory.curve().crossing_day)
	assert_bool(SavePoint.allowed()).is_true()
	SimLoop.state.crossed = true
	assert_bool(SavePoint.allowed()).is_false()
