# src/sim/systems/squire.gd — o escudeiro do rei (§08; Q-114, o dono a 29/09/2026).
#
# "O escudeiro tem um escudo que protege o rei. O rei pode dar 5 moedas ao
# escudeiro, que lhe deixam levar 5 golpes de inimigos fracos e 2 de inimigos
# fortes. Ao juntar 3 moedas largadas por inimigos, o escudeiro ganha uma espada
# que da 3 golpes; depois a espada parte-se e o ciclo recomeca. Com a espada, o
# escudeiro golpeia primeiro, antes de receber o golpe do inimigo. Fica sempre a
# frente do rei; so vai para tras quando esta sem escudo. Nao entrega moedas ao
# rei: o sistema dele e complementar. Evolui para cavaleiro — a investidura —,
# com um escudo mais forte, que recebe mais moedas, e uma espada de 5 golpes."
#
# O escudo guarda-se em pontos: cada moeda vale `shield_per_coin`, um golpe fraco
# gasta `weak_hit` e um forte `strong_hit` — 5 moedas x 2 = 10 pontos = 5 golpes
# de 2 ou 2 de 5. Forte e o golpe de dano `strong_from_damage` ou mais.
#
# Puro: os numeros vem do ability_params do escudeiro (units.csv).
class_name Squire
extends RefCounted

## Pontos de escudo que tem agora.
var shield := 0
## Golpes que a espada ainda da. Zero: sem espada.
var sword := 0
## Moedas caidas de inimigos juntas para a proxima espada.
var loot := 0
## Investido cavaleiro (a fase 2 do Monarca).
var knight := false

var _p: Dictionary


func _init(params: Dictionary) -> void:
	_p = params


func _n(chave: StringName) -> int:
	var cavaleiro := StringName("knight_" + String(chave))
	return int(_p.get(cavaleiro, _p.get(chave, 0))) if knight else int(_p.get(chave, 0))


## Os pontos de um escudo cheio.
func shield_cap() -> int:
	return _n(&"shield_coins") * int(_p.get(&"shield_per_coin", 0))


## Quantas moedas o escudo ainda aceita.
func coins_wanted() -> int:
	var por_moeda := int(_p.get(&"shield_per_coin", 0))
	if por_moeda <= 0:
		return 0
	return ceili(float(shield_cap() - shield) / por_moeda)


## O rei da `moedas` ao escudo. Devolve quantas ficaram nele.
func arm(moedas: int) -> int:
	var usa := mini(moedas, coins_wanted())
	shield = mini(shield_cap(), shield + usa * int(_p.get(&"shield_per_coin", 0)))
	return usa


## Moedas caidas de inimigos: ao juntar as da espada, e sem espada, ganha uma.
func take_loot(moedas: int) -> void:
	loot += moedas
	var preco := int(_p.get(&"sword_coins", 0))
	if sword == 0 and preco > 0 and loot >= preco:
		loot -= preco
		sword = _n(&"sword_strikes")


## Um golpe de `dano` contra o rei ou contra ele. Verdadeiro se o escudo o levou.
func block(dano: int) -> bool:
	if shield <= 0:
		return false
	var forte := dano >= int(_p.get(&"strong_from_damage", 0))
	shield = maxi(0, shield - int(_p.get(&"strong_hit" if forte else &"weak_hit", 0)))
	return true


## Com a espada, golpeia primeiro: o dano do golpe que da, e a espada gasta-se.
## Zero sem espada. Partida, o ciclo recomeca com as moedas que juntar.
func strike() -> int:
	if sword <= 0:
		return 0
	sword -= 1
	var dano := _n(&"sword_damage")
	take_loot(0)
	return dano


## A que distancia do rei anda, a frente ou atras.
func escort_px() -> float:
	return float(_p.get(&"escort_px", 0.0))


## Fica a frente do rei com escudo; sem ele, vai para tras.
func shielded() -> bool:
	return shield > 0


func to_dict() -> Dictionary:
	return {&"shield": shield, &"sword": sword, &"loot": loot, &"knight": knight}


func from_dict(d: Dictionary) -> void:
	shield = int(d.get(&"shield", 0))
	sword = int(d.get(&"sword", 0))
	loot = int(d.get(&"loot", 0))
	knight = bool(d.get(&"knight", false))
