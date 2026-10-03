# src/sim/systems/supply.gd — o que as tropas levam para a batalha, e o reino repoe (Q-163,
# o dono a 30/09/2026).
#
# O dono: "as classes jogaveis nao tem recursos de batalha limitados, mas faz sentido as
# tropas terem recursos limitados, ou um certo tipo de limitacao, que tem que estar
# sempre a economia em dia para manter o armazenamento do exercito em dia". O arqueiro
# leva uma aljava (units.csv, `ammo`): cada tiro gasta uma flecha, e com a aljava vazia
# nao dispara. A alvorada o reino repoe as aljavas das tuas tropas, na banca do arco, a
# um preco por flecha — pago do saco do rei, pela ordem dos ids, enquanto chegar. Um
# corpo de classe jogavel nao tem teto (`ammo` 0), e o rei tambem nao.
#
# O Imperador Arqueiro tem aljava, e e dele (ADR 0052, Q-200): a banca nao a repoe. So o
# escudeiro dele a enche, pago com as moedas da bolsa dele — sem moedas, nao ha flechas
# novas; sem espaco, nao ha cobranca; e o que um lote traz e nao cabe fica pago, em
# credito, para a reposicao seguinte.
#
# Puro: as tropas, os dados, a bolsa e o preco entram de fora.
class_name Supply
extends RefCounted

const NENHUM := -1

## As flechas que cada tropa ja gastou da aljava: unit id -> quantas.
var spent: Dictionary = {}
## As aljavas pessoais, que a banca nao repoe: unit id -> true (Q-200).
var personal: Dictionary = {}
## As flechas pagas que nao couberam: unit id -> quantas (Q-200).
var credit: Dictionary = {}


## Se a tropa `i` ainda tem com que disparar. Sem teto, tem sempre.
func can_shoot(unidades: UnitSystem, i: int, dados: UnitData) -> bool:
	return dados == null or dados.ammo <= 0 or int(spent.get(unidades.ids[i], 0)) < dados.ammo


## Um tiro: gasta uma flecha a quem tem aljava.
func shoot(unidades: UnitSystem, i: int, dados: UnitData) -> void:
	if dados != null and dados.ammo > 0:
		spent[unidades.ids[i]] = int(spent.get(unidades.ids[i], 0)) + 1


## As flechas que faltam a tropa `i`, e as que ainda leva.
func missing(unidades: UnitSystem, i: int) -> int:
	return int(spent.get(unidades.ids[i], 0))


func left(unidades: UnitSystem, i: int, dados: UnitData) -> int:
	return maxi(0, dados.ammo - missing(unidades, i)) if dados != null and dados.ammo > 0 else 0


## Uma aljava pessoal com `flechas` dentro (o imperador ao comecar ou ao ser coroado).
func arm(unidades: UnitSystem, i: int, dados: UnitData, flechas: int) -> void:
	var unit_id := unidades.ids[i]
	personal[unit_id] = true
	credit.erase(unit_id)
	var falta := dados.ammo - clampi(flechas, 0, dados.ammo) if dados != null else 0
	if falta > 0:
		spent[unit_id] = falta
	else:
		spent.erase(unit_id)


## O escudeiro do imperador `i` enche-lhe a aljava: o credito primeiro, e depois uma moeda
## da bolsa dele por `por_moeda` flechas. Devolve as moedas gastas — 0 sem espaco, sem
## moeda, ou com o credito a chegar.
func refill(unidades: UnitSystem, i: int, dados: UnitData, por_moeda: int) -> int:
	var unit_id := unidades.ids[i]
	var falta := missing(unidades, i)
	if dados == null or dados.ammo <= 0 or falta <= 0:
		return 0
	var credito := int(credit.get(unit_id, 0))
	var gasto := 0
	if credito <= 0:
		if unidades.carried_coins[i] <= 0 or por_moeda <= 0:
			return 0
		unidades.carried_coins[i] -= 1
		gasto = 1
		credito = por_moeda
	var repor := mini(falta, credito)
	_guardar(spent, unit_id, falta - repor)
	_guardar(credit, unit_id, credito - repor)
	return gasto


## Quantas tropas vivas do dono do `rei` ja gastaram flechas: o guia pede a banca.
func short(unidades: UnitSystem, rei: int) -> int:
	var r := unidades.index_of(rei)
	var n := 0
	for unit_id: int in spent if r != NENHUM else {}:
		var i := unidades.index_of(unit_id)
		if i != NENHUM and unidades.alive(i) and unidades.owners[i] == unidades.owners[r]:
			n += 1
	return n


## Se a obra que faz as flechas (rules.csv, `ammo_depot`) esta de pe.
static func depot(obras: BuildSystem, banca: StringName) -> bool:
	return (
		obras != null and obras.standing().any(func(v: BuildSlot) -> bool: return v.kind == banca)
	)


## A alvorada: repoe as aljavas de quem e de `dono`, pela ordem dos ids, com `bolsa`
## moedas no maximo e `por_moeda` flechas por moeda. Quem morreu, saiu ou deixou de ser
## teu esquece-se. Devolve as moedas gastas.
func restock(unidades: UnitSystem, dono: int, bolsa: int, por_moeda: int) -> int:
	var gasto := 0
	var credito := 0
	var ids := spent.keys()
	ids.sort()
	for unit_id: int in ids:
		var i := unidades.index_of(unit_id)
		if i == NENHUM or not unidades.alive(i):
			spent.erase(unit_id)
			continue
		if unidades.owners[i] != dono or personal.has(unit_id):
			continue
		var falta := int(spent[unit_id])
		while falta > 0:
			if credito <= 0:
				if gasto >= bolsa or por_moeda <= 0:
					break
				gasto += 1
				credito += por_moeda
			var repor := mini(falta, credito)
			falta -= repor
			credito -= repor
		if falta > 0:
			spent[unit_id] = falta
		else:
			spent.erase(unit_id)
	return gasto


func to_dict() -> Dictionary:
	return {
		&"spent": spent.duplicate(),
		&"personal": personal.duplicate(),
		&"credit": credit.duplicate()
	}


## Um save de antes das aljavas: todas cheias. De antes dos monarcas: nenhuma pessoal.
func from_dict(d: Dictionary) -> void:
	spent = _ints(d.get(&"spent", {}))
	credit = _ints(d.get(&"credit", {}))
	personal = {}
	for unit_id: int in _ints(d.get(&"personal", {})):
		personal[unit_id] = true


static func _ints(valor: Variant) -> Dictionary:
	var saida := {}
	for chave: Variant in valor if valor is Dictionary else {}:
		saida[int(chave)] = int(valor[chave])
	return saida


static func _guardar(registo: Dictionary, unit_id: int, quanto: int) -> void:
	if quanto > 0:
		registo[unit_id] = quanto
	else:
		registo.erase(unit_id)
