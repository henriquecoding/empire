# src/world/beast_pen.gd — o pincel do bestiario: pixeis de criatura (§22, §80).
#
# Uma criatura desenha-se em PIXEIS DELA, e nao em px de mundo: o x anda para a
# frente (para onde ela olha), o y sobe a partir dos pes, e um pixel dela vale
# `escala` px de mundo — 2 na pose de descanso, a grelha do dither do §80. Assim
# cada criatura escreve-se uma vez, virada para a direita, e o pincel espelha-a,
# estica-a com a pose do golpe (CombatFx) e espalma-a na morte (DeathBurst).
#
# A criatura e uma lista de TRACOS numa constante (o portao G4 quer os numeros em
# constantes, §47, como no ShapeArt): [traco, papel, numeros...]. Cada numero e um
# numero, ou [base, sinal, k, sinal, k...] — a base mais k vezes cada sinal do
# instante (Signal): o passo, a onda, a arma, o golpe, o ciclo. E assim que uma
# pata anda e uma asa bate sem uma linha de codigo por criatura.
#
# As cores pedem-se por PAPEL — o escuro, o corpo, a luz, o osso, a carne — e o
# pincel ja as tem com a luz da noite (Lighting.body). O olho e outra coisa: e
# emissivo, nao leva luz nenhuma, e e roxo porque e dela (ADR 0034).
class_name BeastPen
extends RefCounted

enum Tone { DARK, BODY, LIGHT, BONE, FLESH }
## RECT x, y, largo, alto · BLOB cx, cy, rx, ry · LINE x0, y0, x1, y1, grosso ·
## POLY x0, y0, x1, y1... · GLOW x, y, lado (o olho; o papel nao conta)
enum Stroke { RECT, BLOB, LINE, POLY, GLOW }
## Os sinais de um instante: o passo e o contra-passo (so a andar), a onda e a
## segunda onda (sempre: respirar, bater asas, ondular), a arma e o golpe (a pose
## da simulacao, StrikePose), o ciclo de 0 a 1 e outro a meio ritmo, e se anda.
enum Sinal { PASSO, CONTRA, ONDA, ONDA2, ARMA, BATE, CICLO, CICLO2, ANDA }

## Um pixel de criatura em px de mundo, com a criatura em descanso.
const PIXEL := 2.0
## O halo do olho: o alfa do anel de um pixel a volta dele.
const HALO := 0.35
const MEIO := 0.5
const OLHO_GRANDE := 2.0
const QUADRADO := 2.0
const NUMEROS := 2
const ESQUERDA := -1.0
## Os codigos do que se grava (record): ate POLIGONO e o papel de um rectangulo, ate ao
## olho o de um poligono, e os tres do olho, que nao levam papel nem luz.
const POLIGONO := 8
const HALO_OLHO := 16
const NUCLEO_OLHO := 17
const BRILHO_OLHO := 18
const OLHO_TONS := 2
## Os numeros de um traco, pela ordem em que se escrevem.
const A := 0
const B := 1
const C := 2
const D := 3
const E := 4

var canvas: CanvasItem
## Os pes, em px de mundo, ja presos a grelha.
var foot := Vector2.ZERO
var escala := Vector2(PIXEL, PIXEL)
var facing := 1.0
## Quanto a criatura inteira sobe, em pixeis dela: o saltitar e o pairar.
var subida := 0.0
## Papel -> cor com a luz que la chega.
var tones: Dictionary = {}
## As duas cores do olho (o roxo do Lume: meio e nucleo). Sem elas, sem olhos.
var eye := PackedColorArray()
## Tudo numa cor so: o branco do golpe e o corpo que se espalma (DeathBurst).
var flat := false
var flat_color := Color.WHITE
var _gravado: Array = []


func _init(onde: CanvasItem, pes: Vector2, tamanho: Vector2, lado: float) -> void:
	canvas = onde
	foot = pes.round()
	escala = tamanho
	facing = 1.0 if lado >= 0.0 else ESQUERDA


func tone(papel: Tone) -> Color:
	return flat_color if flat else tones.get(papel, Color.MAGENTA)


## Os tracos de uma criatura, com os sinais deste instante: gravar e pintar.
func strokes(lista: Array, sinais: PackedFloat32Array) -> void:
	replay(record(lista, sinais))


## Os tracos em pixeis dela, gravados sem cor nem subida: [codigo, Rect2 ou pontos, ...].
## O codigo e o papel, o papel mais POLIGONO, ou um dos tres do olho. Sao as mesmas contas
## para a mesma pose, e o Bestiary guarda-as: uma pose rasteriza-se uma vez (03/10/2026).
func record(lista: Array, sinais: PackedFloat32Array) -> Array:
	_gravado = []
	var n := PackedFloat32Array()
	for traco: Array in lista:
		n.clear()
		for k in range(NUMEROS, traco.size()):
			var termo: Variant = traco[k]
			n.append(value(termo, sinais) if termo is Array else float(termo))
		var papel: Tone = traco[1]
		match int(traco[0]):
			Stroke.RECT:
				rect(n[A], n[B], n[C], n[D], papel)
			Stroke.BLOB:
				blob(n[A], n[B], n[C], n[D], papel)
			Stroke.LINE:
				line(n[A], n[B], n[C], n[D], papel, n[E] if n.size() > E else 1.0)
			Stroke.POLY:
				var pontos := PackedVector2Array()
				for i in range(0, n.size() - 1, 2):
					pontos.append(Vector2(n[i], n[i + 1]))
				poly(pontos, papel)
			Stroke.GLOW:
				glow(n[A], n[B], n[C] if n.size() > C else 1.0)
	return _gravado


## O que se gravou, com as cores e a subida deste pen. O `at()` vai numa transformacao so:
## era uma conta de px de mundo por canto de cada rectangulo, centenas por criatura.
func replay(gravado: Array) -> void:
	canvas.draw_set_transform(foot, 0.0, Vector2(facing * escala.x, -escala.y))
	var cores: Array[Color] = []
	for papel: Tone in Tone.values():
		cores.append(tone(papel))
	var olhos := not flat and eye.size() >= OLHO_TONS
	var cima := Vector2(0.0, subida)
	for i in range(0, gravado.size(), NUMEROS):
		var codigo: int = gravado[i]
		if codigo < POLIGONO:
			var caixa: Rect2 = gravado[i + 1]
			canvas.draw_rect(Rect2(caixa.position + cima, caixa.size), cores[codigo])
		elif codigo < HALO_OLHO:
			var pontos: PackedVector2Array = gravado[i + 1]
			canvas.draw_colored_polygon(Transform2D(0.0, cima) * pontos, cores[codigo - POLIGONO])
		elif olhos:
			var caixa: Rect2 = gravado[i + 1]
			canvas.draw_rect(Rect2(caixa.position + cima, caixa.size), _olho(codigo))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## Um numero de um traco: ele proprio, ou a base mais k vezes cada sinal.
static func value(termo: Variant, sinais: PackedFloat32Array) -> float:
	if not termo is Array:
		return float(termo)
	var soma := float(termo[0])
	for i in range(1, termo.size() - 1, 2):
		soma += float(termo[i + 1]) * sinais[int(termo[i])]
	return soma


## O px de mundo de um pixel da criatura: x para a frente, y para cima.
func at(x: float, y: float) -> Vector2:
	return foot + Vector2(x * facing * escala.x, -(y + subida) * escala.y)


## Um rectangulo de pixeis, com o canto de tras e de baixo em (x, y).
func rect(x: float, y: float, w: float, h: float, papel: Tone) -> void:
	_caixa(x, y, w, h, papel)


## Uma massa oval, linha a linha: o corpo de quase tudo o que a noite traz.
func blob(cx: float, cy: float, rx: float, ry: float, papel: Tone) -> void:
	var linhas := maxi(1, roundi(ry))
	for j in range(-linhas, linhas + 1):
		var meia := rx * sqrt(maxf(0.0, 1.0 - pow(float(j) / maxf(ry, MEIO), QUADRADO)))
		if meia < MEIO:
			continue
		_caixa(roundf(cx - meia), cy + float(j), roundf(meia * QUADRADO), 1.0, papel)


## Uma linha de pixeis com `grosso` de espessura: patas, chifres, dedos.
func line(x0: float, y0: float, x1: float, y1: float, papel: Tone, grosso := 1.0) -> void:
	var passos := maxi(1, roundi(maxf(absf(x1 - x0), absf(y1 - y0))))
	for i in passos + 1:
		var t := float(i) / float(passos)
		var x := roundf(lerpf(x0, x1, t) - grosso * MEIO)
		var y := roundf(lerpf(y0, y1, t) - grosso * MEIO)
		_caixa(x, y, grosso, grosso, papel)


## Um poligono de pixeis: asas, capuz, a broca. Os vertices prendem-se a grelha.
func poly(pontos: PackedVector2Array, papel: Tone) -> void:
	var dela := PackedVector2Array()
	for p in pontos:
		dela.append(Vector2(roundf(p.x), roundf(p.y)))
	_gravado.append_array([int(papel) + POLIGONO, dela])


## Um olho aceso: o nucleo claro, o roxo a volta e um halo fraco. Nao leva luz: a cor
## e a do olho de quem o pinta, e sem olho (o branco, a morte) nao se pinta.
func glow(x: float, y: float, lado := 1.0) -> void:
	_caixa(x - 1.0, y - 1.0, lado + OLHO_GRANDE, lado + OLHO_GRANDE, HALO_OLHO)
	_caixa(x, y, lado, lado, NUCLEO_OLHO)
	var brilho := y + lado - 1.0 if lado >= OLHO_GRANDE else y
	_caixa(x, brilho, 1.0, 1.0, BRILHO_OLHO)


## Um rectangulo em pixeis dela, gravado com o codigo do que o pinta.
func _caixa(x: float, y: float, w: float, h: float, codigo: int) -> void:
	if w <= 0.0 or h <= 0.0:
		return
	_gravado.append_array([codigo, Rect2(x, y, w, h)])


func _olho(codigo: int) -> Color:
	match codigo:
		HALO_OLHO:
			return Color(eye[0], HALO)
		NUCLEO_OLHO:
			return eye[0]
	return eye[1]
