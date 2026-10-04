# Pausa, opcoes e confirmacao em paginas distintas (UX-01, pedido de 30/09).
class_name PauseMenu
extends Control

enum Page { HOME, OPTIONS, CONTROLS, CONFIRM }

const GRUPO_JOGO := &"jogo"
const RECOMECAR := &"new_game"
const ABDICAR := &"end_reign"
const FUNDO := Color(0.035, 0.04, 0.035, 0.78)

var _titulo: Label
var _opcoes: OptionsPanel
var _retomar: Button
var _novo: Button
var _zero: FreshStartPanel
var _options_button: Button
var _controls_button: Button
var _exit_button: Button
var _export_button: Button
var _save_note: Label
var _frame: PauseLayout
var _pages := PausePages.new()
var _page := Page.HOME
var _device := Glyphs.Device.KEYBOARD
var _perdido := false
var _herdeiro := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"pause_menu")
	var fundo := ColorRect.new()
	fundo.color = FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	_frame = PauseLayout.new()
	add_child(_frame)
	_titulo = PauseTheme.label(_frame.header)
	_retomar = PauseTheme.button(_frame.actions, &"UI_RESUME", _ao_retomar)
	PauseTheme.primary(_retomar)
	_novo = PauseTheme.button(_frame.actions, &"UI_NEW_GAME", _ao_recomecar)
	_options_button = PauseTheme.button(_frame.actions, &"UI_OPTIONS", show_options)
	_controls_button = PauseTheme.button(_frame.actions, &"UI_CONTROLS", _show_controls)
	_frame.actions.add_child(ScreenRow.new())  # o ecra inteiro do browser (UX-03)
	_zero = FreshStartPanel.new(_fechar)
	_frame.actions.add_child(_zero)
	_export_button = PauseTheme.button(
		_frame.actions, &"ARRIVAL_EXPORT", ArrivalTelemetry.export_local
	)
	_exit_button = PauseTheme.button(_frame.actions, &"UI_SAVE_AND_QUIT", _leave)
	_save_note = PauseTheme.label(_frame.actions)
	_save_note.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)
	_save_note.add_theme_color_override("font_color", PauseTheme.MUTED)
	_pages.build(_frame, back, _zero)
	_opcoes = _pages.option_panel
	_device = PauseHelp.current_device()
	_escrever()
	hide()
	EventBus.game_paused.connect(_na_pausa)


func _na_pausa(pausado: bool) -> void:
	if pausado:
		open(defeated() or SimLoop.state != null and SimLoop.state.crossed)
	else:
		_fechar()


func open(perdido: bool) -> void:
	_frame.enter()
	_perdido = perdido
	_herdeiro = not perdido and heir_waits()
	_retomar.visible = not perdido
	_novo.visible = perdido or _herdeiro
	_opcoes.refresh()
	_zero.close()
	_page = Page.HOME
	_frame.switch_to(_frame.home)
	_escrever()
	show()
	(_novo if perdido else _retomar).grab_focus()


static func defeated() -> bool:
	return Defeat.happened()


static func heir_waits() -> bool:
	return SimLoop.state != null and Defeat.king_fell() and not Defeat.happened()


func show_options() -> void:
	_page = Page.OPTIONS
	_opcoes.refresh()
	_frame.switch_to(_pages.options)
	_opcoes.focus_first()


func show_confirmation() -> void:
	_page = Page.CONFIRM
	_frame.switch_to(_pages.reset)
	_zero._cancelar.grab_focus()


func back() -> void:
	var previous := _page
	if previous == Page.HOME:
		_ao_retomar()
		return
	_zero.close()
	_page = Page.HOME
	_frame.switch_to(_frame.home)
	var origin := _options_button if previous == Page.OPTIONS else _controls_button
	if previous == Page.CONFIRM:
		origin = _zero._abrir
	origin.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	_device = Glyphs.device_of(event, _device, Input.get_joy_name(event.device))
	_pages.help.refresh(_device)
	_frame.footer.text = PauseHelp.hint(_device)
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _show_controls() -> void:
	_page = Page.CONTROLS
	_pages.help.refresh(_device)
	_frame.switch_to(_pages.controls)
	(_pages.controls.get_child(2) as Button).grab_focus()


func _leave() -> void:
	PauseSession.leave(self, _save_note)


func _escrever() -> void:
	_titulo.text = tr(&"UI_CROWN_FALLEN") if _perdido else tr(&"UI_PAUSED")
	_frame.status.text = PauseSession.status()
	_frame.context.text = _frame.status.text
	_options_button.text = tr(&"UI_OPTIONS")
	_controls_button.text = tr(&"UI_CONTROLS")
	_export_button.text = tr(&"ARRIVAL_EXPORT")
	_exit_button.text = (
		tr(&"UI_MENU_EXIT_WEB") if OS.has_feature("web") else tr(&"UI_SAVE_AND_QUIT")
	)
	_save_note.text = PauseSession.save_note()
	_frame.footer.text = PauseHelp.hint(_device)
	_pages.refresh()
	if _herdeiro:
		_titulo.text = tr(&"UI_HEIR_CHOICE")
		_retomar.text = tr(&"UI_HEIR_CONTINUE")
		_novo.text = tr(&"UI_HEIR_DECLINE")
		return
	if _perdido and SimLoop.state != null and SimLoop.state.crossed:
		_titulo.text = (
			tr(&"UI_PAUSED") if LegacyStore.failed else crossing_title(LegacyStore.pending())
		)
	if _perdido:
		var line := (
			tr(&"UI_LEGACY_FAILED") if LegacyStore.failed else legacy_line(LegacyStore.pending())
		)
		_titulo.text += "\n" + line
	_retomar.text = tr(&"UI_RESUME")
	_novo.text = tr(&"UI_NEW_GAME")


## A regiao atravessada (P-K): a seguinte, ou, depois da ultima, o epilogo (§79).
static func crossing_title(legado: Dictionary) -> String:
	if int(legado.get(Legacy.REGIAO, 1)) > 0:
		return TranslationServer.translate(&"UI_CROSSED")
	var fim := String(SimLoop.night.epilogue()).to_upper()
	return TranslationServer.translate(&"UI_CAMPAIGN_END").format(
		{"epilogue": TranslationServer.translate(StringName("EPILOGUE_" + fim))}
	)


## O que o jogo novo herda, numa linha (§16, Q-134).
static func legacy_line(legado: Dictionary) -> String:
	if legado.has(Legacy.COMITIVA):
		var quem := (legado[Legacy.COMITIVA] as PackedStringArray).size()
		var saco := int(legado.get(Legacy.SACO, 0))
		var linha := TranslationServer.translate(&"UI_PARTY").format({"party": quem, "purse": saco})
		return linha + "\n" + memory_line(legado)
	return (
		TranslationServer
		. translate(&"UI_LEGACY")
		. format(
			{
				"slots": (legado.get(Legacy.OBRAS, []) as Array).size(),
				"seeds": int(legado.get(Legacy.SEMENTES, 0)),
				"found":
				(legado.get(Legacy.ACHADOS, PackedStringArray()) as PackedStringArray).size(),
			}
		)
	)


## O que a campanha leva da regiao atravessada, dito antes de chegar (CONT-02, Q-143).
static func memory_line(legado: Dictionary) -> String:
	var povos := 0
	for chave in [CampaignMemory.SOLTOS, CampaignMemory.RETIDOS, CampaignMemory.PERDIDOS]:
		povos += (legado.get(chave, PackedStringArray()) as PackedStringArray).size()
	return (
		TranslationServer
		. translate(&"UI_CROSSING_MEMORY")
		. format(
			{
				"debt": int(legado.get(CampaignMemory.DIVIDA, 0)),
				"peoples": povos,
				"heir": int(legado.get(CampaignMemory.TREINO, 0)),
			}
		)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _opcoes != null:
		_escrever()


func _fechar() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()
	_frame.leave()
	hide()


func _ao_retomar() -> void:
	if not _perdido and not defeated():
		SimLoop.set_paused(false)


func _ao_recomecar() -> void:
	if _herdeiro:
		_herdeiro = false
		get_tree().call_group(GRUPO_JOGO, ABDICAR)
		open(true)
		return
	_fechar()
	get_tree().call_group(GRUPO_JOGO, RECOMECAR)
