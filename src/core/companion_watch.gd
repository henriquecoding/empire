class_name CompanionWatch
extends RefCounted

const POST := &"companion_post"
const POST_X := 612.0


static func author() -> void:
	WorldWorks.post(POST, SimLoop.core_x + POST_X)


static func site() -> BuildSlot:
	for slot in SimLoop.builds.slots:
		if slot.kind == POST and slot.territory == 0:
			return slot
	return null


static func available() -> bool:
	return SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id) < 0


static func pay(drop: Dictionary) -> bool:
	var post := site()
	if post == null or not post.standing() or not available():
		return false
	if int(drop[EventRelay.FAIXA]) != post.band:
		return false
	if absf(float(drop[EventRelay.ONDE]) - post.x) > post.catch_half():
		return false
	var who := ArrivalLabor.candidate()
	if who < 0:
		return false
	var offered := int(drop[EventRelay.QUANTO])
	var spent := SimLoop.companion.pay(offered, LastCartWatch.rules().companion_cost)
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.carried_coins[r] += offered - spent
	if spent > 0:
		EventBus.queue(&"coin_spent", [spent, POST])
	if SimLoop.companion.enroll(who, LastCartWatch.rules().companion_cost):
		if SimLoop.arrival.worker == who:
			SimLoop.arrival.assign(LastCart.NONE, &"")
	return true


static func plan() -> void:
	var who := SimLoop.companion.worker
	var i := SimLoop.units.index_of(who)
	var post := site()
	if i < 0 or post == null or not SimLoop.units.alive(i):
		SimLoop.companion.worker = -1
		return
	SimLoop.units.set_target_x(who, post.x)
	SimLoop.units.job_ids[i] = -1
	if absf(SimLoop.units.xs[i] - post.x) > post.catch_half():
		return
	Monarchy.embody(SimLoop.units, i, Registry.entry(&"units", MonarchWatch.data().companion))
	MonarchWatch.bond(SimLoop.king_id, who)
	SimLoop.companion.finish()
	SimLoop.arrival.record(&"companion_hired")
	EventBus.queue(&"unit_promoted", [who, &"vagrant", MonarchWatch.data().companion])


static func battles(events: Array[Dictionary]) -> void:
	if not SimLoop.arrival.active or MonarchWatch.evolved(SimLoop.field):
		return
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	var c := SimLoop.field.monarchy.companion_index(units, SimLoop.king_id)
	if (
		r < 0
		or c < 0
		or not units.alive(r)
		or units.healths[r] <= 0
		or units.bands[r] != units.bands[c]
	):
		return
	var radius := SimFactory.curve().recruit_notice_px
	var together := absf(units.xs[r] - units.xs[c]) <= radius
	for event in events:
		if (
			int(event[CombatSystem.CHAVE]) != CombatSystem.EV_MORTE
			or not bool(event.get(CombatSystem.CRIATURA, false))
		):
			continue
		# A criatura ja saiu das colunas quando isto corre: o sitio, a faixa e se era
		# aliada vem no proprio evento da morte (BUG-02).
		var id := int(event[CombatSystem.DE])
		if bool(event.get(CombatSystem.ALIADA, false)) or SimLoop.field.song.allies.has(id):
			continue
		if int(event.get(CombatSystem.FAIXA, -1)) != units.bands[r]:
			continue
		if absf(float(event.get(CombatSystem.ONDE, INF)) - units.xs[r]) > radius:
			continue
		SimLoop.companion.victory(id, together)
	if SimLoop.companion.battles.size() < LastCartWatch.rules().battle_evolve_count:
		return
	var field := SimLoop.field
	if MonarchWatch.skill_class() == Monarchy.REI:
		if field.classes.locked:
			return
		field.classes.phase = 2
		field.classes.squire.knight = true
	else:
		var skill := MonarchWatch.skill_class()
		if bool(field.hero_progress.locked.get(skill, false)):
			return
		field.hero_progress.phases[skill] = 2
	var health_mult := LastCartWatch.rules().companion_evolved_health_mult
	units.max_healths[c] = roundi(units.max_healths[c] * health_mult)
	units.healths[c] = roundi(units.healths[c] * health_mult)
	SimLoop.arrival.record(&"monarch_evolved_in_battle")
	EventBus.queue(&"king_action_chosen", [units.owners[r], &"battle_evolution"])
