# src/world/offer_view.gd — a Oferta que se ve: o prato e a frase (§75).
#
# "Nao numa caixa. Junto a mancha, na tipografia entalhada da §24." A frase fica
# enquanto o prato estiver no chao, e o prato e um alguidar de barro do tamanho
# de um sitio de obra, a borda da mancha. O preco pousa em cima dele pelo gesto
# do PriceTag: so quando o rei o alcanca, porque so ai a moeda cai nele.
#
# Greybox (Q-079): as proporcoes sao geometria. A tipografia entalhada e a do
# HUD do §24 quando a arte a trouxer; ate la, a letra de sistema com orla.
class_name OfferView
extends RefCounted

## O alguidar: fundo mais estreito do que a boca, e baixo.
const FUNDO := 0.7
const ALTO := 0.5
## A frase: tamanho da letra e quanto acima do horizonte assenta.
const LETRA := 18
const ORLA := 4
const ACIMA := 12.0


static func draw_on(canvas: CanvasItem, luz: Lighting) -> void:
	var ofertas := SimLoop.night.offers
	if not ofertas.active():
		return
	var chao := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var boca := ofertas.dish_width * WorldPalette.MEIA
	var fundo := boca * FUNDO
	var alto := WorldPalette.DEGRAU * ALTO
	var x := ofertas.dish_x
	var alguidar := PackedVector2Array(
		[
			Vector2(x - boca, chao - alto),
			Vector2(x + boca, chao - alto),
			Vector2(x + fundo, chao),
			Vector2(x - fundo, chao),
		]
	)
	canvas.draw_colored_polygon(alguidar, luz.body(WorldPalette.BARRO, x))
	_frase(canvas, ofertas.offer())
	_preco(canvas, ofertas, chao - alto)


static func _frase(canvas: CanvasItem, o: OfferData) -> void:
	if o == null:
		return
	var fonte := ThemeDB.fallback_font
	var texto := TranslationServer.translate(o.display_key)
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x
	var onde := Vector2(
		SimLoop.night.rot.position_x() - largura * WorldPalette.MEIA, Band.HORIZON - ACIMA
	)
	canvas.draw_string_outline(
		fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, ORLA, WorldPalette.SILHUETA
	)
	canvas.draw_string(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, WorldPalette.MOEDA)


static func _preco(canvas: CanvasItem, ofertas: OfferSystem, topo: float) -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	if rei == UnitSystem.NENHUM or int(SimLoop.units.bands[rei]) != int(Band.Kind.SURFACE):
		return
	if absf(SimLoop.units.xs[rei] - ofertas.dish_x) > ofertas.dish_width * WorldPalette.MEIA:
		return
	var falta := ofertas.needed() - ofertas.paid
	PriceTag.stack(canvas, ofertas.dish_x, topo, falta, SimLoop.units.carried_coins[rei])
