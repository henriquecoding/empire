# src/world/offer_view.gd — a voz da Podridao, vista (§75).
#
# "Nao numa caixa. Junto a mancha, na tipografia entalhada da §24, como as placas
# de loja. Uma frase. Nunca mais do que oito palavras." E um prato de barro no
# chao, a borda dela, do tamanho de um slot de construcao — um alvo, nao um menu.
#
# E o Zelador: uma figura alta e fina que anda atras da mancha, nao ataca, e olha
# para o teu nucleo. Desenha-o o bestiario (ADR 0049), como a criatura `tender`;
# a arte final e do ART-04.
#
# A frase sai por chave de data/i18n/strings.csv e nunca como texto escrito aqui.
# Nao ha contador nenhum: nem o tempo que falta, nem a Divida (§75).
class_name OfferView
extends RefCounted

## O barro do alguidar, e a fala: o ambar da candeia, que e a voz dela.
const BARRO := Color(0.55, 0.33, 0.20)
const FALA := Color(0.96, 0.85, 0.61)

## Em fraccoes da caixa de uma tropa (ActorArt.ESCALA.caixa).
const PRATO := {"alto": 0.18, "fundo": 0.7}
const LETRA := {"tamanho": 16, "acima": 0.62}


static func draw_on(canvas: CanvasItem, luz: Lighting, tempo: float = 0.0) -> void:
	var voz := SimLoop.night.voice
	if voz.tender.active:
		_zelador(canvas, voz.tender.x, luz, tempo)
	if voz.offers.phase != OfferSystem.Phase.OPEN:
		return
	var oferta := voz.offers.offer()
	if oferta == null:
		return
	_prato(canvas, voz.offers.plate_x, voz.offers.band, luz)
	_frase(canvas, SimLoop.night.rot.position_x(), oferta.display_key)


static func _prato(canvas: CanvasItem, x: float, faixa: int, luz: Lighting) -> void:
	var largo := SimFactory.rot_profile().offer_plate_px
	var unidade: float = ActorArt.ESCALA.caixa
	var alto: float = unidade * PRATO.alto
	var chao := WorldPalette.ground_of(faixa)
	var borda := Rect2(x - largo * WorldPalette.MEIA, chao - alto, largo, alto)
	canvas.draw_rect(borda, luz.body(BARRO, x))
	var fundo: float = largo * PRATO.fundo
	var dentro := Rect2(x - fundo * WorldPalette.MEIA, chao - alto, fundo, alto * WorldPalette.MEIA)
	canvas.draw_rect(dentro, luz.body(BARRO.darkened(WorldPalette.MEIA), x))


## Por cima da mancha, e nao numa caixa. A candeia e a luz dela, e a frase e a
## voz: nao leva ambiente, como a candeia nao leva.
static func _frase(canvas: CanvasItem, x: float, chave: String) -> void:
	var fonte := ThemeDB.fallback_font
	var texto := TranslationServer.translate(chave)
	var tamanho: int = LETRA.tamanho
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var y := float(Band.HORIZON) + float(Band.GROUND_LINE - Band.HORIZON) * (1.0 - LETRA.acima)
	var onde := Vector2(x - largura * WorldPalette.MEIA, y)
	canvas.draw_string(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, FALA)


static func _zelador(canvas: CanvasItem, x: float, luz: Lighting, tempo: float) -> void:
	var forma := Silhouette.Form.ZELADOR
	var caixa := Bestiary.box(forma, x, int(Band.Kind.SURFACE))
	var tons := Bestiary.tones(forma, func(c: Color) -> Color: return luz.body(c, x))
	var roxo := WorldLight.stops(SimFactory.rot_profile())
	var olhos := PackedColorArray([roxo[1], roxo[2]])
	var frente := signf(SimLoop.core_x - x)  # olha para o teu nucleo (§75)
	Bestiary.draw(canvas, forma, caixa, tons, olhos, tempo, frente, 0.0, 0.0)
