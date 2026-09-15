# src/sim/systems/passages.gd — quem muda de faixa, e onde (§11, §53).
#
# O mundo tem tres faixas e um andar de baixo, e o §25 poe a descoberta dele ao
# minuto 10:00: "e o momento em que o jogo deixa de ser Kingdom". Ao minuto
# 12:00 poe a factura: "noite 2: um Rastejante entra pela passagem que abriste.
# Toda a decisao tem custo — a licao central do jogo, ensinada por perda."
#
# Este ficheiro e essa factura. Uma passagem aberta e um caminho que tambem serve
# a quem vem de baixo, e um muro na superficie nao trava nada disso — que e
# exatamente o ponto da tactica avancada da §51: "se o caminho de superficie
# estiver selado, a mancha usa a faixa subterranea".
#
# Estatico e puro. So sobe quem PODE mudar de faixa — o can_change_band do §44,
# que hoje e o Cavador — e so onde ha passagem.
class_name Passages
extends RefCounted

## O que devolve, para quem chama traduzir no passage_used da §46.
const QUEM := &"id"
const DE := &"from"
const PARA := &"to"


## As criaturas do subsolo que chegaram a uma passagem sobem. Devolve quem subiu.
static func surface(
	criaturas: CreatureSystem, dados: Dictionary, passagens: PackedFloat32Array
) -> Array[Dictionary]:
	var subiram: Array[Dictionary] = []
	if passagens.is_empty():
		return subiram
	for creature_id in TargetPicker.ids_por_ordem(criaturas.ids):
		var c := criaturas.index_of(creature_id)
		if criaturas.bands[c] != int(Band.Kind.UNDERGROUND) or not criaturas.alive(c):
			continue
		var perfil: CreatureData = dados.get(criaturas.data_ids[c])
		if perfil == null or not perfil.can_change_band:
			continue
		if not near(criaturas.xs[c], passagens):
			continue
		criaturas.bands[c] = int(Band.Kind.SURFACE)
		subiram.append(
			{QUEM: creature_id, DE: int(Band.Kind.UNDERGROUND), PARA: int(Band.Kind.SURFACE)}
		)
	return subiram


## Se uma criatura desta faixa alcanca aquela. E o espelho do Posts.reaches()
## que o F1-07 escreveu para as tropas, e faltava deste lado: sem ele uma
## criatura batia em qualquer faixa que o targets_bands listasse, de onde quer
## que estivesse.
##
## A faixa dela propria alcanca sempre. Outra so se ela NAO puder mudar de
## faixa — e isso separa exatamente as duas criaturas que o §07 descreve de
## maneiras diferentes:
##
##   O ALADO (can_change_band = false) vive no ar e bate no chao de la: "ignora
##   a camada de solo, so atacavel por arqueiros e torres altas" (§07). A
##   resposta a ele e um posto que chegue la acima, e e a torre alta.
##   O CAVADOR (can_change_band = true) "passa pela faixa subterranea" (§07) —
##   PASSA, nao ataca de la. Para bater tem de subir, e sobe onde ha passagem
##   (§11, §51, e o surface() aqui em cima). Sem esta regra a passagem que o
##   §25 poe ao minuto 12:00 nao custava nada a ninguem, e a noite 10 nao tinha
##   resposta nenhuma — nem muro, nem torre, nem torre alta.
static func reaches(dados: CreatureData, sua_faixa: int, alvo: int) -> bool:
	if not dados.targets_bands.has(alvo):
		return false
	if alvo == sua_faixa:
		return true
	return not dados.can_change_band


## Se este x esta ao alcance de alguma passagem. A tolerancia e a do Band, e e a
## mesma para o monarca e para o que vem de baixo: uma passagem nao e mais larga
## para uns do que para outros.
static func near(x: float, passagens: PackedFloat32Array) -> bool:
	for passagem in passagens:
		if absf(x - passagem) <= Band.PASSAGE_PX:
			return true
	return false
