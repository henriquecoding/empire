# src/sim/systems/succession.gd — o herdeiro (§15, §16; auditoria D6 e AUD-05).
#
# O §15: "Treino — 10 dias na Casa do Herdeiro. Custa 5 moedas/dia." O §16: "Morte
# do rei — se houver sucessor, ele assume no amanhecer." Ate a auditoria de 26/09
# nada disto existia: um rei morto deixava o mundo sem comando (D6), e a correcao
# minima fez dele o fim da partida. Com a casa de pe, cada alvorada tira um dia de
# treino ao saco do rei; com o herdeiro formado, a morte do rei deixa de ser a
# derrota, e na alvorada seguinte o herdeiro nasce no castelo e a coroa passa.
#
# Sem herdeiro continua a ser derrota: o §16 da ao rei sem sucessor um interregno,
# mas o interregno pede outro personagem jogavel que o atravesse, e na Fase 1 o
# monarca e o unico (Q-133).
#
# Puro: recebe as obras, as tropas e os numeros ja lidos da curva.
class_name Succession
extends RefCounted

const NENHUM := -1
## A obra onde o herdeiro se forma (buildings.csv).
const CASA := &"heir_house"
const METADE := 0.5

## Dias de treino do herdeiro que vem. Formado quando chega a `_dias`.
var days: int = 0
## O imperio a quem o herdeiro pertence: o do rei que o pagou.
var owner: int = NENHUM
## Quem joga escolheu nao continuar com o herdeiro: "se o imperador morre e o
## herdeiro estiver pronto, o jogador pode optar por continuar" (Q-146).
var declined := false

var _dias: int
var _custo: int


func _init(dias_de_treino: int, custo_por_dia: int) -> void:
	_dias = dias_de_treino
	_custo = custo_por_dia


## Verdadeiro se ha herdeiro formado a espera da coroa.
func ready() -> bool:
	return _dias > 0 and days >= _dias


## Se a coroa pode passar na proxima alvorada: herdeiro formado e castelo de pe,
## onde ele nasce. "O sucessor so nasce no castelo, e ele deve existir para poder
## continuar; se nao houver, a partida acaba" (Q-137, o dono a 29/09/2026). A casa
## e onde se forma, e nao onde nasce: perde-la depois de formado nao o perde.
## E a condicao que o Defeat, o guia e a coroacao leem.
func possible(obras: BuildSystem) -> bool:
	return ready() and not declined and castle(obras) != null


## O castelo-arvore de pe, ou null.
static func castle(obras: BuildSystem) -> BuildSlot:
	for obra in obras.standing():
		if obra.kind == BuildSlot.NUCLEO:
			return obra
	return null


## A casa do herdeiro de pe, ou null.
func house(obras: BuildSystem) -> BuildSlot:
	for obra in obras.standing():
		if obra.kind == CASA:
			return obra
	return null


## Uma alvorada: com a casa de pe e o herdeiro por formar, o saco do rei paga um
## dia de treino. Devolve o que pagou — zero se nao havia casa, rei ou moedas.
func dawn(obras: BuildSystem, unidades: UnitSystem, rei: int) -> int:
	if ready() or house(obras) == null:
		return 0
	var i := unidades.index_of(rei)
	if i == NENHUM or not unidades.alive(i) or unidades.carried_coins[i] < _custo:
		return 0
	unidades.carried_coins[i] -= _custo
	owner = unidades.owners[i]
	days += 1
	return _custo


## A coroa passa: o herdeiro nasce no castelo com os dados do monarca, e o treino
## recomeca do zero para o proximo. Devolve o id dele, ou NENHUM sem herdeiro.
func crown(estado: GameState, unidades: UnitSystem, obras: BuildSystem, monarca: UnitData) -> int:
	if not possible(obras):
		return NENHUM
	var castelo := castle(obras)
	days = 0
	declined = false
	return unidades.spawn(estado, monarca, owner, castelo.x)


func to_dict() -> Dictionary:
	return {&"days": days, &"owner": owner, &"declined": declined}


func from_dict(d: Dictionary) -> void:
	days = int(d.get(&"days", 0))
	owner = int(d.get(&"owner", NENHUM))
	declined = bool(d.get(&"declined", false))
