class_name FoundationUnder
extends RefCounted

const SIGNATURE := &"royal_vault"
const SIDES := [-1.0, 1.0]
const HALF := 0.5


## A reserva nova adapta-se ao chao livre; o conteudo ja descoberto fica no sitio.
## Esta previsao nao escreve no mundo nem consome o RNG da simulacao.
static func plan(center: float) -> Dictionary:
	var under := SimLoop.field.under
	var obstacles: Array = []
	var offset := UnderWatch.ALCAPAO_PX.x
	for k in under.count():
		if under.key_of(k) == UnderWatch.HATCH_KEY:
			offset = under.mouth_of(k) - SimLoop.core_x
			continue
		obstacles.append(
			under.span(k) if under.generated(k) else under.sites[k][UndergroundSites.PLAN]
		)
	var candidates: Array[float] = [center + offset, center - offset]
	for side in SIDES:
		candidates.append(center + side * UnderWatch.ALCAPAO_PX.x)
		candidates.append(center + side * UnderWatch.ALCAPAO_PX.y)
	var boundary := INF
	for slot in SimLoop.builds.slots:
		if slot.territory == 0 and slot.two_paths():
			boundary = minf(boundary, absf(slot.x - SimLoop.core_x))
	var lead := (UnderWatch.rules().arrival_px + UnderWatch.rules().margin_px) * HALF
	for obstacle: Vector2 in obstacles:
		for edge in [obstacle.x - lead, obstacle.y + lead]:
			if is_finite(edge) and absf(edge - center) < boundary - lead:
				candidates.append(edge)
	for mouth in candidates:
		var inward := CellarWatch.toward(mouth, center)
		for direction in [inward, -inward]:
			var cap := CellarWatch.envelope(mouth, direction)
			cap = Vector2(maxf(cap.x, center - boundary), minf(cap.y, center + boundary))
			cap = UnderFit.clip(cap, mouth, obstacles)
			if UnderFit.check(cap, mouth, [], UnderWatch.rules()) == UnderFit.OK:
				return {&"mouth": mouth, &"cap": cap}
	return {}
