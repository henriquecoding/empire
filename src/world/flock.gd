# src/world/flock.gd — um bando de passaros, pelas regras de Reynolds (1986).
#
# Tres regras locais e uma de rumo, e o bando aparece sozinho: cada passaro
# afasta-se de quem esta demasiado perto (separacao), acerta o passo com os
# vizinhos (alinhamento) e chega-se ao meio deles (coesao); e todos vao atras
# de um rumo que anda devagar pelo ceu. Eram meia duzia de passaros; com o mundo
# continuo (Q-173) o bando junta os das terras todas — 107 numa semente medida a
# 03/10/2026 —, e todos contra todos custava 1 ms por frame. Os vizinhos procuram-se
# agora por ordem de x: ordena-se o bando (no motor, nao em GDScript), e cada passaro
# so olha para a frente ate um raio de vizinho — e cada par conta-se uma vez, para os dois.
#
# Puro: nao le relogio nem RNG. Quem o usa da o rumo e o passo.
class_name Flock
extends RefCounted

## Distancias em px, pesos sem unidade, velocidades em px/s.
const REGRAS := {
	"vizinho": 70.0,
	"perto": 16.0,
	"afastar": 2.2,
	"alinhar": 0.5,
	"juntar": 0.35,
	"rumo": 0.9,
	"min": 38.0,
	"max": 95.0,
}

## Longe do ecra o bando anda aos saltos de LONGE_S segundos: ninguem o ve, e cada passo
## custa o bando inteiro. Perto (a `vista` do advance), anda frame a frame.
const LONGE_S := 0.2

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
## Onde o bando ficou no ultimo passo.
var caixa := Rect2()
var _por_andar := 0.0


func add(onde: Vector2, velocidade: Vector2) -> int:
	positions.append(onde)
	velocities.append(velocidade)
	return positions.size() - 1


func size() -> int:
	return positions.size()


## Um frame: um passo, se o bando esta perto da `vista`; longe, so de LONGE_S em LONGE_S.
func advance(delta: float, rumo: Vector2, vista := PresentationBounds.TUDO) -> void:
	_por_andar += delta
	if _por_andar < LONGE_S and not vista.intersects(caixa.grow(REGRAS.vizinho)):
		return
	step(_por_andar, rumo)
	_por_andar = 0.0


func step(delta: float, rumo: Vector2) -> void:
	var n := positions.size()
	var afastar := PackedVector2Array()
	var passo := PackedVector2Array()
	var meio := PackedVector2Array()
	var vizinhos := PackedInt32Array()
	afastar.resize(n)
	passo.resize(n)
	meio.resize(n)
	vizinhos.resize(n)
	var ordem := _por_x()
	for a in n:
		var i := int(ordem[a].y)
		var p := positions[i]
		for b in range(a + 1, n):
			if ordem[b].x - ordem[a].x > REGRAS.vizinho:
				break
			var j := int(ordem[b].y)
			var d := p.distance_to(positions[j])
			if d > REGRAS.vizinho:
				continue
			vizinhos[i] += 1
			vizinhos[j] += 1
			passo[i] += velocities[j]
			passo[j] += velocities[i]
			meio[i] += positions[j]
			meio[j] += positions[i]
			if d < REGRAS.perto and d > 0.0:
				afastar[i] += (p - positions[j]) / d
				afastar[j] -= (p - positions[j]) / d
	var novas := velocities.duplicate()
	for i in n:
		var p := positions[i]
		var v := velocities[i]
		var querer := (rumo - p).normalized() * REGRAS.max * REGRAS.rumo
		if vizinhos[i] > 0:
			querer += (passo[i] / vizinhos[i] - v) * REGRAS.alinhar
			querer += (meio[i] / vizinhos[i] - p) * REGRAS.juntar
		querer += afastar[i] * REGRAS.max * REGRAS.afastar
		v += querer * delta
		novas[i] = v.limit_length(REGRAS.max)
		if novas[i].length() < REGRAS.min:
			novas[i] = novas[i].normalized() * REGRAS.min
	velocities = novas
	for i in n:
		positions[i] += velocities[i] * delta
	caixa = Rect2(positions[0], Vector2.ZERO) if n > 0 else Rect2()
	for p in positions:
		caixa = caixa.expand(p)


## O bando por ordem de x, como (x, indice): o sort() do motor ordena pelo x.
func _por_x() -> Array[Vector2]:
	var ordem: Array[Vector2] = []
	ordem.resize(positions.size())
	for i in positions.size():
		ordem[i] = Vector2(positions[i].x, i)
	ordem.sort()
	return ordem


## O meio do bando, para quem quer saber onde ele vai.
func center() -> Vector2:
	var soma := Vector2.ZERO
	for p in positions:
		soma += p
	return soma / maxf(1.0, float(positions.size()))
