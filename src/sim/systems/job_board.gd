# src/sim/systems/job_board.gd — a camada A da §52: quem trabalha onde.
#
# E o algoritmo do Kingdom, e a previsibilidade e a funcionalidade. Num jogo de
# controlo indireto o jogador tem de conseguir antecipar para onde vai a tropa;
# uma IA que otimiza melhor mas surpreende e pior (§52). Por isso: sem behavior
# trees, sem custo escondido, e uma formula de tres termos que se le em voz alta.
#
#     score = adequacao(unidade, posto) x proximidade x urgencia(fase)
#
# A histerese e a parte que parece um detalhe e nao e: sem ela a atribuicao
# treme a cada fase e as tropas passam o dia a atravessar o mapa em vez de
# trabalhar. Uma unidade so muda de posto se o score novo superar o atual em
# mais do que job_hysteresis (§29, prompt 4).
#
# Puro: nao e Node, nao conhece o catalogo de eventos, e nao sorteia nada — a
# atribuicao e determinista de proposito, e e a mesma duas vezes seguidas.
#
# Uma diferenca de forma face ao §29, e so de forma: o prompt escreve
# `assign(units: Array[UnitState], ...)` e aqui as tropas sao COLUNAS (§52,
# §63). A tabela da §70 manda no UnitSystem, e por isso e ele que entra.
class_name JobBoard
extends RefCounted

const NENHUM := -1

## Abaixo disto ninguem e atribuido. Zero e o que sai de um posto sem urgencia
## nesta fase (a plantacao a noite) ou de quem nao serve para ele: em qualquer
## dos casos, por la alguem era pior do que deixar a vaga aberta.
const SCORE_MINIMO := 0.0

var slots: Array[JobSlot] = []

var _curva: EconomyCurve
var _postos: Dictionary = {}
var _dados: Dictionary = {}
var _anterior: Dictionary = {}


## `postos` e JobData por id; `dados` e UnitData por id. Os dois entram de fora
## porque a simulacao nao conhece o indice de recursos (§70).
func _init(curva: EconomyCurve, postos: Dictionary, dados: Dictionary) -> void:
	assert(curva != null, "o JobBoard precisa de um EconomyCurve")
	_curva = curva
	_postos = postos
	_dados = dados


## Publica uma vaga e devolve-a, ja com o id que a coluna job_ids vai guardar.
func post(vaga: JobSlot) -> JobSlot:
	vaga.id = slots.size()
	vaga.unit_id = NENHUM
	slots.append(vaga)
	return vaga


## Esquece as vagas e quem estava nelas. E o que um segmento novo, ou um muro
## que caiu, obrigam: uma vaga que deixou de existir nao pode continuar a
## prender uma tropa.
func clear() -> void:
	slots = []
	_anterior = {}


func free_slots() -> int:
	var n := 0
	for vaga in slots:
		if vaga.unit_id == NENHUM:
			n += 1
	return n


## Uma passagem, uma vez por fase (passo 3 do §43). Devolve unit_id -> id da
## vaga, e escreve a coluna job_ids e o alvo de quem foi atribuido.
##
## As vagas sao percorridas por prioridade decrescente (§52) e as tropas por id
## crescente (§42): a ordem das colunas nao e estavel e uma atribuicao que
## dependesse dela mudava a cada morte.
func assign(unidades: UnitSystem, fase: int) -> Dictionary:
	var ordem := _vagas_por_prioridade()
	var candidatos := _candidatos(unidades)
	var novo := {}

	for vaga in ordem:
		vaga.unit_id = NENHUM
		var melhor := NENHUM
		var melhor_score := SCORE_MINIMO
		for unit_id in candidatos:
			if novo.has(unit_id):
				continue
			var score := _score(unidades, unidades.index_of(unit_id), vaga, fase)
			if score <= melhor_score or not _pode_mudar(unidades, unit_id, vaga.id, score, fase):
				continue
			melhor_score = score
			melhor = unit_id
		if melhor != NENHUM:
			novo[melhor] = vaga.id
			vaga.unit_id = melhor

	_escrever(unidades, candidatos, novo)
	_anterior = novo.duplicate()
	return novo


## A adequacao ao posto vezes a proximidade vezes a urgencia da fase. Os tres
## termos sao dados: job_affinity em units.csv, job_proximity_px na curva,
## urgency_by_phase em jobs.csv. Nenhum esta escrito aqui.
func _score(unidades: UnitSystem, i: int, vaga: JobSlot, fase: int) -> float:
	if i == NENHUM or unidades.bands[i] != int(vaga.band):
		return SCORE_MINIMO
	var posto: JobData = _postos.get(vaga.job_id)
	var dados: UnitData = _dados.get(unidades.data_ids[i])
	if posto == null or dados == null or fase >= posto.urgency_by_phase.size():
		return SCORE_MINIMO
	var adequacao: float = dados.job_affinity.get(vaga.job_id, SCORE_MINIMO)
	if adequacao <= SCORE_MINIMO:
		return SCORE_MINIMO
	var distancia := absf(unidades.xs[i] - vaga.x)
	var proximidade := 1.0 / (1.0 + distancia / _curva.job_proximity_px)
	return adequacao * proximidade * posto.urgency_by_phase[fase]


## A histerese do prompt 4. Quem ja la esta fica sem ter de se provar outra vez;
## quem vem de outro posto tem de superar o seu em mais de job_hysteresis.
func _pode_mudar(unidades: UnitSystem, unit_id: int, vaga_id: int, score: float, fase: int) -> bool:
	if not _anterior.has(unit_id) or _anterior[unit_id] == vaga_id:
		return true
	return score > _score_do_posto_atual(unidades, unit_id, fase) * (1.0 + _curva.job_hysteresis)


## Quanto vale o posto que ele ja tem, NESTA fase. Recalculado e nao lembrado: o
## que faz uma tropa mudar de posto e a fase ter mudado, e um score guardado da
## fase anterior comparava duas coisas diferentes.
func _score_do_posto_atual(unidades: UnitSystem, unit_id: int, fase: int) -> float:
	var vaga_id: int = _anterior.get(unit_id, NENHUM)
	if vaga_id < 0 or vaga_id >= slots.size():
		return SCORE_MINIMO
	return _score(unidades, unidades.index_of(unit_id), slots[vaga_id], fase)


## Vivos, teus, e por id crescente. Um vagabundo por recrutar anda atras de
## moedas e nao de postos (F1-04), e por isso nao e candidato a nada.
func _candidatos(unidades: UnitSystem) -> PackedInt32Array:
	var lista := PackedInt32Array()
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		lista.append(unidades.ids[i])
	lista.sort()
	return lista


func _vagas_por_prioridade() -> Array[JobSlot]:
	var ordem := slots.duplicate()
	ordem.sort_custom(
		func(a: JobSlot, b: JobSlot) -> bool:
			var pa := _prioridade(a)
			var pb := _prioridade(b)
			return a.id < b.id if is_equal_approx(pa, pb) else pa > pb
	)
	return ordem


func _prioridade(vaga: JobSlot) -> float:
	var posto: JobData = _postos.get(vaga.job_id)
	return posto.priority if posto != null else SCORE_MINIMO


## Escreve o resultado nas colunas: o posto de quem foi atribuido e o alvo em x
## que o passo 5 vai percorrer, e NENHUM para quem ficou sem nada.
func _escrever(unidades: UnitSystem, candidatos: PackedInt32Array, novo: Dictionary) -> void:
	for unit_id in candidatos:
		var i := unidades.index_of(unit_id)
		if not novo.has(unit_id):
			unidades.job_ids[i] = NENHUM
			continue
		var vaga: JobSlot = slots[novo[unit_id]]
		unidades.job_ids[i] = vaga.id
		unidades.set_target_x(unit_id, vaga.x)
