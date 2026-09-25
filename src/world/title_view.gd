# src/world/title_view.gd — a fita de quem tem nome (§76).
#
# "Uma fita no slot overlay que ja existe na composicao por slots (§58). Uma cor
# por tipo de feito. Zero sprites novos de corpo." A cor vem de titles.csv.
#
# Quem mereceu e espera por vaga "para um passo a frente das outras e nao e
# nomeada": no greybox e a fita por pintar — so o contorno, e a promessa.
class_name TitleView
extends RefCounted

## Em fraccoes da caixa do corpo: uma tira a atravessar o peito.
const FITA := {"y": 0.42, "alto": 0.1, "traco": 1.0}


static func draw_on(canvas: CanvasItem, caixa: Rect2, unit_id: int, luz: Lighting) -> void:
	var nomes := SimLoop.night.names
	var titulo := nomes.title_of(unit_id)
	var tira := Rect2(
		caixa.position.x,
		caixa.position.y + caixa.size.y * FITA.y,
		caixa.size.x,
		maxf(FITA.traco, caixa.size.y * FITA.alto)
	)
	if titulo != "":
		var dados := Registry.entry(&"lore/titles", StringName(titulo)) as TitleData
		if dados != null:
			canvas.draw_rect(tira, luz.body(Color.html(dados.ribbon_color), caixa.get_center().x))
		return
	if nomes.waiting.has(unit_id):
		canvas.draw_rect(
			tira, luz.body(WorldPalette.MOEDA, caixa.get_center().x), false, FITA.traco
		)
