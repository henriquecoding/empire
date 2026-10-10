class_name UndergroundSites
extends RefCounted

const CELLAR := &"cellar"
const HATCH := &"hatch"
const DUNGEON := &"dungeon"
const CAVE := &"cave"
const A := &"a"
const B := &"b"
const KIND := &"kind"
const ROLL := &"roll"
const FEATS := &"feats"
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
const RULES := &"rules"
const FAMILY := &"family"
const MANDATORY := &"mandatory"
const DENY := &"deny"
const SEGMENT := &"segment"
const LAYOUTS := &"layouts"
const META := &"meta"
const VERSION := &"v"
const CHEST := &"chest"
const MENDED := &"mended"
const WHY := &"why"
const PLAN := &"plan"
const LIMIT := &"limit"
const MAX_ROOMS := 12
const PER_ROOM := 3
const ROLLS := 1 + MAX_ROOMS * PER_ROOM
const HALF := 0.5
const NONE := -1

var sites: Array[Dictionary] = []
var layouts: Dictionary = {}
## Por chave: a versao do gerador com que o sitio nasceu, o bau e se foi reparado.
var meta: Dictionary = {}
var revision := 0


func post(
	key: String, kind: StringName, mouth: float, need: Vector2, cap: Vector2, spec: Dictionary
) -> void:
	var registo := {KEY: key, SITE: kind, MOUTH: mouth, NEED: need, CAP: cap, SPEC: spec}
	var novo := true
	for i in sites.size():
		if sites[i][KEY] == key:
			sites[i] = registo
			novo = false
	if novo:
		sites.append(registo)
	UnderReserve.reserve(self)


func count() -> int:
	return sites.size()


## A boca mais perto de `x`, das que levam a algum lado: um sitio rejeitado nao tem
## entrada (ADR 0072).
func find(x: float, alcance: float) -> int:
	var melhor := NONE
	var perto := alcance
	for i in sites.size():
		var d := absf(float(sites[i][MOUTH]) - x)
		if d <= perto and usable(i):
			melhor = i
			perto = d
	return melhor


func generated(i: int) -> bool:
	return layouts.has(key_of(i))


## Obrigatorio nao dispensa chao util: nunca publicar uma escada sem baia.
func usable(i: int) -> bool:
	return why(i) == UnderFit.OK


## Porque o sitio nao serve, ou UnderFit.OK. O de um sitio gerado e o do que nasceu.
func why(i: int) -> StringName:
	if generated(i):
		return (meta.get(key_of(i), {}) as Dictionary).get(WHY, UnderFit.OK)
	return sites[i].get(WHY, UnderFit.OK)


func generate(i: int, rolls: PackedFloat32Array) -> bool:
	if generated(i) or not usable(i):
		return false
	var s := sites[i]
	var lim: Vector2 = s[LIMIT]
	if is_nan(lim.x):
		return false
	var rooms_new := UnderLayout.lay_out(s[MOUTH], s[NEED], lim, rolls, s[SPEC])
	if rooms_new.is_empty():
		return false
	var bounds := Vector2(rooms_new.front()[A], rooms_new.back()[B])
	if (
		UnderFit.check(bounds, s[MOUTH], UnderLayout.blocked(s[SPEC]), UnderLayout.rules(s[SPEC]))
		!= UnderFit.OK
	):
		return false
	layouts[key_of(i)] = rooms_new
	meta[key_of(i)] = {VERSION: UnderLayout.rules(s[SPEC]).generator_version}
	UnderReserve.stamp(self, i)
	revision += 1
	UnderReserve.reserve(self)
	return true


## A cave real cresce ate `cap`, para o lado que ele pedir, sem passar o chao de outro.
func excavate(i: int, cap: Vector2) -> bool:
	if not generated(i):
		return false
	var lim := UnderReserve.limit_of(self, i, cap)
	if is_nan(lim.x):
		return false
	var cresceu := false
	for lado in [-1, 1]:
		var ate := lim.x if lado < 0 else lim.y
		cresceu = (
			UnderLayout.extend(rooms(i), lado, ate, sites[i][SPEC], HALF, &"storage") or cresceu
		)
	if not cresceu:
		return false
	UnderReserve.stamp(self, i)
	revision += 1
	UnderReserve.reserve(self)
	return true


func set_cap(i: int, cap: Vector2) -> void:
	if sites[i][CAP] != cap:
		sites[i][CAP] = cap
		UnderReserve.reserve(self)


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
	for i in sites.size():
		if kind_of(i) == HATCH and usable(i):
			saida.append(mouth_of(i))
	return saida


## As bocas que nao sao passagens do reino: masmorras, cavernas e alcapoes, das que levam
## a algum lado.
func mouths() -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for i in sites.size():
		if kind_of(i) != CELLAR and usable(i):
			saida.append(mouth_of(i))
	return saida


func to_dict() -> Dictionary:
	return {LAYOUTS: layouts.duplicate(true), META: meta.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	layouts = (d.get(LAYOUTS, {}) as Dictionary).duplicate(true)
	meta = (d.get(META, {}) as Dictionary).duplicate(true)
	revision += 1
	UnderReserve.reserve(self)
