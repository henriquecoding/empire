class_name UndergroundSites
extends RefCounted

const CELLAR := &"cellar"
const HATCH := &"hatch"
const DUNGEON := &"dungeon"
const A := &"a"
const B := &"b"
const KIND := &"kind"
const ROLL := &"roll"
const KEY := &"key"
const SITE := &"site"
const MOUTH := &"mouth"
const NEED := &"need"
const CAP := &"cap"
const SPEC := &"spec"
const ROOM := &"room"
const EXTRA := &"extra"
const POOL := &"pool"
const ENTRANCE := &"entrance"
const ENTRANCE_PX := &"entrance_px"
const FEATURES := &"features"
const LAYOUTS := &"layouts"
const MAX_ROOMS := 12
const PER_ROOM := 3
const ROLLS := 1 + MAX_ROOMS * PER_ROOM
const FIT := 0.5
const HALF := 0.5
const NONE := -1

var sites: Array[Dictionary] = []
var layouts: Dictionary = {}
var revision := 0


func post(
	key: String, kind: StringName, mouth: float, need: Vector2, cap: Vector2, spec: Dictionary
) -> void:
	var registo := {KEY: key, SITE: kind, MOUTH: mouth, NEED: need, CAP: cap, SPEC: spec}
	for i in sites.size():
		if sites[i][KEY] == key:
			sites[i] = registo
			return
	sites.append(registo)


func count() -> int:
	return sites.size()


func find(x: float, alcance: float) -> int:
	var melhor := NONE
	var perto := alcance
	for i in sites.size():
		var d := absf(float(sites[i][MOUTH]) - x)
		if d <= perto:
			melhor = i
			perto = d
	return melhor


func generated(i: int) -> bool:
	return layouts.has(key_of(i))


func generate(i: int, rolls: PackedFloat32Array) -> bool:
	if generated(i):
		return false
	var s := sites[i]
	layouts[key_of(i)] = lay_out(s[MOUTH], s[NEED], s[CAP], rolls, s[SPEC])
	revision += 1
	return true


func excavate(i: int, cap: Vector2) -> bool:
	if not generated(i) or rooms(i).size() >= MAX_ROOMS:
		return false
	var limit := span(i)
	if cap.y <= limit.y:
		return false
	rooms(i).append(_sala(limit.y, cap.y, &"storage", HALF))
	revision += 1
	return true


func rooms(i: int) -> Array:
	return layouts.get(key_of(i), [])


func span(i: int) -> Vector2:
	var salas := rooms(i)
	if salas.is_empty():
		return Vector2(NAN, NAN)
	return Vector2(salas.front()[A], salas.back()[B])


func key_of(i: int) -> String:
	return sites[i][KEY]


func kind_of(i: int) -> StringName:
	return sites[i][SITE]


func mouth_of(i: int) -> float:
	return sites[i][MOUTH]


func site_at(x: float) -> int:
	for i in sites.size():
		var lim := span(i)
		if not is_nan(lim.x) and x >= lim.x and x <= lim.y:
			return i
	return NONE


func confine(unidades: UnitSystem) -> void:
	for i in unidades.count():
		if int(unidades.bands[i]) != int(Band.Kind.UNDERGROUND):
			continue
		var s := site_at(unidades.xs[i])
		if s == NONE:
			continue
		var lim := span(s)
		unidades.target_xs[i] = clampf(unidades.target_xs[i], lim.x, lim.y)


func hatches() -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for s in sites:
		if s[SITE] == HATCH:
			saida.append(s[MOUTH])
	return saida


func to_dict() -> Dictionary:
	return {LAYOUTS: layouts.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	layouts = (d.get(LAYOUTS, {}) as Dictionary).duplicate(true)
	revision += 1


static func lay_out(
	mouth: float, need: Vector2, cap: Vector2, rolls: PackedFloat32Array, spec: Dictionary
) -> Array[Dictionary]:
	var sala: Vector2 = spec.get(ROOM, Vector2.ONE)
	var largura := maxf(lerpf(sala.x, sala.y, _u(rolls, 1)), float(spec.get(ENTRANCE_PX, 0.0)))
	largura = minf(largura, cap.y - cap.x)
	var a := clampf(mouth - largura * HALF, cap.x, cap.y - largura)
	var salas: Array[Dictionary] = [_sala(a, a + largura, spec.get(ENTRANCE, &""), _u(rolls, 2))]
	while salas.front()[A] > maxf(need.x, cap.x) and _juntar(salas, -1, cap, rolls, spec):
		pass
	while salas.back()[B] < minf(need.y, cap.y) and _juntar(salas, 1, cap, rolls, spec):
		pass
	var extra: int = spec.get(EXTRA, 0)
	for _e in mini(floori(_u(rolls, 0) * float(extra + 1)), extra):
		var lado := -1 if _u(rolls, PER_ROOM * (salas.size() + 1)) < HALF else 1
		if (
			not _juntar(salas, lado, cap, rolls, spec)
			and not _juntar(salas, -lado, cap, rolls, spec)
		):
			break
	for f: Array in spec.get(FEATURES, []):
		for s in salas:
			if float(f[0]) >= s[A] and float(f[0]) <= s[B]:
				s[KIND] = f[1]
	return salas


static func _juntar(
	salas: Array[Dictionary], lado: int, cap: Vector2, rolls: PackedFloat32Array, spec: Dictionary
) -> bool:
	var j := salas.size()
	if j >= MAX_ROOMS:
		return false
	var sala: Vector2 = spec.get(ROOM, Vector2.ONE)
	var largura := lerpf(sala.x, sala.y, _u(rolls, 1 + PER_ROOM * j))
	var tipos: Array = spec.get(POOL, [])
	var u := _u(rolls, 2 + PER_ROOM * j)
	var tipo: StringName = (
		tipos[mini(floori(u * tipos.size()), tipos.size() - 1)] if not tipos.is_empty() else &""
	)
	if lado < 0:
		var b: float = salas.front()[A]
		var a := maxf(cap.x, b - largura)
		if b - a < sala.x * FIT:
			return false
		salas.push_front(_sala(a, b, tipo, u))
	else:
		var a: float = salas.back()[B]
		var b := minf(cap.y, a + largura)
		if b - a < sala.x * FIT:
			return false
		salas.push_back(_sala(a, b, tipo, u))
	return true


static func _sala(a: float, b: float, tipo: StringName, u: float) -> Dictionary:
	return {A: a, B: b, KIND: tipo, ROLL: u}


static func _u(rolls: PackedFloat32Array, i: int) -> float:
	return rolls[i] if i < rolls.size() else HALF
