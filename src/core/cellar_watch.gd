class_name CellarWatch
extends RefCounted

const EXCAVATION := &"cellar_excavation"
const WORKSITE_X := -612.0
const HALF := 0.5
const LEFT := -1.0
const RIGHT := 1.0
## Sem chao nenhum para la do envelope: a escavacao fecha ja.
const NO_ROOM := -1.0


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


## A cave real: a largura habitavel inicial e um passo por estagio de escavacao, para la
## da boca (ADR 0072, §6.4) — e nunca por cima do chao de outro sitio.
static func sync() -> void:
	var under := SimLoop.field.under
	for k in under.count():
		if under.key_of(k) != UnderWatch.HATCH_KEY or not SimLoop.arrival.active:
			continue
		var tier := 0
		for slot in SimLoop.builds.slots:
			if slot.kind == EXCAVATION:
				tier = slot.level
		var step := LastCartWatch.rules().cellar_step_px
		var inward := _inward(k, SimLoop.core_x)
		var room := envelope(under.mouth_of(k), inward)
		var grown := Vector2(room.x - step * tier, room.y) if inward < 0.0 else room
		if inward > 0.0:
			grown.y += step * tier
		under.sites[k][UndergroundSites.SPEC][UndergroundSites.EXTRA] = 0
		under.set_cap(k, grown)
		under.excavate(k, grown)
		var free := under_limit(k, room, inward)
		var stages := RulesFactory.realm_stages().size()
		SimLoop.builds.cellar_room = (
			stages if is_inf(free) else clampi(floori(free / step), 0, stages)
		)


## O envelope inicial de uma reserva com a boca em `mouth`: a chegada de um lado e a baia
## do lado `inward` (+1 ou -1), na largura habitavel do underground.csv. Nunca centrada no
## alcapao quando isso a faz sair da sede (§13.A do relatorio).
static func envelope(mouth: float, inward: float) -> Vector2:
	var r := UnderWatch.rules()
	var lead := (r.arrival_px + r.margin_px) * HALF
	if inward < 0.0:
		return Vector2(mouth + lead - r.cellar_base_px, mouth + lead)
	return Vector2(mouth - lead, mouth - lead + r.cellar_base_px)


## Quanto chao a cave real ainda tem para la do envelope inicial, sem tocar noutro sitio.
static func under_limit(k: int, room: Vector2, inward: float) -> float:
	var aberto := Vector2(-INF, room.y) if inward < 0.0 else Vector2(room.x, INF)
	var lim := UnderReserve.limit_of(SimLoop.field.under, k, aberto)
	if is_nan(lim.x):
		return NO_ROOM
	return room.x - lim.x if inward < 0.0 else lim.y - room.y


## Para que lado fica o meio da sede, visto da boca: +1 ou -1.
static func toward(mouth: float, center: float) -> float:
	return LEFT if mouth > center else RIGHT


## Para onde cresce a reserva `k`: para onde ja cresceu (um save de antes crescia para a
## direita), ou, de novo, para o meio da sede.
static func _inward(k: int, center: float) -> float:
	var under := SimLoop.field.under
	var mouth := under.mouth_of(k)
	if under.generated(k):
		var lim := under.span(k)
		if not is_equal_approx(lim.y - mouth, mouth - lim.x):
			return RIGHT if lim.y - mouth > mouth - lim.x else LEFT
	var vault: Dictionary = SimLoop.arrival.site_signature.get(FoundationUnder.SIGNATURE, {})
	if not vault.is_empty():
		var cap: Vector2 = vault[&"cap"]
		return RIGHT if cap.y - mouth > mouth - cap.x else LEFT
	return toward(mouth, center)


## O bau mais perto de `x`, ao alcance da mao: o da baia, nunca o da subida (SUB-12).
static func chest_at(x: float) -> String:
	var under := SimLoop.field.under
	for k in under.count():
		if under.kind_of(k) != UndergroundSites.HATCH or not under.generated(k):
			continue
		if absf(x - UnderReserve.chest_x(under, k)) <= Band.PASSAGE_PX:
			return under.key_of(k)
	return ""


static func foreign(field: FieldWork, id: int, record: Dictionary) -> void:
	if record.has(&"camp") or record[&"sites"].is_empty():
		return
	var house := SimLoop.builds.index_of(record[&"sites"][0])
	if house < 0 or not SimLoop.builds.slots[house].standing():
		return
	var key := "realm_hatch_%d" % id
	if SimLoop.treasury.chests.has(key):
		for site: Dictionary in field.under.sites:
			if site[UndergroundSites.KEY] == key:
				return
	var mouth := float(record[&"x"]) + UnderWatch.ALCAPAO_PX.x
	var spec := UnderWatch.spec(UndergroundSites.HATCH, 0.0, [])
	spec[UndergroundSites.MANDATORY] = false  # sem chao, o reino estrangeiro nao tem cave
	var cap := envelope(mouth, toward(mouth, float(record[&"x"])))
	field.under.post(key, UndergroundSites.HATCH, mouth, Vector2(mouth, mouth), cap, spec)
	var k := field.under.find(mouth, Band.PASSAGE_PX)
	if k == UndergroundSites.NONE or field.under.key_of(k) != key:
		return
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
			_rob(c, key)
			continue
		var under := SimLoop.field.under
		var site := under.site_at(creatures.xs[c])
		if site >= 0 and under.kind_of(site) == UndergroundSites.HATCH:
			var chest := UnderReserve.chest_x(under, site)
			if not is_nan(chest):
				creatures.goal_xs[c] = chest


## O ladrao leva o que lhe cabe, e leva-o consigo: se morrer, cai onde ele cair (§9.6).
static func _rob(c: int, key: String) -> void:
	var creatures := SimLoop.creatures
	var id := creatures.ids[c]
	var room := UnderWatch.rules().thief_carry - SimLoop.treasury.carried_by(id)
	var loss := SimLoop.treasury.steal(key, room)
	if loss <= 0:
		return
	SimLoop.treasury.carry(id, loss)
	creatures.coin_drops[c] += loss
	SimLoop.arrival.record(&"treasury_stolen", loss)
