class_name BuildSlot
extends RefCounted

enum State { EMPTY, SCAFFOLD, BUILDING, DONE, DAMAGED, RUIN }

enum Path { NENHUMA, GUARNICAO, FORTIFICACAO }

const NENHUM := -1

const NUCLEO := &"core"
const METADE := 0.5

var territory := 0
## A razao por que o territorio recusa este sitio, ou vazia (ADR 0077). Derivada: nao vai no save.
var terrain_bar: StringName = &""
var foundation := false
var builder_work := false
var rebuild_cost := 0
var id: int = NENHUM
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE

var kind: StringName = &""

var costs: PackedInt32Array = PackedInt32Array()
var works: PackedFloat32Array = PackedFloat32Array()
var healths: PackedInt32Array = PackedInt32Array()
var defenses := PackedFloat32Array()

var healths_a: PackedInt32Array = PackedInt32Array()
var posts_a: PackedInt32Array = PackedInt32Array()
var posts_b: PackedInt32Array = PackedInt32Array()
var contacts: PackedInt32Array = PackedInt32Array()
var conquests: PackedStringArray = PackedStringArray()
var woods: PackedInt32Array = PackedInt32Array()
var unique: PackedByteArray = PackedByteArray()
var path: Path = Path.NENHUMA

var contact: PackedInt32Array = PackedInt32Array()

var width: float = 0.0
var widths: PackedFloat32Array = PackedFloat32Array()

var blocks: bool = false

var job_id: StringName = &""
var job_slots: int = 0

var yield_per_day: float = 0.0
var stock: float = 0.0
var charge := 0.0
var razed_by_rot: bool = false

var effects: Dictionary = {}
var effects_b: Dictionary = {}
var variant: int = 0

var level: int = 0
var state: State = State.EMPTY
var paid: int = 0
var progress: float = 0.0
var health: int = 0
var mending := false
var rest_day := 0
var soaked: float = 0.0


func standing() -> bool:
	return state == State.DONE or state == State.DAMAGED


func upgrading() -> bool:
	return level > 0 and not mending and state in [State.SCAFFOLD, State.BUILDING]


func holds() -> bool:
	return standing() or upgrading()


func woods_for_next(conquistas: PackedStringArray) -> int:
	if level >= woods.size():
		return 0
	var povo := conquests[level] if level < conquests.size() else ""
	if povo.is_empty() or povo in conquistas:
		return woods[level] if povo.is_empty() else 0
	return woods[level] if woods[level] > 0 else NENHUM


func next_unique() -> bool:
	return level < unique.size() and unique[level] == 1


func repair_cost() -> int:
	if level <= 0 or level > costs.size() or costs[level - 1] <= 0 or works.is_empty():
		return NENHUM
	if state == State.RUIN:
		return rebuild_cost if foundation else costs[level - 1]
	if state != State.DAMAGED:
		return NENHUM
	var perdida := 1.0 - float(health) / maxf(1.0, float(max_health()))
	return maxi(1, ceili(costs[level - 1] * perdida))


func soak(quanto: int, defesa: float) -> int:
	if kind == NUCLEO and level > 0 and level <= defenses.size():
		defesa = defenses[level - 1]
	if (not two_paths() and kind != NUCLEO) or defesa <= 0.0:
		return quanto
	soaked += quanto * defesa / (1.0 + defesa)
	var poupado := mini(quanto, int(soaked))
	soaked -= poupado
	return quanto - poupado


func next_cost() -> int:
	return costs[level] if level < costs.size() else NENHUM


func max_health() -> int:
	if level <= 0:
		return 0
	if path == Path.GUARNICAO and level <= healths_a.size():
		return healths_a[level - 1]
	return healths[level - 1] if level <= healths.size() else 0


func posts() -> int:
	if level <= 0:
		return 0
	var tabela := posts_a if path == Path.GUARNICAO else posts_b
	return tabela[level - 1] if level <= tabela.size() else job_slots


func contact_slots() -> int:
	return contacts[level - 1] if level > 0 and level <= contacts.size() else 0


func to_dict() -> Dictionary:
	return {
		&"id": id,
		&"kind": kind,
		&"x": x,
		&"band": int(band),
		&"territory": territory,
		&"foundation": foundation,
		&"rebuild_cost": rebuild_cost,
		&"level": level,
		&"state": int(state),
		&"paid": paid,
		&"progress": progress,
		&"health": health,
		&"mending": mending,
		&"rest_day": rest_day,
		&"soaked": soaked,
		&"stock": stock,
		&"path": int(path),
		&"variant": variant,
		&"contact": contact,
		&"charge": charge,
	}


func from_dict(d: Dictionary) -> void:
	territory = int(d.get(&"territory", territory))
	foundation = bool(d.get(&"foundation", foundation))
	rebuild_cost = int(d.get(&"rebuild_cost", rebuild_cost))
	level = d.get(&"level", level)
	state = d.get(&"state", int(state)) as State
	paid = d.get(&"paid", paid)
	progress = d.get(&"progress", progress)
	health = d.get(&"health", health)
	mending = d.get(&"mending", mending)
	rest_day = int(d.get(&"rest_day", 0))
	soaked = d.get(&"soaked", soaked)
	stock = d.get(&"stock", stock)
	path = d.get(&"path", int(path)) as Path
	variant = d.get(&"variant", variant)
	contact = d.get(&"contact", contact)
	charge = d.get(&"charge", charge)
	fit()


func fit() -> void:
	if not widths.is_empty():
		width = widths[clampi(level, 0, widths.size() - 1)]


func raise_to(nivel: int) -> void:
	level = clampi(nivel, 0, costs.size())
	paid = 0
	progress = 0.0
	state = State.DONE if level > 0 else State.EMPTY
	health = max_health()
	fit()


func raised_health(antes: int) -> int:
	if kind != NUCLEO or antes <= 0:
		return max_health()
	return ceili(float(health) * max_health() / antes)


func catch_half() -> float:
	return (widths[0] if not widths.is_empty() else width) * METADE


func two_paths() -> bool:
	return not healths_a.is_empty()


func choose_path(escolha: Path) -> bool:
	if not two_paths() or level > 1:
		return false
	path = escolha
	return true
