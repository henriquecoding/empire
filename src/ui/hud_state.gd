class_name HudState
extends RefCounted


static func mode() -> StringName:
	if SimLoop.builds != null and SimLoop.builds.fallen(BuildSlot.NUCLEO):
		return &"defeat"
	return &"playing" if SimLoop.running() else &"paused"


static func context_key() -> StringName:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM:
		return &"HUD_EXPLORE"
	var x := SimLoop.units.xs[i]
	for passage in SimLoop.passages:
		if absf(x - passage) <= Band.PASSAGE_PX:
			return &"HUD_PASSAGE"
	for slot in SimLoop.builds.slots:
		if int(slot.band) == SimLoop.units.bands[i] and PriceTag.over(slot, x):
			if PriceTag.owed_by(slot) > 0:
				return &"HUD_BUILD"
	if SimLoop.night.rot != null and SimLoop.night.rot.active():
		return &"HUD_NIGHT"
	return &"HUD_EXPLORE"
