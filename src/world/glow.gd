# src/world/glow.gd — uma luz, e o que ela da a cada distancia (§80, ADR 0048).
#
# O §80 desenha a luz com tres paragens — nucleo, meio, bordo — e nunca com um
# gradiente. Ate aqui eram tres discos pintados POR CIMA do mundo: um alvo opaco
# que tapava o chao e nao alumiava nada, nem de noite nem de dia. Agora uma luz e
# isto: um centro, um raio e as tres cores, e quem a recebe e o mundo — o
# cenario no shader (SceneryLight) e os corpos no Lighting. As contas sao as
# mesmas nos dois sitios; esta e a que se testa.
#
# A luz SOMA-SE ao ambiente: perto do fogo ve-se mais, e longe ve-se o que o olho
# ve de noite (BandLight.seen). Duas luzes sobrepostas somam-se tambem, ate ao
# tecto do Lighting — e o Lume, de forca 1, continua a dominar as tuas fogueiras
# de forca 0,5 a mesma distancia (§80, Q-078).
class_name Glow
extends RefCounted

## A forca respira meio segundo atras do raio: as duas ondas nao batem juntas.
const MEIO_SEGUNDO := 0.5

## O centro, no mundo: x e a linha de chao da faixa, ou a altura de uma mao.
var center := Vector2.ZERO
var band := int(Band.Kind.SURFACE)
var radius := 0.0
## A forca das paragens (Q-078): 1 e o Lume; as tuas luzes sao mais fracas.
var strength := 1.0
## Bordo, meio, nucleo — a ordem do WorldLight.stops().
var stops := PackedColorArray()
var kind := Flicker.Kind.FIRE


func _init(
	onde: Vector2,
	faixa: int,
	raio: float,
	forca: float,
	cores: PackedColorArray,
	tipo: Flicker.Kind
) -> void:
	center = onde
	band = faixa
	radius = raio
	strength = forca
	stops = cores
	kind = tipo


## A mesma luz a cintilar agora (Flicker): o raio aos saltos de uma celula e a
## forca a respirar com ele.
func alive(tempo: float, celula: float) -> Glow:
	var raio := Flicker.radius(radius, kind, tempo, center.x, celula)
	var forca := strength * Flicker.of(kind, tempo + MEIO_SEGUNDO, center.x)
	return Glow.new(center, band, raio, forca, stops, kind)


## A paragem que acende a esta distancia: 2 e o nucleo, 0 o bordo, -1 fora.
func stop_at(d: float) -> int:
	return WorldLight.stop_at(radius, d)


## A luz que chega a um ponto: a cor da paragem dele vezes a forca, e nada fora.
func light_at(p: Vector2) -> Color:
	var paragem := stop_at(center.distance_to(p))
	if paragem < 0 or stops.size() < WorldLight.PARAGENS:
		return Color(0.0, 0.0, 0.0, 0.0)
	var cor := stops[paragem]
	return Color(cor.r * strength, cor.g * strength, cor.b * strength, 1.0)


## Quanto um ponto esta dentro: 1 no nucleo, um terco no bordo, 0 fora. E o que
## o §80 chama "perto da luz" — a medida com que um corpo deixa de ser silhueta.
func reach_at(p: Vector2) -> float:
	var paragem := stop_at(center.distance_to(p))
	if paragem < 0:
		return 0.0
	return float(paragem + 1) / float(WorldLight.PARAGENS)
