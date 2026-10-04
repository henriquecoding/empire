class_name CellarWatch
extends RefCounted

const EXCAVATION := &"cellar_excavation"
const WORKSITE_X := -612.0


static func author() -> void:
	var slot := WorldWorks.post(EXCAVATION, SimLoop.core_x + WORKSITE_X)
	var rules := LastCartWatch.rules()
	var stages := RulesFactory.realm_stages().size() - 1
	slot.costs = PackedInt32Array()
	slot.works = PackedFloat32Array()
	slot.healths = PackedInt32Array()
	for _stage in stages:
		slot.costs.append(rules.cellar_cost)
		slot.works.append(rules.cellar_work_s)
		slot.healths.append((Registry.entry(&"buildings", EXCAVATION) as BuildingData).max_health)
	slot.builder_work = true


static func sync() -> void:
	var under := SimLoop.field.under
	for k in under.count():
		if under.key_of(k) != UnderWatch.HATCH_KEY:
			continue
		var tier := 0
		for slot in SimLoop.builds.slots:
			if slot.kind == EXCAVATION:
				tier = slot.level
		var mouth := under.mouth_of(k)
		var step := LastCartWatch.rules().cellar_step_px
		var cap := Vector2(mouth - step / 2, mouth + step * tier + step / 2)
		if SimLoop.arrival.active:
			under.sites[k][UndergroundSites.CAP] = cap
			under.sites[k][UndergroundSites.SPEC][UndergroundSites.EXTRA] = 0
			under.excavate(k, cap)


static func chest_at(x: float) -> String:
	var under := SimLoop.field.under
	for k in under.count():
		if under.kind_of(k) != UndergroundSites.HATCH or not under.generated(k):
			continue
		if absf(x - under.mouth_of(k)) <= Band.PASSAGE_PX:
			return under.key_of(k)
	return ""


static func foreign(field: FieldWork, id: int, record: Dictionary) -> void:
	if record.has(&"camp"):
		return
	var key := "realm_hatch_%d" % id
	var mouth := float(record[&"x"]) + UnderWatch.ALCAPAO_PX.x
	var step := LastCartWatch.rules().cellar_step_px
	field.under.post(
		key,
		UndergroundSites.HATCH,
		mouth,
		Vector2(mouth, mouth),
		Vector2(mouth - step, mouth + step),
		UnderWatch.spec(UndergroundSites.HATCH, 0.0, [])
	)
	if not SimLoop.treasury.chests.has(key):
		var coins := mini(
			LastCartWatch.rules().foreign_chest_coins, floori(field.settlements.treasury(id))
		)
		if field.settlements.spend(id, coins):
			SimLoop.treasury.open(key, coins)


static func deposit(drop: Dictionary) -> bool:
	if int(drop[EventRelay.FAIXA]) != Band.Kind.UNDERGROUND:
		return false
	var key := chest_at(float(drop[EventRelay.ONDE]))
	if key.is_empty():
		return false
	SimLoop.treasury.deposit(key, int(drop[EventRelay.QUANTO]))
	EventBus.queue(&"coin_spent", [int(drop[EventRelay.QUANTO]), &"treasury"])
	return true


static func take() -> bool:
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	if r < 0 or units.bands[r] != Band.Kind.UNDERGROUND:
		return false
	var key := chest_at(units.xs[r])
	if key.is_empty():
		return false
	var space := units.coin_capacities[r] - units.carried_coins[r]
	var taken := SimLoop.treasury.withdraw(key, space)
	units.carried_coins[r] += taken
	if taken > 0:
		EventBus.queue(&"coin_collected", [SimLoop.king_id, taken])
	return taken > 0


static func steal() -> void:
	var creatures := SimLoop.creatures
	for c in creatures.count():
		if not creatures.alive(c) or creatures.bands[c] != Band.Kind.UNDERGROUND:
			continue
		var key := chest_at(creatures.xs[c])
		if SimLoop.field.song.allies.has(creatures.ids[c]):
			continue
		if not key.is_empty():
			var loss := SimLoop.treasury.steal(key, SimLoop.treasury.amount(key))
			if loss > 0:
				SimLoop.arrival.record(&"treasury_stolen", loss)
			continue
		var under := SimLoop.field.under
		var site := under.site_at(creatures.xs[c])
		if site >= 0 and under.kind_of(site) == UndergroundSites.HATCH:
			creatures.goal_xs[c] = under.mouth_of(site)
