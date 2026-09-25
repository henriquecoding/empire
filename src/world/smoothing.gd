# src/world/smoothing.gd — o render interpola; a simulacao nao (§40, I5; GB-10).
#
# A invariante I5 diz as duas metades numa linha: "a simulacao corre a passo
# fixo de 30 Hz, desacoplada do render. O render interpola; a simulacao nao." A
# primeira metade estava feita desde o F0-06; a segunda nao estava em lado
# nenhum. Cada posicao ficava dois frames parada e saltava de uma vez — a 60 Hz,
# e pior num ecra de 144 — e o rei, a 80 px/s, avancava 2,7 px aos solavancos. A
# camara segue-o, e levava os solavancos com ela para o mundo inteiro.
#
# O que isto guarda e o que se ve, e nada mais: as duas ultimas posicoes de cada
# corpo, por id. Quem desenha pede a posicao entre as duas pela fracao do tick
# que ja passou. O custo e o de sempre desta tecnica — o que se ve esta um tick
# atras do que se simula, 33 ms — e e o mesmo que o motor cobra na dele.
#
# Estatico de proposito: tres BandView, o ImpactView, o PriceTag e a camara leem
# a mesma gravacao, e quem grava e a cena de jogo, uma vez por passo de fisica,
# depois do SimLoop (§45: "se esta num no, e derivado e descartavel").
class_name Smoothing
extends RefCounted

## Os corpos que se movem. Tres grupos e nao um: os ids das moedas, das tropas e
## dos bichos saem do mesmo contador hoje, e nada garante que amanha saiam.
enum Group { UNITS, CREATURES, COINS }

## Acima disto, entre dois ticks, um corpo nao andou: foi posto — um save
## carregado, a captura com --rei. Interpolar um salto era desenhar durante um
## tick um corpo que nunca esteve em sitio nenhum. O teste confere-o contra o
## passo mais rapido que os dados tem, para que uma montaria nova nao o apanhe.
const SALTO_PX := 64.0

static var _antes: Array[Dictionary] = [{}, {}, {}]
static var _agora: Array[Dictionary] = [{}, {}, {}]


## Um tick novo: o que era agora passa a antes. `alturas` so as moedas tem — a
## unica altura que o §45 deixa guardar.
static func record(
	grupo: Group, ids: PackedInt32Array, xs: PackedFloat32Array, alturas := PackedFloat32Array()
) -> void:
	var agora := {}
	for i in ids.size():
		var altura := alturas[i] if i < alturas.size() else 0.0
		agora[ids[i]] = Vector2(xs[i], altura)
	_antes[grupo] = _agora[grupo]
	_agora[grupo] = agora


## Os tres grupos a partir do SimLoop. E o que a cena de jogo chama.
static func record_all() -> void:
	if SimLoop.state == null or SimLoop.coins == null:
		return
	record(Group.UNITS, SimLoop.units.ids, SimLoop.units.xs)
	record(Group.CREATURES, SimLoop.creatures.ids, SimLoop.creatures.xs)
	record(Group.COINS, SimLoop.coins.ids, SimLoop.coins.xs, SimLoop.coins.heights)


static func reset() -> void:
	_antes = [{}, {}, {}]
	_agora = [{}, {}, {}]


## Onde desenhar, entre o tick anterior e `agora`. `agora` e o valor da coluna,
## e nao o gravado: se o SimLoop andou e a gravacao ainda nao, o destino continua
## a ser a verdade da simulacao.
static func blend(grupo: Group, id: int, agora: Vector2, fracao: float) -> Vector2:
	var antes: Variant = _antes[grupo].get(id)
	if antes == null:
		return agora
	var de := antes as Vector2
	if absf(agora.x - de.x) > SALTO_PX:
		return agora
	return de.lerp(agora, clampf(fracao, 0.0, 1.0))


## O x de um corpo, com a fracao do tick que o motor ja conta.
static func x_of(grupo: Group, id: int, x: float) -> float:
	return blend(grupo, id, Vector2(x, 0.0), Engine.get_physics_interpolation_fraction()).x


## O x e a altura de uma moeda — o arco inteiro, e nao so o chao.
static func coin(id: int, x: float, altura: float) -> Vector2:
	var f := Engine.get_physics_interpolation_fraction()
	return blend(Group.COINS, id, Vector2(x, altura), f)
