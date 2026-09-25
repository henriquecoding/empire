# src/world/name_view.gd — quem tem nome, e quem espera por um (§76).
#
# "Uma fita no slot overlay que ja existe. Uma cor por tipo de feito. Zero
# sprites novos de corpo." A fita e da cor do titulo (titles.csv). Quem cumpriu
# um feito e nao coube nos nove da um passo a frente — aqui, uma seta por cima,
# que e a promessa por pagar que o jogador atento ve.
#
# Greybox (Q-079): a fita definitiva e a do ART-04.
class_name NameView
extends RefCounted

## A fita, em fraccao da caixa: larga como meia caixa, fina como um traco.
const FITA_LARGURA := 0.5
const FITA_ALTURA := 3.0
const SETA := 4.0


static func draw_on(canvas: CanvasItem, caixa: Rect2, unit_id: int) -> void:
	var nomes := SimLoop.night.names
	var titulo := nomes.title_of(unit_id)
	if titulo != &"":
		var dados := Registry.entry(&"lore/titles", titulo) as TitleData
		var largo := caixa.size.x * FITA_LARGURA
		var fita := Rect2(
			caixa.get_center().x - largo * WorldPalette.MEIA, caixa.position.y, largo, FITA_ALTURA
		)
		canvas.draw_rect(fita, Color.from_string(dados.ribbon_color, WorldPalette.MOEDA))
		return
	if unit_id in nomes.waiting:
		var topo := Vector2(caixa.get_center().x, caixa.position.y - SETA * FITA_ALTURA)
		var seta := PackedVector2Array(
			[topo, topo + Vector2(-SETA, SETA), topo + Vector2(SETA, SETA)]
		)
		canvas.draw_colored_polygon(seta, WorldPalette.MOEDA)
