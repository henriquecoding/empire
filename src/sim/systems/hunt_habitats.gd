class_name HuntHabitats
extends RefCounted

const HALF := 0.5


## O espaco que o animal ocupa ou percorre para cada lado da sua toca.
static func margin(data: WildlifeData) -> float:
	return maxf(data.roam_px, data.flee_px) + float(data.shadow_width) * HALF


## O trecho inteiro respeita a distancia minima desta especie a sede.
static func supports(data: WildlifeData, span: Vector2, center: float) -> bool:
	if data.habitat_min_px <= 0.0:
		return true
	var gap := maxf(0.0, maxf(span.x - center, center - span.y))
	return gap - margin(data) >= data.habitat_min_px


## Territorio contiguo da sede ate as muralhas proprias de pe, independentemente por lado.
static func claimed(builds: BuildSystem) -> Vector2:
	var seat := RealmLadder.seat(builds)
	if seat == null:
		return Vector2(INF, -INF)
	var span := Vector2(seat.x - seat.width * HALF, seat.x + seat.width * HALF)
	for site in builds.slots:
		if not _local(site) or not site.two_paths() or not site.holds():
			continue
		span.x = minf(span.x, site.x - site.width * HALF)
		span.y = maxf(span.y, site.x + site.width * HALF)
	return span


## Ocupacao encerra a toca, nao mata nem teleporta o animal que ja la estava.
## O estado alive vai no save: uma muralha cair nao faz brotar caca dentro da cidade.
static func reserve(hunt: HuntingSystem, builds: BuildSystem) -> void:
	var span := claimed(builds)
	var occupied: Array[Vector2] = []
	for site in builds.slots:
		var building := (
			site.paid > 0 and site.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]
		)
		if _local(site) and (site.holds() or building):
			occupied.append(Vector2(site.x - site.width * HALF, site.x + site.width * HALF))
	for k in hunt.burrows.xs.size():
		if hunt.burrows.alive[k] == 0:
			continue
		var x := hunt.burrows.xs[k]
		var reach := margin(hunt.species_at(x))
		if _inside(x, span, reach):
			hunt.burrows.alive[k] = 0
			continue
		for built in occupied:
			if _inside(x, built, reach):
				hunt.burrows.alive[k] = 0
				break


static func _local(site: BuildSlot) -> bool:
	return site.territory == 0 and site.band == Band.Kind.SURFACE


static func _inside(x: float, span: Vector2, reach: float) -> bool:
	return span.x <= span.y and x >= span.x - reach and x <= span.y + reach
