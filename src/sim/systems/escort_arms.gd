# Q-200: a companhia evoluída dispara da aljava paga que abastece.
class_name EscortArms
extends RefCounted


static func source(units: UnitSystem, i: int, data: UnitData, escorts: Dictionary) -> int:
	if data == null or data.ability != &"arrow_supply":
		return i
	var patron := units.index_of(int(escorts.get(units.ids[i], UnitSystem.NENHUM)))
	if patron < 0 or not units.alive(patron) or units.healths[patron] <= 0:
		return UnitSystem.NENHUM
	if units.owners[patron] != units.owners[i] or units.bands[patron] != units.bands[i]:
		return UnitSystem.NENHUM
	return patron
