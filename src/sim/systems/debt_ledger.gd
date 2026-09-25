# src/sim/systems/debt_ledger.gd — a Divida da Candeia (§75).
#
# Um contador escondido, de 0 a debt_max. Sobe com cada oferta aceite e nunca
# desce: nao ha aqui nenhuma funcao que subtraia, e o D-06 prova-o pelos
# caminhos e nao so pelos dados. Nunca aparece como numero — o mostrador e a
# luz da candeia, e quem a desenha pergunta por limiares, nao pelo valor.
class_name DebtLedger
extends RefCounted

var debt: int = 0

var _perfil: RotProfile


func _init(perfil: RotProfile) -> void:
	_perfil = perfil


## Soma o que uma oferta aceite custa. Um delta negativo e recusado em vez de
## aplicado: a Divida nao desce, nem por engano de dados (D-06).
func add(delta: int) -> void:
	if delta <= 0:
		return
	debt = mini(debt + delta, _perfil.debt_max)


## Quantos limiares da §75 ja passaram: 0 a debt_tiers.size(). E o que a luz le.
func tier() -> int:
	var n := 0
	for limiar in _perfil.debt_tiers:
		if debt >= limiar:
			n += 1
	return n


## Aos 6 aparece o Zelador (§75).
func tender() -> bool:
	return debt >= _perfil.tender_from_debt


## Aos 9 deixa de haver escuro a noite, e as fogueiras perdem o bonus.
func ambient_light() -> bool:
	return debt >= _perfil.ambient_light_from_debt


## Aos 12 a candeia tem duas chamas e o epilogo Uniao fecha (§79).
func second_flame() -> bool:
	return debt >= _perfil.second_flame_from_debt


func to_dict() -> Dictionary:
	return {&"debt": debt}


func from_dict(d: Dictionary) -> void:
	debt = clampi(int(d.get(&"debt", debt)), 0, _perfil.debt_max)
