# src/sim/systems/burrows.gd — as tocas de onde a caca sai (§06, §25; Q-106, Q-120).
#
# "Como em Kingdom, os coelhos saem de arbustos ou coisas similares; os arbustos
# geram aos poucos os coelhos, o que faz estar constantemente a farmar. Se fizer
# algo errado e perder o arbusto, para de ser gerado o coelho e consequentemente
# aquela receita" — e "nunca nascem todos ao mesmo tempo: sempre progressivamente,
# de forma suave e estavel" (o dono, 29/09/2026).
#
# Cada toca e um x fixo da regiao. De dia, uma toca sem bicho a porta conta o seu
# tempo e, quando acaba, poe um coelho a porta — um de cada vez: um coelho que
# ninguem caca fica la e a toca espera. Os tempos de partida sao sorteados uma vez,
# espalhados pelo periodo, para as tocas nao darem todas ao mesmo tempo. Uma toca
# perdida nao volta nesta regiao.
#
# Puro: o periodo e as posicoes chegam ja lidos (HuntWatch).
class_name Burrows
extends RefCounted

var xs: Array[float] = []
## 1 viva, 0 perdida.
var alive: PackedByteArray = PackedByteArray()
## Segundos de luz que faltam para o proximo bicho de cada toca.
var waits: PackedFloat32Array = PackedFloat32Array()


func placed() -> bool:
	return not xs.is_empty()


## As tocas da regiao, com o tempo que cada uma espera ate ao primeiro bicho.
func place(onde: Array[float], esperas: Array[float]) -> void:
	xs = onde.duplicate()
	alive = PackedByteArray()
	waits = PackedFloat32Array()
	for k in onde.size():
		alive.append(1)
		waits.append(esperas[k] if k < esperas.size() else 0.0)


## `delta` segundos de luz. Devolve os x onde saiu um bicho agora. `fora` sao os
## bichos que ja estao a porta: uma toca com o seu la fora nao da outro.
func grow(delta: float, periodo: float, fora: Array[float]) -> Array[float]:
	var sairam: Array[float] = []
	if periodo <= 0.0:
		return sairam
	for k in xs.size():
		if alive[k] == 0 or fora.has(xs[k]):
			continue
		waits[k] -= delta
		if waits[k] <= 0.0:
			waits[k] += periodo
			sairam.append(xs[k])
	return sairam


## Perde as tocas a `raio` de algum destes x (as raizes de um Amargueiro, Q-106).
## Devolve os x das que se perderam agora.
func wither(perigos: PackedFloat32Array, raio: float) -> Array[float]:
	var perdidas: Array[float] = []
	for k in xs.size():
		if alive[k] == 0:
			continue
		for x in perigos:
			if absf(x - xs[k]) <= raio:
				alive[k] = 0
				perdidas.append(xs[k])
				break
	return perdidas


func living() -> int:
	var n := 0
	for a in alive:
		n += a
	return n


func to_dict() -> Dictionary:
	return {&"xs": xs.duplicate(), &"alive": alive, &"waits": waits}


func from_dict(d: Dictionary) -> void:
	xs.assign(d.get(&"xs", []))
	alive = PackedByteArray(d.get(&"alive", PackedByteArray()))
	waits = PackedFloat32Array(d.get(&"waits", PackedFloat32Array()))
	alive.resize(xs.size())
	waits.resize(xs.size())
