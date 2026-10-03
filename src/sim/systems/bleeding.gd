# src/sim/systems/bleeding.gd — a ferida que a flecha do Imperador Arqueiro deixa (ADR
# 0052, Q-201; o dono a 02/10/2026: "chance de sangramento ao acertar e perda gradual de
# vida do inimigo").
#
# Um impacto que fez dano abre a ferida com a chance dos dados; o sorteio vem de fora, do
# fluxo `combat`, e so se faz quando houve impacto. Uma ferida por alvo: um proc novo
# renova o prazo e nao soma dano. O primeiro ponto cai um segundo depois, e os seguintes
# de segundo a segundo, ate o prazo acabar. Quem nao tem sangue — a tag `bloodless` das
# criaturas, ou quem nao se pode matar — nao sangra. Quem morreu, saiu ou passou a aliado
# deixa de sangrar: o convertido nao morre de uma flecha que ja tinha levado.
#
# O dano sai como golpes para o lote comum do CombatSystem: uma morte, uma recompensa,
# mesmo que a flecha e a ferida a matem no mesmo tick.
#
# Puro: as criaturas, os dados e a sorte entram de fora.
class_name Bleeding
extends RefCounted

const NENHUM := -1
const FONTE := &"source"
const ALVO := &"target"
const PRAZO := &"remaining"
const PROXIMO := &"next"
const DANO := &"damage"
## A tag das criaturas sem sangue (creatures.csv): substancia, mineral, espectro.
const SEM_SANGUE := &"bloodless"
## O ritmo da ferida: um ponto por segundo.
const RITMO := 1.0
## A folga do relogio em float: 4 s a passos de 1/30 nao dao zero certo.
const FOLGA := 0.0001

## alvo id -> {source, remaining, next, damage}.
var wounds: Dictionary = {}
var _devidos: Array[Dictionary] = []


## Se `dados` sangra: pode morrer e nao e substancia, mineral nem espectro.
static func bleeds(dados: CreatureData) -> bool:
	return dados != null and dados.can_be_killed and not dados.tags.has(SEM_SANGUE)


## Um impacto com dano de `fonte` em `alvo`: com `sorte` abaixo da chance do arco
## (`bleed_chance`), a ferida abre — ou renova o prazo (`bleed_seconds`) da que la estava,
## sem somar dano (`bleed_damage`). Verdadeiro se abriu ou renovou.
func strike(alvo: int, fonte: int, dados: CreatureData, sorte: float, arco: Dictionary) -> bool:
	var segundos := float(arco.get(&"bleed_seconds", 0.0))
	var dano := int(arco.get(&"bleed_damage", 0))
	if not bleeds(dados) or sorte >= float(arco.get(&"bleed_chance", 0.0)):
		return false
	if segundos <= 0.0 or dano <= 0:
		return false
	if wounds.has(alvo):
		wounds[alvo][PRAZO] = segundos
		wounds[alvo][FONTE] = fonte
		return true
	wounds[alvo] = {FONTE: fonte, PRAZO: segundos, PROXIMO: RITMO, DANO: dano}
	return true


## Um tick: cada ferida conta, e o que cai fica devido ate o take(). Quem morreu, saiu ou
## esta em `aliados` deixa de sangrar.
func tick(delta: float, bichos: CreatureSystem, aliados: Dictionary) -> void:
	for alvo: int in wounds.keys():
		var c := bichos.index_of(alvo)
		if c == NENHUM or not bichos.alive(c) or aliados.has(alvo):
			wounds.erase(alvo)
			continue
		var ferida: Dictionary = wounds[alvo]
		ferida[PRAZO] = float(ferida[PRAZO]) - delta
		ferida[PROXIMO] = float(ferida[PROXIMO]) - delta
		while float(ferida[PROXIMO]) <= FOLGA:
			_devidos.append({FONTE: int(ferida[FONTE]), ALVO: alvo, DANO: int(ferida[DANO])})
			ferida[PROXIMO] = float(ferida[PROXIMO]) + RITMO
		if float(ferida[PRAZO]) <= FOLGA:
			wounds.erase(alvo)


## O dano que caiu desde o ultimo take(), por ordem: {source, target, damage}.
func take() -> Array[Dictionary]:
	var saida := _devidos
	_devidos = []
	return saida


func to_dict() -> Dictionary:
	return {&"wounds": wounds.duplicate(true)}


## Um save de antes do sangramento nao tem feridas.
func from_dict(d: Dictionary) -> void:
	wounds = {}
	_devidos = []
	var guardadas: Variant = d.get(&"wounds", {})
	for alvo: Variant in guardadas if guardadas is Dictionary else {}:
		wounds[int(alvo)] = (guardadas[alvo] as Dictionary).duplicate()
