class_name FoundationChoice
extends RefCounted

const DOMINANT_SHARE := 0.5


static func ready() -> bool:
	var o := SimLoop.arrival
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	return (
		o.active
		and o.choice == &""
		and king >= 0
		and u.alive(king)
		and u.bands[king] == Band.Kind.SURFACE
		and not u.walking(king, SimLoop.king_id)
		and o.stationary_s >= LastCartWatch.rules().foundation_stop_s
		and not priority_at(u.xs[king])
		and valid(u.xs[king])
	)


static func priority_at(x: float) -> bool:
	var o := SimLoop.arrival
	if absf(x - o.cache_x) <= Band.PASSAGE_PX:
		return true
	# As passagens e as masmorras; o alcapao do castelo so existe depois de fundar.
	if Passages.near(x, Passages.open(SimLoop.passages, SimLoop.builds)):
		return true
	if Passages.near(x, SimLoop.field.wilds.dungeons(SimLoop.world_width)):
		return true
	var trees := SimLoop.night.amargueiros
	for k in trees.count():
		if trees.fates[k] == AmargueiroSystem.Fate.OLD and absf(x - trees.xs[k]) <= Band.PASSAGE_PX:
			return true
	for at in SimLoop.secrets.xs:
		if absf(x - at) <= Band.PASSAGE_PX:
			return true
	return Verbs.at_fork(x) or TravelWatch.at_gate() or Lume.at_base(x)


static func valid(x: float) -> bool:
	var protected: Array[Vector2] = []
	var under := SimLoop.field.under
	for k in under.count():
		if under.key_of(k) == UnderWatch.HATCH_KEY:
			continue
		var mouth := under.mouth_of(k)
		protected.append(Vector2(mouth - Band.PASSAGE_PX, mouth + Band.PASSAGE_PX))
	for at in SimLoop.secrets.xs:
		protected.append(Vector2(at, at))
	for site in SimLoop.builds.slots:
		if site.territory != 0 and site.kind != AmargueiroSystem.CORTE:
			protected.append(Vector2(site.x - site.catch_half(), site.x + site.catch_half()))
	for k in SimLoop.night.amargueiros.count():
		var at := SimLoop.night.amargueiros.xs[k]
		protected.append(Vector2(at, at))
	# So o chao da propria sede tem de estar livre (ADR 0070): o que fica perto e
	# consequencia, nao proibicao, e a clareira conserva-o. Antes bastava uma estatua ou
	# uma raiz a 240 px para recusar, e quase nenhum sitio servia.
	var sede := RealmLadder.seat(SimLoop.builds)
	return (
		SiteValidator.valid(x, sede.catch_half(), Frontier.walk_limits(), protected)
		and not FoundationUnder.plan(x).is_empty()
	)


static func claim(x: float) -> bool:
	var o := SimLoop.arrival
	if not ready() or not is_finite(x):
		return false
	var king := SimLoop.units.index_of(SimLoop.king_id)
	if not is_equal_approx(x, SimLoop.units.xs[king]) or not valid(x):
		return false
	var signature := signature_at(x)
	signature[FoundationUnder.SIGNATURE] = FoundationUnder.plan(x)
	if not o.claim(&"free", x - o.origin):
		return false
	o.free_site = true
	o.site_signature = signature
	var radius := LastCartWatch.rules().foundation_clear_radius
	o.clear_manifest = [Vector2(x - radius, x + radius)]
	LastCartWatch.reanchor(x - SimLoop.core_x, false)
	for id in o.citizens:
		var i := SimLoop.units.index_of(id)
		if i >= 0 and SimLoop.units.alive(i):
			SimLoop.units.owners[i] = SimLoop.units.owners[king]
	LastCartWatch.commit()
	return true


static func signature_at(x: float) -> Dictionary:
	var biome := StringName(SimLoop.state.chapters.regions[SimLoop.state.region])
	var wilds := SimLoop.field.wilds
	for side in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in wilds.count(side):
			var start := wilds.x_of(side, k, SimLoop.world_width)
			if x >= start and x < start + wilds.width:
				var r := wilds.at(side, k)
				biome = (
					r[WildSegments.PARA]
					if float(r[WildSegments.MISTURA]) >= DOMINANT_SHARE
					else r[WildSegments.DE]
				)
	var data := Registry.entry(&"biomes", biome) as BiomeData
	return {
		&"dominant_biome": biome,
		&"resources": data.resources.duplicate() if data != null else [],
		&"terrain_form": &"surface",
		&"seed": SimLoop.state.seed,
		&"position": x,
		&"provenance": &"FOUNDATION_SAMPLED",
		&"signature_version": 2,
		&"climate_band": &"PENDING_CLIMATE_MODEL",
		&"ecosystem": biome,
		# O que o territorio permitia ao fundar, por necessidade (ADR 0077): a fotografia
		# fica; o perfil vivo muda com o mundo.
		&"territory": TerritoryWatch.preview(x)[TerritoryProfile.NEEDS],
	}
