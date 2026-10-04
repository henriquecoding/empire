class_name LastCart
extends RefCounted

const NONE := -1
const RETURNING := -1.0
const FORAGE := &"forage"
const SCOUT := &"scout"
const RESCUE := &"rescue"

var active := false
var origin := 0.0
var choice: StringName = &""
var offset := 0.0
var seconds := 0.0
var worker := NONE
var task: StringName = &""
var progress := 0.0
var cache_x := 0.0
var cache_coins := 0
var scar := false
var tainted := false
var scouted := false
var survived := false
var consolidated := false
var earned := 0
var earned_day := 1
var events: Dictionary = {}


func begin(x: float, cache: float, coins: int) -> void:
	active = true
	origin = x
	cache_x = cache
	cache_coins = maxi(0, coins)


func claim(id: StringName, shift: float) -> bool:
	if not active or choice != &"" or id == &"":
		return false
	choice = id
	offset = shift
	record(&"foundation_choice_committed", id)
	record(&"foundation_choice_id", id)
	return true


func record(event: StringName, value: Variant = true) -> void:
	if not events.has(event):
		events[event] = {&"seconds": seconds, &"value": value}


func assign(id: int, work: StringName) -> void:
	worker = id
	task = work if id != NONE else &""
	progress = 0.0
	if id != NONE:
		record(&"first_worker_assignment", work)
		if survived and events.has(&"pre_night_strategy"):
			if events[&"pre_night_strategy"][&"value"] != work:
				record(&"post_night_plan_changed", work)


func work(delta: float, duration: float) -> bool:
	if worker == NONE or task == &"":
		return false
	progress += maxf(0.0, delta)
	if progress < duration:
		return false
	progress = 0.0
	return true


func spoil() -> int:
	var lost := cache_coins
	cache_coins = 0
	scar = true
	record(&"night_one_loss_type", &"provisions" if lost > 0 else &"none")
	return lost


func to_dict() -> Dictionary:
	return {
		&"active": active,
		&"origin": origin,
		&"choice": choice,
		&"offset": offset,
		&"seconds": seconds,
		&"worker": worker,
		&"task": task,
		&"progress": progress,
		&"cache_x": cache_x,
		&"cache_coins": cache_coins,
		&"scar": scar,
		&"tainted": tainted,
		&"scouted": scouted,
		&"survived": survived,
		&"consolidated": consolidated,
		&"earned": earned,
		&"earned_day": earned_day,
		&"events": events.duplicate(true),
	}


func from_dict(d: Dictionary) -> void:
	active = d.get(&"active", false) == true
	origin = float(d.get(&"origin", 0.0))
	choice = StringName(d.get(&"choice", &""))
	offset = float(d.get(&"offset", 0.0))
	seconds = float(d.get(&"seconds", 0.0))
	worker = int(d.get(&"worker", NONE))
	task = StringName(d.get(&"task", &""))
	progress = float(d.get(&"progress", 0.0))
	cache_x = float(d.get(&"cache_x", 0.0))
	cache_coins = int(d.get(&"cache_coins", 0))
	scar = d.get(&"scar", false) == true
	tainted = d.get(&"tainted", false) == true
	scouted = d.get(&"scouted", false) == true
	survived = d.get(&"survived", false) == true
	consolidated = d.get(&"consolidated", false) == true
	earned = int(d.get(&"earned", 0))
	earned_day = int(d.get(&"earned_day", 1))
	events = d.get(&"events", {}).duplicate(true)
