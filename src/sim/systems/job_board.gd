# src/sim/systems/job_board.gd — a camada A da §52: quem trabalha onde.
class_name JobBoard
extends RefCounted

const NENHUM := -1

## Abaixo disto ninguem e atribuido. Zero e o que sai de um posto sem urgencia
## nesta fase (a plantacao a noite) ou de quem nao serve para ele: em qualquer
## dos casos, por la alguem era pior do que deixar a vaga aberta.
const SCORE_MINIMO := 0.0

## Metade. Nao e afinacao: e o centro de uma largura e o centro de um passo.
const MEIO := 0.5
## O posto da obra paga para reparar (jobs.csv, §09, Q-108).
const REPARAR := &"repair"

var slots: Array[JobSlot] = []
## Quem esteve no posto na fase que acabou: e o que faz uma obra render (Q-121).
var staffing: Staffing

var _publicadas: Array = []
var _roster: Array = []
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
	staffing = Staffing.new(postos)


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
	_publicadas = []
	_roster = []


## As vagas que as obras de pe publicam (§20: "postos publicam vagas"). Chamada
## uma vez por fase, antes do assign().
##
## So reconstroi o quadro quando ele mudou MESMO. Refaze-lo a cada fase apagava
## a memoria da histerese e punha as tropas a trocar de posto de fase em fase —
## exatamente o que ela existe para evitar.
func publish(obras: BuildSystem) -> void:
	var querem: Array = []
	for obra in obras.slots:
		if obra.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
			querem.append([obra.id, &"build", 1, obra.level, obra.path, obra.band, obra.x])
		# Um muro a subir de degrau continua guardado pelo degrau que ja tem (D4).
		var postos := obra.posts() if obra.holds() else 0
		if obra.job_id != &"" and postos > 0:
			querem.append([obra.id, obra.job_id, postos, obra.level, obra.path, obra.band, obra.x])
		if obra.mending and obra.standing():
			querem.append([obra.id, REPARAR, 1, obra.level, obra.path, obra.band, obra.x])
	if querem == _publicadas:
		return
	clear()
	for entry in querem:
		var obra: BuildSlot = obras.slots[obras.index_of(entry[0])]
		var job: StringName = entry[1]
		for k in entry[2]:
			var na_obra := job in [&"build", REPARAR]
			var x := obra.x if na_obra else _lugar(obra, k)
			var vaga := post(JobSlot.new(job, x, obra.band))
			if not na_obra:
				vaga.grants(obra)
	_publicadas = querem


## Reage a recrutamento, morte, faixa e classe sem reatribuir a cada movimento.
func refresh(obras: BuildSystem, unidades: UnitSystem, fase: int) -> void:
	publish(obras)
	var roster: Array = [fase]
	for i in unidades.count():
		roster.append(
			[
				unidades.ids[i],
				unidades.owners[i],
				unidades.alive(i),
				unidades.bands[i],
				unidades.data_ids[i]
			]
		)
	if roster != _roster:
		assign(unidades, fase)
		_roster = roster
	staffing.observe(slots, unidades, fase)


## Onde fica a k-esima vaga de uma obra: repartidas pela largura dela, e nao
## todas em cima do mesmo pixel. E a mesma regra da fila do §50 — posicoes
## ATRIBUIDAS e nao emergentes, para que nao vibrem nem se empurrem.
func _lugar(obra: BuildSlot, k: int) -> float:
	var quantos := obra.posts()
	if quantos <= 1:
		return obra.x
	var passo := obra.width / quantos
	return obra.x - obra.width * MEIO + passo * (k + MEIO)


## A vaga com este id, ou null. E o que o combate pergunta para saber se quem
## dispara esta numa torre — "a torre nao da dano, da certeza" (§07).
func slot_of(job_id: int) -> JobSlot:
	return slots[job_id] if job_id >= 0 and job_id < slots.size() else null


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
	if vaga.job_id in [&"build", REPARAR] and dados.tags.has(&"worker"):
		adequacao = maxf(adequacao, dados.job_affinity.get(&"farm", SCORE_MINIMO))
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
