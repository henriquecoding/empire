# tools/captura_mancha.gd — onde esta a mancha no ecra, para a ficha da fotografia.
#
# Fora do jogo, como o resto do tools/captura*. O `check_silhueta.py` do §80 so deixa
# violeta onde a Podridao esta, e por isso a ficha tem de dizer onde ela esta.
extends RefCounted


## Onde a mancha e o rasto dela estao NO ECRA, em rectangulos. A camara so anda
## em x, mas quem converte e a transformacao do canvas: repetir a conta aqui era
## ter dois sitios a decidir onde uma coisa aparece.
static func on_screen(vista: Viewport) -> Array:
	var rot := SimLoop.night.rot if SimLoop.state != null else null
	if rot == null or not rot.active():
		return []
	var t := vista.get_canvas_transform()
	var largura := maxf(rot.state.width, WorldPalette.DEGRAU)
	var meia := largura * WorldPalette.MEIA
	var chao := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var massa := Rect2(rot.position_x() - meia, float(Band.HORIZON), largura, chao - Band.HORIZON)
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	var ate := maxf(rot.state.trail_from, rot.state.trail_to)
	var rasto := Rect2(de, chao - WorldPalette.RASTO, ate - de, WorldPalette.RASTO)
	return [_no_ecra(t, massa), _no_ecra(t, rasto)]


static func _no_ecra(t: Transform2D, caixa: Rect2) -> Array:
	var canto := t * caixa.position
	var fim := t * caixa.end
	return [canto.x, canto.y, fim.x - canto.x, fim.y - canto.y]
