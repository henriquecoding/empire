# src/world/price_tag.gd — o preco daquilo em cima de que estas (§02, §24, §55).
#
# O Kingdom resolve o jogo inteiro com este gesto: chegas-te a uma coisa e ela
# diz-te quanto custa, em MOEDAS e nao em algarismos. Aqui faltava, e a falta
# custava o que se ve — o §55 diz "uma obra existe quando uma moeda cai num
# BuildSlot" e "nao ha botao construir", mas sem preco a silhueta convida sem
# dizer para quanto, e o jogador larga moedas a ver se acerta.
#
# O §24 nao abre excepcao nenhuma ao HUD diegetico, e isto tambem nao e uma: o
# preco nao vive num canto do ecra nem esta la sempre. Vive EM CIMA da coisa, so
# aparece quando o gesto que ele descreve funcionaria mesmo, e desaparece quando
# te afastas. E a "etiqueta de preco" das lojas do §01 aplicada a uma obra.
#
# Tres decisoes, e nenhuma delas inventa um numero:
#
#  · QUANDO aparece — exactamente onde o gesto pega. Numa obra, dentro da
#    largura dela, que e o raio com que o BuildSystem absorve uma moeda caida;
#    numa pessoa, dentro do recruit_notice_px, que e a distancia a que o §25 diz
#    que ela repara na moeda. Se o ves, funciona; se nao funciona, nao o ves.
#  · O QUE diz — o que FALTA, e nao o que custa: uma obra ja paga a meio mostra
#    o resto, e um vagabundo que ja apanhou uma moeda mostra as que ainda lhe
#    faltam para o preco do §07.
#  · O QUE PODES pagar agora — as moedas que o teu saco cobre saem douradas e as
#    outras ficam apagadas. E o mesmo que o Kingdom faz ao esbater o preco que
#    nao tens, e responde a pergunta toda de relance: quanto falta, e quanto
#    disso posso eu.
#
# Nao leva luz, pela mesma razao que o Gauge nao leva (Q-080): e um instrumento,
# e um instrumento que se apaga a noite deixa de ser um instrumento. Desaparece
# com o ART-01, como o resto do greybox.
class_name PriceTag
extends RefCounted

## As moedas de um preco, empilhadas. Nao sao balanceamento — sao geometria de
## greybox, como as alturas do Silhouette, e vao-se embora com a arte.
##
## O RAIO nao e o `WorldPalette.MOEDA_R` da moeda no chao, e isso e deliberado:
## uma moeda no chao e uma COISA, que se apanha e que tem o tamanho que tem;
## isto e um preco, e um preco tem de se ler de relance do outro lado do ecra. A
## moeda do chao tem 6 px de diametro num ecra de 1280 e desaparece.
const RAIO := 5.0
const POR_FILA := 10
const PASSO := 13.0
const ACIMA := 14.0
const MEIA := 0.5
## Quanto resta da cor de uma moeda que ainda nao podes pagar. Apagada e nao
## cinzenta: continua a ser uma moeda, e o que lhe falta e a tua luz.
const APAGADA := 0.35


## Os precos que o monarca alcanca nesta faixa. `tropas` e a tabela de UnitData
## por id e `edificios` a de BuildingData, montadas uma vez por quem desenha.
static func draw_on(
	canvas: CanvasItem, faixa: Band.Kind, tropas: Dictionary, edificios: Dictionary
) -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	if rei == UnitSystem.NENHUM or not SimLoop.units.alive(rei):
		return
	# O rei esta numa faixa so, e o preco de uma coisa noutra faixa nao e uma
	# coisa que ele alcance (§11).
	if int(SimLoop.units.bands[rei]) != int(faixa):
		return
	var x := SimLoop.units.xs[rei]
	var saco := SimLoop.units.carried_coins[rei]
	_obras(canvas, faixa, edificios, x, saco)
	_gente(canvas, faixa, tropas, x, saco)


## O degrau seguinte de cada obra ao alcance. O raio e a meia largura da obra —
## o mesmo com que o BuildSystem decide que uma moeda caiu NELA (§55).
static func _obras(
	canvas: CanvasItem, faixa: Band.Kind, edificios: Dictionary, x: float, saco: int
) -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.band != faixa or not over(vaga, x):
			continue
		var falta := owed_by(vaga)
		if falta <= 0 and SimLoop.field != null:
			falta = SimLoop.field.training.owed(vaga, SimLoop.units)
		var madeira := SimLoop.night.amargueiros
		var subir := vaga.state in [BuildSlot.State.EMPTY, BuildSlot.State.DONE]
		if falta <= 0 or (subir and not SimLoop.builds.can_climb(vaga, SimLoop.state, madeira)):
			continue
		var caixa := BuildView.drawn_box(vaga, Silhouette.of_slot(vaga, edificios))
		_moedas(canvas, vaga.x, caixa.position.y, falta, saco)


## Se uma moeda largada daqui cai NESTA obra. E a meia largura com que o
## BuildSystem a absorve (§55), perguntada de fora para que o preco apareca
## exactamente onde o gesto pega.
static func over(vaga: BuildSlot, x: float) -> bool:
	return absf(vaga.x - x) <= vaga.width * MEIA


## Quanto falta pagar do degrau seguinte — ou da reparacao, se esta tocada ou
## em ruina (Q-108) —, ou zero: chegou ao topo, esta a meio, ou ja se repara.
##
## Uma obra a meio nao aceita moeda — §55, "pagar mais nao a faz andar mais
## depressa: quem a faz andar e quem esta la" — e por isso tambem nao tem preco.
static func owed_by(vaga: BuildSlot) -> int:
	var reparar := vaga.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN]
	if (
		vaga.mending
		or (vaga.state != BuildSlot.State.EMPTY and not vaga.standing() and not reparar)
	):
		return 0
	var custo := vaga.repair_cost() if reparar else vaga.next_cost()
	if custo <= 0:
		return 0
	return maxi(0, custo - vaga.paid)


## Quantas moedas faltam ao saco desta pessoa para ela passar a ser tua. E a
## conta do RecruitSystem vista do lado de fora: ele compara o SACO com o
## recruit_cost do §07, e nao a ultima moeda apanhada.
static func owed_by_unit(unidades: UnitSystem, i: int) -> int:
	return maxi(0, unidades.recruit_costs[i] - unidades.carried_coins[i])


## O preco de quem ainda nao e de ninguem. O raio e o recruit_notice_px: e a
## distancia a que o §25 diz que uma moeda largada o faz vir — largar mais longe
## do que isto nao recruta ninguem, e por isso mais longe nao ha preco nenhum.
static func _gente(
	canvas: CanvasItem, faixa: Band.Kind, tropas: Dictionary, x: float, saco: int
) -> void:
	var unidades := SimLoop.units
	var alcance := SimFactory.curve().recruit_notice_px
	for i in unidades.count():
		if int(unidades.bands[i]) != int(faixa) or not unidades.alive(i):
			continue
		if not SimLoop.recruits.vagrant(unidades, i) or absf(unidades.xs[i] - x) > alcance:
			continue
		var falta := owed_by_unit(unidades, i)
		if falta <= 0:
			continue
		var dados: UnitData = tropas.get(unidades.data_ids[i])
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var em := Smoothing.x_of(Smoothing.Group.UNITS, unidades.ids[i], unidades.xs[i])
		var caixa := Silhouette.body_box(Silhouette.Form.CAIXA, em, int(faixa), alto)
		# A cabeca do §25 — o chapeu — desenha-se por cima da caixa, e o preco
		# tem de ficar acima dele para nao lhe assentar em cima.
		_moedas(canvas, em, caixa.position.y - WorldPalette.BARRA, falta, saco)


## `falta` moedas empilhadas sobre (x, topo), de baixo para cima. As primeiras
## `saco` saem douradas — sao as que ja podes pousar ali — e as outras apagadas.
## Contam-se: e para isso que ha uma por moeda e nao um algarismo.
static func _moedas(canvas: CanvasItem, x: float, topo: float, falta: int, saco: int) -> void:
	var base := topo - ACIMA
	for n in falta:
		var fila := n / POR_FILA
		var nesta := mini(falta - fila * POR_FILA, POR_FILA)
		var coluna := n % POR_FILA
		var centro := Vector2(x + (float(coluna) - (nesta - 1) * MEIA) * PASSO, base - fila * PASSO)
		var cor := WorldPalette.MOEDA
		if n >= saco:
			cor = WorldPalette.dim(WorldPalette.MOEDA, APAGADA)
		# A orla escura por baixo: sem ela um preco dourado sobre o ceu do
		# meio-dia e um preco cinzento sobre o solo somem os dois (§80).
		canvas.draw_circle(centro, RAIO + 1.0, WorldPalette.SILHUETA)
		canvas.draw_circle(centro, RAIO, cor)
