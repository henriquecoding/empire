# tools/captura.gd — uma fotografia da cena de jogo (GB-01, §67).
#
# Fora do jogo: `tools/` esta no exclude_filter do export e nunca sai daqui.
# Corre com um ecra virtual e grava um PNG, para que se possa ver o greybox — e
# ver que a noite e castanha (ADR 0011) — sem uma maquina com ecra.
#
#   xvfb-run -a godot --path . tools/captura.tscn -- --segundos 40 --saida x.png
#
# Corre como CENA e nao com `-s`: o modo de script nao carrega autoloads, e sem
# eles nao ha SimLoop nenhum para fotografar.
extends Node

const JOGO := "res://scenes/game.tscn"
const SAIDA := "build/empire.png"
const SEGUNDOS := 3.0
const PASSO := 1.0 / 30.0

var _restam: int = 0
var _saida: String = SAIDA


func _ready() -> void:
	var args := _argumentos()
	_saida = String(args.get("saida", SAIDA))
	_restam = int(float(args.get("segundos", SEGUNDOS)) * Engine.get_frames_per_second())
	if _restam <= 0:
		_restam = int(SEGUNDOS * Engine.physics_ticks_per_second)
	add_child(load(JOGO).instantiate())
	# Avancar a simulacao a mao, e nao esperar pelo relogio: fotografar a noite
	# custava 340 segundos de espera por causa das seis fases do §48.
	_avancar(float(args.get("avancar", 0.0)))


func _process(_delta: float) -> void:
	_restam -= 1
	if _restam > 0:
		return
	set_process(false)
	await RenderingServer.frame_post_draw
	var imagem := get_viewport().get_texture().get_image()
	print("captura: %s (erro %d)" % [_saida, imagem.save_png(_saida)])
	get_tree().quit()


## Corre `segundos` de simulacao ao passo fixo, sem render. E o mesmo step() que
## os testes usam, e por isso a fotografia mostra um estado que a suite tambem
## consegue reproduzir.
##
## Para quando a partida para. O step() e publico e nao olha ao _running — quem
## o chama a mao tem de olhar, senao continua a andar com um jogo ja acabado e a
## fotografia mostra um mundo que nunca existiu.
func _avancar(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		if not SimLoop.running():
			return
		SimLoop.step(PASSO)


func _argumentos() -> Dictionary:
	var saida := {}
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size() - 1:
		if args[i].begins_with("--"):
			saida[args[i].substr(2)] = args[i + 1]
			i += 1
		i += 1
	return saida
