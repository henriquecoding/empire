class_name GameHud
extends Control

const INK := Color(0.08, 0.07, 0.06)
const PAPER := Color(0.12, 0.10, 0.10, 0.94)
const PAPER_LIGHT := Color(0.20, 0.16, 0.13, 0.94)
const GOLD := Color(0.95, 0.67, 0.27)
const MINT := Color(0.53, 0.79, 0.57)
const TEXT := Color(0.96, 0.92, 0.81)
const MUTED := Color(0.79, 0.75, 0.66)
const JADE := Color(0.33, 0.53, 0.45)
const FAIXA_TOPO := 72.0
const AVISO_S := 3.0
const TEXTO_S := 0.1
const HINT := {"font": 14, "margin": 28.0, "height": 28.0, "bottom": 44.0}
const NOTICE := {"font": 16, "width": 480.0}

var _ribbon: HudRibbon
var _context: ContextPanel
var _dica: Label
var _aviso: Label
var _aviso_ate := 0.0
var _texto_em := 0.0
var _dispositivo := Glyphs.Device.KEYBOARD


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(&"painel")
	_ribbon = HudRibbon.new()
	add_child(_ribbon)
	_context = ContextPanel.new()
	add_child(_context)
	_dica = HudStyle.label(self, HINT.font, HudStyle.MUTED)
	_dica.add_theme_stylebox_override("normal", HudStyle.panel())
	_dica.add_to_group(&"instrumentos")
	_aviso = HudStyle.label(self, NOTICE.font, HudStyle.GOLD)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.add_theme_stylebox_override("normal", HudStyle.panel())
	_aviso.add_to_group(&"instrumentos")
	_aviso.add_to_group(&"hud_notice")
	_dispositivo = Glyphs.initial()
	add_child(TravelPanel.new())
	add_child(CombatBar.new())
	EventBus.coin_collected.connect(_no_apanhar)
	EventBus.game_paused.connect(_na_pausa)
	for sinal: StringName in HudText.AVISOS:
		EventBus.connect(sinal, _dizer_chave.bind(HudText.AVISOS[sinal]).unbind(_argumentos(sinal)))


func _input(evento: InputEvent) -> void:
	var nome := ""
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
		nome = Input.get_joy_name(evento.device)
	_dispositivo = Glyphs.device_of(evento, _dispositivo, nome)


func _process(delta: float) -> void:
	if SimLoop.state == null or ClockService.clock == null:
		return
	_texto_em -= delta
	if _texto_em <= 0.0:
		_texto_em = TEXTO_S
		_ribbon.refresh()
		var ability := &"HINT_CHARM" if HeroWatch.current() == &"bard" else &"HINT_MARK"
		var mark := Assume.marks(SimLoop.field) or HeroWatch.current() == &"bard"
		_dica.text = Glyphs.hint(_dispositivo, mark, ability)
	_dispor()
	_aviso_ate = maxf(0.0, _aviso_ate - delta)
	_aviso.visible = _aviso_ate > 0.0 and SimLoop.running()
	_dica.visible = not _dica.text.is_empty() and not TouchControls.active


func _dispor() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	var area := get_viewport_rect().size / zoom
	_dica.scale = Vector2.ONE * zoom
	_dica.position = Vector2(HINT.margin, get_viewport_rect().size.y - HINT.bottom * zoom)
	_dica.size = Vector2(area.x - HINT.margin * 2, HINT.height)
	_dica.clip_text = true
	var width := minf(NOTICE.width, area.x - HudLayout.MARGIN * 2)
	_aviso.scale = Vector2.ONE * zoom
	_aviso.size = Vector2(width, 0)
	var top := (
		_context.get_global_rect().end.y if _context.visible else HudLayout.CONTEXT_TOP * zoom
	)
	_aviso.position = Vector2((area.x - width) * HudLayout.HALF * zoom, top + HudLayout.GAP * zoom)


func _dizer_chave(chave: StringName) -> void:
	_dizer(tr(chave))


static func _argumentos(sinal: StringName) -> int:
	for signal_info in EventBus.get_signal_list():
		if signal_info.name == sinal:
			return signal_info.args.size()
	return 0


func say(mensagem: String) -> void:
	_dizer(mensagem)


func _dizer(mensagem: String) -> void:
	_aviso.text = mensagem
	_aviso_ate = AVISO_S
	_aviso.visible = true


func _no_apanhar(unit_id: int, amount: int) -> void:
	if unit_id == SimLoop.king_id:
		_dizer(HudText.coins(amount))


func _na_pausa(pausado: bool) -> void:
	visible = not pausado
