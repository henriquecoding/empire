class_name GameHud
extends Control

const INK := Color(0.08, 0.07, 0.06)
const PAPER := Color(0.12, 0.10, 0.10, 0.88)
const PAPER_LIGHT := Color(0.20, 0.16, 0.13, 0.94)
const GOLD := Color(0.95, 0.67, 0.27)
const MINT := Color(0.53, 0.79, 0.57)
const TEXT := Color(0.96, 0.92, 0.81)
const MUTED := Color(0.73, 0.67, 0.56)
const JADE := Color(0.33, 0.53, 0.45)
const RODAPE_LINHA := Color(0.32, 0.26, 0.20)

const ECRA := {"largura": 1280.0, "altura": 720.0}

const TITULO := {"x": 36.0, "y": 24.0, "w": 160.0, "h": 32.0, "letra": 22}
const RELOGIO := {"x": 232.0, "y": 20.0, "w": 540.0, "h": 28.0, "letra": 19}
const RECURSOS := {"x": 232.0, "y": 44.0, "w": 540.0, "h": 24.0, "letra": 13}
const OBJECTIVO := {"x": 844.0, "y": 23.0, "w": 390.0, "h": 44.0, "letra": 13}
const DICA := {"x": 40.0, "y": 0.0, "acima": 44.0, "w": 1120.0, "h": 26.0, "letra": 13}
const AVISO := {"x": 400.0, "y": 112.0, "w": 480.0, "h": 30.0, "letra": 16}

const PAINEL_ESQ := {"x": 20.0, "y": 16.0, "w": 180.0, "h": 56.0}
const PAINEL_MEIO := {"x": 216.0, "y": 16.0, "w": 586.0, "h": 56.0}
const PAINEL_DIR := {"recuo": 456.0, "y": 16.0, "w": 436.0, "h": 56.0}
const BARRA := {"x": 228.0, "y": 69.0, "w": 562.0, "h": 3.0}
const RODAPE := {"x": 20.0, "acima": 48.0, "margem": 40.0, "h": 30.0}
const AVISO_CAIXA := {"x": 390.0, "y": 108.0, "w": 500.0, "h": 38.0}

const TRACO := {"painel": 2.0, "rodape": 1.0, "contorno": 3}

const FAIXA_TOPO := 72.0

const AVISO_S := 2.0
## De quanto em quanto tempo os textos se refazem: o guia e as contas custavam meio ms por
## frame, e um numero que muda dez vezes por segundo ja se le como imediato (03/10/2026).
const TEXTO_S := 0.1
const CEM := 100.0
const SEM_NUCLEO := -1.0

var _titulo: Label
var _relogio: Label
var _recursos: Label
var _objectivo: Label
var _dica: Label
var _aviso: Label
var _topo: Control
var _rodape: Control
var _moldura_aviso: Control
var _aviso_ate := 0.0
var _texto_em := 0.0
var _dispositivo := Glyphs.Device.KEYBOARD


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(&"painel")
	_titulo = _label("", TITULO, GOLD)
	_relogio = _label("", RELOGIO, TEXT)
	_recursos = _label("", RECURSOS, MUTED)
	_objectivo = _label("", OBJECTIVO, MINT)
	_objectivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica = _label("", DICA, MUTED)
	_aviso = _label("", AVISO, GOLD)
	_topo = _faixa()
	_rodape = _faixa()
	_moldura_aviso = _faixa()
	_moldura_aviso.position = _caixa(AVISO_CAIXA).position
	_moldura_aviso.size = _caixa(AVISO_CAIXA).size
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# §26: os glifos sao os do dispositivo activo. Um Steam Deck nao tem teclado,
	# e por isso um comando ligado ao arrancar e o comando que se esta a usar.
	_dispositivo = Glyphs.initial()
	_escrever_fixos()
	add_child(ContextPanel.new())
	add_child(TravelPanel.new())
	add_child(CombatBar.new())
	EventBus.coin_collected.connect(_no_apanhar)
	EventBus.game_paused.connect(_na_pausa)
	for sinal: StringName in HudText.AVISOS:
		var aviso: String = HudText.AVISOS[sinal]
		EventBus.connect(sinal, _dizer_chave.bind(aviso).unbind(_argumentos(sinal)))


func _input(evento: InputEvent) -> void:
	var nome := ""
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
		nome = Input.get_joy_name(evento.device)
	var novo := Glyphs.device_of(evento, _dispositivo, nome)
	if novo != _dispositivo:
		_dispositivo = novo
		_dica.text = Glyphs.hint(novo, _marca())


func _escrever_fixos() -> void:
	_titulo.text = tr(&"GAME_CODENAME")
	_dica.text = Glyphs.hint(_dispositivo, _marca())


func _marca() -> bool:
	return SimLoop.field == null or Assume.marks(SimLoop.field) or HeroWatch.current() == &"bard"


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSLATION_CHANGED and _dica != null:
		_escrever_fixos()


func _process(delta: float) -> void:
	if SimLoop.state == null or ClockService.clock == null:
		return
	_texto_em -= delta
	if _texto_em <= 0.0:
		_texto_em = TEXTO_S
		_atualizar()
	_dispor()
	_aviso_ate = maxf(0.0, _aviso_ate - delta)
	_aviso.visible = _aviso_ate > 0.0
	_moldura_aviso.visible = _aviso.visible
	queue_redraw()


func _draw() -> void:
	var largura := maxf(size.x, ECRA.largura)
	var altura := maxf(size.y, ECRA.altura)
	_painel(_caixa(PAINEL_ESQ), PAPER_LIGHT, GOLD)
	_painel(_caixa(PAINEL_MEIO), PAPER, JADE)
	var direito := Rect2(largura - PAINEL_DIR.recuo, PAINEL_DIR.y, PAINEL_DIR.w, PAINEL_DIR.h)
	_painel(direito, PAPER, MINT)
	draw_rect(Rect2(BARRA.x, BARRA.y, BARRA.w, BARRA.h), INK)
	if ClockService.clock != null:
		var feito := BARRA.w * ClockService.clock.phase_progress()
		draw_rect(Rect2(BARRA.x, BARRA.y, feito, BARRA.h), GOLD)
	# No toque nao ha rodape de teclas: os botoes no ecra dizem o que fazem (ADR 0047).
	var rodape := altura - RODAPE.acima
	if not _dica.text.is_empty():
		draw_rect(Rect2(RODAPE.x, rodape, largura - RODAPE.margem, RODAPE.h), PAPER)
		var fim := Vector2(largura - RODAPE.x, rodape)
		draw_line(Vector2(RODAPE.x, rodape), fim, RODAPE_LINHA, TRACO.rodape)
	# A pausa e a derrota ja nao se desenham aqui: sao o PauseMenu (GB-13, GB-16).
	if _aviso.visible:
		_painel(_caixa(AVISO_CAIXA), PAPER_LIGHT, GOLD)


func _atualizar() -> void:
	var ability := &"HINT_CHARM" if HeroWatch.current() == &"bard" else &"HINT_MARK"
	_dica.text = Glyphs.hint(_dispositivo, _marca(), ability)
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	_relogio.text = (
		HudText.clock(SimLoop.state.day, fase, relogio.phase_progress())
		+ " · "
		+ SeasonText.of(SimLoop.field, SimLoop.state.day)
	)
	var rei := SimLoop.units.index_of(Assume.driven())  # o saco de quem se conduz (§08)
	var saco := SimLoop.units.carried_coins[rei] if rei >= 0 else 0
	var cabem := SimLoop.units.coin_capacities[rei] if rei >= 0 else 0
	var soldo := SimLoop.economy.upkeep(SimLoop.field.upkeep.troops(SimLoop.units, SimLoop.king_id))
	_recursos.text = HudText.resources(
		saco, cabem, GameplayGuide.troops(), _vida_nucleo(), SimLoop.state.greed, soldo
	)
	var archotes := SimLoop.night.dark.torch.torches  # Q-029
	var animo := SimLoop.field.spirit.value(ClockService.clock.day)  # Q-102
	_recursos.text += HudText.extras(archotes, animo, SimLoop.state.royal_seeds)  # Q-095
	_objectivo.text = GameplayGuide.goal()


func _dispor() -> void:
	_dica.position = Vector2(DICA.x, size.y - DICA.acima)
	_topo.size = Vector2(size.x, FAIXA_TOPO)
	_rodape.position = Vector2(0.0, size.y - RODAPE.acima)
	_rodape.size = Vector2(size.x, RODAPE.h)


func _vida_nucleo() -> int:
	var melhor := SEM_NUCLEO
	for vaga in SimLoop.builds.slots:
		if vaga.kind != BuildSlot.NUCLEO:
			continue
		melhor = maxf(melhor, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
	return clampi(int(round(melhor * CEM)), 0, int(CEM))


func _label(conteudo: String, caixa: Dictionary, cor: Color) -> Label:
	var label := Label.new()
	label.text = conteudo
	label.position = Vector2(caixa.x, caixa.y)
	label.size = Vector2(caixa.w, caixa.h)
	label.add_theme_font_size_override("font_size", caixa.letra)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", TRACO.contorno)
	add_child(label)
	return label


func _faixa() -> Control:
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.add_to_group(&"instrumentos")
	add_child(faixa)
	return faixa


static func _caixa(medida: Dictionary) -> Rect2:
	return Rect2(medida.x, medida.y, medida.w, medida.h)


func _painel(caixa: Rect2, fundo: Color, risco: Color) -> void:
	draw_rect(caixa, fundo)
	draw_line(caixa.position, caixa.position + Vector2(caixa.size.x, 0.0), risco, TRACO.painel)
	draw_line(caixa.position, caixa.position + Vector2(0.0, caixa.size.y), risco, TRACO.painel)


func _dizer_chave(chave: StringName) -> void:
	_dizer(tr(chave))


static func _argumentos(sinal: StringName) -> int:
	for s in EventBus.get_signal_list():
		if s.name == sinal:
			return s.args.size()
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
	if not pausado:
		_dizer(tr(&"TOAST_RESUMED"))
