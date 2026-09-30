# src/sim/systems/burrows.gd — as tocas de onde a caca sai (§06, §25; Q-106, Q-120, Q-150).
#
# "Como em Kingdom, os coelhos saem de arbustos ou coisas similares; os arbustos
# geram aos poucos os coelhos, o que faz estar constantemente a farmar. Se fizer
# algo errado e perder o arbusto, para de ser gerado o coelho e consequentemente
# aquela receita" — e "nunca nascem todos ao mesmo tempo: sempre progressivamente,
# de forma suave e estavel" (o dono, 29/09/2026). E depois (Q-150, 30/09/2026): "as
# cacas devem aparecer de onde faca sentido, de arbustos, de arvores, de lagos, de
# rochas, de buracos". Cada toca e um sitio do cenario — o arbusto, o buraco, a rocha,
# a arvore, o lago — e o bicho que la faz sentido (wildlife.csv, `sources`).
#
# Cada toca e um x fixo da regiao. De dia, uma toca sem bicho a porta conta o seu
# tempo e, quando acaba, poe um bicho a porta — um de cada vez: um bicho que ninguem
# caca fica la e a toca espera. Os tempos de partida sao sorteados uma vez,
# espalhados pelo periodo, para as tocas nao darem todas ao mesmo tempo. Uma toca
# perdida nao volta nesta regiao.
#
# Puro: o periodo, as posicoes, os sitios e os bichos chegam ja lidos (HuntWatch).
class_name Burrows
extends RefCounted

## O sitio e o bicho de quem nao os diz: o arbusto e o coelho de sempre.
const ARBUSTO := &"bush"
const COELHO := &"rabbit"

var xs: Array[float] = []
## 1 viva, 0 perdida.
var alive: PackedByteArray = PackedByteArray()
## Segundos de luz que faltam para o proximo bicho de cada toca.
var waits: PackedFloat32Array = PackedFloat32Array()
## O sitio de cada toca (Q-150) e o bicho que dela sai.
var kinds := PackedStringArray()
var game := PackedStringArray()


func placed() -> bool:
	return not xs.is_empty()


## As tocas da regiao, com o tempo que cada uma espera ate ao primeiro bicho, o
## sitio (`fontes`) e o bicho (`caca`) de cada uma; sem eles, arbustos com coelhos.
func place(
	onde: Array[float],
	esperas: Array[float],
	fontes := PackedStringArray(),
	caca := PackedStringArray()
) -> void:
	xs = onde.duplicate()
	alive = PackedByteArray()
	waits = PackedFloat32Array()
	kinds = PackedStringArray()
	game = PackedStringArray()
	for k in onde.size():
		alive.append(1)
		waits.append(esperas[k] if k < esperas.size() else 0.0)
		kinds.append(fontes[k] if k < fontes.size() else String(ARBUSTO))
		game.append(caca[k] if k < caca.size() else String(COELHO))


## O bicho da toca em `x`, ou o coelho se nao ha toca ali.
func game_at(x: float) -> StringName:
	var k := xs.find(x)
	return StringName(game[k]) if k >= 0 and k < game.size() else COELHO


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
	return {&"xs": xs.duplicate(), &"alive": alive, &"waits": waits, &"kinds": kinds, &"game": game}


## Um save de antes da Q-150 nao diz o sitio nem o bicho: arbustos com coelhos.
func from_dict(d: Dictionary) -> void:
	xs.assign(d.get(&"xs", []))
	alive = PackedByteArray(d.get(&"alive", PackedByteArray()))
	waits = PackedFloat32Array(d.get(&"waits", PackedFloat32Array()))
	kinds = PackedStringArray(d.get(&"kinds", PackedStringArray()))
	game = PackedStringArray(d.get(&"game", PackedStringArray()))
	alive.resize(xs.size())
	waits.resize(xs.size())
	for k in range(kinds.size(), xs.size()):
		kinds.append(String(ARBUSTO))
	for k in range(game.size(), xs.size()):
		game.append(String(COELHO))
