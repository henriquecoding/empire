class_name ImperialSuccession
extends RefCounted


static func at_house() -> bool:
	var field := SimLoop.field
	if (
		field == null
		or not field.succession.ready()
		or field.succession.declined
		or field.crown_drop.down
	):
		return false
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	var house := field.succession.house(SimLoop.builds)
	return (
		r >= 0
		and units.alive(r)
		and units.healths[r] > 0
		and house != null
		and units.bands[r] == house.band
		and absf(units.xs[r] - house.x) <= house.catch_half()
	)


## A mesma validacao ao abrir e confirmar. Nao ha uma segunda coroa nem um tick
## entre consumir o herdeiro, cancelar os gestos e assumir o perfil escolhido.
static func exchange(profile: StringName) -> bool:
	if (
		not at_house()
		or not Registry.has_entry(&"monarchs", profile)
		or profile == MonarchWatch.data().id
	):
		return false
	var field := SimLoop.field
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	var data := Registry.entry(&"monarchs", profile) as MonarchData
	var body := Registry.entry(&"units", data.unit) as UnitData
	var companion := field.monarchy.companion_index(units, SimLoop.king_id)
	var health_ratio := float(units.healths[r]) / units.max_healths[r]
	var before := Registry.entry(&"units", units.data_ids[r]) as UnitData
	if before.ammo > 0:
		field.succession.personal_stock[field.monarchy.current()] = {
			&"arrows": field.supply.left(units, r, before),
			&"credit": int(field.supply.credit.get(SimLoop.king_id, 0))
		}
	var stock: Dictionary = field.succession.personal_stock.get(profile, {})
	Monarchy.embody(units, r, body)
	units.healths[r] = maxi(1, floori(health_ratio * body.max_health))
	if companion >= 0:
		Monarchy.embody(units, companion, Registry.entry(&"units", data.companion))
	field.monarchy.profile = profile
	field.monarchy.generation += 1
	field.succession.days = 0
	field.succession.lost = false
	field.succession.recovery_nights = SimFactory.curve().heir_recovery_nights
	if body.ammo > 0:
		field.supply.arm(units, r, body, int(stock.get(&"arrows", 0)))
		field.supply.credit[SimLoop.king_id] = int(stock.get(&"credit", 0))
	SimLoop.intents.clear()
	SimLoop.combat.manual.cancel()
	units.clear_target(SimLoop.king_id)
	units.pilot = UnitSystem.NENHUM
	MonarchWatch.sync()
	return true


static func bonus() -> float:
	if SimLoop.field == null:
		return 1.0
	var curve := SimFactory.curve()
	var remaining := SimLoop.field.succession.recovery_nights
	if remaining <= 0 or curve.heir_recovery_nights <= 0:
		return 1.0
	return lerpf(
		curve.heir_boost_inheritance, 1.0, 1.0 - float(remaining) / curve.heir_recovery_nights
	)
