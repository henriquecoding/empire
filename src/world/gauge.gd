# src/world/gauge.gd — os instrumentos do greybox, e so eles (§24, §67, GB-03).
#
# O §07 e explicito: "sem numeros no ecra. Nada de barras de vida flutuantes nem
# de dano em texto. O estado le-se pelo sprite". Isto e o contrario disso, e sabe
# que e: nao ha sprite nenhum, e sem instrumento nao se consegue MEDIR uma noite
# — que e para o que o greybox existe (§67). Desaparece com o ART-01, e este
# ficheiro e onde se ve o que ha para apagar.
#
# A barra leva CALHA. E a diferenca entre ler e adivinhar: o castelo-arvore tem
# 480 px de largo e 1000 de vida, e a 48 de vida a parte cheia sao 23 px — um
# risco que tanto pode ser "quase morto" como "um arranhao num sitio pequeno".
# Com a calha por tras, os mesmos 23 px passam a dizer 5%.
class_name Gauge
extends RefCounted


## A vida de uma coisa, por cima dela. Cheia nao se desenha — um ecra com uma
## barra por cima de cada tropa viva e ruido, e o que interessa e quem esta a
## perder.
static func health(canvas: CanvasItem, caixa: Rect2, racio: float) -> void:
	if racio >= 1.0 or racio <= 0.0:
		return
	var topo := caixa.position - Vector2(0.0, WorldPalette.BARRA * WorldPalette.CONTORNO)
	var calha := Rect2(topo, Vector2(caixa.size.x, WorldPalette.BARRA))
	canvas.draw_rect(calha, WorldPalette.VAZIO)
	var largo := caixa.size.x * clampf(racio, 0.0, 1.0)
	canvas.draw_rect(Rect2(topo, Vector2(largo, WorldPalette.BARRA)), WorldPalette.VIDA)


## §24: "o saco do personagem enche visivelmente; moedas caem quando esta
## cheio". E a unica linha do HUD diegetico que o greybox cumpre tal e qual —
## nao e uma barra por cima da cabeca, e o corpo a encher por baixo — e e a que
## diz quem tem com que pagar a obra do lado.
static func purse(canvas: CanvasItem, caixa: Rect2, moedas: int, cabem: int) -> void:
	if cabem <= 0 or moedas <= 0:
		return
	var cheio := clampf(float(moedas) / float(cabem), 0.0, 1.0)
	var alto := caixa.size.y * WorldPalette.SACO * cheio
	var canto := Vector2(caixa.position.x, caixa.end.y - alto)
	canvas.draw_rect(Rect2(canto, Vector2(caixa.size.x, alto)), WorldPalette.MOEDA)


## Quanto do degrau seguinte de uma obra ja esta pago (§55). Sem isto nao ha
## maneira de saber se faltam cinco moedas ou uma, e o §55 nao tem contador
## nenhum para o dizer — enche o fantasma por baixo, como o saco.
static func paid(canvas: CanvasItem, fantasma: Rect2, vaga: BuildSlot) -> void:
	var custo := vaga.next_cost()
	if custo <= 0 or vaga.paid <= 0:
		return
	var racio := clampf(float(vaga.paid) / float(custo), 0.0, 1.0)
	var alto := fantasma.size.y * racio
	var canto := Vector2(fantasma.position.x, fantasma.end.y - alto)
	canvas.draw_rect(Rect2(canto, Vector2(fantasma.size.x, alto)), WorldPalette.ANDAIME)
