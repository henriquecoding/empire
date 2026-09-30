# src/world/wild_ground.gd — o chao das terras geradas (o pedido do dono de 30/09/2026:
# "os personagens nao devem caminhar sobre nada"; "entre as regioes devem haver
# caminhos e trilhas para fazerem transicoes suaves"; ADR 0038).
#
# A regiao tinha chao e as terras bravias nao: o rei andava sobre o campo liso, com um
# vazio preto por baixo. Agora cada segmento gerado tem campo, caminho e terra nas cores
# do bioma, com o subsolo por baixo (WildTunnel). Nada da saltos de um segmento para o
# seguinte: ao longo de um trilho as cores passam em gradiente do povo de onde se vem
# para o povo para onde se vai, como o Minecraft mistura os biomas numa fronteira, e a
# estrada da regiao (e a da terra de cada povo) estreita-se em trilho ao sair e
# alarga-se ao chegar ao limiar seguinte (WorldPlan.mix_ends e trail_ends).
#
# Cenario: desenha o que o WildSegments guardou, e nao entra na simulacao.
class_name WildGround
extends RefCounted

## Por bioma: campo, caminho, terra, rocha. A floresta e a do EnramadosLayer.
const PALETA := {
	&"ancient_forest": ["6e7546", "b09a68", "483b2a", "65543a"],
	&"coast": ["7f8a5c", "cdb988", "5a4832", "7d6f58"],
	&"canyon": ["8d7348", "c69c66", "6b4329", "8b5b3b"],
	&"floodplain": ["7b8b4b", "b9a270", "4f412c", "6b5b41"],
	&"volcanic": ["54503f", "8c7c67", "2f2b27", "4c423b"],
	&"subterranean": ["5b5747", "9b8b6b", "3b3327", "56493b"],
	&"glacier": ["98a3a1", "d4cfc2", "5f6567", "8a9295"],
	&"marsh": ["5f6b45", "8f8761", "3f3b29", "57513b"],
}
const BIOMA_DE_CASA := &"ancient_forest"
const CAMPO := 0
const CAMINHO := 1
const TERRA := 2
const ROCHA := 3
const TOPO_CAMPO := 421.0
const TOPO_ESTRADA := 490.0
## O trilho e mais estreito do que a estrada da regiao: 18 px de chao batido e nao 27.
const TOPO_TRILHO := 499.0
## A erva so come as margens onde o caminho ja e mais trilho do que estrada.
const ESTREITO := 0.5
const CELULA := 64.0
const DETALHE := 4.0
const MEIO := 0.5


## As quatro cores da mistura `t` entre o bioma de onde se vem e o para onde se vai.
static func colors(registo: Dictionary, t: float) -> Array[Color]:
	var de: Array = PALETA.get(registo.get(WildSegments.DE, &""), PALETA[BIOMA_DE_CASA])
	var para: Array = PALETA.get(registo.get(WildSegments.PARA, &""), PALETA[BIOMA_DE_CASA])
	var saida: Array[Color] = []
	for i in de.size():
		saida.append(Color(de[i]).lerp(Color(para[i]), t))
	return saida


## As duas pontas de um segmento, da esquerda para a direita: a mistura (x, y) e quao
## estreito e o caminho (z, w). A leste a ponta de dentro e a esquerda; a oeste, a direita.
static func ends(terras: WildSegments, lado: int, k: int) -> Vector4:
	var m := terras.plan.mix_ends(lado, k)
	var t := terras.plan.trail_ends(lado, k)
	if lado == WorldPlan.LESTE:
		return Vector4(m.x, m.y, t.x, t.y)
	return Vector4(m.y, m.x, t.y, t.x)


## O chao de todos os segmentos gerados, com o assunto de cada um por cima.
static func draw_ground(canvas: CanvasItem, terras: WildSegments, largura: float) -> void:
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var registo := terras.at(lado, k)
			var x0 := terras.x_of(lado, k, largura)
			var p := ends(terras, lado, k)
			var topo := Vector2(
				lerpf(TOPO_ESTRADA, TOPO_TRILHO, p.z), lerpf(TOPO_ESTRADA, TOPO_TRILHO, p.w)
			)
			var span := ground_span(registo, lado, x0, terras.width)
			_chao(canvas, span, colors(registo, p.x), colors(registo, p.y), topo)
			var x := terras.subject_x(lado, k, largura)
			var aqui := colors(registo, lerpf(p.x, p.y, (x - x0) / terras.width))
			var tinta := WildLands.paint(aqui, registo)
			match int(registo[WildSegments.ZONA]):
				WorldPlan.Zone.EDGE:
					WildEdge.draw(canvas, registo, lado, x0, terras.width, tinta)
				WorldPlan.Zone.TRAIL:
					WildSubjects.draw(canvas, registo, x, x0, terras.width)
				_:
					WildLands.draw(canvas, registo, x, tinta, lado)


## O subsolo de todos os segmentos: a terra, o tunel e as camaras das masmorras.
static func draw_underground(canvas: CanvasItem, terras: WildSegments, largura: float) -> void:
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var registo := terras.at(lado, k)
			var x0 := terras.x_of(lado, k, largura)
			var p := ends(terras, lado, k)
			var boca := NAN
			if int(registo.get(WildSegments.PASSAGEM, 0)) > 0:
				boca = terras.subject_x(lado, k, largura)
			var span := ground_span(registo, lado, x0, terras.width)
			var semente := int(registo[WildSegments.SEMENTE])
			WildTunnel.draw(canvas, span, colors(registo, p.x), colors(registo, p.y), semente, boca)


## As plantas do campo das terras geradas: as tabelas do bioma de onde se vem e do bioma
## para onde se vai, e cada planta fica de um ou do outro pela mistura no sitio dela.
static func plants(terras: WildSegments, largura: float, regiao: int) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	var ruido := Wilds.woods()
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var r := terras.at(lado, k)
			var span := ground_span(r, lado, terras.x_of(lado, k, largura), terras.width)
			var p := ends(terras, lado, k)
			for ponta in [WildSegments.DE, WildSegments.PARA]:
				var camadas := Wilds.table(Wilds.CAMPO, StringName(r.get(ponta, &"")))
				var todas := Wilds.plants(camadas, span.x, span.y, regiao, Wilds.SAL.campo, ruido)
				var mistura := Vector2(p.x, p.y)
				saida.append_array(half(todas, span, mistura, ponta == WildSegments.PARA))
	return saida


## Uma faixa de chao de `span.x` a `span.y`, com o topo a ir de `topo.x` a `topo.y` e a
## cor de `c0` a `c1`: e assim que nada da saltos de um segmento para o outro.
static func band(
	canvas: CanvasItem, span: Vector2, topo: Vector2, fundo: float, c0: Color, c1: Color
) -> void:
	var pontos := PackedVector2Array(
		[
			Vector2(span.x, topo.x),
			Vector2(span.y, topo.y),
			Vector2(span.y, fundo),
			Vector2(span.x, fundo),
		]
	)
	canvas.draw_polygon(pontos, PackedColorArray([c0, c1, c1, c0]))


## Um traco horizontal cortado ao que ha de chao, para nada sair da beira.
static func dash(
	canvas: CanvasItem, x: float, y: float, w: float, span: Vector2, cor: Color
) -> void:
	var a := maxf(x, span.x)
	var b := minf(x + w, span.y)
	if b > a:
		canvas.draw_rect(Rect2(a, y, b - a, DETALHE), cor)


## As plantas de um dos dois biomas: a variante de cada planta (0..1) contra a mistura no
## x onde ela nasce decide de qual e.
static func half(
	plantas: PackedFloat32Array, span: Vector2, mistura: Vector2, destino: bool
) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for i in range(0, plantas.size(), Wilds.PLANTA):
		var aqui := lerpf(mistura.x, mistura.y, inverse_lerp(span.x, span.y, plantas[i + 1]))
		if (plantas[i + Wilds.PLANTA - 1] < aqui) == destino:
			saida.append_array(plantas.slice(i, i + Wilds.PLANTA))
	return saida


## De onde a onde ha chao num segmento: todo, menos na borda, onde acaba na beira.
static func ground_span(registo: Dictionary, lado: int, x0: float, w: float) -> Vector2:
	if int(registo[WildSegments.ZONA]) != WorldPlan.Zone.EDGE:
		return Vector2(x0, x0 + w)
	if lado == WorldPlan.LESTE:
		return Vector2(x0, x0 + WildSegments.BORDO_PX)
	return Vector2(x0 + w - WildSegments.BORDO_PX, x0 + w)


static func _chao(
	canvas: CanvasItem, span: Vector2, esq: Array[Color], dir: Array[Color], topo: Vector2
) -> void:
	var linha := float(Band.GROUND_LINE)
	band(canvas, span, Vector2(TOPO_CAMPO, TOPO_CAMPO), linha, esq[CAMPO], dir[CAMPO])
	band(canvas, span, topo, linha, esq[CAMINHO], dir[CAMINHO])
	var estreito := lerpf(TOPO_ESTRADA, TOPO_TRILHO, ESTREITO)
	var metade := CELULA * MEIO
	var x := floorf(span.x / CELULA) * CELULA
	while x < span.y:
		var f := clampf(inverse_lerp(span.x, span.y, x), 0.0, 1.0)
		var y := lerpf(topo.x, topo.y, f)
		# Pedras e sulcos no caminho, e erva a comer as margens de um trilho.
		dash(canvas, x, y + DETALHE, metade, span, esq[ROCHA].lerp(dir[ROCHA], f))
		dash(canvas, x + metade, linha - DETALHE, metade, span, esq[TERRA].lerp(dir[TERRA], f))
		if y > estreito:
			dash(canvas, x + DETALHE, y, metade - DETALHE, span, esq[CAMPO].lerp(dir[CAMPO], f))
		x += CELULA
	var fundo := float(Band.SCREEN_BOTTOM)
	band(canvas, span, Vector2(linha, linha), fundo, esq[TERRA], dir[TERRA])
