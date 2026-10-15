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
## Sem mudar de x durante isto, o Zelador parou (quatro ticks da simulacao).
const PARADO_S := 0.15

## O ultimo x do Zelador e quando mudou; quando levou a desta noite (ADR 0083).
static var _visto_x := NAN
static var _mudou := -INF
static var _levou := INF


static func draw_on(canvas: CanvasItem, luz: Lighting, tempo: float = 0.0) -> void:
	var voz := SimLoop.night.voice
	if voz.tender.active:
		_zelador(canvas, voz.tender, luz, tempo)
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


static func _zelador(canvas: CanvasItem, zelador: Tender, luz: Lighting, tempo: float) -> void:
	var x := zelador.x
	var forma := Silhouette.Form.ZELADOR
	if AnimatedBeasts.handles(forma):  # o Zelador animado do dono (ADR 0083)
		var perfil := AnimatedBeasts.id_of(forma)
		var quadro := tender_frame(perfil, zelador, tempo)
		var lado := signf(SimLoop.core_x - x)
		var pe := Vector2(x, WorldPalette.ground_of(int(Band.Kind.SURFACE)))
		var pose := AnimatedBeasts.pose(forma, pe, lado if lado != 0.0 else 1.0, Vector2.ONE)
		AnimatedArt.lit(canvas, perfil, quadro, pose, luz, x)
		AnimatedArt.glow(canvas, perfil, quadro, pose, Color.WHITE)
		return
	var caixa := Bestiary.box(forma, x, int(Band.Kind.SURFACE))
	var tons := Bestiary.tones(forma, func(c: Color) -> Color: return luz.body(c, x))
	var roxo := WorldLight.stops(SimFactory.rot_profile())
	var olhos := PackedColorArray([roxo[1], roxo[2]])
	var frente := signf(SimLoop.core_x - x)  # olha para o teu nucleo (§75)
	Bestiary.draw(canvas, forma, caixa, tons, olhos, tempo, frente, 0.0, 0.0)


## O quadro do Zelador: anda para o teu nucleo, para num muro, e quando leva a tropa da
## noite cuida dela (tend) uma vez.
static func tender_frame(perfil: StringName, zelador: Tender, tempo: float) -> int:
	if not is_equal_approx(zelador.x, _visto_x):
		_visto_x = zelador.x
		_mudou = tempo
	if not zelador.took:
		_levou = INF
	elif _levou == INF:
		_levou = tempo
	var cuida := tempo - _levou
	if cuida >= 0.0 and cuida < AnimatedArt.seconds(perfil, &"tend"):
		return AnimatedArt.frame(perfil, &"tend", cuida)
	var anda := tempo - _mudou <= PARADO_S
	return AnimatedArt.frame(perfil, &"walk" if anda else &"idle", tempo)
