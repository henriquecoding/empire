# src/sim/state/job_slot.gd — uma vaga publicada por um posto (§20, §52).
#
# Os postos sao AUTORADOS: um canteiro publica uma vaga de plantacao, um muro
# publica vagas de muro. A vaga sabe o que e, onde e, e em que faixa — e mais
# nada. Quem decide se vale a pena e o JobBoard, e o que ela vale muda com a
# fase do dia (jobs.csv).
class_name JobSlot
extends RefCounted

const NENHUM := -1
const HALF := 0.5

## A chave do JobData: &"wall", &"farm", &"tower". Nao e texto para o ecra.
var job_id: StringName = &""
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE

## Quem la esta, ou NENHUM. Escrito pelo JobBoard e por mais ninguem.
var unit_id: int = NENHUM

## O id da vaga dentro do quadro que a publicou. O JobBoard atribui-o no post();
## e o que a coluna job_ids das tropas guarda.
var id: int = NENHUM

## A obra que publicou esta vaga, ou NENHUM.
var source: int = NENHUM

# Os efeitos do posto, COPIADOS da obra quando ela publica (§10, effect_params).
# "A torre nao da dano — da certeza" (§07): quem esta nela dispara com esta
# precisao em vez da accuracy_open, alcanca mais, e ve a faixa aerea. Copiados e
# nao perguntados, pela mesma razao das colunas quentes das tropas: o combate
# pergunta por eles a cada tick.
var accuracy: float = 0.0
var range_bonus: float = 0.0
var hits_aerial: bool = false
## Onde fica a obra que da estes efeitos, e ate onde ela chega: a certeza e de
## quem esta EM CIMA dela, e nao de quem so tem o posto (auditoria de 26/09, D3).
var origin_x: float = 0.0
var reach: float = 0.0


func _init(posto: StringName, onde: float, faixa: Band.Kind) -> void:
	job_id = posto
	x = onde
	band = faixa


## Le os efeitos da obra que publica esta vaga. As chaves sao as do
## effect_params de buildings.csv e nao ha nenhuma escrita em codigo de sistema.
func grants(obra: BuildSlot) -> void:
	source = obra.id
	accuracy = obra.effects.get(&"accuracy", 0.0)
	range_bonus = obra.effects.get(&"range_bonus", 0.0)
	hits_aerial = obra.effects.get(&"hits_aerial", 0.0) > 0.0
	origin_x = obra.x
	reach = obra.width * HALF


## Se quem esta em `x` esta dentro da obra que publicou esta vaga.
func holds(x: float) -> bool:
	return absf(x - origin_x) <= reach
