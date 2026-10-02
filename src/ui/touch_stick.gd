# src/ui/touch_stick.gd — a alavanca do polegar esquerdo (ADR 0047).
#
# Flutuante e so horizontal: o mundo e uma linha (§11), e andar e esquerda ou direita.
# O centro e onde o polegar pousou — mesmo quando a base desenhada nao pode estar la,
# como num polegar pousado na barra preta de um telemovel. Arrastar ate ao fim corre:
# e o "drag all the way" do Kingdom no telemovel, e o king_run do §24 (Q-149). Se o
# dedo passa da borda, o centro vai atras dele: voltar para o outro lado custa so o
# caminho de volta, e nao o caminho todo.
class_name TouchStick
extends RefCounted

## O que o polegar treme sem querer andar, em px a 1280x720.
const MORTA := 12.0
## A partir de que fraccao do raio se corre.
const CORRE := 0.8

## A base desenhada e o raio dela.
var base := Vector2.ZERO
var radius := 0.0
## O quanto o polegar saiu do centro, em x, ja preso ao raio.
var offset := 0.0
var held := false
var _zero := 0.0
var _morta := MORTA


## O polegar pousou em `p`; a base desenha-se em `onde`, com o raio e a escala dados.
func begin(p: Vector2, onde: Vector2, raio: float, escala: float) -> void:
	held = true
	base = onde
	radius = raio
	_zero = p.x
	_morta = MORTA * escala
	offset = 0.0


func move(p: Vector2) -> void:
	if not held:
		return
	var dx := p.x - _zero
	if absf(dx) > radius:
		var excesso := dx - signf(dx) * radius
		_zero += excesso
		base.x += excesso
		dx = signf(dx) * radius
	offset = dx


func end() -> void:
	held = false
	offset = 0.0


## -1, 0 ou 1: o sentido em que o polegar empurra, fora da zona morta.
func axis() -> float:
	if not held or absf(offset) < _morta:
		return 0.0
	return signf(offset)


func runs() -> bool:
	return held and absf(offset) >= CORRE * radius
