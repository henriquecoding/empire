## Prepared visual fixtures; this tool is excluded from game exports.
extends Node

const GAME := preload("res://scenes/game.tscn")
const SEED := 20260919
const WARMUP := 60
const MEASURE := 120
var _frame := 0
var _mode := "day"
var _samples: Array[float] = []
var _physics: Array[float] = []
var _game: Game
var _out := "build/review"
var _draw_calls := 0.0
var _start := 0


func _ready() -> void:
	_start = Time.get_ticks_usec()
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_mode = args[0]
	if args.size() > 1:
		_out = args[1]
	TranslationServer.set_locale("pt_PT")
	Registry.load_all()
	SimLoop.autosave_enabled = false
	_game = GAME.instantiate()
	add_child(_game)
	SimLoop.start(SEED)
	Greybox.build()
	var clock := Registry.entry(&"economy", &"clock") as ClockData
	var elapsed := 0.0
	var phase := GameClock.Phase.NIGHT if _mode == "night" else GameClock.Phase.NOON
	for i in int(phase):
		elapsed += clock.phase_durations[i]
	elapsed += clock.phase_durations[phase] * 0.5
	ClockService.seek(1, elapsed)
	if _mode == "cast":
		# Hold simulation for a reference lineup; this mode is not a performance test.
		SimLoop.set_physics_process(false)
		for i in SimLoop.units.count():
			if SimLoop.units.ids[i] != SimLoop.king_id:
				SimLoop.units.xs[i] = 100.0
		var roles := [&"squire", &"cook", &"archer"]
		var offsets := [-260.0, -130.0, 150.0]
		for i in roles.size():
			var troop := Registry.entry(&"units", roles[i]) as UnitData
			SimLoop.units.spawn(SimLoop.state, troop, 1, SimLoop.core_x + offsets[i])
	if _mode in ["passage", "under"]:
		var king := SimLoop.units.index_of(SimLoop.king_id)
		SimLoop.units.xs[king] = SimLoop.passages[0]
		if _mode == "under":
			SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	if _mode == "crowd":
		var troop := Registry.entry(&"units", &"archer") as UnitData
		for i in 300 - SimLoop.units.count():
			SimLoop.units.spawn(SimLoop.state, troop, 1, 80.0 + float(i % 60) * 60.0)
	if _mode in ["pause", "defeat"]:
		if _mode == "defeat":
			for slot in SimLoop.builds.slots:
				if slot.kind == BuildSlot.NUCLEO:
					slot.health = 0
					slot.state = BuildSlot.State.RUIN
		SimLoop.set_paused(true)
	if _mode == "states":
		var states := [
			BuildSlot.State.EMPTY,
			BuildSlot.State.SCAFFOLD,
			BuildSlot.State.BUILDING,
			BuildSlot.State.DONE,
			BuildSlot.State.DAMAGED
		]
		for i in states.size():
			var slot := Greybox._do_edificio(
				Registry.entry(&"buildings", &"training_house"),
				SimLoop.core_x - 480.0 + float(i) * 160.0
			)
			slot.state = states[i]
			slot.level = 1 if i >= 3 else 0
			slot.health = 20 if i == 4 else slot.max_health()
			SimLoop.builds.post(slot)


func _process(delta: float) -> void:
	_frame += 1
	if _mode == "motion":
		Input.action_press(&"move_right")
	if _frame <= WARMUP:
		return
	_samples.append(delta * 1000.0)
	_physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	_draw_calls = maxf(
		_draw_calls, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	)
	if _frame < WARMUP + MEASURE:
		return
	set_process(false)
	Input.action_release(&"move_right")
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
	assert(image.save_png(_out + ".png") == OK)
	_samples.sort()
	_physics.sort()
	var result := {
		"fixture": _mode,
		"prepared_state": true,
		"simulation_held": _mode == "cast",
		"seed": SEED,
		"renderer": RenderingServer.get_video_adapter_name(),
		"units": SimLoop.units.count(),
		"frames_measured": MEASURE,
		"frame_p50_ms": _samples[MEASURE / 2],
		"frame_p95_ms": _samples[int(MEASURE * 0.95)],
		"physics_p95_ms": _physics[int(MEASURE * 0.95)],
		"max_draw_calls": _draw_calls,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"elapsed_seconds": float(Time.get_ticks_usec() - _start) / 1000000.0,
		"viewport": str(get_viewport().get_visible_rect().size),
		"window": str(DisplayServer.window_get_size()),
		"king_band": SimLoop.units.bands[SimLoop.units.index_of(SimLoop.king_id)],
	}
	var file := FileAccess.open(_out + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	get_tree().quit()
