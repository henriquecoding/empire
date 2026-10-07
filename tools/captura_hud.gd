# tools/captura_hud.gd — a HUD do jogo real numa imagem, e o que e preciso para a repetir.
#
# O PNG sai com um JSON ao lado: alem das medidas do contexto, o manifesto que o plano de
# cenarios pede a cada captura (CV-01, §30.1): o commit, o motor, o renderer, o modo de
# stretch, a semente, o dia, a fase e onde esta o monarca. Uma captura sem isto nao se
# compara com outra. `--fundacao true` para o monarca no primeiro sitio livre a leste,
# `--ficha true` abre a ficha desse sitio (UX-08) e `--inspetor true` abre o inspetor com
# a sobreposicao do territorio (CV-39); `--x` poe o monarca num x do mundo.
extends Node

const PREFS := "user://hud_capture.cfg"
const PASSO_PX := 16.0

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
	if _options.get("fundacao", "false") == "true":
		_parar_num_sitio()
	if _options.has("x"):  # o monarca num x do mundo, para enquadrar uma fonte (CV-39)
		var rei := SimLoop.units.index_of(SimLoop.king_id)
		SimLoop.units.xs[rei] = float(_options.x)
		SimLoop.units.clear_target(SimLoop.king_id)
	if _options.get("overview", "false") == "true":
		SimLoop.set_paused(true)
		(_game.get_node(^"Interface/Pausa") as PauseMenu)._show_controls(PauseMenu.Page.REALM)


func _process(_delta: float) -> void:
	_frames -= 1
	if _frames == 10 and _options.get("captions", "false") == "true":
		EventBus.dusk_fell.emit(ClockService.clock.day)
	if _frames == 20 and _options.get("ficha", "false") == "true":
		get_tree().call_group(&"site_sheet", &"open")
	if _frames == 20 and _options.get("inspetor", "false") == "true":
		var estado := _game.get_node(^"Interface/Estado") as Inspector
		estado.visible = true
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
		"manifest": _manifesto(),
	}
	FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE).store_string(
		JSON.stringify(facts, "\t")
	)
	for file: String in [PREFS, PREFS + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	get_tree().quit(result)


## O primeiro sitio a leste do monarca onde a fundacao vale, e o monarca parado la.
func _parar_num_sitio() -> void:
	var u := SimLoop.units
	var rei := u.index_of(SimLoop.king_id)
	var x := u.xs[rei]
	while x < SimLoop.world_width:
		x += PASSO_PX
		if FoundationChoice.valid(x) and not FoundationChoice.priority_at(x):
			break
	u.xs[rei] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.arrival.stationary_s = LastCartWatch.rules().foundation_stop_s


## O que identifica esta captura (§30.1 do plano de cenarios).
func _manifesto() -> Dictionary:
	var sha := []
	OS.execute("git", ["rev-parse", "HEAD"], sha)
	var u := SimLoop.units
	var rei := u.index_of(SimLoop.king_id)
	return {
		"commit": String(sha[0]).strip_edges() if not sha.is_empty() else "",
		"godot": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"stretch": ProjectSettings.get_setting("display/window/stretch/mode"),
		"aspect": ProjectSettings.get_setting("display/window/stretch/aspect"),
		"scale_mode": ProjectSettings.get_setting("display/window/stretch/scale_mode"),
		"screen_scale": DisplayServer.screen_get_scale(),
		"locale": TranslationServer.get_locale(),
		"seed": SimLoop.state.seed,
		"day": SimLoop.state.day,
		"phase": ClockService.clock.current_phase(),
		"king_x": u.xs[rei] if rei >= 0 else 0.0,
		"king_band": u.bands[rei] if rei >= 0 else -1,
		"touch": TouchControls.active,
		"site_sheet": SiteSheet.active,
		"inspector": Inspector.shown,
	}
