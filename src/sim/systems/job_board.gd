class_name JobBoard
extends RefCounted

const NENHUM := -1

const SCORE_MINIMO := 0.0

const MEIO := 0.5
const REPARAR := &"repair"

var territories: Dictionary = {}
var excluded := PackedInt32Array()
var slots: Array[JobSlot] = []
var staffing: Staffing

var _publicadas: Array = []
var _roster: Array = []
var _curva: EconomyCurve
var _postos: Dictionary = {}
var _dados: Dictionary = {}
var _anterior: Dictionary = {}


func _init(curva: EconomyCurve, postos: Dictionary, dados: Dictionary) -> void:
	assert(curva != null, "o JobBoard precisa de um EconomyCurve")
	_curva = curva
	_postos = postos
	_dados = dados
	staffing = Staffing.new(postos)


func post(vaga: JobSlot) -> JobSlot:
	vaga.id = slots.size()
	vaga.unit_id = NENHUM
	slots.append(vaga)
	return vaga


func clear() -> void:
	slots = []
	_anterior = {}
	_publicadas = []
	_roster = []


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
			vaga.territory = obra.territory
			vaga.builder_only = (
				job == REPARAR or (na_obra and (obra.two_paths() or obra.builder_work))
			)
			if not na_obra:
				vaga.grants(obra)
	_publicadas = querem


func refresh(obras: BuildSystem, unidades: UnitSystem, fase: int) -> void:
	publish(obras)
	var roster: Array = [fase, excluded]
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


func _lugar(obra: BuildSlot, k: int) -> float:
	var quantos := obra.posts()
	if quantos <= 1:
		return obra.x
	var passo := obra.width / quantos
	return obra.x - obra.width * MEIO + passo * (k + MEIO)


func slot_of(job_id: int) -> JobSlot:
	return slots[job_id] if job_id >= 0 and job_id < slots.size() else null


func free_slots() -> int:
	var n := 0
	for vaga in slots:
		if vaga.unit_id == NENHUM:
			n += 1
	return n


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


func _score(unidades: UnitSystem, i: int, vaga: JobSlot, fase: int) -> float:
	if i == NENHUM or unidades.bands[i] != int(vaga.band):
		return SCORE_MINIMO
	if int(territories.get(unidades.ids[i], 0)) != vaga.territory:
		return SCORE_MINIMO
	var posto: JobData = _postos.get(vaga.job_id)
	var dados: UnitData = _dados.get(unidades.data_ids[i])
	if posto == null or dados == null or fase >= posto.urgency_by_phase.size():
		return SCORE_MINIMO
	if vaga.builder_only and dados.id != RepairWork.REPAIRER:
		return SCORE_MINIMO
	var adequacao: float = dados.job_affinity.get(vaga.job_id, SCORE_MINIMO)
	if vaga.job_id == &"build" and dados.tags.has(&"worker"):
		adequacao = maxf(adequacao, dados.job_affinity.get(&"farm", SCORE_MINIMO))
	if adequacao <= SCORE_MINIMO:
		return SCORE_MINIMO
	var distancia := absf(unidades.xs[i] - vaga.x)
	var proximidade := 1.0 / (1.0 + distancia / _curva.job_proximity_px)
	return adequacao * proximidade * posto.urgency_by_phase[fase]


func _pode_mudar(unidades: UnitSystem, unit_id: int, vaga_id: int, score: float, fase: int) -> bool:
	if not _anterior.has(unit_id) or _anterior[unit_id] == vaga_id:
		return true
	return score > _score_do_posto_atual(unidades, unit_id, fase) * (1.0 + _curva.job_hysteresis)


func _score_do_posto_atual(unidades: UnitSystem, unit_id: int, fase: int) -> float:
	var vaga_id: int = _anterior.get(unit_id, NENHUM)
	if vaga_id < 0 or vaga_id >= slots.size():
		return SCORE_MINIMO
	return _score(unidades, unidades.index_of(unit_id), slots[vaga_id], fase)


func _candidatos(unidades: UnitSystem) -> PackedInt32Array:
	var lista := PackedInt32Array()
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		if unidades.ids[i] == unidades.pilot or unidades.ids[i] in excluded:
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


func _escrever(unidades: UnitSystem, candidatos: PackedInt32Array, novo: Dictionary) -> void:
	for unit_id in candidatos:
		var i := unidades.index_of(unit_id)
		if not novo.has(unit_id):
			unidades.job_ids[i] = NENHUM
			continue
		var vaga: JobSlot = slots[novo[unit_id]]
		unidades.job_ids[i] = vaga.id
		unidades.set_target_x(unit_id, vaga.x)
