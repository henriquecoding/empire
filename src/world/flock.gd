# src/world/flock.gd — um bando de passaros, pelas regras de Reynolds (1986).
#
# Tres regras locais e uma de rumo, e o bando aparece sozinho: cada passaro
# afasta-se de quem esta demasiado perto (separacao), acerta o passo com os
# vizinhos (alinhamento) e chega-se ao meio deles (coesao); e todos vao atras
# de um rumo que anda devagar pelo ceu. Sao meia duzia de passaros, e por isso
# os vizinhos procuram-se todos contra todos — nao ha grelha que compense.
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

var positions := PackedVector2Array()
var velocities := PackedVector2Array()


func add(onde: Vector2, velocidade: Vector2) -> int:
	positions.append(onde)
	velocities.append(velocidade)
	return positions.size() - 1


func size() -> int:
	return positions.size()


func step(delta: float, rumo: Vector2) -> void:
	var novas := velocities.duplicate()
	for i in positions.size():
		var p := positions[i]
		var afastar := Vector2.ZERO
		var passo := Vector2.ZERO
		var meio := Vector2.ZERO
		var vizinhos := 0
		for j in positions.size():
			if j == i:
				continue
			var d := p.distance_to(positions[j])
			if d > REGRAS.vizinho:
				continue
			vizinhos += 1
			passo += velocities[j]
			meio += positions[j]
			if d < REGRAS.perto and d > 0.0:
				afastar += (p - positions[j]) / d
		var v := velocities[i]
		var querer := (rumo - p).normalized() * REGRAS.max * REGRAS.rumo
		if vizinhos > 0:
			querer += (passo / vizinhos - v) * REGRAS.alinhar
			querer += (meio / vizinhos - p) * REGRAS.juntar
		querer += afastar * REGRAS.max * REGRAS.afastar
		v += querer * delta
		novas[i] = v.limit_length(REGRAS.max)
		if novas[i].length() < REGRAS.min:
			novas[i] = novas[i].normalized() * REGRAS.min
	velocities = novas
	for i in positions.size():
		positions[i] += velocities[i] * delta


## O meio do bando, para quem quer saber onde ele vai.
func center() -> Vector2:
	var soma := Vector2.ZERO
	for p in positions:
		soma += p
	return soma / maxf(1.0, float(positions.size()))
