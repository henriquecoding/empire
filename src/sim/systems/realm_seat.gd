# src/sim/systems/realm_seat.gd — o que a sede guarda fora das obras (ADR 0059).
#
# A carroca de provisoes da chegada (plano do reino §6.2): uma bolsa unica, posta ao
# pe da Clareira, que o monarca leva ao passar. Nao e o bau da sala secreta (ADR 0053),
# que continua a comecar vazio; e nao volta ao carregar um save, ao trocar de monarca
# nem na sucessao — vem com a fundacao, e a fundacao e uma por partida.
#
# O alvo da moeda no nucleo (plano §3.6, §23.2): ate aqui uma moeda largada no nucleo
# evoluia o monarca sempre que ele podia, por ordem do codigo. Agora o nucleo tem dois
# alvos e o jogador escolhe: a sede, por omissao, ou o monarca, quando ele pode evoluir.
#
# E a marca da sede herdada: um save de antes da fundacao trazia o castelo de pe, e o
# castelo e a Fortaleza — sem os degraus pagos (plano §27.1).
#
# Puro: recebe o sitio e o saco; quem le o mundo e o FoundationWatch.
class_name RealmSeat
extends RefCounted

## Onde esta a carroca, e o que ainda leva.
var cart_x := 0.0
var cart_coins := 0
var cart_open := true
## Verdadeiro quando o jogador escolheu evoluir o monarca no nucleo.
var monarch_aim := false
## A sede veio de um save de antes da fundacao.
var inherited := false


## Poe a carroca da chegada. Uma por fundacao: quem chama e o jogo novo.
func place_cart(x: float, moedas: int) -> void:
	cart_x = x
	cart_coins = maxi(0, moedas)


## O monarca em `x` leva da carroca o que lhe cabe no saco (`espaco`), se estiver ao
## `alcance` dela. Devolve quanto levou; o resto fica na carroca.
func take_cart(x: float, alcance: float, espaco: int) -> int:
	if not cart_open or cart_coins <= 0 or espaco <= 0 or absf(x - cart_x) > alcance:
		return 0
	var levou := mini(cart_coins, espaco)
	cart_coins -= levou
	return levou


## Troca o alvo da moeda no nucleo. So ha escolha quando o monarca pode evoluir; sem ela
## o alvo e sempre a sede. Devolve o alvo novo: verdadeiro e o monarca.
func toggle_aim(pode_evoluir: bool) -> bool:
	monarch_aim = pode_evoluir and not monarch_aim
	return monarch_aim


## Se a moeda largada no nucleo vai para o monarca: so com ele escolhido e a poder evoluir.
func aims_monarch(pode_evoluir: bool) -> bool:
	return monarch_aim and pode_evoluir


func to_dict() -> Dictionary:
	return {
		&"cart_x": cart_x,
		&"cart_coins": cart_coins,
		&"cart_open": cart_open,
		&"monarch_aim": monarch_aim,
		&"inherited": inherited,
	}


## Um save sem sede (de antes da fundacao) chega aqui ja migrado: o SaveMigrations escreve
## a marca de herdada. Campos em falta ficam como estao (§62).
func from_dict(d: Dictionary) -> void:
	cart_x = float(d.get(&"cart_x", cart_x))
	cart_coins = int(d.get(&"cart_coins", cart_coins))
	cart_open = d.get(&"cart_open", true) == true
	monarch_aim = d.get(&"monarch_aim", monarch_aim) == true
	inherited = d.get(&"inherited", inherited) == true
