extends RefCounted


## Uma sociedade madura para provar viagens, sem voltar ao nascimento instantaneo.
static func prepare(id: int) -> void:
	SimLoop.field.settlements.first_night_day = 1
	SocialWatch.awaken(SimLoop.field, 2)
	var record: Dictionary = SimLoop.field.settlements.records[id]
	for site in record[&"sites"]:
		var slot := SimLoop.builds.slots[SimLoop.builds.index_of(site)]
		slot.level = 1
		slot.state = BuildSlot.State.DONE
		slot.health = slot.max_health()
