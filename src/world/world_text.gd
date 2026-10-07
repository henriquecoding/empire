# src/world/world_text.gd — as letras escritas no mundo, legiveis no telemovel (UX-06).
#
# Um nome no chao ("Provisoes", o alcance de uma torre) mede-se em px do mundo, e o
# mundo desce a meio ponto por px num telemovel deitado: 13 px liam-se a 7 pontos. As
# letras crescem como a interface cresce, so ate ao MAX, para nao taparem o que nomeiam.
class_name WorldText
extends RefCounted

const MAX := 1.6
const MIN_POINTS := 0.01


## O tamanho de letra para `base` px de mundo no ecra onde `canvas` se desenha.
static func px(canvas: CanvasItem, base: int) -> int:
	if canvas == null or not canvas.is_inside_tree():
		return base
	var pixels := canvas.get_viewport().get_final_transform().get_scale().x
	return roundi(base * grow(pixels, DisplayServer.screen_get_scale()))


## Quanto a letra cresce com `pixels` de janela por px de mundo e `density` px por ponto.
static func grow(pixels: float, density: float) -> float:
	var points := maxf(MIN_POINTS, pixels / maxf(1.0, density))
	return clampf(1.0 / points, 1.0, MAX)
