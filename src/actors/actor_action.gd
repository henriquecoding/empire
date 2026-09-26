# src/actors/actor_action.gd — o que um corpo esta a fazer, para a arte o mostrar.
#
# O contrato de accoes do planejamento visual de 26/09 (§4.1, lote 4). Ate aqui
# o OriginalArt percorria as duracoes todas sem saber o que a unidade fazia, e o
# unico sinal de accao era o baloico de um pixel. Isto e a ponte: le o estado
# que a simulacao JA decidiu (a FSM do §52, a vida, o x) e escolhe a tag do
# manifesto que o mostra. Nao decide nada — nem acerto, nem dano, nem quando o
# golpe cai: a apresentacao representa, a simulacao manda.
#
# A prioridade e a do §8.3 do planejamento de 19/09: a morte tem tratamento
# proprio; depois o dano imediato, o medo, a accao em curso e o repouso. Uma
# tag que a arte ainda nao tem cai para a seguinte da cadeia — e por isso uma
# animacao nova entra no jogo quando entra no manifesto, sem tocar em codigo.
class_name ActorAction
extends RefCounted

enum Kind { IDLE, WALK, WORK, ATTACK, HIT, FLEE, DIE }

## O nome de cada accao no manifesto (tags do Aseprite, em minusculas).
const TAGS := {
	Kind.IDLE: &"idle",
	Kind.WALK: &"walk",
	Kind.WORK: &"work",
	Kind.ATTACK: &"attack",
	Kind.HIT: &"hit",
	Kind.FLEE: &"flee",
	Kind.DIE: &"die",
}
## Sem a tag propria, o que se mostra em vez dela. Fugir e andar depressa; o
## resto, sem arte, e o repouso — nunca um frame de outra accao a fingir.
const FALLBACK := {Kind.FLEE: Kind.WALK}
## Accoes que acontecem uma vez e ficam no ultimo frame, em vez de repetir.
const ONCE := [Kind.HIT, Kind.DIE]


## A accao de uma unidade neste frame. `andou` e `ferida` sao o que o render viu
## entre dois frames (o x mudou, a vida desceu); `estado` e o da FSM.
static func of(estado: UnitFsm.State, andou: bool, ferida: bool) -> Kind:
	if estado == UnitFsm.State.DEAD:
		return Kind.DIE
	if ferida:
		return Kind.HIT
	if estado == UnitFsm.State.FLEE:
		return Kind.FLEE
	if estado == UnitFsm.State.FIGHT:
		return Kind.ATTACK
	if andou:
		return Kind.WALK
	if estado == UnitFsm.State.WORK:
		return Kind.WORK
	return Kind.IDLE


## A accao que a arte deste perfil consegue mostrar para `kind`: a propria, a
## da cadeia FALLBACK, ou o repouso.
static func shown(art: OriginalArt, perfil: StringName, kind: Kind) -> Kind:
	var atual := kind
	while atual != Kind.IDLE:
		if art.has_action(perfil, TAGS[atual]):
			return atual
		atual = FALLBACK.get(atual, Kind.IDLE) as Kind
	return Kind.IDLE


static func loops(kind: Kind) -> bool:
	return not kind in ONCE
