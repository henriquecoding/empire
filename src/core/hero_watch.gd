class_name HeroWatch
extends RefCounted


static func current() -> StringName:
	var i := SimLoop.units.index_of(Assume.driven())
	return SimLoop.field.roster.class_of_body(SimLoop.units.data_ids[i]) if i >= 0 else &""


static func tick(delta: float) -> void:
	var field := SimLoop.field
	field.song.tick(delta, SimLoop.creatures)
	SimLoop.creatures.allies = field.song.allies
	field.focus.allies = field.song.allies
	field.focus.tick(delta, SimLoop.creatures)
	SimLoop.combat.focus = field.focus
	SimLoop.combat.picker.focused = field.focus.targets
	SimLoop.combat.picker.song = field.song
	field.focus.piercing.clear()
	var archer := (Registry.entry(&"classes", &"archer") as ClassData).base_unit
	var evolved := field.hero_progress.phase_of(&"archer") > 1
	if not evolved:
		if SimLoop.creatures.count() == 0:
			return
		if not SimLoop.units.data_ids.has(&"bard") and not SimLoop.units.data_ids.has(&"bard_hero"):
			return
	var driven := Assume.driven()
	for i in SimLoop.units.count():
		var data_id := SimLoop.units.data_ids[i]
		if evolved and data_id == archer:
			field.focus.piercing.append(SimLoop.units.ids[i])
		if data_id == &"bard" or data_id == &"bard_hero":
			if SimLoop.units.ids[i] != driven and SimLoop.units.alive(i):
				_charm(SimLoop.units.ids[i], SimLoop.units.xs[i])


static func action(x: float) -> void:
	var who := Assume.driven()
	var field := SimLoop.field
	match current():
		&"archer":
			var phase := field.hero_progress.phase_of(&"archer")
			for id in field.focus.aim(SimLoop.units, SimLoop.creatures, who, x, phase):
				EventBus.queue(&"target_marked", [id, who])
		&"bard":
			var promoted := BardPromotion.at(who, x)
			if not promoted:
				_charm(who, x)


static func pace() -> float:
	var i := SimLoop.units.index_of(Assume.driven())
	if i >= 0 and SimLoop.units.data_ids[i] == &"bard_hero":
		return SimLoop.field.song.pace(1)
	return 1.0


static func evolve_ready() -> bool:
	var class_id := current()
	if class_id == &"" or class_id == &"monarch":
		return false
	var units := SimLoop.units
	var i := units.index_of(Assume.driven())
	for site in SimLoop.builds.slots:
		if site.kind == BuildSlot.NUCLEO and site.band == units.bands[i]:
			if absf(site.x - units.xs[i]) <= site.width * BuildSystem.METADE:
				return SimLoop.field.hero_progress.can_evolve(class_id, SimLoop.state.royal_seeds)
	return false


static func evolve() -> bool:
	if not evolve_ready():
		return false
	return SimLoop.field.hero_progress.evolve(current(), SimLoop.state)


static func resolved(events: Array[Dictionary]) -> Array[Dictionary]:
	for event in events:
		if event.get(CombatSystem.CHAVE, -1) != CombatSystem.EV_MORTE:
			continue
		if not bool(event.get(CombatSystem.CRIATURA, false)):
			continue
		var id := int(event[CombatSystem.DE])
		for owner: int in SimLoop.field.focus.targets:
			if SimLoop.field.focus.marked(id, owner):
				SimLoop.field.hero_progress.record(&"archer")
				break
	return events


static func _charm(who: int, x: float) -> void:
	var song := SimLoop.field.song
	var converted := song.conversions()
	var phase := SimLoop.field.hero_progress.phase_of(&"bard")
	var target := song.cast(SimLoop.units, SimLoop.creatures, who, x, phase)
	if target >= 0:
		if song.conversions() > converted:
			SimLoop.field.hero_progress.record(&"bard")
		EventBus.queue(&"target_marked", [target, who])
