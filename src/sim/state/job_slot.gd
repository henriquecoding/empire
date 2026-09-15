# src/sim/state/job_slot.gd — uma vaga publicada por um posto (§20, §52).
#
# Os postos sao AUTORADOS: um canteiro publica uma vaga de plantacao, um muro
# publica vagas de muro. A vaga sabe o que e, onde e, e em que faixa — e mais
# nada. Quem decide se vale a pena e o JobBoard, e o que ela vale muda com a
# fase do dia (jobs.csv).
class_name JobSlot
extends RefCounted

const NENHUM := -1

## A chave do JobData: &"wall", &"farm", &"tower". Nao e texto para o ecra.
var job_id: StringName = &""
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE

## Quem la esta, ou NENHUM. Escrito pelo JobBoard e por mais ninguem.
var unit_id: int = NENHUM

## O id da vaga dentro do quadro que a publicou. O JobBoard atribui-o no post();
## e o que a coluna job_ids das tropas guarda.
var id: int = NENHUM


func _init(posto: StringName, onde: float, faixa: Band.Kind) -> void:
	job_id = posto
	x = onde
	band = faixa
