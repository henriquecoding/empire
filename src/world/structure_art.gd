# src/world/structure_art.gd — o que cada obra E, por dentro do contorno (§25, §55).
#
# O Outline da a forma e o BuildView o estado; isto e o que enche a forma, e nao
# muda nem uma nem o outro — se mudasse, uma obra deixava de se ler pelo
# contorno, que e o que o §80 exige. As medidas sao fraccao da caixa, como no
# ActorArt: a caixa vem da altura do nivel, e escrever em pixeis era ter uma
# torre de nivel 3 com a mesma seteira de uma de nivel 1.
class_name StructureArt
extends RefCounted

const STONE := Color(0.27, 0.28, 0.30)
const STONE_LIGHT := Color(0.52, 0.49, 0.40)
const WOOD := Color(0.43, 0.25, 0.13)
const WOOD_LIGHT := Color(0.68, 0.41, 0.19)
const LEAF := Color(0.18, 0.34, 0.22)
const BARK := Color(0.25, 0.14, 0.08)
const GOLD := Color(0.92, 0.59, 0.20)
const WINDOW := Color(0.98, 0.72, 0.30)

## O tronco do castelo-arvore (§10): nunca mais fino do que `minimo`, senao uma
## obra de nivel 1 fica com um pau em vez de um tronco.
const TRONCO := {"minimo": 22.0, "largura": 0.18, "topo": 0.34, "alto": 0.66, "tinta": 0.40}
const RAIZ := {"acima": 2.0, "vao": 56.0, "abaixo": 4.0, "traco": 6.0}

## A copa: duas de lado e uma ao cume, que e a forma que o Outline ja promete.
## As janelas acesas do nucleo, e a porta por onde se entra.
const COPA := {"y": 0.28, "lado": 0.27, "raio": 0.18, "cume": 0.11, "cume_r": 0.23, "tinta": 0.42}
const VAO := {"quantos": 3, "x": 0.31, "passo": 0.19, "y": 0.40, "w": 0.07, "h": 0.10}
const PORTA := {"largo": 30.0, "alto": 38.0, "meio": 15.0, "fecho": 34.0, "traco": 3.0}
const NUCLEO_TINTA := {"vao": 0.25, "madeira": 0.35, "ouro": 0.35}

## A ponte que so aparece a partir do nivel 2: e o que se ve crescer.
const PONTE := {"nivel": 1, "recuo": 22.0, "y": 0.53, "traco": 5.0, "tinta": 0.38}

## O muro (§25): uma fiada por nivel, e nunca menos de duas — uma so nao e muro.
const MURO := {"fiadas": 2, "topo": 0.20, "vao": 0.70, "traco": 2.0}
const PEDRA_TINTA := {"pedra": 0.42, "clara": 0.38, "ouro": 0.45, "seteira": 0.35}
const PEDRA := {"colunas": 6, "vaos": 5.0, "desvio": 8.0, "acima": 0.10, "abaixo": 0.08}
const AMEIA := {"x": 4.0, "y": 5.0, "w": 8.0}

## A torre: a plataforma de onde se dispara, mais larga do que o fuste (§07).
const PLATAFORMA := {"recuo": 4.0, "y": 0.18, "folga": 8.0, "h": 0.12, "tinta": 0.38}
const DENTE := {"quantos": 5, "vaos": 4.0, "x": 3.0, "y": 8.0, "w": 6.0}
const SETEIRA := {"quantas": 3, "y": 0.38, "passo": 0.18, "x": 5.0, "w": 10.0, "h": 18.0}
const BASE := {"recuo": 4.0, "acima": 3.0, "traco": 4.0}

## A torre alta (§10) leva mastro e galhardete: e a obra que chega onde o Alado
## voa, e tem de se ver que chega.
const MASTRO := {"alto": 34.0, "traco": 3.0, "pano": 32.0, "vao": 27.0, "queda": 24.0}
const MASTRO_TINTA := {"ouro": 0.30, "traco": 4.0}

## Tudo o resto e uma casa, e o que a distingue vem do Outline: chamine,
## estandarte ou abobada.
const CASA := {"x": 0.10, "y": 0.38, "w": 0.80, "h": 0.62, "traco": 5.0}
const CASA_TINTA := {"telha": 0.40, "parede": 0.42, "porta": 0.42, "janela": 0.34}
const CASA_VAO := {"quantos": 2, "x": 0.18, "passo": 0.48, "y": 0.25, "w": 0.18, "h": 0.18}
const CASA_PORTA := {"x": 0.11, "y": 0.42, "w": 0.22}
const CHAMINE := {"x": 0.70, "w": 0.13, "h": 0.34, "tinta": 0.35}
const ESTANDARTE := {"x": 0.18, "traco": 3.0, "topo": 3.0, "vao": 0.28, "queda": 0.10}
const ESTANDARTE_TINTA := {"pau": 0.35, "pano": 0.34, "traco": 4.0}
const ABOBADA := {"raio": 0.25, "pontos": 12, "traco": 3.0, "tinta": 0.30}

## O contorno por cima de tudo: e ele que o §80 deixa ler a uma cor so.
const CONTORNO_TINTA := 0.20


static func draw_on(
	canvas: CanvasItem,
	forma: Silhouette.Form,
	caixa: Rect2,
	vaga: BuildSlot,
	cor: Color,
	dentes: int
) -> void:
	if vaga.state == BuildSlot.State.EMPTY:
		return
	match forma:
		Silhouette.Form.COPA:
			_core(canvas, caixa, cor, vaga.level)
		Silhouette.Form.AMEIA:
			_wall(canvas, caixa, cor, vaga.level)
		Silhouette.Form.TORRE, Silhouette.Form.MASTRO:
			_tower(canvas, caixa, cor, forma == Silhouette.Form.MASTRO)
		_:
			_house(canvas, caixa, cor, forma)
	var pontos := Outline.shape(forma, caixa, dentes)
	if pontos.size() < 2:
		return
	pontos.append(pontos[0])
	canvas.draw_polyline(
		pontos, _mix(WorldPalette.LINHA, cor, CONTORNO_TINTA), WorldPalette.CONTORNO
	)


static func _core(canvas: CanvasItem, box: Rect2, cor: Color, level: int) -> void:
	var meio := box.get_center().x
	var largo := box.size.x
	var alto := box.size.y
	var topo := box.position.y
	var fuste := maxf(TRONCO.minimo, largo * TRONCO.largura)
	var tronco := Rect2(
		meio - fuste * WorldPalette.MEIA, topo + alto * TRONCO.topo, fuste, alto * TRONCO.alto
	)
	var casca := _mix(BARK, cor, TRONCO.tinta)
	canvas.draw_rect(tronco, casca)
	var acima := tronco.end.y - RAIZ.acima
	var abaixo := tronco.end.y + RAIZ.abaixo
	var esq := Vector2(tronco.position.x, acima)
	var dir := Vector2(tronco.end.x, acima)
	canvas.draw_line(esq, Vector2(esq.x - RAIZ.vao, abaixo), casca, RAIZ.traco)
	canvas.draw_line(dir, Vector2(dir.x + RAIZ.vao, abaixo), casca, RAIZ.traco)
	var folha := _mix(LEAF, cor, COPA.tinta)
	var copa_y := topo + alto * COPA.y
	var lado := largo * COPA.lado
	canvas.draw_circle(Vector2(meio - lado, copa_y), largo * COPA.raio, folha)
	canvas.draw_circle(Vector2(meio + lado, copa_y), largo * COPA.raio, folha)
	var cume := Vector2(meio, topo + alto * COPA.cume)
	canvas.draw_circle(cume, largo * COPA.cume_r, folha)
	for i in VAO.quantos:
		var x := box.position.x + largo * (VAO.x + float(i) * VAO.passo)
		var vao := Rect2(x, topo + alto * VAO.y, largo * VAO.w, alto * VAO.h)
		canvas.draw_rect(vao, _mix(WINDOW, cor, NUCLEO_TINTA.vao))
	var porta := Rect2(meio - PORTA.meio, box.end.y - PORTA.alto, PORTA.largo, PORTA.alto)
	canvas.draw_rect(porta, _mix(WOOD, cor, NUCLEO_TINTA.madeira))
	var verga := Vector2(meio, box.end.y - PORTA.fecho)
	var ouro := _mix(GOLD, cor, NUCLEO_TINTA.ouro)
	canvas.draw_line(verga, Vector2(meio, box.end.y), ouro, PORTA.traco)
	if level <= PONTE.nivel:
		return
	var ponte := topo + alto * PONTE.y
	canvas.draw_line(
		Vector2(box.position.x + PONTE.recuo, ponte),
		Vector2(box.end.x - PONTE.recuo, ponte),
		_mix(WOOD_LIGHT, cor, PONTE.tinta),
		PONTE.traco
	)


static func _wall(canvas: CanvasItem, box: Rect2, cor: Color, level: int) -> void:
	var ink := _mix(STONE, cor, PEDRA_TINTA.pedra)
	var clara := _mix(STONE_LIGHT, cor, PEDRA_TINTA.clara)
	var fiadas := maxi(MURO.fiadas, level + 1)
	for fiada in fiadas:
		var y := box.position.y + box.size.y * (MURO.topo + float(fiada) * MURO.vao / float(fiadas))
		canvas.draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), clara, MURO.traco)
		for coluna in PEDRA.colunas:
			var x := box.position.x + float(coluna) * box.size.x / PEDRA.vaos
			x += float(fiada % 2) * PEDRA.desvio
			var de := Vector2(x, y - box.size.y * PEDRA.acima)
			canvas.draw_line(de, Vector2(x, y + box.size.y * PEDRA.abaixo), ink, MURO.traco)
	for coluna in PEDRA.colunas:
		var x := box.position.x + float(coluna) * box.size.x / PEDRA.vaos
		canvas.draw_rect(Rect2(x - AMEIA.x, box.position.y - AMEIA.y, AMEIA.w, AMEIA.y), ink)
	var peitoril := box.position.y + box.size.y * MURO.topo
	var ouro := _mix(GOLD, cor, PEDRA_TINTA.ouro)
	canvas.draw_line(
		Vector2(box.position.x, peitoril), Vector2(box.end.x, peitoril), ouro, MURO.traco
	)


static func _tower(canvas: CanvasItem, box: Rect2, cor: Color, alta: bool) -> void:
	var ink := _mix(STONE, cor, PEDRA_TINTA.pedra)
	var plataforma := Rect2(
		box.position.x - PLATAFORMA.recuo,
		box.position.y + box.size.y * PLATAFORMA.y,
		box.size.x + PLATAFORMA.folga,
		box.size.y * PLATAFORMA.h
	)
	canvas.draw_rect(plataforma, _mix(STONE_LIGHT, cor, PLATAFORMA.tinta))
	for i in DENTE.quantos:
		var x := plataforma.position.x + float(i) * plataforma.size.x / DENTE.vaos
		canvas.draw_rect(Rect2(x - DENTE.x, plataforma.position.y - DENTE.y, DENTE.w, DENTE.y), ink)
	for i in SETEIRA.quantas:
		var y := box.position.y + box.size.y * (SETEIRA.y + float(i) * SETEIRA.passo)
		var vao := Rect2(box.get_center().x - SETEIRA.x, y, SETEIRA.w, SETEIRA.h)
		canvas.draw_rect(vao, _mix(WINDOW, cor, PEDRA_TINTA.seteira))
	var pe := box.end.y - BASE.acima
	var de := Vector2(box.position.x + BASE.recuo, pe)
	canvas.draw_line(de, Vector2(box.end.x - BASE.recuo, pe), ink, BASE.traco)
	if not alta:
		return
	var meio := box.get_center().x
	var topo := box.position.y
	canvas.draw_line(Vector2(meio, topo), Vector2(meio, topo - MASTRO.alto), ink, MASTRO.traco)
	canvas.draw_line(
		Vector2(meio, topo - MASTRO.pano),
		Vector2(meio + MASTRO.vao, topo - MASTRO.queda),
		_mix(GOLD, cor, MASTRO_TINTA.ouro),
		MASTRO_TINTA.traco
	)


static func _house(canvas: CanvasItem, box: Rect2, cor: Color, forma: Silhouette.Form) -> void:
	var largo := box.size.x
	var alto := box.size.y
	var corpo := Rect2(
		box.position.x + largo * CASA.x,
		box.position.y + alto * CASA.y,
		largo * CASA.w,
		alto * CASA.h
	)
	canvas.draw_rect(corpo, _mix(WOOD, cor, CASA_TINTA.parede))
	var telhado := _mix(STONE, cor, CASA_TINTA.telha)
	var cume := box.get_center()
	canvas.draw_line(Vector2(box.position.x, corpo.position.y), cume, telhado, CASA.traco)
	canvas.draw_line(cume, Vector2(box.end.x, corpo.position.y), telhado, CASA.traco)
	for i in CASA_VAO.quantos:
		var x := corpo.position.x + corpo.size.x * (CASA_VAO.x + float(i) * CASA_VAO.passo)
		var y := corpo.position.y + corpo.size.y * CASA_VAO.y
		var vao := Rect2(x, y, corpo.size.x * CASA_VAO.w, corpo.size.y * CASA_VAO.h)
		canvas.draw_rect(vao, _mix(WINDOW, cor, CASA_TINTA.janela))
	var vao_porta := corpo.size.y * CASA_PORTA.y
	var porta := Rect2(
		corpo.get_center().x - corpo.size.x * CASA_PORTA.x,
		corpo.end.y - vao_porta,
		corpo.size.x * CASA_PORTA.w,
		vao_porta
	)
	canvas.draw_rect(porta, _mix(BARK, cor, CASA_TINTA.porta))
	# O que separa esta casa das outras tres vem do Outline: fumo, pano ou arco.
	var topo := box.position.y
	if forma == Silhouette.Form.CHAMINE:
		var fumo := Rect2(
			box.position.x + largo * CHAMINE.x, topo, largo * CHAMINE.w, box.size.y * CHAMINE.h
		)
		canvas.draw_rect(fumo, _mix(BARK, cor, CHAMINE.tinta))
	elif forma == Silhouette.Form.ESTANDARTE:
		var x := box.position.x + largo * ESTANDARTE.x
		var pau := _mix(BARK, cor, ESTANDARTE_TINTA.pau)
		canvas.draw_line(Vector2(x, topo), Vector2(x, corpo.end.y), pau, ESTANDARTE.traco)
		canvas.draw_line(
			Vector2(x, topo + ESTANDARTE.topo),
			Vector2(x + largo * ESTANDARTE.vao, topo + box.size.y * ESTANDARTE.queda),
			_mix(GOLD, cor, ESTANDARTE_TINTA.pano),
			ESTANDARTE_TINTA.traco
		)
	elif forma == Silhouette.Form.ABOBADA:
		canvas.draw_arc(
			Vector2(corpo.get_center().x, corpo.end.y),
			corpo.size.x * ABOBADA.raio,
			PI,
			TAU,
			ABOBADA.pontos,
			_mix(GOLD, cor, ABOBADA.tinta),
			ABOBADA.traco
		)


static func _mix(base: Color, cor: Color, quanto: float) -> Color:
	return base.lerp(cor, clampf(quanto, 0.0, 1.0))
