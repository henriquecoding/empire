# src/sim/systems/recruit_system.gd — o minuto 0:20 do §25 (F1-04).
#
# Duas frases do dossie, e o jogo inteiro pendurado nelas:
#
#   "O vagabundo segue-te. Largas uma moeda perto dele."
#   "Ele apanha-a e ganha um chapeu. Nada mais e preciso dizer."
#
# E o Verbo 1 a servir para a primeira coisa que serve (§61): a moeda sai da mao,
# faz o arco, pousa, e o que estava ali deixa de ser de ninguem e passa a ser
# teu. Nao ha botao, nao ha menu e nao ha caixa de texto — e a regra do §25.
#
# Puro: nao e Node, nao conhece o Registry nem o EventBus, e recebe a curva no
# construtor como o CoinSystem recebe a dele. Quem enfileira os eventos e o
# SimLoop, porque a simulacao nao emite (§43, passo 11).
#
# O que NAO esta aqui, e nao e esquecimento: oficios e postos sao o F1-05, e e o
# JobSystem que vai dar trabalho a quem hoje anda atras do rei. A condicao de
# seguir ja esta escrita a pensar nisso — segue quem NAO tem posto — e por isso
# o F1-05 tira gente da fila sem tocar neste ficheiro.
class_name RecruitSystem
extends RefCounted

## O dono de quem nao e de ninguem. O §45 diz que os ids comecam em 1 para que
## o 0 nunca seja um id valido e sirva de "nenhum"; um vagabundo nasce assim.
const SEM_DONO := 0

const NENHUM := -1

## De que lado fica quem esta exatamente em cima do rei. Nao e balanceamento e
## por isso nao vai para data/: e uma direccao — atras, que num mundo de uma
## linha e a esquerda.
const ATRAS := -1.0

## As chaves do que pickup() devolve. Ficam aqui e nao em strings soltas pelo
## caminho: quem le do outro lado le estas.
const UNIDADE := &"unit_id"
const MOEDAS := &"amount"
const RECRUTADO := &"hired"
const PRECO := &"price"

var _curva: EconomyCurve


func _init(curva: EconomyCurve) -> void:
	assert(curva != null, "o RecruitSystem precisa de um EconomyCurve")
	_curva = curva


## Passo 4 do §43 — intencao de movimento, que e o que este passo escreve.
##
## Quem ainda nao e de ninguem anda para a moeda pousada mais proxima. "Perto"
## e o recruit_notice_px: sem tecto, um vagabundo do outro lado do mapa punha-se
## a caminho de uma moeda que o jogador largou para outra pessoa.
##
## So moedas POUSADAS: uma moeda ainda no ar nao e um destino, e persegui-la
## dava-lhe uma corrida atras de um arco.
##
## FATIADO pelo mesmo criterio da FSM (§52), e nao por economia cega: escolher
## para que moeda se anda E uma decisao, e "o movimento e o combate continuam a
## correr todos os ticks — e so a DECISAO que e fatiada". O custo aqui e o
## PRODUTO de unidades por moedas, e medido sem fatiar dava 3,9 ms por tick com
## 300 vagabundos e 60 moedas — a simulacao inteira do §63 tem 4,0. O §63 diz
## qual e a alavanca antes de se optimizar codigo, e e esta.
##
## Uma moeda apanhada por outro deixa quem vinha a caminho a andar para um
## sitio vazio durante ate cinco ticks. E um sexto de segundo, e e o mesmo
## atraso que a §52 ja aceita para tudo o resto.
func seek_coins(unidades: UnitSystem, moedas: CoinSystem, tick: int) -> void:
	if moedas.count() == 0:
		return
	for i in unidades.count():
		if unidades.owners[i] != SEM_DONO or not unidades.alive(i):
			continue
		if not UnitFsm.decides(unidades.ids[i], tick):
			continue
		var alvo := _moeda_mais_proxima(moedas, unidades.xs[i], unidades.bands[i])
		if alvo == NENHUM:
			unidades.target_ids[i] = UnitSystem.NENHUM
			continue
		# QUAL moeda, e nao so para onde: o passo 5 apanha a moeda por que se
		# veio, e nao varre o chao todo a procura de uma. E o target_ids do §45,
		# que estava na coluna a espera de quem o escrevesse.
		unidades.target_ids[i] = moedas.ids[alvo]
		unidades.set_target_x(unidades.ids[i], moedas.xs[alvo])


## Passo 4 tambem: quem ja e teu e ainda nao tem posto anda atras de ti.
##
## A forma da fila e a do §50 — `base + i * espacamento`, posicoes ATRIBUIDAS e
## nao emergentes, por id crescente para que nao vibrem nem se empurrem. O §50
## escreve-a para quem espera vez num muro; e a mesma pergunta e fica a mesma
## resposta, com numeros proprios (Q-063).
func follow(unidades: UnitSystem, king_id: int) -> void:
	var rei := unidades.index_of(king_id)
	if rei == NENHUM or not unidades.alive(rei):
		return
	var dono := unidades.owners[rei]
	var seguidores := _seguidores(unidades, king_id, dono)
	var rei_x := unidades.xs[rei]
	for lugar in seguidores.size():
		var i := unidades.index_of(seguidores[lugar])
		var recuo := _curva.follow_distance_px + lugar * _curva.follow_spacing_px
		unidades.set_target_x(seguidores[lugar], rei_x + _lado(unidades.xs[i], rei_x) * recuo)


## O recrutamento em si, e o unico sitio onde ele acontece. Devolve verdadeiro
## quando esta moeda comprou esta pessoa.
##
## O preco e o recruit_cost do UnitData e nao um numero deste ficheiro: o §07 da
## um custo a cada tropa, e um vagabundo custa 1. Quem paga menos do que isso nao
## compra nada — e a moeda ja foi apanhada e fica com ele, que e o que acontece
## no Kingdom e e o que o §25 desenha.
func hire(unidades: UnitSystem, unit_id: int, dono: int, pago: int, preco: int) -> bool:
	var i := unidades.index_of(unit_id)
	if i == NENHUM or unidades.owners[i] != SEM_DONO or not unidades.alive(i):
		return false
	if dono == SEM_DONO or pago < preco:
		return false
	unidades.owners[i] = dono
	return true


## Passo 5 do §43, a seguir ao movimento: quem chegou a uma moeda apanha-a, e
## quem ainda nao era de ninguem e acabou de apanhar o seu preco passa a ser teu.
##
## As duas coisas sao consequencia de ter CHEGADO, e por isso correm depois do
## movimento e nao antes. O §43 nao tem um passo para a apanha — a Q-063 diz
## porque e que ela mora no passo 5, como a Q-061 disse do arco.
##
## Devolve o que aconteceu, por unidade; quem chama e que anuncia (§43, passo 11).
func pickup(unidades: UnitSystem, moedas: CoinSystem, king_id: int) -> Array[Dictionary]:
	var apanhas: Array[Dictionary] = []
	if moedas.count() == 0:
		return apanhas
	var dono_do_rei := owner_of(unidades, king_id)
	# Por id crescente (§42): duas unidades a caminho da mesma moeda tem de dar
	# sempre a mesma vencedora, e a ordem das colunas nao e estavel.
	var por_id := unidades.ids.duplicate()
	por_id.sort()
	for unit_id in por_id:
		var apanha := _apanhar(unidades, moedas, unit_id, dono_do_rei)
		if not apanha.is_empty():
			apanhas.append(apanha)
	return apanhas


## De quem sao os recrutados. Sem rei em campo nao ha recrutamento: a moeda foi
## apanhada na mesma — o §25 desenha isso — mas nao comprou ninguem.
func owner_of(unidades: UnitSystem, king_id: int) -> int:
	var rei := unidades.index_of(king_id)
	if rei == NENHUM:
		return SEM_DONO
	return unidades.owners[rei]


func _apanhar(
	unidades: UnitSystem, moedas: CoinSystem, unit_id: int, dono_do_rei: int
) -> Dictionary:
	var i := unidades.index_of(unit_id)
	var moeda := unidades.target_ids[i]
	if moeda == UnitSystem.NENHUM or not unidades.alive(i):
		return {}
	var espaco := unidades.coin_capacities[i] - unidades.carried_coins[i]
	if espaco <= 0:
		return {}
	var era_de_ninguem := vagrant(unidades, i)
	var apanhado := moedas.collect_one(
		moeda, unidades.xs[i], unidades.bands[i] as Band.Kind, espaco
	)
	if apanhado <= 0:
		return {}
	unidades.target_ids[i] = UnitSystem.NENHUM
	unidades.carried_coins[i] += apanhado
	var preco := unidades.recruit_costs[i]
	# Conta o SACO e nao a moeda que acabou de apanhar. O §07 da precos de 1 a
	# 18, e a moeda da §02 vale uma: comparar com a ultima apanhada so deixava
	# recrutar quem custa 1, e o arqueiro do minuto 1:10 (§25) nunca seria teu.
	# Ele fica com o que apanhou — e o que o §25 desenha e o teste do F1-04 fixa.
	var comprado := (
		era_de_ninguem and hire(unidades, unit_id, dono_do_rei, unidades.carried_coins[i], preco)
	)
	return {UNIDADE: unit_id, MOEDAS: apanhado, RECRUTADO: comprado, PRECO: preco}


## Verdadeiro se esta unidade ainda nao e de ninguem — o que o ecra mostra como
## "sem chapeu" (§25). Fica aqui, e nao espalhado por comparacoes a SEM_DONO,
## para que o dia em que "ser recrutado" deixar de ser "ter dono" se mude num
## sitio so.
func vagrant(unidades: UnitSystem, i: int) -> bool:
	return unidades.owners[i] == SEM_DONO


## A moeda pousada mais proxima dentro do raio de reparo, ou NENHUM. Empate pelo
## indice menor, que e estavel porque as colunas sao percorridas por ordem.
func _moeda_mais_proxima(moedas: CoinSystem, x: float, faixa: int) -> int:
	var melhor := NENHUM
	var melhor_d := _curva.recruit_notice_px
	for c in moedas.count():
		if moedas.settled[c] == 0 or moedas.bands[c] != faixa:
			continue
		var d := absf(moedas.xs[c] - x)
		if d < melhor_d:
			melhor_d = d
			melhor = c
	return melhor


## Quem segue, POR ID CRESCENTE: vivo, teu, sem posto, e nao es tu proprio.
##
## Devolve ids e nao indices porque a ordem das colunas nao e estavel — o
## remove() troca a unidade removida com a ultima (§42). Ordenar indices dava
## uma fila que se reordenava sozinha a cada morte, e cada um mudava de lugar
## sem se ter mexido.
func _seguidores(unidades: UnitSystem, king_id: int, dono: int) -> PackedInt32Array:
	var lista := PackedInt32Array()
	for i in unidades.count():
		if unidades.ids[i] == king_id or unidades.owners[i] != dono:
			continue
		if unidades.job_ids[i] != UnitSystem.NENHUM or not unidades.alive(i):
			continue
		lista.append(unidades.ids[i])
	lista.sort()
	return lista


## De que lado do rei fica quem o segue: o lado em que ja esta. Quem esta
## exatamente em cima dele vai para tras — a esquerda — porque um recuo de zero
## punha-o dentro do rei.
func _lado(x: float, rei_x: float) -> float:
	if is_equal_approx(x, rei_x):
		return ATRAS
	return signf(x - rei_x)
