# src/world/actor_art.gd — o que uma tropa E, por dentro da caixa (§22, §24).
#
# O Silhouette diz a forma e o Outline o contorno; isto e o que enche esse
# contorno: pernas, tronco, cara, chapeu e a marca que se leva na mao. Nao
# inventa estado nenhum — le a coluna, desenha, e acabou.
#
# Nenhum numero vive solto numa linha de desenho: estao todos nas tabelas aqui
# em cima, e em FRACCAO DA CAIXA sempre que se referem ao corpo. A caixa e o
# contrato com quem escolhe a altura (§22), e uma medida em pixeis deixava de a
# respeitar no primeiro tamanho diferente. So a marca da mao e em pixeis, e pela
# mesma razao do Outline: uma arma sai do corpo de proposito.
class_name ActorArt
extends RefCounted

const SKIN := Color(0.78, 0.55, 0.38)
const SKIN_LIGHT := Color(0.95, 0.72, 0.48)
const CLOTH := Color(0.20, 0.35, 0.48)
const CLOTH_LIGHT := Color(0.32, 0.54, 0.61)
const METAL := Color(0.68, 0.70, 0.72)
const WOOD := Color(0.43, 0.25, 0.13)
const WOOD_LIGHT := Color(0.68, 0.41, 0.19)
const EYE := Color(0.98, 0.88, 0.59)
const SOMBRA := Color(0.03, 0.03, 0.04, 0.30)

## A caixa do tamanho 1 tem 48 px (§01: quatro degraus). Nada encolhe abaixo de
## `minima` — por baixo disso a cara junta-se ao corpo e deixa de se ler.
const ESCALA := {"minima": 0.55, "caixa": 48.0}

## O baloico de quem anda. Quem esta parado nao baloica, e e assim que se ve de
## longe quem vai a algum lado.
const BALOICO := {"ritmo": 5.0, "desfase": 0.025, "alto": 0.9}

## O corpo, em fraccao da ALTURA da caixa. `morto` e a linha que sobra de quem caiu.
const CORPO := {"cabeca": 0.25, "morto": 0.48, "anca": 0.39, "joelho": 0.24, "raio": 0.30}

## O mesmo corpo, em fraccao da LARGURA: onde assenta cada perna.
const PERNA := {"anca": 0.16, "joelho": 0.20, "pe_tras": 0.07, "pe_frente": 0.34}

## O tronco, e a gola que lhe marca o ombro.
const TRONCO := {"x": 0.34, "y": 0.36, "w": 0.68, "h": 0.37, "gola": 0.14}
const COSTURA := {"topo": 3.0, "fundo": 2.0}

## A cara: a faixa clara do queixo, o olho do lado para onde se anda, e a boca.
const CARA := {"x": 0.26, "y": 0.07, "w": 0.52, "olho_x": 0.13, "olho": 3.0, "boca": 0.16}

## Quanto de cada cor propria entra na cor da tropa. A cor da tropa manda — e
## dela que se sabe de quem ela e (§22) — e isto e o que lhe da volume.
const MISTURA := {"tinta": 0.38, "pele": 0.32, "pano": 0.38, "gola": 0.28, "cara": 0.35}

## Para que lado a tropa esta virada. Nao e uma coluna do estado: le-se do alvo,
## e e o que poe o olho e a arma do lado certo.
const LADO := {"frente": 1.0, "tras": -1.0}

## O traco nunca e mais fino do que `minimo`: por baixo disso some-se.
const TRACO := {"minimo": 2.0, "fino": 1.0, "raio": 4.0, "sombra": 2.0}

## A aba e a coroa. Quem nao tem dono nao tem chapeu, e e o que separa um
## vagabundo de um teu a qualquer distancia (§22).
const CHAPEU := {"aba": 4.0, "aba_x": 0.34, "coroa": 14.0, "coroa_x": 0.18}

## Onde a mao esta, e ate onde a arma vai. Em pixeis, como as marcas do Outline.
const MAO := {"x": 0.26, "y": 0.56, "ponta_x": 18.0, "ponta_y": -13.0}
const ARCO := {"x": 7.0, "y": -4.0, "raio": 10.0, "de": -1.1, "ate": 1.1, "pontos": 8}
const HASTE := {"x": 22.0, "y": -18.0, "traco": 1.5}
const FERRAMENTA := {"x": 15.0, "y": -11.0, "gume_x": 5.0, "gume_y": 3.0}
const MACA := {"x": 14.0, "y": -11.0, "bola_x": 16.0, "bola_y": -13.0, "raio": 4.0}
const VIGA := {"tras": 14.0, "frente": 25.0, "traco": 5.0}


static func draw_unit(
	canvas: CanvasItem,
	box: Rect2,
	data: UnitData,
	units: UnitSystem,
	index: int,
	cor: Color,
	tempo: float
) -> void:
	if data == null:
		return
	var scale := maxf(ESCALA.minima, box.size.y / ESCALA.caixa)
	var ink := cor.darkened(MISTURA.tinta)
	var stroke := maxf(TRACO.minimo, scale * TRACO.minimo)
	var chao := box.end.y + 1.0
	var sombra := chao + TRACO.sombra
	canvas.draw_line(Vector2(box.position.x, sombra), Vector2(box.end.x, sombra), SOMBRA, stroke)
	if not units.alive(index):
		var caido := box.position.y + box.size.y * CORPO.morto
		canvas.draw_line(Vector2(box.position.x, caido), Vector2(box.end.x, caido), ink, stroke)
		return

	var bob := _baloico(box, units, index, tempo)
	var meio := box.get_center().x
	var center := Vector2(meio, box.position.y + box.size.y * CORPO.cabeca + bob)
	var anca := chao - box.size.y * CORPO.anca + bob
	var joelho := chao - box.size.y * CORPO.joelho + bob
	var esquerdo := Vector2(meio - box.size.x * PERNA.joelho, joelho)
	var direito := Vector2(meio + box.size.x * PERNA.joelho, joelho)
	canvas.draw_line(Vector2(meio - box.size.x * PERNA.anca, anca), esquerdo, ink, stroke)
	canvas.draw_line(Vector2(meio + box.size.x * PERNA.anca, anca), direito, ink, stroke)
	canvas.draw_line(esquerdo, Vector2(meio - box.size.x * PERNA.pe_tras, chao), SKIN, stroke)
	canvas.draw_line(direito, Vector2(meio + box.size.x * PERNA.pe_frente, chao), SKIN, stroke)
	_tronco(canvas, box, meio, cor, ink, bob, scale)
	_cara(canvas, box, center, cor, ink, units, index, scale)
	_hat(canvas, center, box, units, index, scale)
	draw_weapon(canvas, box, data, units, index, cor)


## Quem esta parado nao baloica: o baloico e a unica coisa que diz, sem numeros,
## que aquela coluna esta a ir a algum lado.
static func _baloico(box: Rect2, units: UnitSystem, index: int, tempo: float) -> float:
	if is_zero_approx(units.target_xs[index] - units.xs[index]):
		return 0.0
	return sin(tempo * BALOICO.ritmo + box.position.x * BALOICO.desfase) * BALOICO.alto


static func _tronco(
	canvas: CanvasItem, box: Rect2, meio: float, cor: Color, ink: Color, bob: float, scale: float
) -> void:
	var torso := Rect2(
		meio - box.size.x * TRONCO.x,
		box.position.y + box.size.y * TRONCO.y + bob,
		box.size.x * TRONCO.w,
		box.size.y * TRONCO.h
	)
	canvas.draw_rect(torso, cor.lerp(CLOTH, MISTURA.pano))
	var gola := Vector2(torso.size.x, maxf(TRACO.minimo, torso.size.y * TRONCO.gola))
	canvas.draw_rect(Rect2(torso.position, gola), cor.lerp(CLOTH_LIGHT, MISTURA.gola))
	canvas.draw_line(
		Vector2(torso.get_center().x, torso.position.y + COSTURA.topo),
		Vector2(torso.get_center().x, torso.end.y - COSTURA.fundo),
		ink,
		maxf(TRACO.fino, scale)
	)


static func _cara(
	canvas: CanvasItem,
	box: Rect2,
	center: Vector2,
	cor: Color,
	ink: Color,
	units: UnitSystem,
	index: int,
	scale: float
) -> void:
	var raio := maxf(TRACO.raio, box.size.x * CORPO.raio)
	canvas.draw_circle(center, raio, cor.lerp(SKIN, MISTURA.pele))
	var queixo := Rect2(
		center.x - box.size.x * CARA.x,
		center.y + box.size.y * CARA.y,
		box.size.x * CARA.w,
		maxf(TRACO.minimo, scale)
	)
	canvas.draw_rect(queixo, SKIN_LIGHT.lerp(cor, MISTURA.cara))
	var lado := box.size.x * CARA.olho_x
	var frente := lado if units.target_xs[index] >= units.xs[index] else -lado
	var olho := Vector2(center.x + frente - CARA.olho * WorldPalette.MEIA, center.y - 1.0)
	canvas.draw_rect(Rect2(olho, Vector2(CARA.olho, CARA.olho)), EYE)
	var boca := center.y + box.size.y * CARA.boca
	canvas.draw_line(
		Vector2(center.x - lado, boca), Vector2(center.x + lado, boca), ink, maxf(TRACO.fino, scale)
	)


static func _hat(
	canvas: CanvasItem, head: Vector2, box: Rect2, units: UnitSystem, index: int, scale: float
) -> void:
	if units.owners[index] == RecruitSystem.SEM_DONO:
		return
	var rei := units.ids[index] == SimLoop.king_id
	var cor := WorldPalette.REI if rei else WorldPalette.CHAPEU
	var traco := maxf(TRACO.minimo, scale * TRACO.minimo)
	var brim := head.y - CHAPEU.aba * scale
	var aba := box.size.x * CHAPEU.aba_x
	canvas.draw_line(Vector2(head.x - aba, brim), Vector2(head.x + aba, brim), cor, traco)
	if not rei:
		return
	var bico := Vector2(head.x, head.y - CHAPEU.coroa * scale)
	var pe := box.size.x * CHAPEU.coroa_x
	canvas.draw_line(Vector2(head.x - pe, brim), bico, WorldPalette.REI, traco)
	canvas.draw_line(bico, Vector2(head.x + pe, brim), WorldPalette.REI, traco)


## A marca do §24, e so ela: e o que se ve de uma tropa a 1 bit, e por isso cada
## oficio leva a sua e nenhuma leva a de outro.
static func draw_weapon(
	canvas: CanvasItem,
	box: Rect2,
	data: UnitData,
	units: UnitSystem,
	index: int,
	cor: Color,
	facing: float = 0.0
) -> void:
	var scale := maxf(ESCALA.minima, box.size.y / ESCALA.caixa)
	var lado := LADO.frente if units.target_xs[index] >= units.xs[index] else LADO.tras
	if not is_zero_approx(facing):
		lado = facing
	var mao := Vector2(
		box.get_center().x + lado * box.size.x * MAO.x, box.position.y + box.size.y * MAO.y
	)
	var ponta := mao + Vector2(lado * MAO.ponta_x, MAO.ponta_y)
	match Silhouette.of_unit(data):
		Silhouette.Mark.ARCO:
			var punho := mao + Vector2(lado * ARCO.x, ARCO.y)
			var angle := 0.0 if lado > 0.0 else PI
			canvas.draw_arc(
				punho,
				ARCO.raio * scale,
				ARCO.de + angle,
				ARCO.ate + angle,
				ARCO.pontos,
				cor,
				TRACO.minimo
			)
			canvas.draw_line(mao, punho, cor, 1.0)
		Silhouette.Mark.HASTE:
			ponta = mao + Vector2(lado * HASTE.x, HASTE.y)
			canvas.draw_line(mao, ponta, METAL.lerp(cor, MISTURA.cara), scale * HASTE.traco)
		Silhouette.Mark.LAMINA:
			canvas.draw_line(mao, ponta, METAL.lerp(cor, MISTURA.cara), scale * TRACO.minimo)
		Silhouette.Mark.FERRAMENTA:
			ponta = mao + Vector2(lado * FERRAMENTA.x, FERRAMENTA.y)
			canvas.draw_line(mao, ponta, WOOD_LIGHT.lerp(cor, MISTURA.cara), scale * TRACO.minimo)
			canvas.draw_line(
				ponta + Vector2(-lado * FERRAMENTA.gume_x, -FERRAMENTA.gume_y),
				ponta + Vector2(lado * FERRAMENTA.gume_x, FERRAMENTA.gume_y),
				METAL,
				TRACO.minimo
			)
		Silhouette.Mark.MACA:
			canvas.draw_line(mao, mao + Vector2(lado * MACA.x, MACA.y), WOOD, scale * TRACO.minimo)
			canvas.draw_circle(
				mao + Vector2(lado * MACA.bola_x, MACA.bola_y),
				MACA.raio * scale,
				WOOD_LIGHT.lerp(cor, MISTURA.cara)
			)
		Silhouette.Mark.VIGA:
			canvas.draw_line(
				mao + Vector2(-lado * VIGA.tras, 0.0),
				mao + Vector2(lado * VIGA.frente, 0.0),
				WOOD_LIGHT.lerp(cor, MISTURA.cara),
				VIGA.traco
			)
