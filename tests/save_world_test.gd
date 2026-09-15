# tests/save_world_test.gd — "fechar e reabrir no dia 7 preserva tudo, incluindo
# a sequencia aleatoria" (F1-14, §62).
#
# Ate aqui o save levava o relogio e mais nada: o autosave de cada alvorada
# escrevia um ficheiro que nao conseguia repor uma partida. As coleccoes da §45
# — tropas, criaturas, moedas, obras, mancha — passam a entrar.
#
# O que NAO entra, e e a decisao que este teste tambem fixa: a escada de uma
# obra, a largura dela e os efeitos sao AUTORADOS pelo segmento (§21) e voltam a
# existir quando ele volta a ser montado. Um save que os levasse deixava de
# poder ser carregado no dia em que o segmento mudasse.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
const SLOT := 0
const DIA_ALVO := 7


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _correr(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		SimLoop.step(PASSO)


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SaveService.delete_slot(SLOT)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	SaveService.delete_slot(SLOT)


## Uma partida com coisas dentro: gente recrutada, moedas no chao, uma obra a
## meio, e a noite do dia em que se grava.
func _jogar_ate_ao_dia(dia: int) -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()
	var canteiro: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == &"farm":
			canteiro = vaga
			break
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[rei] = canteiro.x
	for _k in canteiro.next_cost():
		SimLoop.drop_coin(canteiro.x, canteiro.band, 1, &"player")
	_correr(_relogio().day_seconds * (dia - 1))


func test_o_dia_7_reabre_no_dia_7() -> void:
	_jogar_ate_ao_dia(DIA_ALVO)
	assert_int(SimLoop.state.day).is_equal(DIA_ALVO)
	var antes := SimLoop.state.to_dict()
	var mundo := SimLoop.world()

	assert_bool(SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), mundo)).is_true()
	SimLoop.stop()

	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))

	assert_dict(SimLoop.state.to_dict()).is_equal(antes)
	assert_int(ClockService.clock.day).is_equal(DIA_ALVO)


func test_as_coleccoes_voltam_todas() -> void:
	_jogar_ate_ao_dia(DIA_ALVO)
	var antes := SimLoop.world()
	assert_int(SimLoop.units.count()).is_greater(0)

	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), antes)
	SimLoop.stop()
	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))

	var depois := SimLoop.world()
	for chave in antes:
		var porque := "a coleccao %s nao voltou igual" % chave
		assert_that(depois[chave]).override_failure_message(porque).is_equal(antes[chave])


func test_o_indice_de_ids_e_reconstruido() -> void:
	# O dicionario de ids e DERIVADO das colunas e nao vai no ficheiro. Sem o
	# reindexar, tudo parecia certo ate alguem procurar uma unidade por id.
	_jogar_ate_ao_dia(2)
	var quem := SimLoop.units.ids[SimLoop.units.count() - 1]
	var mundo := SimLoop.world()
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), mundo)
	SimLoop.stop()

	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))

	assert_int(SimLoop.units.index_of(quem)).is_not_equal(UnitSystem.NENHUM)
	assert_int(SimLoop.units.ids[SimLoop.units.index_of(quem)]).is_equal(quem)


func test_a_obra_a_meio_volta_a_meio() -> void:
	_jogar_ate_ao_dia(2)
	var canteiro: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == &"farm":
			canteiro = vaga
			break
	var nivel := canteiro.level
	var estado := canteiro.state
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())
	SimLoop.stop()

	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))

	var voltou: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == &"farm":
			voltou = vaga
			break
	assert_int(voltou.level).is_equal(nivel)
	assert_int(voltou.state).is_equal(estado)
	# A escada volta do segmento e nao do ficheiro (§21).
	assert_array(voltou.costs).is_not_empty()


func test_a_sequencia_aleatoria_continua_onde_ia() -> void:
	# §42: "guardar a semente nao chega. Quem grava a meio da noite 9 tem de
	# retomar a sequencia onde ia" — senao carregar muda a noite que se estava a
	# jogar, e o defeito parece um fantasma.
	_jogar_ate_ao_dia(3)
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())
	var seguinte := RngService.unit_float(&"combat")
	SimLoop.stop()

	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))

	assert_float(RngService.unit_float(&"combat")).is_equal(seguinte)


func test_um_save_sem_mundo_nao_rebenta() -> void:
	# §62: um save de outra versao degrada em vez de recusar. Os saves anteriores
	# ao F1-14 nao tem a chave `world`, e continuam a abrir.
	SimLoop.start(SEMENTE)
	Greybox.build()
	_correr(1.0)
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot())

	assert_dict(SaveService.restore_world(SLOT)).is_empty()
	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))

	# Volta sem gente, e e isso que "degradar" quer dizer: o relogio e a semente
	# vem de la, o campo nao, e o jogo abre em vez de recusar o ficheiro.
	assert_int(SimLoop.units.count()).is_equal(0)
	assert_int(SimLoop.state.seed).is_equal(SEMENTE)
	assert_int(SimLoop.builds.count()).is_greater(0)
	SimLoop.step(PASSO)


func test_as_colunas_saem_do_proprio_sistema() -> void:
	# O Columns le o get_property_list(): uma coluna nova entra no save por ser
	# declarada. Este teste e o que apanha o dia em que ele deixar de as ver.
	var unidades := UnitSystem.new()
	var nomes := Columns.names(unidades)

	assert_array(nomes).contains(["ids", "data_ids", "xs", "healths", "carried_coins"])
	assert_bool(nomes.has("_por_id")).is_false()
	assert_int(nomes.size()).is_equal(unidades.to_dict().size())
