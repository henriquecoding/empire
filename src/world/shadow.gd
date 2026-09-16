# src/world/shadow.gd — a sombra de contacto (§22, §24).
#
# O §22 tem-na no plano de producao — "Sombras de contacto: um sprite de elipse
# por escala e por classe de objeto, mais o no que o coloca, 1 h" — e ate ter
# sprite e isto: a elipse, desenhada.
#
# Nao e decoracao. Sem sombra, um mundo de uma linha nao diz a que altura esta
# uma coisa: uma moeda no ar a 20 px do chao e uma moeda pousada sao o mesmo
# circulo em sitios diferentes, e o §24 chama ao arco dela "a animacao mais
# importante do jogo" precisamente por acontecer milhares de vezes por partida.
# A sombra e o que transforma dois circulos numa MOEDA A CAIR.
#
# A regra e a de sempre: quanto mais alto, menor e mais fraca. Nao ha aqui um
# numero de balanceamento — a altura contra a qual se mede vem do arco que a
# `economy.csv` ja define, pelo `CoinSystem.apex_px()`.
class_name Shadow
extends RefCounted

## Uma elipse e um circulo achatado. Um terco e o que da "chao" sem virar um
## disco visto de cima — a camara do §11 esta quase de lado.
const ACHATAMENTO := 0.34
## Quanto resta da sombra no ponto mais alto do arco, em raio e em opacidade.
## Nao chega a zero: uma sombra que desaparece leva com ela a informacao de onde
## a coisa vai cair, que e para o que ela serve.
const NO_APICE := 0.45
const MEIA := 0.5


## A sombra de uma coisa que esta `acima` px do chao da sua faixa. `apice` e a
## altura contra a qual se mede — acima dela a sombra nao encolhe mais.
static func drop(
	canvas: CanvasItem, x: float, faixa: int, raio: float, acima: float, apice: float
) -> void:
	if raio <= 0.0:
		return
	var subida := 0.0 if apice <= 0.0 else clampf(acima / apice, 0.0, 1.0)
	var escala := lerpf(1.0, NO_APICE, subida)
	var cor := WorldPalette.SOMBRA
	cor.a *= escala
	# A elipse faz-se com a transformacao e nao com um poligono a mao: sao doze
	# vertices por moeda, e numa noite ha dezenas de moedas no chao.
	canvas.draw_set_transform(
		Vector2(x, WorldPalette.ground_of(faixa)), 0.0, Vector2(1.0, ACHATAMENTO)
	)
	canvas.draw_circle(Vector2.ZERO, raio * escala, cor)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Quanto sobe uma sombra ao acompanhar o que a lanca. Devolve a fraccao do
## caminho ja feito, e esta aqui — e nao dentro do `drop` — para que um teste
## possa medir a regra sem um canvas.
static func fade(acima: float, apice: float) -> float:
	if apice <= 0.0:
		return 1.0
	return lerpf(1.0, NO_APICE, clampf(acima / apice, 0.0, 1.0))
