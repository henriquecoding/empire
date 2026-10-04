class_name WallCrew
extends RefCounted


## Ter um construtor permite pagar; a presenca dele na obra e que a faz avancar.
static func available(unidades: UnitSystem, faixa: Band.Kind, dono: int = 0) -> bool:
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		if dono > 0 and unidades.owners[i] != dono:
			continue
		if unidades.healths[i] <= 0 or unidades.bands[i] != int(faixa):
			continue
		if unidades.data_ids[i] == RepairWork.REPAIRER:
			return true
	return false
