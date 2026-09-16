class_name GameHud
extends Control

const FASES := ["ALVORADA", "MANHÃ", "MEIO-DIA", "TARDE", "CREPÚSCULO", "NOITE"]
const INK := Color(0.08, 0.07, 0.06)
const PAPER := Color(0.12, 0.10, 0.10, 0.88)
const PAPER_LIGHT := Color(0.20, 0.16, 0.13, 0.94)
const GOLD := Color(0.95, 0.67, 0.27)
const MINT := Color(0.53, 0.79, 0.57)
const RED := Color(0.90, 0.37, 0.29)
const TEXT := Color(0.96, 0.92, 0.81)
const MUTED := Color(0.73, 0.67, 0.56)

var _title: Label
var _clock_label: Label
var _resources: Label
var _objective: Label
var _hint: Label
var _toast: Label
var _overlay: Label
var _toast_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label("EMPIRE", Vector2(36.0, 27.0), Vector2(230.0, 32.0), 24, GOLD)
	_clock_label = _label("", Vector2(378.0, 27.0), Vector2(510.0, 28.0), 19, TEXT)
	_resources = _label("", Vector2(378.0, 54.0), Vector2(510.0, 24.0), 14, MUTED)
	_objective = _label("", Vector2(944.0, 28.0), Vector2(290.0, 44.0), 14, MINT)
	_hint = _label("", Vector2(40.0, 0.0), Vector2(1120.0, 26.0), 13, MUTED)
	_toast = _label("", Vector2(400.0, 112.0), Vector2(480.0, 30.0), 16, GOLD)
	_overlay = _label("", Vector2(400.0, 280.0), Vector2(480.0, 120.0), 28, TEXT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.build_completed.connect(_on_build_completed)
	EventBus.target_marked.connect(_on_target_marked)
	EventBus.passage_used.connect(_on_passage_used)
	EventBus.wall_breached.connect(_on_wall_breached)
	EventBus.game_paused.connect(_on_game_paused)
	_hint.text = "A/D mover   ·   segurar ESPAÇO largar   ·   E usar passagem   ·   botão direito marcar   ·   TAB estado   ·   ESC pausa"
	_overlay.visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if SimLoop.state == null:
		return
	_atualizar()
	_toast_time = maxf(0.0, _toast_time - delta)
	_toast.visible = _toast_time > 0.0
	if not SimLoop.running:
		_overlay.visible = true
		_overlay.text = "JOGO EM PAUSA\n\nESC para continuar"
	elif _overlay.visible:
		_overlay.visible = false
	queue_redraw()


func _draw() -> void:
	var largura := maxf(size.x, 1280.0)
	var altura := maxf(size.y, 720.0)
	_panel(Rect2(20.0, 16.0, 292.0, 72.0), PAPER_LIGHT, GOLD)
	_panel(Rect2(348.0, 16.0, 570.0, 72.0), PAPER, Color(0.33, 0.53, 0.45))
	_panel(Rect2(largura - 332.0, 16.0, 312.0, 72.0), PAPER, MINT)
	draw_rect(Rect2(360.0, 83.0, 546.0, 3.0), INK)
	if SimLoop.state != null and ClockService.clock != null:
		var progresso := ClockService.clock.phase_progress()
		draw_rect(Rect2(360.0, 83.0, 546.0 * progresso, 3.0), GOLD)
	draw_rect(Rect2(20.0, altura - 48.0, largura - 40.0, 30.0), PAPER)
	draw_line(Vector2(20.0, altura - 48.0), Vector2(largura - 20.0, altura - 48.0), Color(0.32, 0.26, 0.20), 1.0)
	if _toast.visible:
		_panel(Rect2(390.0, 108.0, 500.0, 38.0), PAPER_LIGHT, GOLD)
	if _overlay.visible:
		draw_rect(Rect2(0.0, 0.0, largura, altura), Color(0.02, 0.02, 0.03, 0.62))
		_panel(Rect2(350.0, 252.0, 580.0, 190.0), PAPER_LIGHT, GOLD)


func _atualizar() -> void:
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	var dia := SimLoop.state.day
	var nome := FASES[fase] if fase >= 0 and fase < FASES.size() else "NOITE"
	_clock_label.text = "DIA %02d   ·   %s   ·   %02d%%" % [dia, nome, int(relogio.phase_progress() * 100.0)]
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var saco := SimLoop.units.carried_coins[rei] if rei >= 0 else 0
	var capacidade := SimLoop.units.coin_capacities[rei] if rei >= 0 else 0
	var vida := _vida_nucleo()
	_resources.text = "SACO %02d/%02d   ·   TROPAS %02d   ·   NÚCLEO %03d%%" % [
		saco, capacidade, _meus(), vida
	]
	if SimLoop.night.rot.active():
		_objective.text = "A PODRIDÃO AVANÇA\nprotege as muralhas"
	else:
		_objective.text = "RECOLHE MOEDAS\nprepara a fronteira"


func _vida_nucleo() -> int:
	var melhor := -1.0
	for vaga in SimLoop.builds.slots:
		if vaga.kind != BuildSlot.NUCLEO:
			continue
		melhor = maxf(melhor, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
	return clampi(int(round(melhor * 100.0)), 0, 100)


func _meus() -> int:
	var total := 0
	for i in SimLoop.units.count():
		if SimLoop.units.alive(i) and SimLoop.units.owners[i] != RecruitSystem.SEM_DONO:
			total += 1
	return total


func _label(
	conteudo: String, posicao: Vector2, dimensao: Vector2, tamanho: int, cor: Color
) -> Label:
	var label := Label.new()
	label.text = conteudo
	label.position = posicao
	label.size = dimensao
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _panel(rect: Rect2, fill: Color, accent: Color) -> void:
	draw_rect(rect, fill)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), accent, 2.0)
	draw_line(rect.position, rect.position + Vector2(0.0, rect.size.y), accent, 2.0)


func _toast_message(message: String) -> void:
	_toast.text = message
	_toast_time = 2.0
	_toast.visible = true


func _on_coin_collected(_unit_id: int, amount: int) -> void:
	_toast_message("+%d moeda" % amount)


func _on_build_completed(_building_id: StringName) -> void:
	_toast_message("OBRA CONCLUÍDA")


func _on_target_marked(_target_id: int, _by_id: int) -> void:
	_toast_message("ALVO MARCADO")


func _on_passage_used(_unit_id: int, _from_band: int, _to_band: int) -> void:
	_toast_message("PASSAGEM USADA")


func _on_wall_breached(_wall_id: int) -> void:
	_toast_message("MURALHA ROMPIDA")


func _on_game_paused(paused: bool) -> void:
	_toast_message("JOGO PAUSADO" if paused else "JOGO RETOMADO")
