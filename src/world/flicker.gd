# src/world/flicker.gd — o fogo que cintila e o Lume que respira (ADR 0048).
#
# Uma chama nao tem um brilho: tem tres ou quatro ondas por cima umas das
# outras. E o que os motores fazem ao PointLight de uma tocha — senos de
# frequencias que nao se dividem umas pelas outras, para que o padrao nunca se
# repita a vista. Nada disto e aleatorio (§42): e uma funcao do tempo e de onde a
# luz esta, e duas fogueiras lado a lado nao cintilam em uniao porque a fase de
# cada uma sai do x dela.
#
# O Lume nao cintila: respira. E devagar e fundo, para se ler de longe como uma
# coisa viva e nao como fogo — o roxo e dela, e o fogo e teu (ADR 0034).
class_name Flicker
extends RefCounted

enum Kind { FIRE, LUME, STEADY }

## (hertz, amplitude) de cada onda. As amplitudes somam menos de 10%: um fogo que
## varia mais do que isso deixa de iluminar e passa a piscar.
const FOGO := [Vector2(1.3, 0.045), Vector2(3.7, 0.03), Vector2(8.9, 0.018)]
const LUME := [Vector2(0.35, 0.05), Vector2(0.9, 0.015)]
## Quanto a fase de cada onda anda por px de mundo: o que desencontra as luzes.
const DESFASE := 0.0137


## O multiplicador desta luz agora: 1 e o brilho dela, e anda a volta disso.
static func of(kind: Kind, tempo: float, x: float) -> float:
	var ondas: Array = FOGO if kind == Kind.FIRE else (LUME if kind == Kind.LUME else [])
	var soma := 1.0
	var k := 1.0
	for onda: Vector2 in ondas:
		soma += onda.y * sin(TAU * onda.x * tempo + x * DESFASE * k)
		k += 1.0
	return soma


## O raio a cintilar, preso a grelha do dither: a borda de uma luz anda aos
## saltos de uma celula, como um pixel, e nao escorrega meio pixel por frame.
static func radius(raio: float, kind: Kind, tempo: float, x: float, celula: float) -> float:
	var vivo := raio * of(kind, tempo, x)
	if celula <= 0.0:
		return vivo
	return roundf(vivo / celula) * celula
