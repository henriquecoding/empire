# src/world/creature_art.gd — o que um bicho E, por dentro da caixa (§22, §25).
#
# O corpo do bicho e o poligono do Outline: o que aqui se acrescenta e o que o
# faz mexer-se e olhar para algum lado — asa, pata, focinho e olho. Separado do
# ActorArt porque uma tropa e um bicho nao partilham uma unica medida, e junta-
# los era um ficheiro onde ninguem encontrava nada.
#
# As medidas seguem a regra do ActorArt: fraccao da caixa para o corpo, pixeis
# so para o que sai dela de proposito.
class_name CreatureArt
extends RefCounted

## O mesmo ambar do ActorArt: um olho aceso e a unica coisa quente de um bicho, e
## e por ela que se percebe para onde ele olha.
const EYE := Color(0.98, 0.88, 0.59)

## O bicho do tamanho 1 tem 42 px de alto, e nada encolhe abaixo de `minima`.
const ESCALA := {"minima": 0.55, "caixa": 42.0}

## O baloico: mais lento e mais curto do que o de uma tropa. Um bicho respira.
const BALOICO := {"ritmo": 4.0, "desfase": 0.018, "alto": 0.3}

## Quanto da cor propria entra na tinta e no olho.
const MISTURA := {"tinta": 0.42, "olho": 0.45}

const TRACO := {"asa": 3.0, "pata": 2.0, "corpo": 2.0}

## A asa do Alado (§11): sai da caixa para os dois lados e sobe ate ao topo.
const ASA := {"vao": 24.0, "alto": 8.0, "olho": 0.18}

## O Rastejante (§25): baixo, aos bocados, e com as patas a sair por baixo.
const PATA := {"quantas": 3, "x": 0.18, "passo": 0.30, "alto": 3.0, "fundo": 5.0, "tras": 4.0}

## O olho, e onde ele fica em cada forma.
const OLHO := {"raio": 3.0, "grande": 4.0, "x": 0.17, "alto": 0.12, "focinho": 0.27}

## O Ariete (§25): o focinho E a arma, e por isso atravessa a caixa toda.
const FOCINHO := {"x": 0.18, "y": 3.0}

## As pernas de quem nao e nenhum dos tres: duas, e a sair por baixo do corpo.
const PERNA := {"anca": 0.18, "pe": 0.10, "alto": 6.0}


static func draw_on(
	canvas: CanvasItem, box: Rect2, forma: Silhouette.Form, cor: Color, tempo: float
) -> void:
	var scale := maxf(ESCALA.minima, box.size.y / ESCALA.caixa)
	var onda := sin(tempo * BALOICO.ritmo + box.position.x * BALOICO.desfase)
	var center := box.get_center() + Vector2(0.0, onda * BALOICO.alto)
	var ink := cor.darkened(MISTURA.tinta)
	var olho := EYE.lerp(cor, MISTURA.olho)
	match forma:
		Silhouette.Form.ASA:
			_asas(canvas, box, center, ink, olho, scale)
		Silhouette.Form.RASTEJO:
			_patas(canvas, box, center, ink, olho, scale)
		Silhouette.Form.ARIETE:
			var meio := Vector2(box.position.x, center.y)
			canvas.draw_line(meio, Vector2(box.end.x, center.y), ink, scale * TRACO.corpo)
			var nariz := box.position.x + box.size.x * FOCINHO.x
			canvas.draw_circle(Vector2(nariz, center.y - FOCINHO.y), OLHO.raio * scale, olho)
		_:
			_pernas(canvas, box, center, ink, olho, scale)


static func _asas(
	canvas: CanvasItem, box: Rect2, center: Vector2, ink: Color, olho: Color, scale: float
) -> void:
	var topo := box.position.y + ASA.alto
	canvas.draw_line(
		Vector2(box.position.x, center.y),
		Vector2(box.position.x - ASA.vao * scale, topo),
		ink,
		TRACO.asa
	)
	canvas.draw_line(
		Vector2(box.end.x, center.y), Vector2(box.end.x + ASA.vao * scale, topo), ink, TRACO.asa
	)
	var lado := box.size.x * ASA.olho
	canvas.draw_circle(center + Vector2(-lado, 0.0), OLHO.raio * scale, olho)
	canvas.draw_circle(center + Vector2(lado, 0.0), OLHO.raio * scale, olho)


static func _patas(
	canvas: CanvasItem, box: Rect2, center: Vector2, ink: Color, olho: Color, scale: float
) -> void:
	for i in PATA.quantas:
		var x := box.position.x + box.size.x * (PATA.x + float(i) * PATA.passo)
		canvas.draw_line(
			Vector2(x, box.end.y - PATA.alto),
			Vector2(x - PATA.tras, box.end.y + PATA.fundo),
			ink,
			TRACO.pata
		)
	canvas.draw_circle(center + Vector2(box.size.x * OLHO.focinho, 0.0), OLHO.raio * scale, olho)


static func _pernas(
	canvas: CanvasItem, box: Rect2, center: Vector2, ink: Color, olho: Color, scale: float
) -> void:
	var lado := box.size.x * OLHO.x
	var alto := box.size.y * OLHO.alto
	canvas.draw_circle(center + Vector2(-lado, -alto), OLHO.grande * scale, olho)
	canvas.draw_circle(center + Vector2(lado, -alto), OLHO.grande * scale, olho)
	canvas.draw_line(
		Vector2(box.position.x + box.size.x * PERNA.anca, box.end.y),
		Vector2(box.position.x + box.size.x * PERNA.pe, box.end.y + PERNA.alto),
		ink,
		scale * TRACO.corpo
	)
	canvas.draw_line(
		Vector2(box.end.x - box.size.x * PERNA.anca, box.end.y),
		Vector2(box.end.x - box.size.x * PERNA.pe, box.end.y + PERNA.alto),
		ink,
		scale * TRACO.corpo
	)
