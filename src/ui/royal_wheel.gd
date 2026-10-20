class_name RoyalWheel
extends Control

const FONTS := Vector2i(18, 14)
const CAPTION := Rect2(-170, 136, 340, 40)
const DETAIL := Rect2(-200, 184, 400, 0)
const CENTER_Y := 0.43
const DETAIL_RESERVE := 190
const SHORT_HEIGHT := 500
const SMALL := {
	"margin": 32,
	"center_x": 0.27,
	"center_y": 0.5,
	"text_x": 0.53,
	"top": 24,
	"text_width": 0.47,
	"right": 16,
	"gap": 52
}

static var active := false
static var release_guard := false

var impulses := false
var selected := -1
var _held := false
var _await_release := false
var _art_scale := 1.0
var _mouse := false
var _keyboard := false
var _caption: Label
var _detail: Label
var _device := Glyphs.Device.KEYBOARD
var _center := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_caption = HudStyle.label(self, FONTS.x, Atlas.COIN)
	_detail = HudStyle.label(self, FONTS.y)
	for label: Label in [_caption, _detail]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_stylebox_override("normal", CrownSkin.plate())
	EventBus.game_paused.connect(_paused)
	close()


func _input(event: InputEvent) -> void:
	_device = Glyphs.device_of(event, _device, Input.get_joy_name(event.device))
	if not active:
		return
	RoyalWheelInput.handle(self, event)


func _process(_delta: float) -> void:
	var held := Input.is_action_pressed(&"king_wheel")
	if (
		release_guard
		and not held
		and not Input.is_action_pressed(&"verb_drop")
		and not Input.is_action_pressed(&"attack")
	):
		release_guard = false
	if not allowed():
		if active:
			close()
		_held = held
		return
	if held and not _held and not release_guard:
		if not active:
			open()
		selected = -1
		_mouse = false
		_keyboard = false
	if active:
		fit()
		var aim := InputRouter._stick()
		if _mouse:
			aim = (get_local_mouse_position() - _center) / (RoyalWheelArt.INNER * _art_scale)
		if not _keyboard:
			selected = InputRouter.wheel_segment(aim, count())
		InputRouter.pointed = selected
		if _held and not held and not _await_release:
			choose(selected)
		if not held:
			_await_release = false
		if active:
			_readout()
			queue_redraw()
	_held = held
	Pace.scale = (
		(Registry.entry(&"economy", &"clock") as ClockData).wheel_time_scale
		if active and Preferences.on(Preferences.WHEEL_SLOWDOWN)
		else 1.0
	)


static func allowed() -> bool:
	return (
		SimLoop.running()
		and SimLoop.field != null
		and Assume.king()
		and SimLoop.units.index_of(SimLoop.king_id) >= 0
		and not ClassSelection.active
		and not TravelPanel.active
		and not SiteSheet.active
	)


func open() -> void:
	if not allowed():
		return
	active = true
	impulses = false
	_keyboard = false
	selected = -1
	show()
	fit()
	_readout()
	queue_redraw()


func close() -> void:
	active = false
	release_guard = true
	_await_release = false
	impulses = false
	_keyboard = false
	selected = -1
	InputRouter.pointed = -1
	Pace.scale = 1.0
	hide()


func choose(index: int) -> void:
	if not active or index < 0 or index >= count():
		close()
		return
	if not impulses and index == RoyalCommands.Family.BOOST:
		impulses = true
		_await_release = true
		selected = -1
		_held = false
		_mouse = false
		_readout()
		queue_redraw()
		return
	var was_impulse := impulses
	close()
	if was_impulse:
		RoyalCommands.boost(index, self)
	else:
		RoyalCommands.choose(index, self, _device)


func count() -> int:
	return SimLoop.field.crown.ids().size() if impulses else RoyalCommands.FAMILIES.size()


func fit() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	# O aro pode encolher numa janela baixa; a leitura conserva a escala de texto.
	var screen := get_viewport_rect().size / zoom
	scale = Vector2.ONE * zoom
	size = screen
	_center = Vector2(screen.x / 2, minf(screen.y * CENTER_Y, screen.y - DETAIL_RESERVE))
	_caption.position = _center + CAPTION.position
	_caption.size = CAPTION.size
	_detail.position = _center + DETAIL.position
	_detail.size = DETAIL.size
	_art_scale = 1.0
	if screen.y < SHORT_HEIGHT:
		_art_scale = minf(1.0, (screen.y - SMALL.margin) / (RoyalWheelArt.RADIUS * 2))
		_center = Vector2(screen.x * SMALL.center_x, screen.y * SMALL.center_y)
		_caption.position = Vector2(screen.x * SMALL.text_x, SMALL.top)
		_caption.size = Vector2(screen.x * SMALL.text_width - SMALL.right, CAPTION.size.y)
		_detail.position = _caption.position + Vector2(0, SMALL.gap)
		_detail.size = Vector2(_caption.size.x, 0)
		if TouchControls.active:
			_caption.size.x -= HudRibbon.PAUSE_OFFSET.x


func _readout() -> void:
	_caption.text = tr(&"WHEEL_TITLE" if not impulses else &"WHEEL_BOOST")
	_detail.text = tr(&"WHEEL_GESTURE")
	if selected < 0:
		return
	if not impulses:
		_caption.text = tr(RoyalCommands.NAMES[selected])
		_detail.text = (
			tr(&"WHEEL_BOOST_HELP")
			if selected == RoyalCommands.Family.BOOST
			else RoyalCommands.describe(selected, _device)
		)
		return
	var id: StringName = SimLoop.field.crown.ids()[selected]
	var data := Registry.entry(&"crown/impulses", id) as ImpulseData
	_caption.text = tr(data.display_key)
	var price := SimLoop.field.crown.price(
		id, ClockService.clock.day, RulesFactory.impulse_cost_mult(SimLoop.state.greed)
	)
	var refusal := InputRouter.impulse_refusal(id)
	_detail.text = refusal if not refusal.is_empty() else tr(&"WHEEL_COST").format({"cost": price})


func _draw() -> void:
	if active:
		draw_set_transform(_center, 0.0, Vector2.ONE * _art_scale)
		RoyalWheelArt.draw(self, Vector2.ZERO, selected, impulses, count())


func _paused(_paused_now: bool) -> void:
	close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		close()


func _exit_tree() -> void:
	active = false
	release_guard = false
	Pace.scale = 1.0
