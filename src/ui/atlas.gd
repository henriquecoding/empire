# src/ui/atlas.gd — o Atlas do Imperio: as cores, o canto e as linhas da interface (ADR 0078).
#
# Uma gramatica so para a HUD, a ficha de um sitio e a pausa: o campo escuro onde se joga,
# o linho claro onde se le com calma, o latao da moeda, e tres estados com significado
# que nao muda de bioma para bioma (perigo, cumprido, informacao). A paleta e a do plano
# mestre da HUD de 07/10/2026 (§5.4); a LINHA e a TINTA_SUAVE sao derivadas aqui e
# medidas no atlas_test, como os pares do plano.
#
# Os motivos: o canto de registo (um canto recortado, o oposto em esquadria) e as linhas
# de territorio (tres tracos de comprimentos diferentes). O selo do horizonte pede desenho
# original (ART) e nao vive aqui.
class_name Atlas
extends RefCounted

## surface.field — o fundo opaco da HUD e dos controlos.
const FIELD := Color("172a2b")
## surface.raised — subareas e botoes secundarios.
const RAISED := Color("233b3c")
## text.primary e text.secondary, sobre o campo.
const TEXT := Color("f1e9d8")
const SECONDARY := Color("bdc9c3")
## accent.coin — a moeda e a accao economica, e so isso.
const COIN := Color("dab879")
## state.danger, state.valid e state.info: acompanhados sempre de texto ou forma.
const DANGER := Color("ffa28e")
const VALID := Color("a5cca5")
const INFO := Color("9cc8de")
## surface.folio e text.ink — a leitura demorada.
const FOLIO := Color("e7decb")
const INK := Color("253839")
const INK_SOFT := Color("4a5a57")
## A borda de um cartao no campo: 3,2:1, um sinal e nao texto.
const LINE := Color("5e7a74")
## O campo deixa ver o mundo por baixo, mas nunca a ponto de o texto descer de 4,5:1.
const FIELD_ALPHA := 0.95
## Quanto mede o recorte do canto de registo, e as margens da grelha de 4.
const CUT := 10
## A sombra curta do cartao: um desnivel, e nao volume.
const SHADOW := Color(0, 0, 0, 0.18)
const STEP := 4
const PADDING := 12
## As linhas de territorio: os tres comprimentos, em fraccao da largura, e o passo.
const RULE := [1.0, 0.68, 0.36]
const RULE_GAP := 3.0
const RULE_STROKE := 1.0
const RULE_HEIGHT := 2 * RULE_GAP + 3 * RULE_STROKE
## A luminancia relativa do sRGB (WCAG 2.2).
const LINEAR := 0.04045
const LOW := 12.92
const CURVE := 2.4
const OFFSET := 0.055
const FLARE := 0.05
const WEIGHTS := Vector3(0.2126, 0.7152, 0.0722)


## Um cartao com o canto de registo: o de cima a esquerda recortado em recta, os outros em
## esquadria. `fill` e o fundo e `edge` a borda; a sombra e curta, um desnivel e nao volume.
static func card(
	fill: Color = FIELD, edge: Color = LINE, alpha: float = FIELD_ALPHA
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill, alpha)
	style.border_color = edge
	style.set_border_width_all(1)
	style.corner_radius_top_left = CUT
	style.corner_detail = 1
	style.anti_aliasing = false
	style.set_content_margin_all(PADDING)
	style.shadow_color = SHADOW
	style.shadow_size = STEP - 1
	return style


## A folha de leitura: linho claro, tinta escura e o mesmo canto.
static func folio() -> StyleBoxFlat:
	return card(FOLIO, INK_SOFT, 1.0)


## As tres linhas de territorio, a comecar em `at`, com `width` de comprimento maximo.
static func rule(ci: CanvasItem, at: Vector2, width: float, color: Color) -> void:
	for i in RULE.size():
		var y := at.y + i * (RULE_GAP + RULE_STROKE)
		var fim := at.x + width * float(RULE[i])
		ci.draw_line(Vector2(at.x, y), Vector2(fim, y), color, RULE_STROKE)


## O contraste entre duas cores opacas, de 1 a 21.
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + FLARE) / (minf(la, lb) + FLARE)


static func _luminance(c: Color) -> float:
	var rgb := Vector3(_channel(c.r), _channel(c.g), _channel(c.b))
	return rgb.dot(WEIGHTS)


static func _channel(v: float) -> float:
	return v / LOW if v <= LINEAR else pow((v + OFFSET) / (1.0 + OFFSET), CURVE)
