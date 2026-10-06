# src/ui/touch_art.gd — os controlos de toque, desenhados (ADR 0047).
#
# Nao ha arte para isto (art/ nao se toca daqui, regra 9), e por isso sao formas lisas
# com as cores do painel do greybox: papel escuro meio transparente, o ouro da moeda, e
# o icone de cada gesto em tracos. O mundo continua a ver-se por baixo — o HUD do §24 e
# o mundo a dizer as coisas, e os botoes nao o tapam mais do que precisam.
#
# Os icones sao dados: formas em unidades de meia largura, que o _forma() desenha. Um
# icone novo e uma linha da tabela, como as silhuetas do greybox (ShapeArt).
class_name TouchArt
extends RefCounted

const PAPEL := Color(0.12, 0.10, 0.10, 0.80)
const PAPEL_PREMIDO := Color(0.20, 0.16, 0.13, 0.78)
const TINTA := Color(0.08, 0.07, 0.06, 0.9)
const TRACO := 1.5
const ICONE := 4.0
const MEIO := 0.5
## Fraccoes do raio: o icone, onde ele e o rotulo ficam, o botao premido, e a largura
## que o rotulo pode ter antes de encolher a letra.
const MEDIDA := {"icone": 0.26, "alto": 0.2, "rotulo": 0.42, "premido": 0.94, "texto": 1.72}
## §26: nenhum caracter abaixo de 12 px a 1280x720.
const LETRA := {"corpo": 13, "min": 12, "contorno": 4}
## Um botao que hoje nao faz nada apaga-se; o INTERAGIR ganha um aro quando ha um alvo.
const APAGADO := 0.35
## O botao premido enche-se da cor do aro: o polegar tapa-o, e a borda e o que se ve.
const PREMIDO := 0.3
const ALAVANCA := {"seta": 0.78, "ponta": 0.14, "polegar": 0.42, "repouso": 0.7, "aro": 0.8}
const ROSCA := {"raio": 1.25, "bolha": 17.0, "letra": 14, "aro": 2.0}
const SEGMENTOS := 48
const LADOS := [-1.0, 1.0]

## Cada icone: linhas ["l", de, ate, espessura], poligonos ["p", pontos], circulos
## cheios ["c", centro, raio] e aros a tinta ["a", centro, raio].
const ICONES := {
	&"moeda": [["c", Vector2.ZERO, 1.0], ["a", Vector2.ZERO, 0.6]],
	&"pino":
	[
		["c", Vector2(0, -0.5), 0.45],
		["l", Vector2(-0.6, -0.05), Vector2(0.6, -0.05), 1.0],
		["l", Vector2(0, 0), Vector2(0, 1), 0.6],
	],
	&"corre":
	[
		["l", Vector2(-0.9, -0.7), Vector2(-0.2, 0), 0.8],
		["l", Vector2(-0.2, 0), Vector2(-0.9, 0.7), 0.8],
		["l", Vector2(0.1, -0.7), Vector2(0.8, 0), 0.8],
		["l", Vector2(0.8, 0), Vector2(0.1, 0.7), 0.8],
	],
	&"espada":
	[["l", Vector2(-1, 1), Vector2(1, -1), 1.0], ["l", Vector2(-0.8, 0), Vector2(0, 0.8), 1.0]],
	&"flecha":
	[
		["l", Vector2(-1, 1), Vector2(0.6, -0.6), 0.6],
		["p", [Vector2(1, -1), Vector2(0.86, -0.29), Vector2(0.29, -0.86)]],
	],
	&"alaude":
	[["c", Vector2(-0.35, 0.35), 0.55], ["l", Vector2(-0.35, 0.35), Vector2(1, -1), 0.6]],
	&"canto":
	[
		["c", Vector2(-0.3, 0.6), 0.35],
		["l", Vector2(0.05, 0.6), Vector2(0.05, -0.9), 0.6],
		["l", Vector2(0.05, -0.9), Vector2(0.6, -0.5), 0.6],
	],
	&"mira":
	[
		["a", Vector2.ZERO, 0.75],
		["l", Vector2(-1, 0), Vector2(1, 0), 0.5],
		["l", Vector2(0, -1), Vector2(0, 1), 0.5],
	],
	&"vigilia":
	[
		[
			"p",
			[
				Vector2(0, -1),
				Vector2(0.25, -0.25),
				Vector2(1, 0),
				Vector2(0.25, 0.25),
				Vector2(0, 1),
				Vector2(-0.25, 0.25),
				Vector2(-1, 0),
				Vector2(-0.25, -0.25),
			]
		]
	],
	&"passar":
	[
		["p", [Vector2(-1, -0.1), Vector2(-0.35, -1), Vector2(0.3, -0.1)]],
		["p", [Vector2(-0.3, 0.1), Vector2(0.35, 1), Vector2(1, 0.1)]],
	],
	&"coroa":
	[
		[
			"p",
			[
				Vector2(-1, 0.6),
				Vector2(-1, -0.5),
				Vector2(-0.5, 0),
				Vector2(0, -0.8),
				Vector2(0.5, 0),
				Vector2(1, -0.5),
				Vector2(1, 0.6),
			]
		]
	],
	&"pausa":
	[
		["p", [Vector2(-0.6, -0.7), Vector2(-0.2, -0.7), Vector2(-0.2, 0.7), Vector2(-0.6, 0.7)]],
		["p", [Vector2(0.2, -0.7), Vector2(0.6, -0.7), Vector2(0.6, 0.7), Vector2(0.2, 0.7)]],
	],
}


## Um botao redondo: o fundo, o aro, o icone, o rotulo e, se o houver, o anel de recarga.
static func button(ci: CanvasItem, c: Vector2, r: float, estado: Dictionary) -> void:
	var premido: bool = estado.get(&"premido", false)
	var alfa := APAGADO if estado.get(&"apagado", false) else 1.0
	var cor: Color = estado.get(&"cor", GameHud.TEXT)
	var raio := r * (MEDIDA.premido if premido else 1.0)
	ci.draw_circle(c, raio, _alfa(PAPEL_PREMIDO if premido else PAPEL, alfa))
	if premido:
		ci.draw_circle(c, raio, _alfa(cor, PREMIDO * alfa))
	ci.draw_arc(c, raio, 0.0, TAU, SEGMENTOS, _alfa(cor, alfa), TRACO, true)
	if estado.get(&"brilho", false):
		ci.draw_arc(c, raio + 4, 0.0, TAU, SEGMENTOS, GameHud.MINT, 2.0)
	var pronto: float = estado.get(&"pronto", 1.0)
	if pronto < 1.0:
		var de := -PI * MEIO
		var arco := _alfa(GameHud.GOLD, alfa)
		ci.draw_arc(c, raio - TRACO, de, de + TAU * pronto, SEGMENTOS, arco, TRACO)
	var icone_em := c - Vector2(0.0, raio * MEDIDA.alto)
	icon(ci, estado.get(&"icone", &""), icone_em, raio * MEDIDA.icone, _alfa(cor, alfa))
	label(ci, estado.get(&"rotulo", ""), c + Vector2(0.0, raio * MEDIDA.rotulo), raio, alfa)


## O rotulo, centrado e com contorno: le-se em cima do ceu e do chao.
static func label(ci: CanvasItem, texto: String, em: Vector2, raio: float, alfa: float) -> void:
	if texto.is_empty():
		return
	var letra := HudStyle.font()
	var factor := ci.get_viewport().get_final_transform().get_scale().x
	var corpo := roundi(LETRA.corpo * HudLayout.scale_for(factor))
	var minimum := roundi(LETRA.min * HudLayout.scale_for(factor))
	while corpo > minimum and letra.get_string_size(texto, 0, -1, corpo).x > raio * MEDIDA.texto:
		corpo -= 1
	var largura := raio * 2
	var onde := em + Vector2(-raio, letra.get_ascent(corpo) * MEIO)
	var centro := HORIZONTAL_ALIGNMENT_CENTER
	var contorno := _alfa(TINTA, alfa)
	ci.draw_string_outline(letra, onde, texto, centro, largura, corpo, LETRA.contorno, contorno)
	ci.draw_string(letra, onde, texto, centro, largura, corpo, _alfa(GameHud.TEXT, alfa))


## Um icone da tabela, centrado em `c`, com `s` de meia largura.
static func icon(ci: CanvasItem, qual: StringName, c: Vector2, s: float, cor: Color) -> void:
	for forma: Array in ICONES.get(qual, []):
		_forma(ci, forma, c, s, cor)


static func _forma(ci: CanvasItem, f: Array, c: Vector2, s: float, cor: Color) -> void:
	match f[0]:
		"l":
			ci.draw_line(c + f[1] * s, c + f[2] * s, cor, ICONE * f.back())
		"p":
			var pontos := PackedVector2Array()
			for p: Vector2 in f[1]:
				pontos.append(c + p * s)
			ci.draw_colored_polygon(pontos, cor)
		"c":
			ci.draw_circle(c + f[1] * s, f[2] * s, cor)
		"a":
			ci.draw_arc(c + f[1] * s, f[2] * s, 0.0, TAU, SEGMENTOS, TINTA, TRACO * MEIO, true)


## A alavanca: o aro, as duas setas que dizem que so anda para os lados, e o polegar.
## Em repouso mal se ve — ensina onde pousar o polegar; a corrida acende o aro de ouro.
static func stick(ci: CanvasItem, base: Vector2, raio: float, desvio: float, corre: bool) -> void:
	var alfa := ALAVANCA.repouso if is_zero_approx(desvio) and not corre else 1.0
	ci.draw_circle(base, raio, _alfa(PAPEL, alfa))
	var aro := GameHud.GOLD if corre else GameHud.TEXT
	ci.draw_arc(base, raio, 0.0, TAU, SEGMENTOS, _alfa(aro, alfa * ALAVANCA.aro), TRACO, true)
	for lado: float in LADOS:
		var ponta := base + Vector2(lado * raio * ALAVANCA.seta, 0.0)
		ci.draw_colored_polygon(_seta(ponta, lado, raio * ALAVANCA.ponta), _alfa(aro, alfa))
	var polegar := base + Vector2(clampf(desvio, -raio, raio), 0.0)
	ci.draw_circle(polegar, raio * ALAVANCA.polegar, _alfa(PAPEL_PREMIDO, alfa))
	ci.draw_arc(polegar, raio * ALAVANCA.polegar, 0.0, TAU, SEGMENTOS, _alfa(aro, alfa), TRACO)


## A roda do rei ao toque (§24): os segmentos a volta do dedo, de cima e no sentido do
## relogio como o InputRouter.wheel_segment os conta, e o apontado em ouro.
static func wheel(ci: CanvasItem, c: Vector2, alcance: float, n: int, apontado: int) -> void:
	var raio := alcance * ROSCA.raio
	var letra := ThemeDB.fallback_font
	var centro := HORIZONTAL_ALIGNMENT_CENTER
	ci.draw_arc(c, raio, 0.0, TAU, SEGMENTOS, _alfa(GameHud.TEXT, APAGADO), TRACO, true)
	for i in n:
		var angulo := TAU * i / n
		var em := c + Vector2(sin(angulo), -cos(angulo)) * raio
		ci.draw_circle(em, ROSCA.bolha, GameHud.GOLD if i == apontado else GameHud.PAPER)
		ci.draw_arc(em, ROSCA.bolha, 0.0, TAU, SEGMENTOS, GameHud.TEXT, ROSCA.aro, true)
		var onde := em + Vector2(-ROSCA.bolha, letra.get_ascent(ROSCA.letra) * MEIO)
		var tinta := TINTA if i == apontado else GameHud.TEXT
		ci.draw_string(letra, onde, str(i + 1), centro, ROSCA.bolha * 2, ROSCA.letra, tinta)


static func _alfa(cor: Color, alfa: float) -> Color:
	return Color(cor.r, cor.g, cor.b, cor.a * alfa)


## Um triangulo a apontar para `lado` (-1 ou 1), com a ponta em `c`.
static func _seta(c: Vector2, lado: float, s: float) -> PackedVector2Array:
	var costas := c - Vector2(lado * s * 2, 0.0)
	return PackedVector2Array([c, costas + Vector2(0.0, s), costas - Vector2(0.0, s)])
