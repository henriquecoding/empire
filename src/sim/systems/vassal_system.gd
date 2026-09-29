# src/sim/systems/vassal_system.gd — os povos que te pagam tributo (§13; Q-103, o dono
# a 29/09/2026).
#
# "Deve ser feito todo um sistema de vassalos e suseranos: ao conquistar um povo,
# eles continuam funcionando como imperio, mas agora geram-me um tipo de imposto
# real, dando-me recursos e moedas. O meu reino sera sempre o que eu comeco; os
# outros que assimilei podem inclusive ser conquistados ou consumidos pelo meu
# inimigo, dependendo do modo de jogo." O §13 da o numero: um povo que sobrevive
# "rende 4–6 moedas/dia para sempre".
#
# Cada vassalo tem um tributo por dia e uma firmeza. A alvorada paga o tributo de
# todos; e, no modo em que eles podem cair, cada noite gasta-lhes firmeza a razao
# da massa dela — a Podridao que tu seguras a porta tambem os come a eles. Sem
# firmeza, o vassalo e consumido e deixa de pagar.
#
# Puro: os numeros chegam de fora (economy.csv).
class_name VassalSystem
extends RefCounted

const POVO := 0
const TRIBUTO := 1
const FIRMEZA := 2
const DESDE := 3

## [povo, tributo por dia, firmeza, dia em que passou a vassalo], por ordem.
var vassals: Array = []
## A fraccao de tributo que ainda nao fez uma moeda.
var owed := 0.0


func add(povo: StringName, tributo: int, firmeza: float, dia: int) -> void:
	if not has(povo):
		vassals.append([String(povo), tributo, firmeza, dia])


func has(povo: StringName) -> bool:
	for v in vassals:
		if v[POVO] == String(povo):
			return true
	return false


func peoples() -> PackedStringArray:
	var povos := PackedStringArray()
	for v in vassals:
		povos.append(v[POVO])
	return povos


## A alvorada: `massa` e a da noite que acabou, `erosao` a firmeza que cada ponto
## dela tira; `caem` diz se o modo deixa cair vassalos. Devolve as moedas de
## tributo e os povos consumidos esta noite.
func dawn(massa: float, erosao: float, caem: bool) -> Dictionary:
	var caidos := PackedStringArray()
	var ficam: Array = []
	for v in vassals:
		if caem:
			v[FIRMEZA] = float(v[FIRMEZA]) - massa * erosao
		if float(v[FIRMEZA]) <= 0.0:
			caidos.append(v[POVO])
		else:
			ficam.append(v)
			owed += int(v[TRIBUTO])
	vassals = ficam
	var moedas := int(owed)
	owed -= moedas
	return {&"coins": moedas, &"fallen": caidos}


func to_dict() -> Dictionary:
	return {&"vassals": vassals.duplicate(true), &"owed": owed}


func from_dict(d: Dictionary) -> void:
	vassals = d.get(&"vassals", []).duplicate(true)
	owed = float(d.get(&"owed", 0.0))
