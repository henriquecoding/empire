class_name RealmReadout
extends RefCounted

const PERCENT := 100.0


static func purse() -> Vector2i:
	if SimLoop.units == null:
		return Vector2i.ZERO
	var index := SimLoop.units.index_of(Assume.driven())
	if index < 0:
		return Vector2i.ZERO
	return Vector2i(SimLoop.units.carried_coins[index], SimLoop.units.coin_capacities[index])


static func core_health() -> int:
	var best := float(-1)
	if SimLoop.builds == null or not RealmLadder.founded(SimLoop.builds):
		return -1
	for slot: BuildSlot in SimLoop.builds.slots:
		if slot.kind == BuildSlot.NUCLEO:
			best = maxf(best, float(slot.health) / maxf(1.0, float(slot.max_health())))
	return roundi(best * PERCENT) if best >= 0.0 else -1


static func overview() -> String:
	if SimLoop.state == null or SimLoop.field == null:
		return ""
	var coins := purse()
	var wages := SimLoop.economy.upkeep(SimLoop.field.upkeep.troops(SimLoop.units, SimLoop.king_id))
	var core := core_health()
	var core_text := str(core) + "%" if core >= 0 else _tr(&"HUD_NOT_FOUNDED")
	var values := {
		"bag": coins.x,
		"cap": coins.y,
		"troops": GameplayGuide.troops(),
		"wages": ("%.1f" % wages).replace(".", HudText.tr_decimal()),
		"greed": SimLoop.state.greed,
		"core": core_text,
		"spirit": roundi(SimLoop.field.spirit.value(ClockService.clock.day)),
		"torches": SimLoop.night.dark.torch.torches,
		"seeds": SimLoop.state.royal_seeds,
	}
	var lines := PackedStringArray([SeasonText.of(SimLoop.field, SimLoop.state.day), ""])
	for key: StringName in [
		&"HUD_DETAIL_PURSE",
		&"HUD_DETAIL_TROOPS",
		&"HUD_DETAIL_WAGES",
		&"HUD_DETAIL_CORE",
		&"HUD_DETAIL_GREED",
		&"HUD_DETAIL_SPIRIT",
		&"HUD_DETAIL_TORCHES",
		&"HUD_DETAIL_SEEDS"
	]:
		lines.append(_tr(key).format(values))
	return "\n".join(lines)


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)
