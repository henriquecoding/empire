# src/sim/systems/posts.gd — o que um posto acrescenta a quem o ocupa (§07, §10).
#
# "Um arqueiro em campo aberto acerta 1/3 das flechas; dentro de torre, 100%. A
# TORRE NAO DA DANO — DA CERTEZA. E como se ensina posicionamento sem uma unica
# linha de tutorial." (§07)
#
# Tres perguntas, e as tres tem a mesma resposta: depende do posto onde ele
# esta. Um arqueiro e o mesmo arqueiro em campo aberto e em cima de uma torre —
# o que muda e o sitio, e o sitio esta em buildings.csv, na coluna
# effect_params. Nao ha aqui um `if e_torre`.
#
# Estatico e puro: recebe o quadro de postos e as colunas, e nao guarda nada.
class_name Posts
extends RefCounted


## A vaga que esta tropa ocupa, ou null.
static func of(postos: JobBoard, unidades: UnitSystem, i: int) -> JobSlot:
	if postos == null:
		return null
	return postos.slot_of(unidades.job_ids[i])


## A precisao com que ela dispara. Dentro de torre e a do posto; em campo aberto
## e a accuracy_open do §19 — 0,34 no arqueiro.
static func accuracy(postos: JobBoard, unidades: UnitSystem, i: int, dados: UnitData) -> float:
	var vaga := of(postos, unidades, i)
	if vaga == null or vaga.accuracy <= 0.0:
		return dados.accuracy_open
	return vaga.accuracy


## O alcance. A torre de arqueiros da +40% (§10, range_bonus).
static func range_px(postos: JobBoard, unidades: UnitSystem, i: int, dados: UnitData) -> float:
	var vaga := of(postos, unidades, i)
	var bonus := vaga.range_bonus if vaga != null else 0.0
	return float(dados.range_px) * (1.0 + bonus)


## Se ela chega a esta faixa, e e a Q-006 fechada: "um arqueiro no chao nao chega
## aos 200 px do topo com 200 px de alcance; em muro ou torre de arqueiros
## tambem nao — SO a torre alta".
##
## Tres perguntas por ordem: pode apontar para la (targets_bands)? e a faixa
## dele? entao chega. Senao, so chega se o POSTO lhe der altura. Sem isto o
## Alado nao obriga a nada, e o §07 diz que ele obriga a torre alta.
static func reaches(
	postos: JobBoard, unidades: UnitSystem, i: int, dados: UnitData, faixa: int
) -> bool:
	if not dados.targets_bands.has(faixa):
		return false
	if faixa == int(unidades.bands[i]):
		return true
	var vaga := of(postos, unidades, i)
	return vaga != null and vaga.hits_aerial and faixa == int(Band.Kind.AERIAL)
