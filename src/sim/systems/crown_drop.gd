# src/sim/systems/crown_drop.gd — a coroa no chao, recuperavel ate a alvorada (§16, §74;
# Q-167, o dono a 30/09/2026; relatorio Kingdom, K2).
#
# A proposta aprovada: "a coroa cai quando o rei cai e recupera-se ate a alvorada, se
# nenhuma criatura a apanhar; na mancha, alimenta o Lume." A derrota deixa de ser
# binaria: o rei que cai com o escudo gasto (Q-114) fica no chao e a coroa ao pe dele.
# Se uma criatura chega a ela, leva-a, e so entao o rei morre — com herdeiro ou sem ele
# (§16). Se a mancha a cobre, a coroa alimenta o Lume (ADR 0034: "o combustivel es tu").
# Se quem o jogador conduz a apanha, o rei levanta-se ja; e se a alvorada chega com ela
# no chao, levanta-se na alvorada (§16: "ressurreicao ate ao amanhecer").
#
# So a leva uma criatura viva e hostil: a que a Nia converteu (as `aliadas` do BardSong) e
# do reino da coroa, e nao a rouba (ADR 0052, UN-11).
#
# Puro: as criaturas, a mancha, quem a apanha e os numeros entram de fora.
class_name CrownDrop
extends RefCounted

## O que aconteceu a coroa neste tick.
enum Fate { NONE, TAKEN, CONSUMED, RECOVERED }

const NENHUM := -1

## Se a coroa esta no chao, a espera.
var down := false
var x := 0.0
var band := 0


## O rei caiu em `onde`, na faixa `faixa`: a coroa fica no chao.
func fall(onde: float, faixa: int) -> void:
	down = true
	x = onde
	band = faixa


## Um tick com a coroa no chao: uma criatura viva e hostil a `alcance` dela leva-a — as
## de `aliadas` nao —; a mancha entre `mancha.x` e `mancha.y` come-a; quem se conduz
## (`quem`, de pe e na faixa dela) a `apanha` apanha-a. Por esta ordem: quem chega
## primeiro e o bicho. `alcance` e `apanha` vem em `raios` (x e y).
func tick(
	bichos: CreatureSystem,
	raios: Vector2,
	mancha: Vector2,
	unidades: UnitSystem,
	quem: int,
	aliadas: Dictionary = {}
) -> Fate:
	if not down:
		return Fate.NONE
	var alcance := raios.x
	var apanha := raios.y
	for c in bichos.count():
		if not bichos.alive(c) or aliadas.has(bichos.ids[c]):
			continue
		if bichos.bands[c] == band and absf(bichos.xs[c] - x) <= alcance:
			down = false
			return Fate.TAKEN
	if band == int(Band.Kind.SURFACE) and mancha.x < mancha.y and x >= mancha.x and x <= mancha.y:
		down = false
		return Fate.CONSUMED
	var i := unidades.index_of(quem)
	if i != NENHUM and unidades.alive(i) and unidades.bands[i] == band:
		if absf(unidades.xs[i] - x) <= apanha:
			down = false
			return Fate.RECOVERED
	return Fate.NONE


## A alvorada com a coroa no chao: ninguem a levou, e o rei levanta-se.
func dawn() -> Fate:
	if not down:
		return Fate.NONE
	down = false
	return Fate.RECOVERED


## O rei levanta-se: de pe outra vez, com `fracao` da vida (§16).
static func rise(unidades: UnitSystem, rei: int, fracao: float) -> bool:
	var i := unidades.index_of(rei)
	if i == NENHUM:
		return false
	unidades.healths[i] = maxi(1, roundi(unidades.max_healths[i] * fracao))
	unidades.states[i] = UnitFsm.State.WORK
	unidades.clear_target(rei)
	return true


func to_dict() -> Dictionary:
	return {&"down": down, &"x": x, &"band": band}


func from_dict(d: Dictionary) -> void:
	down = bool(d.get(&"down", false))
	x = float(d.get(&"x", 0.0))
	band = int(d.get(&"band", 0))
