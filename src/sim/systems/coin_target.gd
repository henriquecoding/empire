# src/sim/systems/coin_target.gd — a quem serve uma moeda largada (§02, §55, §61).
#
# Ate a auditoria de 26/09 (D1, D5) a moeda pousada servia quatro leitores pela
# ordem do tick — obra, treino, celeiro, quem a foi buscar — e nenhum sabia quem
# a largou nem para que: a venda do celeiro trocava-lhe o modo, e a moeda largada
# ao lado de um vagabundo pagava a Casa de Treino onde ele estava.
#
# O destino resolve-se agora NO GESTO, com a mesma conta que o painel de contexto
# e o PriceTag fazem: o sitio de obra debaixo do rei, ou nenhum. So esse sitio
# absorve a moeda. Uma moeda sem destino — a do chao, a da caca, a da venda —
# apanha-se, mas nao paga nada sozinha. "Se o ves, funciona; se nao funciona,
# nao o ves."
#
# Puro: recebe as obras e as moedas ja carregadas.
class_name CoinTarget
extends RefCounted

## Sem destino: apanha-se e nao paga nada.
const NENHUM := -1
## Qualquer obra em cujo raio caia. E o que o CoinSystem.drop() da a quem nao diz
## o destino — os testes de um sistema so, que nao passam pelo Verbo 1.
const QUALQUER := -2
const METADE := 0.5


## O sitio de obra que o Verbo 1 paga quando largado em `x`, ou NENHUM. O nucleo
## nao e sitio de obra (§10): o que ele leva, leva-o o FieldWork.claims().
static func slot_at(obras: BuildSystem, x: float, faixa: int) -> int:
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO or int(vaga.band) != faixa:
			continue
		if absf(vaga.x - x) <= vaga.width * METADE:
			return vaga.id
	return NENHUM


## Carimba o destino de uma moeda acabada de largar em `x`: a obra debaixo de
## quem a largou, se foi o rei; NENHUM se caiu de outra coisa — da venda, da
## caca, de quem morreu (§02: so o jogador paga).
static func aim(moedas: CoinSystem, coin_id: int, obras: BuildSystem, do_rei: bool) -> void:
	var i := moedas.index_of(coin_id)
	var faixa := int(moedas.bands[i])
	moedas.targets[i] = slot_at(obras, moedas.xs[i], faixa) if do_rei else NENHUM


## Se a moeda `c`, pousada, paga a obra `vaga`: foi largada para ela, ou foi
## largada sem destino declarado e caiu dentro do raio dela.
static func pays(moedas: CoinSystem, c: int, vaga: BuildSlot) -> bool:
	if moedas.settled[c] == 0 or moedas.bands[c] != int(vaga.band):
		return false
	if moedas.targets[c] == vaga.id:
		return true
	return moedas.targets[c] == QUALQUER and absf(moedas.xs[c] - vaga.x) <= vaga.width * METADE


## Um save anterior ao destino nao o traz: as moedas que ja la estavam ficam sem
## destino, e apanham-se como as outras (§62, degradar em vez de recusar).
static func pad(moedas: CoinSystem) -> void:
	var antes := moedas.targets.size()
	moedas.targets.resize(moedas.ids.size())
	for k in range(antes, moedas.ids.size()):
		moedas.targets[k] = NENHUM
