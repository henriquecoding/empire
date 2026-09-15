# tests/producao_test.gd — o circuito 1 do §06, medido no jogo a andar.
#
# O design_data_test ja confere a coluna "Payback" do §06 contra os .tres:
# custo a dividir pelo rendimento diario da 2 dias no canteiro e no pesqueiro,
# 2,7 no galinheiro. Isso prova que os DADOS dizem o que o dossie diz.
#
# Este ficheiro prova a outra metade, que e a que pode partir sem ninguem dar
# por isso: que uma obra de pe larga mesmo esse numero de moedas por dia com os
# onze passos do §43 a correr a volta. Entre o 2,0 do CSV e duas moedas no chao
# estao seis fases, um stock fraccionario e um `floor` — e um `floor` mal posto
# come uma moeda por dia sem falhar teste nenhum.
#
# A mancha fica de fora destas medicoes DE PROPOSITO. O §06 poe o risco numa
# coluna ao lado do payback, e nao dentro dele: o rasto e o assunto dos dois
# ultimos testes, com nome proprio.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
## §06: o rasto so arrasa a plantacao; as outras obras so param.
const RASTO_LARGURA := 200.0


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _edificio(id: StringName) -> BuildingData:
	return Registry.entry(&"buildings", id) as BuildingData


## Um dia inteiro de jogo, com a mancha mandada embora assim que nasce. Quem
## mede o rendimento nao quer a coluna do risco a entrar pela medicao dentro.
func _um_dia_sem_mancha() -> void:
	for _i in int(_relogio().day_seconds / PASSO):
		SimLoop.step(PASSO)
		if SimLoop.night.rot.active():
			SimLoop.night.rot.retreat()


## Poe a obra de pe agora, sem esperar pelo construtor: o que se mede aqui e o
## que ela produz, e nao o que ela custa a levantar (isso e o jogo_test).
func _levantar(tipo: StringName) -> BuildSlot:
	var vaga := _vaga(tipo)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	vaga.stock = 0.0
	return vaga


func _vaga(tipo: StringName) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == tipo:
			return vaga
	fail("a regiao nao tem nenhum sitio de %s" % tipo)
	return null


## As moedas que ESTA obra largou, contadas pelo sinal da §46 e nao pelo chao:
## uma moeda apanhada por alguem deixa de estar no chao e continua a ter sido
## produzida.
func _moedas_de(vaga: BuildSlot, dias: int) -> int:
	# Uma Array e nao um int: uma lambda de GDScript captura as locais por VALOR,
	# e um contador inteiro la dentro incrementa uma copia.
	var caidas: Array[int] = []
	var ouvinte := func(x: float, _b: int, quanto: int, origem: StringName) -> void:
		if origem == EventRelay.FONTE_PRODUCAO and is_equal_approx(x, vaga.x):
			caidas.append(quanto)
	EventBus.coin_dropped.connect(ouvinte)
	for _d in dias:
		_um_dia_sem_mancha()
	EventBus.coin_dropped.disconnect(ouvinte)
	var total := 0
	for quanto in caidas:
		total += quanto
	return total


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


# ─── O payback do §06, medido ────────────────────────────────────────────────


func test_o_canteiro_paga_se_ao_fim_de_dois_dias() -> void:
	var dados := _edificio(Greybox.CANTEIRO)
	var vaga := _levantar(Greybox.CANTEIRO)

	var moedas := _moedas_de(vaga, 2)

	assert_int(moedas).is_greater_equal(dados.cost)


func test_o_pesqueiro_paga_se_ao_fim_de_dois_dias() -> void:
	var dados := _edificio(Greybox.PESQUEIRO)
	var vaga := _levantar(Greybox.PESQUEIRO)

	var moedas := _moedas_de(vaga, 2)

	assert_int(moedas).is_greater_equal(dados.cost)


func test_o_galinheiro_nao_se_paga_em_dois_dias_e_paga_se_em_tres() -> void:
	# 2,7 dias na tabela do §06, e a tabela nao mente: e mais caro e rende o
	# mesmo que o pesqueiro. E a licao da coluna — nem toda a producao e igual.
	var dados := _edificio(Greybox.GALINHEIRO)
	var vaga := _levantar(Greybox.GALINHEIRO)

	assert_int(_moedas_de(vaga, 2)).is_less(dados.cost)
	assert_int(_moedas_de(vaga, 1)).is_greater(0)


func test_uma_obra_de_pe_larga_por_dia_o_que_o_csv_lhe_da() -> void:
	# O que separa o 2,0 do CSV de duas moedas no chao: seis fases, um stock
	# fraccionario e um floor. Sem isto, 2/6 por fase da 0,99999 a meio do dia
	# e o dia inteiro perde uma moeda.
	for id in [Greybox.CANTEIRO, Greybox.PESQUEIRO, Greybox.GALINHEIRO]:
		SimLoop.stop()
		SimLoop.start(SEMENTE)
		Greybox.build()
		var vaga := _levantar(id)
		assert_int(_moedas_de(vaga, 1)).is_equal(int(_edificio(id).yield_per_day))


# ─── As fontes, e a curva do §06 contra os edificios reais (Q-033) ───────────


func test_a_regiao_tem_as_sete_fontes_do_perfil_equilibrado() -> void:
	# O perfil `balanced` do §06 corre com 7 fontes e da o dia 11 de asfixia. Se
	# a regiao nao tiver 7, esse numero e sobre outro jogo qualquer.
	for vaga in SimLoop.builds.slots:
		if vaga.yield_per_day > 0.0:
			_levantar(vaga.kind)
			vaga.level = 1
			vaga.state = BuildSlot.State.DONE
			vaga.health = vaga.max_health()
	var perfil := Registry.entry(&"economy/profiles", &"balanced") as EconomyProfile

	assert_int(SimLoop.economy.sources(SimLoop.builds)).is_equal(perfil.sources)


func test_so_conta_quem_esta_de_pe() -> void:
	# Um sitio de obra vazio nao e uma fonte. O §06 conta o que produz, e um
	# canteiro por pagar nao produz nada.
	assert_int(SimLoop.economy.sources(SimLoop.builds)).is_equal(0)

	_levantar(Greybox.CANTEIRO)

	assert_int(SimLoop.economy.sources(SimLoop.builds)).is_equal(1)


func test_os_edificios_reais_rendem_menos_do_que_o_simulador_do_06() -> void:
	# Q-033, medida em vez de afirmada. O simulador do §06 da 3 + 2,6 por fonte
	# e os edificios de buildings.csv dao a soma dos yields — e os dois numeros
	# NAO sao o mesmo. Fica escrito aqui para que o dia em que alguem afinar
	# economy.csv ou buildings.csv veja a diferenca mudar.
	for vaga in SimLoop.builds.slots:
		if vaga.yield_per_day > 0.0:
			vaga.level = 1
			vaga.state = BuildSlot.State.DONE
			vaga.health = vaga.max_health()
	var fontes := SimLoop.economy.sources(SimLoop.builds)
	var abstrato := SimLoop.economy.daily_income(fontes, 1)
	var real := SimLoop.economy.built_income(SimLoop.builds, 1)

	assert_float(real).is_less(abstrato)
	assert_float(real).is_greater(abstrato * 0.75)


# ─── O risco, que e a coluna ao lado e nao o payback ─────────────────────────


func test_o_rasto_arrasa_o_canteiro_e_so_para_o_galinheiro() -> void:
	var canteiro := _levantar(Greybox.CANTEIRO)
	var galinheiro := _levantar(Greybox.GALINHEIRO)
	var rasto: Array[Vector2] = [
		Vector2(canteiro.x - RASTO_LARGURA, canteiro.x + RASTO_LARGURA),
		Vector2(galinheiro.x - RASTO_LARGURA, galinheiro.x + RASTO_LARGURA)
	]

	var eventos := SimLoop.economy.on_phase(SimLoop.builds, 0, rasto)

	var arrasadas: Array[StringName] = []
	for evento in eventos:
		if evento[EconomySystem.CHAVE] == EconomySystem.EV_ARRASADA:
			arrasadas.append((evento[EconomySystem.VAGA] as BuildSlot).kind)
	assert_array(arrasadas).contains([Greybox.CANTEIRO])
	assert_array(arrasadas).not_contains([Greybox.GALINHEIRO])


func test_quem_esta_no_rasto_nao_produz_naquela_fase() -> void:
	var galinheiro := _levantar(Greybox.GALINHEIRO)
	var rasto: Array[Vector2] = [
		Vector2(galinheiro.x - RASTO_LARGURA, galinheiro.x + RASTO_LARGURA)
	]

	for _fase in _relogio().phase_durations.size():
		SimLoop.economy.on_phase(SimLoop.builds, 0, rasto)

	assert_float(galinheiro.stock).is_equal(0.0)
