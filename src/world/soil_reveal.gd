# src/world/soil_reveal.gd — quanto do corte de solo se ve: nada ate o rei descer (o
# pedido do dono de 30/09/2026; §11; ADR 0039).
#
# §11: "uma cavidade nao descoberta desenha-se como terra normal. Ao encontrar a
# entrada, a terra dissolve-se com o shader de dither e revela o interior." Aqui fica a
# conta: o progresso da dissolucao (0 tapado, 1 aberto) anda para 1 com o rei la em
# baixo e para 0 com ele ca em cima, e os dezasseis limiares da matriz de Bayer que o
# shader dither_reveal da §60 le. O SoilCover e quem o usa.
#
# Derivado e descartavel (§45): nao entra na simulacao nem no save.
class_name SoilReveal
extends RefCounted

## Quanto leva a terra a ir-se (ou a voltar), em segundos de ecra.
const SEGUNDOS := 0.45
## A matriz de Bayer 4x4, por linhas: a ordem em que cada quadrado se vai.
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const LADO := 4
## O limiar fica no meio do degrau: com o progresso a 0 nada se vai, a 1 vai-se tudo.
const MEIO := 0.5
const BYTE := 255.0

## 0 tapado, 1 aberto.
var progress := 0.0
var _iniciado := false


## Um passo de `delta` segundos, com o rei `em_baixo` ou nao. O primeiro passo nao
## anima: um save retomado com o rei la em baixo abre ja.
func step(delta: float, em_baixo: bool) -> void:
	var alvo := 1.0 if em_baixo else 0.0
	if not _iniciado:
		_iniciado = true
		progress = alvo
		return
	progress = move_toward(progress, alvo, delta / SEGUNDOS)


func open() -> bool:
	return progress >= 1.0


func closed() -> bool:
	return progress <= 0.0


## Se o corte de solo quer estar aberto: o rei esta vivo e la em baixo.
static func wants_open(unidades: UnitSystem, rei: int) -> bool:
	var i := unidades.index_of(rei)
	if i == UnitSystem.NENHUM or not unidades.alive(i):
		return false
	return int(unidades.bands[i]) == int(Band.Kind.UNDERGROUND)


## Os limiares da matriz, por linhas, entre 0 e 1 (exclusive).
static func thresholds() -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for n: int in BAYER:
		saida.append((float(n) + MEIO) / float(BAYER.size()))
	return saida


## A textura `matrix` do dither_reveal: um quadrado de LADO x LADO, em tons de cinzento.
static func matrix() -> ImageTexture:
	var bytes := PackedByteArray()
	for t in thresholds():
		bytes.append(roundi(t * BYTE))
	var imagem := Image.create_from_data(LADO, LADO, false, Image.FORMAT_L8, bytes)
	return ImageTexture.create_from_image(imagem)
