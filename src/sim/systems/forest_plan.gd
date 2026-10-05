# src/sim/systems/forest_plan.gd — onde nascem as arvores, pela ordem certa (ADR 0070).
#
# Primeiro o que o mapa precisa (§8.2 do relatorio de vegetacao): passagens, provisoes,
# acampamentos, estatuas, raizes e tocas ficam reservados, e nenhuma arvore os tapa. So
# depois a floresta enche o resto, celula a celula: no maximo uma arvore por celula, num
# sitio tremido dentro dela, e so onde a densidade do bosque o deixa. A mesma celula da
# sempre a mesma arvore, venha o jogador de onde vier.
#
# E depois o que as regras precisam: uma toca que vive de arvores tem de nascer com
# abrigo, ou a regra que a adormece seria uma armadilha do gerador e nao uma decisao.
#
# Puro: a densidade, o sorteio e a especie chegam como funcoes de quem chama.
class_name ForestPlan
extends RefCounted

## O tremor fica longe das bordas da celula: e o espacamento minimo.
const TREMOR := {"de": 0.15, "largo": 0.7}
## Quantos ids cabem numa zona: a zona e o milhar alto, a celula o resto.
const ZONA := 100000
const MEIO := 0.5
const LADOS := [-1.0, 1.0]


## As arvores de `a` a `b`, em celulas de `step`: [id, x, especie] de cada uma.
## `roll(celula) -> Array[float]` da o tremor; `pick(celula, x) -> StringName` a especie,
## ou &"" se ali nao cresce nada. Nada nasce dentro de `reserved`.
static func place(
	zone: int, a: float, b: float, step: float, roll: Callable, pick: Callable, reserved: Array
) -> Array:
	var saida: Array = []
	if step <= 0.0 or b <= a:
		return saida
	for celula in range(floori(a / step), floori(b / step) + 1):
		var d: Array = roll.call(celula)
		var x: float = floorf((float(celula) + TREMOR.de + float(d[0]) * TREMOR.largo) * step)
		if x < a or x >= b or not open_at(x, reserved):
			continue
		var especie: StringName = pick.call(celula, x)
		if especie != &"":
			saida.append([id_of(zone, celula), x, especie])
	return saida


## Os sitios que faltam para uma toca em `center` ter `need` arvores a `radius`, quando
## ja tem `have`: a volta dela, alternando lados, um passo de cada vez.
static func grove(
	center: float, radius: float, need: int, have: int, step: float, reserved: Array
) -> Array[float]:
	var saida: Array[float] = []
	var passo := 1
	while saida.size() < need - have and float(passo) * step * MEIO <= radius:
		for lado in LADOS:
			var x: float = center + lado * float(passo) * step * MEIO
			if saida.size() < need - have and open_at(x, reserved):
				saida.append(x)
		passo += 1
	return saida


## Se `x` nao cai em nenhum dos intervalos reservados (Vector2 de/ate).
static func open_at(x: float, reserved: Array) -> bool:
	for span: Vector2 in reserved:
		if x >= span.x and x <= span.y:
			return false
	return true


## O id estavel de uma arvore: a zona e a celula. Uma celula negativa (a oeste) tambem.
static func id_of(zone: int, cell: int) -> int:
	return zone * ZONA + posmod(cell, ZONA)
