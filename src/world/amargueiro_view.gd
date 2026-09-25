# src/world/amargueiro_view.gd — o que ficou no campo, desenhado (§74).
#
# Uma arvore de madeira escura e resinosa, com a cara da tropa na casca. A
# cara e o que faz disto uma consequencia e nao um obstaculo: "a unica coisa que
# o jogo faz e mostrar-te a cara na casca antes de a serra entrar". No subsolo
# cresce ao contrario, para baixo. Um Marco e um bloco de pedra.
#
# Greybox, como o resto do Silhouette (Q-079): as proporcoes sao geometria e
# nao balanceamento, e vao-se embora com o ART-04, que traz o tronco por escala
# e o slot `face` das personagens.
class_name AmargueiroView
extends RefCounted

## Uma arvore e um degrau mais alta do que a pessoa que foi.
const DEGRAUS_A_MAIS := 1
## A copa, em fraccao da largura do tronco, para cada lado.
const COPA := 0.9
## A cara, em fraccao da caixa: onde ficam os olhos e a boca na casca.
const OLHOS_Y := 0.3
const OLHOS_X := 0.22
const BOCA_Y := 0.45
const TRACO := 1.5


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting) -> void:
	var arvores := SimLoop.night.trees
	for i in arvores.count():
		if arvores.bands[i] != int(faixa):
			continue
		var caixa := box(arvores, i)
		if arvores.fates[i] == AmargueiroSystem.Fate.MARKER:
			canvas.draw_rect(caixa, luz.body(WorldPalette.OBRA, arvores.xs[i]))
			continue
		var cor := luz.body(WorldPalette.AMARGO, arvores.xs[i])
		_tronco(canvas, caixa, cor, faixa == Band.Kind.UNDERGROUND)
		_cara(canvas, caixa, faixa == Band.Kind.UNDERGROUND)
	_preco(canvas, faixa)


## A caixa da arvore i. Um Marco e baixo; uma arvore cresce um degrau acima de
## quem foi, e no subsolo o mesmo tanto para baixo.
static func box(arvores: AmargueiroSystem, i: int) -> Rect2:
	var chao := WorldPalette.ground_of(arvores.bands[i])
	var largo := arvores.widths[i]
	var alto := WorldPalette.DEGRAU
	if arvores.fates[i] != AmargueiroSystem.Fate.MARKER:
		alto *= arvores.tiers[i] + DEGRAUS_A_MAIS
	var topo := chao if arvores.bands[i] == Band.Kind.UNDERGROUND else chao - alto
	return Rect2(arvores.xs[i] - largo * WorldPalette.MEIA, topo, largo, alto)


static func _tronco(canvas: CanvasItem, caixa: Rect2, cor: Color, invertida: bool) -> void:
	canvas.draw_rect(caixa, cor)
	# A copa e os ramos ficam do lado de onde a arvore cresce: para cima, ou no
	# subsolo para baixo, que e o "ao contrario" do §74.
	var ponta := caixa.end.y if invertida else caixa.position.y
	var meio := caixa.get_center().x
	var abre := caixa.size.x * COPA
	var fundo := ponta + (caixa.size.y if invertida else -caixa.size.y) * WorldPalette.MEIA
	var copa := PackedVector2Array(
		[Vector2(meio - abre, ponta), Vector2(meio, fundo), Vector2(meio + abre, ponta)]
	)
	canvas.draw_colored_polygon(copa, cor)


static func _cara(canvas: CanvasItem, caixa: Rect2, invertida: bool) -> void:
	var cima := caixa.position.y + caixa.size.y * (1.0 - BOCA_Y if invertida else OLHOS_Y)
	var boca := caixa.position.y + caixa.size.y * (1.0 - OLHOS_Y if invertida else BOCA_Y)
	var meio := caixa.get_center().x
	var afasta := caixa.size.x * OLHOS_X
	var tinta := WorldPalette.SILHUETA
	canvas.draw_circle(Vector2(meio - afasta, cima), TRACO, tinta)
	canvas.draw_circle(Vector2(meio + afasta, cima), TRACO, tinta)
	canvas.draw_line(Vector2(meio - afasta, boca), Vector2(meio + afasta, boca), tinta, TRACO)


## O preco do corte, em cima da arvore que o rei alcanca — o mesmo gesto do
## PriceTag (§55): so aparece quando a serra ja pega e so onde a moeda cai nela.
static func _preco(canvas: CanvasItem, faixa: Band.Kind) -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	if rei == UnitSystem.NENHUM or int(SimLoop.units.bands[rei]) != int(faixa):
		return
	var arvores := SimLoop.night.trees
	var x := SimLoop.units.xs[rei]
	var custo := arvores.fell_cost()
	for i in arvores.count():
		if absf(arvores.xs[i] - x) > arvores.widths[i] * WorldPalette.MEIA:
			continue
		if not arvores.ready_for(arvores.ids[i], AmargueiroSystem.CORTAR):
			continue
		var falta := custo - arvores.paid[i]
		var topo := box(arvores, i).position.y
		PriceTag.stack(canvas, arvores.xs[i], topo, falta, SimLoop.units.carried_coins[rei])
