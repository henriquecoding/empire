# src/world/amargueiro_view.gd — o Amargueiro e o Marco, desenhados (§74).
#
# "Uma arvore de madeira escura e resinosa, com a cara da tropa na casca." O
# greybox nao tem sprite de tronco (ART-04 e a arte do rosto): tem uma forma que
# se le de longe — um tronco mais alto do que qualquer tropa, a copa curta e
# torta, e dois olhos a meia altura. A escala e a da pessoa (§22): um vagabundo
# da uma arvore baixa, um monarca uma alta.
#
# No subsolo cresce ao contrario, para baixo (§74): pendura-se do tecto.
#
# Le do SimLoop e nao guarda nada. A serra a meio ve-se como a vida a descer —
# e o mesmo instrumento das obras, e e o que ela e: a arvore a acabar.
class_name AmargueiroView
extends RefCounted

## A madeira escura e resinosa, a resina da copa, e a pele passada a casca.
const CASCA := Color(0.20, 0.13, 0.09)
const RESINA := Color(0.45, 0.27, 0.10)
const ROSTO := Color(0.50, 0.37, 0.25)
const OLHO := Color(0.98, 0.88, 0.59)
## A pedra do Marco: o cinzento da ruina, mais claro — e pedra de proposito.
const PEDRA := Color(0.58, 0.56, 0.50)

## Em fraccoes da caixa de uma tropa (ActorArt.ESCALA.caixa), por escala.
const ALTO := [1.1, 1.45, 1.8]
const TRONCO := {"largo": 0.3, "copa": 0.62, "copa_alta": 0.3, "torto": 0.12}
const CARA := {"y": 0.42, "olho_x": 0.08, "olho": 3.0, "boca": 0.52, "boca_x": 0.07}
const MARCO := {"alto": 0.55, "largo": 0.42, "topo": 0.28}


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting) -> void:
	var bosque := SimLoop.night.amargueiros
	for i in bosque.count():
		if bosque.bands[i] != int(faixa):
			continue
		var x := bosque.xs[i]
		if bosque.fates[i] == AmargueiroSystem.Fate.MARKER:
			_marco(canvas, x, WorldPalette.ground_of(int(faixa)), luz)
			continue
		var caixa := box(bosque, i)
		_arvore(canvas, caixa, not bosque.titles[i].is_empty(), luz, x)
		_serra(canvas, caixa, bosque.slot_ids[i])


## A caixa do tronco no ecra. Publica porque e a mesma pergunta que um teste de
## vista faz: "a arvore de um monarca e mais alta do que a de um vagabundo?"
static func box(bosque: AmargueiroSystem, i: int) -> Rect2:
	var faixa := bosque.bands[i]
	var unidade: float = ActorArt.ESCALA.caixa
	var alto: float = unidade * ALTO[clampi(bosque.tiers[i], 1, ALTO.size()) - 1]
	var largo: float = unidade * TRONCO.largo
	var x := bosque.xs[i] - largo * WorldPalette.MEIA
	if faixa == int(Band.Kind.UNDERGROUND):
		return Rect2(x, float(Band.GROUND_LINE), largo, alto)  # do tecto para baixo
	return Rect2(x, WorldPalette.ground_of(faixa) - alto, largo, alto)


static func _arvore(
	canvas: CanvasItem, caixa: Rect2, nomeada: bool, luz: Lighting, x: float
) -> void:
	canvas.draw_rect(caixa, luz.body(CASCA, x))
	var copa_w := caixa.size.x / TRONCO.largo * TRONCO.copa
	var copa_h := caixa.size.y * TRONCO.copa_alta
	var torto := copa_w * TRONCO.torto
	var copa := Rect2(x - copa_w * WorldPalette.MEIA + torto, caixa.position.y, copa_w, copa_h)
	canvas.draw_rect(copa, luz.body(RESINA, x))
	# A cara na casca: um rosto de madeira, e os olhos acesos se tinha nome (§76).
	var meio := Vector2(x, caixa.position.y + caixa.size.y * CARA.y)
	var olho_x := copa_w * CARA.olho_x
	var olho := Vector2(CARA.olho, CARA.olho)
	var cor_olho := OLHO if nomeada else luz.body(ROSTO, x)
	var canto := Vector2(CARA.olho, CARA.olho) * WorldPalette.MEIA
	canvas.draw_rect(Rect2(meio + Vector2(-olho_x, 0.0) - canto, olho), cor_olho)
	canvas.draw_rect(Rect2(meio + Vector2(olho_x, 0.0) - canto, olho), cor_olho)
	var boca := caixa.position.y + caixa.size.y * CARA.boca
	var boca_x := copa_w * CARA.boca_x
	canvas.draw_line(Vector2(x - boca_x, boca), Vector2(x + boca_x, boca), luz.body(ROSTO, x))


## A serra a meio: a vida da arvore a descer, pelo instrumento das obras.
static func _serra(canvas: CanvasItem, caixa: Rect2, slot_id: int) -> void:
	var s := SimLoop.builds.index_of(slot_id)
	if s == BuildSystem.NENHUM:
		return
	var vaga := SimLoop.builds.slots[s]
	if vaga.state != BuildSlot.State.BUILDING or vaga.works.is_empty():
		return
	Gauge.health(canvas, caixa, 1.0 - vaga.progress / maxf(vaga.works[0], 1.0))


static func _marco(canvas: CanvasItem, x: float, chao: float, luz: Lighting) -> void:
	var unidade: float = ActorArt.ESCALA.caixa
	var largo: float = unidade * MARCO.largo
	var alto: float = unidade * MARCO.alto
	var corpo := Rect2(x - largo * WorldPalette.MEIA, chao - alto, largo, alto)
	canvas.draw_rect(corpo, luz.body(PEDRA, x))
	var topo := Rect2(corpo.position, Vector2(largo, alto * MARCO.topo))
	canvas.draw_rect(topo, luz.body(PEDRA.lightened(MARCO.topo), x))
