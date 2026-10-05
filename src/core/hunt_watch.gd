class_name HuntWatch
extends RefCounted

const SITIOS := [
	[-830.0, &"hole"],
	[-1692.0, &"tree"],
	[-1860.0, &"hole"],
]
const SAL_ESPERA := 150
const SAL_RARO := 157
const INTRO_SECONDS := 70.0  # §25, minuto 1:10; encenacao, nao afinacao de combate.
const BICHO := &"rabbit"
const METADE := 0.5
const LUZ := [
	GameClock.Phase.DAWN, GameClock.Phase.MORNING, GameClock.Phase.NOON, GameClock.Phase.AFTERNOON
]

static var _periodo := {}


static func intro_at(dia_s: float) -> float:
	var base := (Registry.entry(&"economy", &"clock") as ClockData).day_seconds
	return INTRO_SECONDS * dia_s / base


static func tick(
	field: FieldWork, unidades: UnitSystem, delta: float, luz: bool, relogio: GameClock, rei: int
) -> Array[Dictionary]:
	var hunt := field.hunting
	var intro := relogio.elapsed >= intro_at(relogio.day_seconds())
	var raro := func() -> float: return RngService.scatter(hash([SAL_RARO, hunt.herd.born]), 1)[0]
	hunt.grow(
		delta, luz, period(relogio.day_seconds()), raro, WildHunt.rhythms(relogio.day_seconds())
	)
	var caca := hunt.resolve(unidades, luz, intro)
	if SimLoop.combat != null and SimLoop.field == field:
		for golpe in SimLoop.combat.manual.take_missed():
			caca.append_array(RoyalHunt.swing(hunt, golpe))
	var perfis := SimFactory.by_id(&"units")
	var aljava := field.supply  # a flecha do Imperador Arqueiro, mesmo sem condutor (Q-200)
	caca.append_array(RoyalHunt.idle(hunt, unidades, perfis, Assume.driven(), luz, aljava))
	var chao := HuntBag.bag(hunt.bagged, unidades, caca)
	for d in caca:
		if not d in chao:
			EventBus.queue(&"coin_collected", [d[&"hunter"], d[&"amount"]])
	var alcance := SimFactory.curve().recruit_notice_px
	var entregue := HuntBag.deliver(hunt.bagged, unidades, rei, alcance)  # o escudeiro (Q-114)
	if entregue > 0:
		EventBus.queue(&"coin_collected", [rei, entregue])
	return chao


static func stir(field: FieldWork, unidades: UnitSystem, delta: float) -> void:
	var hunt := field.hunting
	var ameacas := Herd.threats_of(unidades)
	var feras := SimFactory.by_id(&"creatures")
	if SimLoop.creatures != null:
		hunt.herd.predators = Herd.predators_of(SimLoop.creatures, feras, field.song.allies)
	var before := hunt.herd.xs.duplicate()
	var strikes := hunt.herd.step(delta, hunt.rabbits, hunt.species_at, ameacas)
	var rules := LastCartWatch.rules()
	EventRelay.builds(
		BoarWalls.collide(
			hunt.herd,
			before,
			hunt.species_at,
			SimLoop.builds,
			rules.boar_stun_s,
			rules.boar_wall_damage
		)
	)
	strikes = strikes.filter(
		func(g: Dictionary) -> bool:
			return (
				not hunt.herd.stunned.has(g[Herd.DE]) or float(hunt.herd.stunned[g[Herd.DE]]) <= 0.0
			)
	)
	for g in Herd.bite(unidades, strikes):
		EventBus.queue(&"unit_damaged", [g[Herd.QUEM], g[Herd.DANO], Herd.NENHUM])  # o javali
	for toca in hunt.herd.caught:  # a Podridao apanhou-o: levanta-se teu inimigo
		var onde := hunt.herd.where(toca)
		var bicho := hunt.lose(toca)
		var criatura: CreatureData = feras.get(bicho.rots_into)
		if criatura != null and SimLoop.creatures != null and _paid(criatura):
			SimLoop.creatures.spawn(SimLoop.state, criatura, onde, SimLoop.core_x)
			EventBus.queue(&"rot_summoned", [criatura.id, onde, 0.0])


## So se levanta se a mancha o pagar: o dia, a massa e a estreia (NightWatch.pay, ADR 0071).
static func _paid(criatura: CreatureData) -> bool:
	return SimLoop.night != null and SimLoop.night.pay(criatura)


static func prepare(
	hunt: HuntingSystem, day: int, core_x: float, width: float, _fase: int = 0
) -> void:
	if width <= 0.0:
		return
	if not hunt.burrows.placed():
		place(hunt, core_x, width)
	elif not hunt.burrows.checked:
		reconcile(hunt, core_x, width)
	if day > hunt.day and SimLoop.night != null:
		wither(hunt, SimLoop.night.amargueiros)
	hunt.open_day(day)


static func place(hunt: HuntingSystem, core_x: float, width: float) -> void:
	var dia_s := ClockService.clock.day_seconds() if ClockService.clock else 0.0
	var ritmos := WildHunt.rhythms(dia_s)
	var periodo := period(dia_s)
	var falta := {}
	for dados in _bichos():
		falta[dados.id] = dados.burrows_per_region
	var onde: Array[float] = []
	var esperas: Array[float] = []
	var fontes := PackedStringArray()
	var caca := PackedStringArray()
	for sitio: Array in SITIOS:
		for dados in _bichos():
			if int(falta[dados.id]) <= 0 or not dados.sources.has(sitio[1]):
				continue
			falta[dados.id] = int(falta[dados.id]) - 1
			var k := onde.size()
			onde.append(clampf(core_x + float(sitio[0]), 0.0, width))
			fontes.append(String(sitio[1]))
			caca.append(String(dados.id))
			var ritmo := float(ritmos.get(dados.id, periodo))
			if dados.id != BICHO:
				esperas.append(RngService.scatter(hash([SAL_ESPERA, k]), 1)[0] * ritmo)
			else:
				esperas.append(0.0 if k == 0 else RngService.float_range(&"economy", 0.0, ritmo))
			break
	hunt.burrows.place(onde, esperas, fontes, caca)
	hunt.wildlife = SimFactory.by_id(&"wildlife")


static func reconcile(hunt: HuntingSystem, core_x: float, width: float) -> void:
	hunt.burrows.checked = true
	var sitios := {}
	for sitio: Array in SITIOS:
		sitios[clampf(core_x + float(sitio[0]), 0.0, width)] = true
	var fora := PackedFloat32Array()  # as tocas de casa que ja nao sao sitio (a porta)
	for x in hunt.burrows.xs:
		if x >= 0.0 and x <= width and not sitios.has(x):
			fora.append(x)
	hunt.wither(fora, 0.0)
	var dia_s := ClockService.clock.day_seconds() if ClockService.clock else 0.0
	var ritmos := WildHunt.rhythms(dia_s)
	var periodo := period(dia_s)
	var tem := {}
	for k in hunt.burrows.game.size():  # so as dos sitios de casa
		var x := hunt.burrows.xs[k]
		if sitios.has(x):
			tem[hunt.burrows.game[k]] = int(tem.get(hunt.burrows.game[k], 0)) + 1
	for sitio: Array in SITIOS:
		var x := clampf(core_x + float(sitio[0]), 0.0, width)
		if hunt.burrows.xs.has(x):
			continue
		for dados in _bichos():
			var id := String(dados.id)
			if int(tem.get(id, 0)) >= dados.burrows_per_region or not dados.sources.has(sitio[1]):
				continue
			tem[id] = int(tem.get(id, 0)) + 1
			var espera := RngService.scatter(hash([SAL_ESPERA, hunt.burrows.xs.size()]), 1)[0]
			var ritmo := float(ritmos.get(dados.id, periodo))
			hunt.burrows.add(x, espera * ritmo, String(sitio[1]), id)
			break


static func period(dia_s: float) -> float:
	if _periodo.has(dia_s):
		return _periodo[dia_s]
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var media := (SimFactory.curve().hunt_yield.x + SimFactory.curve().hunt_yield.y) * METADE
	var moedas := 0.0
	for dados in _bichos():
		moedas += dados.burrows_per_region * dados.coin_yield
	if media <= 0.0 or moedas <= 0.0:
		return 0.0
	var luz := 0.0
	for fase in LUZ:
		luz += relogio.phase_durations[fase]
	var escala := dia_s / relogio.day_seconds if dia_s > 0.0 else 1.0
	_periodo[dia_s] = luz * escala * moedas / media
	return _periodo[dia_s]


static func _bichos() -> Array[WildlifeData]:
	var bioma := SimFactory.biome_of_segment(SimFactory.SEGMENTO_DE_PARTIDA)
	var saida: Array[WildlifeData] = []
	for recurso in Registry.entries(&"wildlife"):
		var dados := recurso as WildlifeData
		if dados.burrows_per_region > 0 and dados.biomes.has(bioma):
			saida.append(dados)
	saida.sort_custom(cheaper)
	return saida


static func wither(hunt: HuntingSystem, arvores: AmargueiroSystem) -> Array[float]:
	var dados := Registry.entry(&"wildlife", BICHO) as WildlifeData
	if arvores == null or dados.burrow_wither_px <= 0.0:
		return []
	var perigos := PackedFloat32Array()
	for k in arvores.xs.size():
		var de_pe := arvores.fates[k] == AmargueiroSystem.Fate.STANDING
		if de_pe and arvores.bands[k] == int(Band.Kind.SURFACE):
			perigos.append(arvores.xs[k])
	return hunt.wither(perigos, dados.burrow_wither_px)


static func cheaper(a: WildlifeData, b: WildlifeData) -> bool:
	if a.id == BICHO or b.id == BICHO:
		return a.id == BICHO and b.id != BICHO
	if a.coin_yield != b.coin_yield:
		return a.coin_yield < b.coin_yield
	return String(a.id) < String(b.id)
