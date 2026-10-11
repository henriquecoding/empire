extends Node

const STEP := 1.0 / 30.0
const POPULATION := 300
const WARMUP := 60
const SAMPLES := 300


func _ready() -> void:
	call_deferred("_measure")


func _measure() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261011)
	Greybox.build()
	LastCartWatch.claim(&"road")
	var units := SimLoop.units
	var owner := units.owners[units.index_of(SimLoop.king_id)]
	var archer := Registry.entry(&"units", &"archer") as UnitData
	while units.count() < POPULATION:
		units.spawn(SimLoop.state, archer, owner, SimLoop.core_x + (units.count() % 20 - 10) * 12.0)
	for _i in WARMUP:
		SimLoop.step(STEP)
	var times := PackedFloat64Array()
	for _i in SAMPLES:
		var start := Time.get_ticks_usec()
		SimLoop.step(STEP)
		times.append((Time.get_ticks_usec() - start) / 1000.0)
	times.sort()
	var sum := 0.0
	for value in times:
		sum += value
	var result := {
		"metodo": "CPU headless; SimLoop.step, sem rasterizacao nem certificacao fisica",
		"certificacao_fisica": false,
		"commit": OS.get_environment("GITHUB_SHA"),
		"godot": Engine.get_version_info().string,
		"sistema": OS.get_name(),
		"processadores": OS.get_processor_count(),
		"tropas": units.count(),
		"criaturas": SimLoop.creatures.count(),
		"amostras": SAMPLES,
		"aquecimento": WARMUP,
		"tick_media_ms": sum / SAMPLES,
		"tick_p50_ms": times[SAMPLES / 2],
		"tick_p95_ms": times[int(SAMPLES * 0.95)],
		"tick_p99_ms": times[int(SAMPLES * 0.99)],
		"tick_max_ms": times[SAMPLES - 1],
	}
	DirAccess.make_dir_recursive_absolute("res://build")
	var file := FileAccess.open("res://build/benchmark-sim.json", FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("benchmark: ", JSON.stringify(result))
	SimLoop.stop()
	get_tree().quit()
