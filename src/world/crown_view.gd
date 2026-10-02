# src/world/crown_view.gd — a coroa no chao, ao pe do rei caido (Q-167; o dono, 02/10).
#
# Era uma forma lisa de 18 px, a espera de arte. O dono, a 02/10/2026, das moedas "e
# itens que sao dropados": grandes, para se verem como no Kingdom, com fisica, e a
# parecer-se com o que sao. A coroa e o item que mais importa apanhar — e a vida do
# reino (§16) —, e e por isso desenhada como a moeda (CoinArt): em pixeis de 2, as
# tres pontas com a bola de ouro, o aro com as pedras, o brilho em cima e a sombra
# em baixo, 30 px de largo.
#
# E CAI: da cabeca do rei ate ao chao na gravidade da moeda, ressalta e balanca como
# ela (CoinBounce), e depois fica a piscar de vez em quando — o brilho que nao leva
# luz, para se dar com ela no escuro. O ouro guarda um pouco da sua cor longe da luz.
# Nada disto toca no sitio dela, que e o da simulacao (CrownDrop).
class_name CrownView
extends RefCounted

## A coroa: aro (#), ouro (o), brilho (+), sombra (.), cunho (=), pedra (r); o espaco
## e vazio.
const COROA := [
	" +     +     + ",
	"#o#   #o#   #o#",
	"#oo# #o+o# #oo#",
	"#ooo#ooooo#ooo#",
	"#ooooooooooooo#",
	"###############",
	"#o=r=oo+oo=r=o#",
	"#oooooooo.....#",
	"###############",
]
const PEDRA := Color("b8352a")
## A altura da cabeca do rei, de onde cai, em px acima do chao.
const QUEDA := 56.0
## O brilho da ponta do meio, e o id dela para o CoinBounce e para o brilho.
const PONTA := Vector2(0.0, -17.0)
const ID := -1
## Ainda nao se viu cair.
const NUNCA := -1.0
const MEIO := 0.5

static var _salto: CoinBounce
static var _desde := NUNCA


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting, tempo: float) -> void:
	var coroa: CrownDrop = SimLoop.field.crown_drop if SimLoop.field != null else null
	if coroa == null or not coroa.down:
		_desde = NUNCA
		return
	if coroa.band != int(faixa):
		return
	var gravidade := SimFactory.curve().coin_gravity_px_s2
	if _desde < 0.0 or tempo < _desde:
		_desde = tempo
		_salto = CoinBounce.new(gravidade)
	var altura := fall(tempo - _desde, gravidade)
	_salto.observe(ID, altura, tempo)
	var acima := altura + _salto.offset(ID, tempo)
	var pe := Vector2(coroa.x, WorldPalette.ground_of(int(faixa)))
	var largo := float(String(COROA[0]).length()) * CoinArt.PIXEL
	Shadow.drop(canvas, coroa.x, int(faixa), largo * MEIO, acima, QUEDA)
	var cor := CoinArt.lit(luz, coroa.x)
	var tons := CoinArt.tones(cor)
	tons["r"] = cor.call(PEDRA)
	var face := maxf(_salto.face(ID, tempo), CoinArt.DE_LADO)
	CoinArt.paint(canvas, pe - Vector2(0.0, acima), COROA, face, tons)
	if acima <= 0.0:
		var brilho := CoinArt.glint(ID, tempo)
		if brilho > 0.0:
			CoinArt.sparkle(canvas, pe + PONTA, brilho)


## A altura da coroa `t` segundos depois de cair, na `gravidade` da moeda: de QUEDA
## ate ao chao.
static func fall(t: float, gravidade: float) -> float:
	return maxf(0.0, QUEDA - gravidade * t * t * MEIO)
