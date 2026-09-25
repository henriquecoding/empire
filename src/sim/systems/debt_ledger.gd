# src/sim/systems/debt_ledger.gd — a Divida da Candeia, e as recusas (§75).
#
# Um contador escondido, de 0 a debt_max. Sobe com cada oferta aceite. NUNCA
# desce: nao ha aqui nenhuma subtracao, e o D-06 guarda-o por caminhos. Nunca
# aparece como numero — o mostrador e a luz da candeia, que le os limiares.
#
# As recusas sao a outra metade: cada noite recusada nas ultimas
# refusal_window_days conta refusal_mass na massa, ate refusal_cap (o RotSystem
# faz a conta). Voltam a zero assim que se aceita uma vez.
#
# Puro. Os campos do save tem os nomes da §84: debt_lantern, refusals_by_day.
class_name DebtLedger
extends RefCounted

var debt: int = 0
## As noites em que houve recusa, por ordem. So as da janela contam.
var refusals_by_day: PackedInt32Array = PackedInt32Array()
## As ofertas de uma vez por campanha que ja foram aceites (Q-040).
var used: PackedStringArray = PackedStringArray()
## "−15% de massa, permanente" (§75): multiplica todas as noites seguintes.
var mass_mult_permanent: float = 1.0
## A decima segunda aceite: "A Podridao nao volta a nascer" (§75, §79).
var ended: bool = false

var _perfil: RotProfile


func _init(perfil: RotProfile) -> void:
	assert(perfil != null, "o DebtLedger precisa do RotProfile")
	_perfil = perfil


## Sobe, e so sobe. Um delta negativo e um erro de dados e nao um desconto.
func incur(delta: int) -> void:
	assert(delta >= 0, "a Divida da Candeia nunca desce (§75, D-06)")
	debt = mini(_perfil.debt_max, debt + maxi(0, delta))


func refuse(dia: int) -> void:
	refusals_by_day.append(dia)


## Aceitar uma vez apaga as recusas (§75). A divida fica — so as recusas saem.
func accept(_dia: int) -> void:
	refusals_by_day = PackedInt32Array()


## As recusas que contam ao crepusculo deste dia: as das ultimas N noites.
func refusals(dia: int) -> int:
	var n := 0
	for d in refusals_by_day:
		if d < dia and dia - d <= _perfil.refusal_window_days:
			n += 1
	return n


func remember(offer_id: StringName) -> void:
	if not used.has(String(offer_id)):
		used.append(String(offer_id))


## Quantos limiares da luz ja foram passados (halo, Zelador, ambar, duas chamas).
func tier() -> int:
	var n := 0
	for limiar in _perfil.debt_tiers:
		if debt >= limiar:
			n += 1
	return n


func tender() -> bool:
	return debt >= _perfil.tender_from_debt


func ambient_light() -> bool:
	return debt >= _perfil.ambient_light_from_debt


func second_flame() -> bool:
	return debt >= _perfil.second_flame_from_debt


func to_dict() -> Dictionary:
	return {
		&"debt_lantern": debt,
		&"refusals_by_day": refusals_by_day,
		&"offers_used": used,
		&"mass_mult_permanent": mass_mult_permanent,
		&"rot_ended": ended,
	}


func from_dict(d: Dictionary) -> void:
	debt = d.get(&"debt_lantern", debt)
	refusals_by_day = d.get(&"refusals_by_day", refusals_by_day)
	used = d.get(&"offers_used", used)
	mass_mult_permanent = d.get(&"mass_mult_permanent", mass_mult_permanent)
	ended = d.get(&"rot_ended", ended)
