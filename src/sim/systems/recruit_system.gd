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
# Depois de recrutada, a pessoa nao anda atras do rei: vai para o nucleo e espera
# la por trabalho, como no Kingdom: New Lands (Q-063) — e o Retinue. O JobSystem
# e que a tira de la, e quem tem posto nao espera por ninguem.
class_name RecruitSystem
extends RefCounted

## O dono de quem nao e de ninguem. O §45 diz que os ids comecam em 1 para que
## o 0 nunca seja um id valido e sirva de "nenhum"; um vagabundo nasce assim.
const SEM_DONO := 0

const NENHUM := -1

## As chaves do que pickup() devolve. Ficam aqui e nao em strings soltas pelo
## caminho: quem le do outro lado le estas.
const UNIDADE := &"unit_id"
const MOEDAS := &"amount"
const RECRUTADO := &"hired"
const PRECO := &"price"

## O desconto de recrutamento do povo de cada regiao da campanha, pela ordem das
## regioes (§04: a Horta tem "tropas baratissimas", Q-007). Escrito pelo SimFactory.
var cost_deltas: PackedInt32Array = PackedInt32Array()
## O estado em que se joga: a regiao dele diz que desconto vale agora.
var state: GameState
## Os ids de dados que andam atras do rei (a tag `follows_king`: o escudeiro).
var followers: Dictionary = {}
## Quem desertou por soldo em atraso: id -> o dia a partir do qual volta a poder ser
## recrutado (Q-144). Partilhado com o UpkeepSystem, que o escreve e o grava.
var resting: Dictionary = {}
## Ritmo derivado do alvo deste tick; nao altera velocidades nem entra no save.
var rush: Dictionary = {}

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
## Escolher e fatiado; perder a moeda cancela o movimento ja neste tick.
func seek_coins(unidades: UnitSystem, moedas: CoinSystem, tick: int) -> void:
	rush.clear()
	for i in unidades.count():
		if unidades.owners[i] != SEM_DONO or not unidades.alive(i):
			continue
		var alvo := moedas.index_of(unidades.target_ids[i])
		if alvo != NENHUM and not _eligible(moedas, alvo, unidades, i):
			alvo = NENHUM
		if resting.has(unidades.ids[i]) and resting_now(unidades.ids[i]):
			alvo = NENHUM
		elif UnitFsm.decides(unidades.ids[i], tick):
			alvo = _moeda_mais_proxima(moedas, unidades, i)
		if alvo == NENHUM:
			unidades.target_ids[i] = UnitSystem.NENHUM
			if unidades.has_targets[i] != 0:
				unidades.clear_target(unidades.ids[i])
			continue
		# QUAL moeda, e nao so para onde: o passo 5 apanha a moeda por que se
		# veio, e nao varre o chao todo a procura de uma. E o target_ids do §45,
		# que estava na coluna a espera de quem o escrevesse.
		unidades.target_ids[i] = moedas.ids[alvo]
		unidades.set_target_x(unidades.ids[i], moedas.xs[alvo])
		rush[unidades.ids[i]] = _curva.recruit_run_mult


## Passo 4 tambem: quem ja e teu e ainda nao tem posto. O escudeiro anda atras
## de ti; os outros vao para o nucleo e esperam la — o minuto 0:20 do Kingdom:
## New Lands, que o dono pediu (Q-063). As posicoes sao do Retinue.
func follow(unidades: UnitSystem, king_id: int, nucleo_x: float) -> void:
	Retinue.place(
		unidades, king_id, nucleo_x, followers, _curva.follow_distance_px, _curva.follow_spacing_px
	)


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
	if dono == SEM_DONO or pago < preco or resting_now(unit_id):
		return false
	unidades.owners[i] = dono
	rush.erase(unit_id)
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
	var c := moedas.index_of(moeda)
	if not _eligible(moedas, c, unidades, i):
		return {}
	var era_de_ninguem := vagrant(unidades, i)
	var apanhado := moedas.collect_one(
		moeda, unidades.xs[i], unidades.bands[i] as Band.Kind, espaco
	)
	if apanhado <= 0:
		return {}
	unidades.target_ids[i] = UnitSystem.NENHUM
	unidades.clear_target(unit_id)
	rush.erase(unit_id)
	unidades.carried_coins[i] += apanhado
	var preco := price(unidades, i)
	# Conta o SACO e nao a moeda que acabou de apanhar. O §07 da precos de 1 a
	# 18, e a moeda da §02 vale uma: comparar com a ultima apanhada so deixava
	# recrutar quem custa 1, e o arqueiro do minuto 1:10 (§25) nunca seria teu.
	# Ele fica com o que apanhou — e o que o §25 desenha e o teste do F1-04 fixa.
	var comprado := (
		era_de_ninguem and hire(unidades, unit_id, dono_do_rei, unidades.carried_coins[i], preco)
	)
	return {UNIDADE: unit_id, MOEDAS: apanhado, RECRUTADO: comprado, PRECO: preco}


## Se quem desertou ainda nao quer voltar (Q-144).
func resting_now(unit_id: int) -> bool:
	return state != null and int(resting.get(unit_id, 0)) > state.day


## Quanto custa comprar esta pessoa aqui: o recruit_cost dela com o desconto do
## povo da regiao (Q-007). O PriceTag mostra este numero, e nao o da coluna.
func price(unidades: UnitSystem, i: int) -> int:
	var delta := 0
	if state != null and state.region >= 0 and state.region < cost_deltas.size():
		delta = cost_deltas[state.region]
	return discounted(unidades.recruit_costs[i], delta)


## "-1 moeda no recrutamento, minimo 1" (Q-007). Quem nao custava nada continua.
static func discounted(base: int, delta: int) -> int:
	if delta == 0 or base <= 0:
		return base
	return maxi(1, base + delta)


## Verdadeiro se esta unidade ainda nao e de ninguem — o que o ecra mostra como
## "sem chapeu" (§25). Fica aqui, e nao espalhado por comparacoes a SEM_DONO,
## para que o dia em que "ser recrutado" deixar de ser "ter dono" se mude num
## sitio so.
func vagrant(unidades: UnitSystem, i: int) -> bool:
	return unidades.owners[i] == SEM_DONO


## A moeda pousada mais proxima dentro do raio de reparo, ou NENHUM. Empate pelo
## indice menor, que e estavel porque as colunas sao percorridas por ordem.
func _moeda_mais_proxima(moedas: CoinSystem, unidades: UnitSystem, i: int) -> int:
	var melhor := NENHUM
	var melhor_d := _curva.recruit_notice_px
	var x := unidades.xs[i]
	var faixa := unidades.bands[i]
	var espaco := unidades.coin_capacities[i] - unidades.carried_coins[i]
	for c in moedas.count():
		if moedas.settled[c] == 0 or moedas.bands[c] != faixa or moedas.targets[c] >= 0:
			continue
		var d := absf(moedas.xs[c] - x)
		if d > melhor_d or moedas.amounts[c] > espaco:
			continue
		if d == melhor_d and melhor != NENHUM and moedas.ids[c] > moedas.ids[melhor]:
			continue
		melhor_d = d
		melhor = c
	return melhor


func _eligible(moedas: CoinSystem, c: int, unidades: UnitSystem, i: int) -> bool:
	return (
		c != NENHUM
		and moedas.settled[c] != 0
		and moedas.targets[c] < 0
		and moedas.bands[c] == unidades.bands[i]
		and moedas.amounts[c] <= unidades.coin_capacities[i] - unidades.carried_coins[i]
	)
