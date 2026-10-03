# src/world/bestiary.gd — o bestiario da Podridao: forma, porte e cor (§07, §22, ADR 0049).
#
# As sete criaturas de creatures.csv eram quatro sprites de quatro packs diferentes
# (um goblin, um olho voador, um cogumelo e um esqueleto, ADR 0042) e tres
# poligonos — e o Devorador, o colosso do §74, saia mais baixo do que o rei. O
# dono (02/10/2026): "a variedade, formato e tamanho dos inimigos deve ser mesmo
# bem feita". Aqui sao uma familia so — a mesma carne pisada, o mesmo osso, os
# mesmos olhos roxos (ADR 0034: roxo e dela) — e cada uma com um tamanho que se
# le contra uma tropa de 47 px e um rei de 94:
#
#   Rastejante  56 x 28   pelo joelho de uma tropa; sao muitos
#   Cavador     60 x 40   pelo peito; vem de baixo
#   Alado       80 x 52   de asa aberta, no ceu
#   Bruto       80 x 80   mais alto do que uma tropa, mais baixo do que o rei
#   Zelador     32 x 96   da altura do rei, e fino
#   Ariete     140 x 60   comprido e baixo: uma viga de lodo
#   Devorador  184 x 164  quase duas vezes o rei; sobe-se a ele
#
# Os tamanhos sao greybox, como as alturas do Silhouette (Q-079): nao mudam nada na
# simulacao. Quem desenha cada uma sao os BeastsSmall, BeastsLarge e BeastsGiant.
class_name Bestiary
extends RefCounted

const F := Silhouette.Form

## O tamanho de cada criatura em pixeis dela; um pixel e BeastPen.PIXEL px de mundo.
const TAMANHO := {
	F.RASTEJO: Vector2(28, 14),
	F.ASA: Vector2(40, 26),
	F.BROCA: Vector2(30, 20),
	F.BRUTO: Vector2(40, 40),
	F.ZELADOR: Vector2(16, 48),
	F.ARIETE: Vector2(70, 30),
	F.COLOSSO: Vector2(92, 82),
}

## As cores de cada uma, por papel (BeastPen.Tone): escuro, corpo, luz, osso e a
## carne do que a Podridao lhe fez crescer. Pouca saturacao de proposito: o frio
## saturado a noite e so dela e so a mancha (§80, o teste das duas frias).
const CORES := {
	F.RASTEJO: ["24181f", "43303a", "67505a", "b9a98d", "6b3a52"],
	F.ASA: ["1f171d", "3d2d37", "5e4652", "a8977d", "573049"],
	F.BROCA: ["2c2118", "514031", "77604a", "c4b394", "5c3a44"],
	F.BRUTO: ["2a221d", "4d4038", "6f5e51", "c3b291", "6a3c58"],
	F.ZELADOR: ["0f0c0d", "2a2326", "3f3539", "b5a68c", "2a2326"],
	F.ARIETE: ["211b26", "3a3043", "5a4c66", "d2c4a5", "64375a"],
	F.COLOSSO: ["1b1416", "3a2a2e", "5a4448", "d6cbb1", "6a2a46"],
}

## Quanto o tempo de cada criatura anda a frente do do ecra, por id: um enxame de
## Rastejantes nao mexe as patas todas ao mesmo tempo.
const DESFASE := 0.37

## O ritmo de cada uma, em radianos (ou voltas, o ciclo) por segundo: o passo, a
## onda (respirar, bater asa, ondular) e o ciclo (o que pinga, a broca, a terra).
const RITMO := {
	F.RASTEJO: Vector3(14, 0, 0),
	F.ASA: Vector3(0, 9, 0),
	F.BROCA: Vector3(10, 0, 6),
	F.BRUTO: Vector3(5, 2, 0),
	F.ZELADOR: Vector3(0, 1.5, 0),
	F.ARIETE: Vector3(0, 3, 0.8),
	F.COLOSSO: Vector3(2, 1.5, 0.7),
}
## Quem sobe e desce inteiro, e com que sinal: o Rastejante saltita com o passo, o
## Alado sobe e desce com a asa, o Zelador paira. (sinal, pixeis)
const SUBIDA := {
	F.RASTEJO: Vector2(BeastPen.Sinal.PASSO, 0.5),
	F.ASA: Vector2(BeastPen.Sinal.ONDA, -1.5),
	F.ZELADOR: Vector2(BeastPen.Sinal.ONDA, 0.5),
}
## A segunda onda anda este tanto atras da primeira, em radianos.
const DESFASE_ONDA := 0.6
## O golpe a bater vai ate aqui (StrikePose.SEGUE do pesado).
const GOLPE := 0.6
const MEIO := 0.5
## As poses ja rasterizadas (BeastPen.record), pela forma e pelos sinais em 1/PASSOS da
## amplitude: um sinal de k pixeis mexe de k/PASSOS em k/PASSOS, abaixo de meio px de
## mundo. Um enxame de Rastejantes era rasterizado traco a traco, criatura a criatura e
## frame a frame — 0,3 ms cada um, medido a 03/10/2026; agora a pose faz-se uma vez.
const PASSOS := 16
const LADO_CHAVE := 33
const POSES_MAX := 4096

static var _poses: Dictionary = {}


static func handles(forma: Silhouette.Form) -> bool:
	return TAMANHO.has(forma)


## A caixa de uma criatura em x, pousada na linha de chao da faixa dela.
static func box(forma: Silhouette.Form, x: float, faixa: int) -> Rect2:
	var tamanho: Vector2 = TAMANHO.get(forma, Vector2.ONE) * BeastPen.PIXEL
	var chao := WorldPalette.ground_of(faixa)
	return Rect2(Vector2(x - tamanho.x * WorldPalette.MEIA, chao - tamanho.y), tamanho)


## As cores de uma forma, cada uma pintada por `pintar(cor) -> Color` — a luz da
## noite (Lighting.body), o escuro de fora da luz (WorldLight.reveal), o aliado.
static func tones(forma: Silhouette.Form, pintar: Callable) -> Dictionary:
	var cores: Array = CORES.get(forma, CORES[F.RASTEJO])
	var tons := {}
	for papel in BeastPen.Tone.values():
		tons[papel] = pintar.call(Color(cores[papel]))
	return tons


## A criatura na caixa (esticada pela pose do golpe), virada para `frente`. `olhos`
## sao as duas cores do olho aceso; `anda` 1 se ela se mexe; `golpe` a arma da pose.
static func draw(
	canvas: CanvasItem,
	forma: Silhouette.Form,
	caixa: Rect2,
	tons: Dictionary,
	olhos: PackedColorArray,
	t: float,
	frente: float,
	anda: float,
	golpe: float
) -> void:
	var pen := _pen(canvas, forma, caixa, frente)
	pen.tones = tons
	pen.eye = olhos
	_corpo(pen, forma, t, anda, golpe)


## A criatura numa cor so, sem olhos: o branco do golpe (§24) e o corpo que se
## espalma na morte (DeathBurst) — com a forma dela, e nao com uma caixa.
static func silhouette(
	canvas: CanvasItem, forma: Silhouette.Form, caixa: Rect2, cor: Color, frente: float, t: float
) -> void:
	var pen := _pen(canvas, forma, caixa, frente)
	pen.flat = true
	pen.flat_color = cor
	_corpo(pen, forma, t, 0.0, 0.0)


static func _pen(
	canvas: CanvasItem, forma: Silhouette.Form, caixa: Rect2, frente: float
) -> BeastPen:
	var tamanho: Vector2 = TAMANHO.get(forma, Vector2.ONE)
	var pes := Vector2(caixa.get_center().x, caixa.end.y)
	return BeastPen.new(canvas, pes, caixa.size / tamanho, frente)


static func _corpo(
	pen: BeastPen, forma: Silhouette.Form, t: float, anda: float, golpe: float
) -> void:
	var sinais := signals(forma, t, anda, golpe)
	var chave := int(forma)
	for k in sinais.size():
		var degrau := roundi(sinais[k] * PASSOS)
		sinais[k] = float(degrau) / PASSOS
		chave = chave * LADO_CHAVE + degrau + PASSOS
	var subida: Vector2 = SUBIDA.get(forma, Vector2.ZERO)
	pen.subida = subida.y * sinais[int(subida.x)]
	var gravado: Array = _poses.get(chave, [])
	if gravado.is_empty():
		if _poses.size() >= POSES_MAX:
			_poses.clear()
		gravado = pen.record(strokes(forma), sinais)
		_poses[chave] = gravado
	pen.replay(gravado)


## Os sinais de um instante (BeastPen.Sinal): o passo e o contra-passo so a andar,
## as duas ondas sempre, a arma e o golpe da pose, e os ciclos de 0 a 1.
static func signals(
	forma: Silhouette.Form, t: float, anda: float, golpe: float
) -> PackedFloat32Array:
	var ritmo: Vector3 = RITMO.get(forma, Vector3.ZERO)
	var sinais := PackedFloat32Array()
	sinais.resize(BeastPen.Sinal.size())
	sinais[BeastPen.Sinal.PASSO] = sin(t * ritmo.x) * anda
	sinais[BeastPen.Sinal.CONTRA] = sin(t * ritmo.x + PI) * anda
	sinais[BeastPen.Sinal.ONDA] = sin(t * ritmo.y)
	sinais[BeastPen.Sinal.ONDA2] = sin(t * ritmo.y + DESFASE_ONDA)
	sinais[BeastPen.Sinal.ARMA] = clampf(-golpe, 0.0, 1.0)
	sinais[BeastPen.Sinal.BATE] = clampf(golpe / GOLPE, 0.0, 1.0)
	sinais[BeastPen.Sinal.CICLO] = fposmod(t * ritmo.z, 1.0)
	sinais[BeastPen.Sinal.CICLO2] = fposmod(t * ritmo.z * MEIO + MEIO, 1.0)
	sinais[BeastPen.Sinal.ANDA] = anda
	return sinais


## Os tracos de cada forma: as constantes dos tres ficheiros do bestiario.
static func strokes(forma: Silhouette.Form) -> Array:
	match forma:
		F.RASTEJO:
			return BeastsSmall.CRAWLER
		F.ASA:
			return BeastsSmall.WINGED
		F.BROCA:
			return BeastsSmall.BURROWER
		F.BRUTO:
			return BeastsLarge.BRUTE
		F.ARIETE:
			return BeastsLarge.SLIME_RAM
		F.COLOSSO:
			return BeastsGiant.DEVOURER
		F.ZELADOR:
			return BeastsGiant.TENDER
	return []
