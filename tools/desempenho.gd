# tools/desempenho.gd — o frame e o tick medidos numa partida pilotada (RG-18, §63).
#
# Fora do jogo: `tools/` esta no exclude_filter do export. E a bancada da auditoria de
# desempenho de 08/10/2026: a cena de jogo inteira, o piloto da vistoria a jogar, a
# semente fixa, e duas medidas — quanto custa um tick da simulacao (o avanco a mao, sem
# desenhar) e quanto custa um frame (a media, o p95 e o p99 do relogio de parede).
#
#   xvfb-run -a godot --path . --rendering-driver dummy --fixed-fps 30 \
#     --resolution 1280x720 tools/desempenho.tscn -- --novo --semente 20260916 --avancar 630
#
# Com janela e o render `dummy` mede-se so o CPU do jogo: sem janela (`--headless`) a
# vista e infinita e nada fica fora do ecra; com o rasterizador por software, o frame e
# o do rasterizador. `--toque 1` liga os controlos de toque. Com `--remote-debug` ligado
# ao tools/perfilador.gd, diz-lhe quando comecar: depois do avanco e do aquecimento.
extends Node

const JOGO := "res://scenes/game.tscn"
const PASSO := 1.0 / 30.0
## Os primeiros frames carregam texturas e moldam texto: nao sao o jogo a correr.
const AQUECER := 60
const MS := 1000.0

var _frames := 400
var _feitos := 0
var _antes := 0
var _tempos := PackedInt64Array()
var _a_medir := false


func _ready() -> void:
	var args := _argumentos()
	_frames = int(args.get("frames", _frames))
	process_priority = -1000
	process_physics_priority = -1000
	var jogo := load(JOGO).instantiate() as Game
	add_child(jogo)
	if jogo._selector != null:
		jogo._chosen(&"monarch")
	if args.get("toque", "0") == "1":
		TouchControls.active = true
		WideTouch.apply(get_tree().root, true)
	var avancar := float(args.get("avancar", 0.0))
	var t0 := Time.get_ticks_usec()
	var passos := 0
	for _i in int(avancar / PASSO):
		if not SimLoop.running():
			break
		Autopilot.step(SimLoop)
		SimLoop.step(PASSO)
		passos += 1
	if passos > 0:
		var por_tick := (Time.get_ticks_usec() - t0) / MS / passos
		print("desempenho: tick %.3f ms (%d passos de piloto e simulacao)" % [por_tick, passos])
	for _i in AQUECER:
		await get_tree().process_frame
	if EngineDebugger.is_active():
		EngineDebugger.send_message("desempenho:medir", [])
	_antes = Time.get_ticks_usec()
	_a_medir = true


func _physics_process(_delta: float) -> void:
	if SimLoop.running():
		Autopilot.step(SimLoop)


func _process(_delta: float) -> void:
	if not _a_medir:
		return
	var agora := Time.get_ticks_usec()
	_tempos.append(agora - _antes)
	_antes = agora
	_feitos += 1
	if _feitos < _frames:
		return
	set_process(false)
	_tempos.sort()
	var n := _tempos.size()
	var soma := 0
	for t in _tempos:
		soma += t
	print(
		(
			"desempenho: frame media %.2f ms | p50 %.2f | p95 %.2f | p99 %.2f | max %.2f"
			% [
				soma / MS / n,
				_tempos[n / 2] / MS,
				_tempos[int(n * 0.95)] / MS,
				_tempos[int(n * 0.99)] / MS,
				_tempos[n - 1] / MS,
			]
		)
	)
	print(
		(
			"desempenho: dia %d fase %d | tropas %d | moedas %d | nos %d | draw calls %d"
			% [
				SimLoop.state.day,
				int(ClockService.clock.current_phase()),
				SimLoop.units.count(),
				SimLoop.coins.count(),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			]
		)
	)
	get_tree().quit()


func _argumentos() -> Dictionary:
	var saida := {}
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size() - 1:
		if args[i].begins_with("--") and not args[i + 1].begins_with("--"):
			saida[args[i].substr(2)] = args[i + 1]
			i += 1
		i += 1
	return saida
