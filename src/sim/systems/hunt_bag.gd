# src/sim/systems/hunt_bag.gd — o saco do cacador: guardar a caca e entrega-la ao rei
# (§02, Q-111). Saiu do HuntingSystem, que chegou as 250 linhas do §28 com a ADR 0057.
# `bagged` e o livro de quanto de caca cada cacador teu leva (id -> moedas).
class_name HuntBag
extends RefCounted


## O cacador teu guarda a moeda da caca no saco, se couber (§02: o arqueiro leva
## 11). Devolve o que fica para cair no chao: a caca de quem nao e de ninguem, e
## a que nao cabe.
static func bag(
	bagged: Dictionary, units: UnitSystem, drops: Array[Dictionary]
) -> Array[Dictionary]:
	var chao: Array[Dictionary] = []
	for d in drops:
		var i := units.index_of(d.get(&"hunter", RecruitSystem.NENHUM))
		var quanto: int = d[&"amount"]
		if i < 0 or units.owners[i] == RecruitSystem.SEM_DONO or d.has(HuntingSystem.GROUND):
			chao.append(d)
			continue
		if units.carried_coins[i] + quanto > units.coin_capacities[i]:
			chao.append(d)
			continue
		units.carried_coins[i] += quanto
		bagged[units.ids[i]] = int(bagged.get(units.ids[i], 0)) + quanto
	return chao


## Quem leva caca e esta a `alcance` do rei, na mesma faixa, entrega-lha — ate
## onde o saco do rei chegar. Devolve quantas moedas entraram no saco do rei.
static func deliver(bagged: Dictionary, units: UnitSystem, rei: int, alcance: float) -> int:
	var r := units.index_of(rei)
	if r < 0 or not units.alive(r):
		return 0
	var entregue := 0
	var ordem := bagged.keys()
	ordem.sort()
	for quem in ordem:
		var i := units.index_of(quem)
		if i < 0 or not units.alive(i):
			bagged.erase(quem)
			continue
		if units.bands[i] != units.bands[r] or absf(units.xs[i] - units.xs[r]) > alcance:
			continue
		var cabe := units.coin_capacities[r] - units.carried_coins[r]
		var n := mini(mini(int(bagged[quem]), units.carried_coins[i]), cabe)
		if n <= 0:
			continue
		units.carried_coins[i] -= n
		units.carried_coins[r] += n
		entregue += n
		bagged[quem] = int(bagged[quem]) - n
		if bagged[quem] <= 0:
			bagged.erase(quem)
	return entregue
