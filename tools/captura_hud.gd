extends Node

const PREFS := "user://hud_capture.cfg"

var _game: Game
var _frames := 90
var _options := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(0, args.size() - 1):
		if args[index].begins_with("--") and not args[index + 1].begins_with("--"):
			_options[args[index].trim_prefix("--")] = args[index + 1]
	Preferences.set_shared(Preferences.new(PREFS))
	Preferences.shared().set_enabled(
		Preferences.TOUCH_LEFT, _options.get("left", "false") == "true"
	)
	Preferences.shared().set_enabled(
		Preferences.CAPTIONS, _options.get("captions", "false") == "true"
	)
	Preferences.shared().set_number(Preferences.TOUCH_SCALE, float(_options.get("size", "1.0")))
	SimLoop.autosave_enabled = false
	_game = preload("res://scenes/game.tscn").instantiate() as Game
	add_child(_game)
	if _game._selector != null:
		_game._chosen(StringName(_options.get("monarch", "monarch")))
	TranslationServer.set_locale(_options.get("locale", "pt_PT"))
	if _options.get("touch", "false") == "true":
		TouchControls.active = true
		CombatInput.device = Glyphs.Device.TOUCH
		(_game.get_node(^"Interface/HUD") as GameHud)._dispositivo = Glyphs.Device.TOUCH
		(_game.get_node(^"Interface/HUD") as GameHud)._context.device = Glyphs.Device.TOUCH
		WideTouch.apply(get_tree().root, true)
	var touch := _game.get_node(^"Interface/Toque") as TouchControls
	touch.pad.layout.left_handed = _options.get("left", "false") == "true"
	if _options.get("overview", "false") == "true":
		SimLoop.set_paused(true)
		(_game.get_node(^"Interface/Pausa") as PauseMenu)._show_controls(PauseMenu.Page.REALM)


func _process(_delta: float) -> void:
	_frames -= 1
	if _frames == 10 and _options.get("captions", "false") == "true":
		EventBus.dusk_fell.emit(ClockService.clock.day)
	if _frames == 10 and _options.has("notice"):
		(_game.get_node(^"Interface/HUD") as GameHud).say(String(_options.notice))
	if _frames > 0:
		return
	set_process(false)
	await RenderingServer.frame_post_draw
	var path: String = _options.get("output", "build/hud/capture.png")
	var result := get_viewport().get_texture().get_image().save_png(path)
	print("HUD capture: %s (%d)" % [path, result])
	var hud := _game.get_node(^"Interface/HUD") as GameHud
	var context := hud._context
	var facts := {
		"window": str(DisplayServer.window_get_size()),
		"viewport": str(get_viewport().get_visible_rect().size),
		"context": str(context.get_global_rect()),
		"context_lines": context.get_line_count(),
		"context_visible_lines": context.get_visible_line_count(),
		"prepared": true,
		"options": _options,
	}
	FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE).store_string(
		JSON.stringify(facts, "\t")
	)
	for file: String in [PREFS, PREFS + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	get_tree().quit(result)
