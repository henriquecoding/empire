# src/sim/systems/staffing.gd — quem esteve no posto na fase que acabou (§06, §52).
#
# A auditoria de 26/09 (§5.3) mediu que a producao nao pedia ninguem: o canteiro
# publicava uma vaga que nao mudava nada, e o trabalhador recrutado nao tinha um
# destino que valesse. Uma obra com posto passa a render inteiro so com quem la
# trabalha — nas fases em que o posto e urgente (jobs.csv): o canteiro de noite
# nao pede ninguem, e nao e por isso que rende menos. Q-121.
#
# Observa-se a cada tick (o JobBoard.refresh chama-o) e fecha-se na mudanca de
# fase, que e quando o passo 7 do §43 pergunta. Puro: recebe o quadro de postos,
# as tropas e os JobData ja carregados.
class_name Staffing
extends RefCounted

const NENHUMA := -1

## As obras que tiveram alguem no posto durante a fase que acabou.
var served: Dictionary = {}
## A fase que acabou; NENHUMA no inicio — e entao ninguem e penalizado pelo que
## nao se viu.
var ended: int = NENHUMA

var _a_servir: Dictionary = {}
var _fase: int = NENHUMA
var _postos: Dictionary


## `postos` e JobData por id.
func _init(postos: Dictionary) -> void:
	_postos = postos


## Um tick: quem esta atribuido a uma vaga e esta dentro da obra que a publicou.
func observe(vagas: Array[JobSlot], unidades: UnitSystem, fase: int) -> void:
	if fase != _fase:
		served = _a_servir
		_a_servir = {}
		ended = _fase
		_fase = fase
	for vaga in vagas:
		if vaga.unit_id == JobSlot.NENHUM or vaga.source == JobSlot.NENHUM:
			continue
		var i := unidades.index_of(vaga.unit_id)
		if i != UnitSystem.NENHUM and unidades.alive(i) and vaga.holds(unidades.xs[i]):
			_a_servir[vaga.source] = true


## Se esta obra trabalhou na fase que acabou: nao tem posto, o posto nao era
## urgente nessa fase, nao se sabe (inicio, save), ou alguem la esteve.
func worked(obra: BuildSlot) -> bool:
	if obra.job_id == &"" or obra.posts() <= 0 or ended == NENHUMA:
		return true
	var posto: JobData = _postos.get(obra.job_id)
	if posto == null or ended >= posto.urgency_by_phase.size():
		return true
	if posto.urgency_by_phase[ended] <= 0.0:
		return true
	return served.has(obra.id)


## O que ja se viu nesta fase e na que acabou vai no save (CONT-03): sem isto, quem
## trabalhou antes de gravar deixava de contar ao retomar, e a mesma fase rendia
## menos carregada do que jogada de seguida (auditoria de 27/09, N5).
func to_dict() -> Dictionary:
	return {
		&"phase": _fase,
		&"ended": ended,
		&"serving": PackedInt32Array(_a_servir.keys()),
		&"served": PackedInt32Array(served.keys()),
	}


func from_dict(guardado: Dictionary) -> void:
	_fase = int(guardado.get(&"phase", NENHUMA))
	ended = int(guardado.get(&"ended", NENHUMA))
	_a_servir = _conjunto(guardado.get(&"serving", PackedInt32Array()))
	served = _conjunto(guardado.get(&"served", PackedInt32Array()))


static func _conjunto(ids: PackedInt32Array) -> Dictionary:
	var saida := {}
	for id in ids:
		saida[id] = true
	return saida
