# src/sim/state/build_slot.gd — um sitio onde se pode construir (§55, §21).
#
# Os slots sao AUTORADOS na cena do segmento, nao calculados: e a decisao do §21,
# "forcar posicoes arriscadas em vez de deixar amontoar tudo no sitio seguro". O
# gerador escolhe segmentos; o segmento decide onde se pode construir.
#
# A escada de niveis esta aqui e nao no sistema porque e ela que distingue um
# canteiro de um muro: o canteiro tem um degrau, o muro tem os cinco do §10. Um
# `if e_muro` espalhado pelo sistema era a mesma coisa escrita pior.
class_name BuildSlot
extends RefCounted

## Os seis estados do §55, e cada um e um frame de sprite, nao uma cena.
enum State { EMPTY, SCAFFOLD, BUILDING, DONE, DAMAGED, RUIN }

## Os dois caminhos da muralha (§10): "cada segmento oferece duas melhorias
## mutuamente exclusivas por nivel. Nunca da para ter as duas — e essa e a
## decisao." A GUARNICAO poe postos e deixa o muro fragil; a FORTIFICACAO poe
## vida e tira dano de saida. NENHUMA e o que nao e muro.
enum Path { NENHUMA, GUARNICAO, FORTIFICACAO }

const NENHUM := -1

## O castelo-arvore (§10). Nao e uma obra como as outras em exactamente uma
## coisa — "se cair, cai a partida" — e por isso o id dele vive aqui, onde quem
## precisa de fazer essa pergunta o encontra sem inventar a string.
const NUCLEO := &"core"

var id: int = NENHUM
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE

## O que ali se constroi: a chave do BuildingData ou do WallData do nivel 1. Nao
## e texto para o ecra — e o que o build_completed leva.
var kind: StringName = &""

## A escada, um degrau por nivel. O indice 0 e o nivel 1.
var costs: PackedInt32Array = PackedInt32Array()
var works: PackedFloat32Array = PackedFloat32Array()
## A vida do caminho B, que e a coluna que o §10 escreve; e a unica que um
## edificio tem, porque um edificio nao tem caminhos.
var healths: PackedInt32Array = PackedInt32Array()

## O caminho A, e os postos dos dois. Vazios em tudo o que nao e muro.
var healths_a: PackedInt32Array = PackedInt32Array()
var posts_a: PackedInt32Array = PackedInt32Array()
var posts_b: PackedInt32Array = PackedInt32Array()
## §07: "so N atacantes engajam". O resto espera em fila (§50).
var contacts: PackedInt32Array = PackedInt32Array()
## O que cada degrau pede alem das moedas (§10, §74): o povo que tens de ter
## conquistado, o Lenho Amargo, e se so pode haver um no imperio. Vazios em tudo
## o que nao e muro.
var conquests: PackedStringArray = PackedStringArray()
var woods: PackedInt32Array = PackedInt32Array()
var unique: PackedByteArray = PackedByteArray()
var path: Path = Path.NENHUMA

## Quem esta em cada slot de contacto, por indice. NENHUM e livre. Escrito pela
## ContactQueue e por mais ninguem.
var contact: PackedInt32Array = PackedInt32Array()

## Largura em px. Manda no raio de apanha da obra e em quem conta como presente.
var width: float = 0.0

## Verdadeiro para o que trava uma criatura a caminho do nucleo: muros e torres.
## Um canteiro nao trava ninguem, e e por isso que o §10 lhe chama outra coisa.
var blocks: bool = false

## O posto que publica quando esta de pe, e quantas vagas dele. Vazio = nao
## publica nenhuma. Os numeros vem de BuildingData.job_slots e de
## WallData.guard_posts_a — nao ha aqui nenhum.
var job_id: StringName = &""
var job_slots: int = 0

## Quanto rende por dia (§06, circuito 1). O EconomySystem divide pelas fases —
## o CSV guarda por dia e o sistema reparte (Q-027, fechada).
var yield_per_day: float = 0.0
## Materia acumulada e ainda nao convertida. Float porque uma fase rende menos
## do que uma moeda e a parte de tras nao se perde.
var stock: float = 0.0
## §49: uma plantacao no rasto da Podridao e destruida; as outras so param.
var razed_by_rot: bool = false

## O effect_params do BuildingData (§10): `accuracy`, `range_bonus`,
## `hits_aerial` e o resto. Uma torre nao da dano — da certeza (§07), e e aqui
## que essa certeza esta escrita, em dados e nao num `if e_torre`.
var effects: Dictionary = {}

var level: int = 0
var state: State = State.EMPTY
## Moedas ja pagas do degrau seguinte. §55: a obra existe quando uma moeda cai.
var paid: int = 0
## Segundos de construtor PRESENTE, e nao tempo decorrido (§55).
var progress: float = 0.0
var health: int = 0
## A obra paga esta a ser reparada, e nao a subir de nivel (§55, Q-108).
var mending := false


## De pe: ja construida, inteira ou tocada, mas ainda nao ruina.
func standing() -> bool:
	return state == State.DONE or state == State.DAMAGED


## Quanto Lenho pede o degrau seguinte a quem conquistou `conquistas`, ou
## NENHUM se nao ha maneira de o subir. Com conquista exigida, o Lenho SUBSTITUI
## a conquista (a muralha de ferro sem a Fornalha, §74); sem ela, o Lenho e um
## custo a mais (o bastiao, 3 Lenhos alem das moedas).
func woods_for_next(conquistas: PackedStringArray) -> int:
	if level >= woods.size():
		return 0
	var povo := conquests[level] if level < conquests.size() else ""
	if povo.is_empty() or povo in conquistas:
		return woods[level] if povo.is_empty() else 0
	return woods[level] if woods[level] > 0 else NENHUM


## Verdadeiro se o degrau seguinte so pode existir uma vez no imperio (§10).
func next_unique() -> bool:
	return level < unique.size() and unique[level] == 1


## Quanto custa pôr esta obra inteira outra vez, ou NENHUM se nao ha o que
## reparar. A ruina custa o degrau em que estava — o §25 da "reparavel por 10
## moedas" a Casa de Treino, que e o preco dela —; a obra tocada paga a parte
## da vida que perdeu (Q-108). Sem preco (o nucleo) nao se repara com moeda.
func repair_cost() -> int:
	if level <= 0 or level > costs.size() or costs[level - 1] <= 0:
		return NENHUM
	if state == State.RUIN:
		return costs[level - 1]
	if state != State.DAMAGED:
		return NENHUM
	var perdida := 1.0 - float(health) / maxf(1.0, float(max_health()))
	return maxi(1, ceili(costs[level - 1] * perdida))


## Quanto custa o degrau seguinte, ou NENHUM se ja chegou ao topo.
func next_cost() -> int:
	return costs[level] if level < costs.size() else NENHUM


## A vida do nivel em que esta, pelo caminho que levou. O nivel 1 e a base comum
## aos dois: a tabela do §10 da-lhe a mesma vida nas duas colunas.
func max_health() -> int:
	if level <= 0:
		return 0
	if path == Path.GUARNICAO and level <= healths_a.size():
		return healths_a[level - 1]
	return healths[level - 1] if level <= healths.size() else 0


## Quantas vagas de posto publica. Num muro sao os postos do caminho escolhido
## (§10); em tudo o resto e o job_slots do BuildingData.
func posts() -> int:
	if level <= 0:
		return 0
	var tabela := posts_a if path == Path.GUARNICAO else posts_b
	return tabela[level - 1] if level <= tabela.size() else job_slots


## Quantos atacantes engajam ao mesmo tempo (§07, §10). Zero e "nao trava".
func contact_slots() -> int:
	return contacts[level - 1] if level > 0 and level <= contacts.size() else 0


## O que MUDA em jogo, e so isso. A escada, a largura e os efeitos sao autorados
## pelo segmento (§21) e voltam a existir quando ele volta a ser montado: grava-
## los era guardar o mundo dentro do save, e um mundo que muda de versao deixava
## de poder ser carregado (§62).
func to_dict() -> Dictionary:
	return {
		&"id": id,
		&"level": level,
		&"state": int(state),
		&"paid": paid,
		&"progress": progress,
		&"health": health,
		&"mending": mending,
		&"stock": stock,
		&"path": int(path),
		&"contact": contact,
	}


func from_dict(d: Dictionary) -> void:
	level = d.get(&"level", level)
	state = d.get(&"state", int(state)) as State
	paid = d.get(&"paid", paid)
	progress = d.get(&"progress", progress)
	health = d.get(&"health", health)
	mending = d.get(&"mending", mending)
	stock = d.get(&"stock", stock)
	path = d.get(&"path", int(path)) as Path
	contact = d.get(&"contact", contact)


## Verdadeiro se este sitio tem os dois caminhos do §10 para escolher.
func two_paths() -> bool:
	return not healths_a.is_empty()


## A escolha do §10, e e uma so: a partir do nivel 2 o muro segue um caminho e
## nao o outro. Recusa depois de o nivel 2 estar de pe — "nunca da para ter as
## duas" tambem quer dizer que nao se troca a meio.
func choose_path(escolha: Path) -> bool:
	if not two_paths() or level > 1:
		return false
	path = escolha
	return true
