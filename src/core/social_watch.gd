class_name SocialWatch
extends RefCounted


## O calendario social comeca na alvorada posterior a primeira noite territorial.
## O mapa de sementes e calculado inteiro, sem gerar arvores, dungeons ou recompensas.
## Visitar primeiro oeste ou leste nao decide a data de nascimento de um povo.
static func awaken(field: FieldWork, day: int) -> void:
	var social := field.settlements
	if social.awake_day > 0 or social.first_night_day <= 0 or day <= social.first_night_day:
		return
	social.awake_day = day
	var world := WildSegments.new(RulesFactory.segment_kits(), RulesFactory.biome_peoples())
	world.from_dict(field.wilds.to_dict())
	var curve := SimFactory.curve()
	var noise_field := RngService.noise(
		Frontier.SAL_CLIMA, 1.0 / float(maxi(1, curve.wild_cluster_segments)), Frontier.OITAVAS
	)
	var edges := {}
	for id in Registry.ids(Frontier.TABELA_BIOMAS):
		edges[StringName(id)] = (
			(Registry.entry(Frontier.TABELA_BIOMAS, StringName(id)) as BiomeData).edge_subject
		)
	for side in [WorldPlan.OESTE, WorldPlan.LESTE]:
		while not world.full(side):
			var k := world.count(side)
			var rolls := RngService.scatter(
				hash([Frontier.SAL, side, k]), WildSegments.SORTEIOS + 1
			)
			var climate := clampf(
				Frontier.MEIO + noise_field.get_noise_1d(float(side * (k + 1))) * Frontier.GANHO,
				0.0,
				1.0
			)
			if (
				world
				. grow(
					side, rolls, climate, curve.wild_cluster, SimLoop.state.chapters.regions, edges
				)
				. is_empty()
			):
				break
		for k in world.count(side):
			SettlementWatch.author(field, side, k, false, world)


## Uma obra de cada vez; o custo e o trabalho sao os mesmos das construcoes reais.
static func develop(field: FieldWork, id: int, record: Dictionary) -> void:
	if not record.has(&"born_day") or record[&"deserted"]:
		return
	for site in record[&"sites"]:
		var slot := SimLoop.builds.slots[SimLoop.builds.index_of(site)]
		if slot.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
			return
		if slot.state == BuildSlot.State.EMPTY:
			if field.settlements.spend(id, slot.next_cost()):
				slot.builder_work = true
				slot.state = BuildSlot.State.SCAFFOLD
				EventBus.queue(&"build_started", [slot.id, slot.kind])
			return


static func camps(field: FieldWork) -> PackedFloat32Array:
	var points := PackedFloat32Array()
	for record: Dictionary in field.settlements.records.values():
		if record.has(&"camp") and not record[&"deserted"]:
			points.append(float(record[&"camp"]))
	return points
