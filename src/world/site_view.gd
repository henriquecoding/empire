# src/world/site_view.gd — os sitios do segmento que nao sao obras (§17, §83).
#
# A camara no subsolo com a Semente Real la dentro enquanto ninguem a achar; a
# estatua meio enterrada a superficie; e a placa da bifurcacao onde cai o
# capitulo que a primeira oferta revela — "um sitio distante acende-se".
#
# Greybox (Q-079): formas simples, e os numeros sao geometria.
class_name SiteView
extends RefCounted

## Dois degraus de alto, e a Semente do dobro de uma moeda.
const NICHO := 2.0
## O nome do capitulo, por cima da placa, quando a oferta o revela (§83, 18:00).
const LETRA := 12


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting) -> void:
	var s := SimLoop.secrets
	var chao := WorldPalette.ground_of(int(faixa))
	for k in s.count():
		if s.bands[k] != int(faixa):
			continue
		var alto := WorldPalette.DEGRAU * NICHO
		var nicho := Rect2(
			s.xs[k] - s.widths[k] * WorldPalette.MEIA, chao - alto, s.widths[k], alto
		)
		canvas.draw_rect(nicho, luz.body(WorldPalette.VAZIO, s.xs[k]))
		if s.seeds[k] > 0 and not String(s.ids[k]) in SimLoop.state.found:
			var semente := Vector2(s.xs[k], chao - WorldPalette.DEGRAU)
			canvas.draw_circle(semente, WorldPalette.MOEDA_R * NICHO, WorldPalette.SEMENTE)
	if faixa == Band.Kind.SURFACE:
		for x in s.chapters:
			_placa(canvas, x, chao, luz)


static func _placa(canvas: CanvasItem, x: float, chao: float, luz: Lighting) -> void:
	var cor := luz.body(WorldPalette.OBRA, x)
	var topo := Vector2(x, chao - WorldPalette.DEGRAU * NICHO)
	var braco := Vector2(WorldPalette.DEGRAU * WorldPalette.MEIA, 0.0)
	canvas.draw_line(Vector2(x, chao), topo, cor, WorldPalette.CONTORNO)
	canvas.draw_line(topo, topo + braco, cor, WorldPalette.CONTORNO)
	var desce := Vector2(0.0, WorldPalette.RASTO)
	canvas.draw_line(topo, topo - braco + desce, cor, WorldPalette.CONTORNO)
	if SimLoop.night.voice.reveals > 0:
		canvas.draw_circle(topo, WorldPalette.MOEDA_R * NICHO, WorldPalette.MOEDA)
		var onde := topo - Vector2(braco.x, WorldPalette.DEGRAU)
		var fonte := ThemeDB.fallback_font
		canvas.draw_string(fonte, onde, chapter_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, cor)


## O capitulo que cai na bifurcacao de casa (XIII-07): o da regiao do povo do
## segmento de partida. Vazio enquanto a campanha nao tiver plano.
static func chapter_name() -> String:
	var casa := SimFactory.biome_of_segment(Greybox.SEGMENTO)
	var id := SimLoop.state.chapters.in_region(casa)
	if id == &"":
		return ""
	var dados := Registry.entry(SimFactory.TABELA_CAPITULOS, id) as ChapterData
	return TranslationServer.translate(dados.display_key)
