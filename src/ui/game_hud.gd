class_name GameHud
extends Control

# As cores do painel sao as do Atlas do Imperio (ADR 0078): quem desenha a HUD, o toque e
# a viagem le-as daqui ou do Atlas, e nao inventa outra paleta.
const INK := Atlas.INK
const PAPER := Color(Atlas.FIELD, Atlas.FIELD_ALPHA)
const PAPER_LIGHT := Color(Atlas.RAISED, Atlas.FIELD_ALPHA)
const GOLD := Atlas.COIN
const MINT := Atlas.VALID
const TEXT := Atlas.TEXT
const MUTED := Atlas.SECONDARY
const JADE := Atlas.INFO
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
var _hint := HintCue.new()


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
	add_child(SiteSheet.new())
	add_child(CombatBar.new())
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
	var stopped := InteractionFocus.still() and not SiteSheet.active
	if stopped:
		_aviso_ate = maxf(0.0, _aviso_ate - delta)
	_aviso.visible = _aviso_ate > 0.0 and stopped
	var key := StringName("controls_%s_%s" % [_dispositivo, HeroWatch.current()])
	_dica.visible = _hint.present(key, stopped and not TouchControls.active, delta)
	_dica.visible = _dica.visible and not _dica.text.is_empty()


func _dispor() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	var area := get_viewport_rect().size / zoom
	_dica.scale = Vector2.ONE * zoom
	_dica.position = Vector2(HINT.margin, get_viewport_rect().size.y - HINT.bottom * zoom)
	_dica.size = Vector2(area.x - HINT.margin * 2, HINT.height)
	_dica.clip_text = true
	var ecra := get_viewport_rect().size
	var top := (
		_context.get_global_rect().end.y if _context.visible else HudLayout.CONTEXT_TOP * zoom
	)
	HudLayout.fit_label(_aviso, ecra, zoom, NOTICE.width, top + HudLayout.GAP * zoom)


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
	_aviso.visible = InteractionFocus.still() and not SiteSheet.active


func _na_pausa(pausado: bool) -> void:
	visible = not pausado
