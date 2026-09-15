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
	_ficha()
	get_tree().quit()


## A ficha da fotografia, ao lado dela. O `check_silhueta.py` do §80 precisa de
## duas coisas que um PNG nao sabe dizer: em que fase do dia foi tirada, e ONDE
## estava a mancha — porque a regra das duas excepcoes diz "violeta e A Podridao
## e so A Podridao", e um teste que nao saiba onde ela esta ou chumba a mancha
## ou nao chumba nada.
func _ficha() -> void:
	var relogio := ClockService.clock
	var ecra := get_viewport().get_visible_rect().size
	var ficha := {
		"largura": ecra.x,
		"altura": ecra.y,
		"dia": SimLoop.state.day if SimLoop.state != null else 0,
		"fase": int(relogio.current_phase()),
		"mancha": _mancha(),
		"instrumentos": _instrumentos(),
	}
	var f := FileAccess.open(_saida.get_basename() + ".json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(ficha, "\t"))
		f.close()


## Onde a mancha e o rasto dela estao NO ECRA, em rectangulos. A camara so anda
## em x, mas quem converte e a transformacao do canvas: repetir a conta aqui era
## ter dois sitios a decidir onde uma coisa aparece.
func _mancha() -> Array:
	var rot := SimLoop.night.rot if SimLoop.state != null else null
	if rot == null or not rot.active():
		return []
	var t := get_viewport().get_canvas_transform()
	var largura := maxf(rot.state.width, WorldPalette.DEGRAU)
	var meia := largura * WorldPalette.MEIA
	var chao := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var massa := Rect2(rot.position_x() - meia, float(Band.HORIZON), largura, chao - Band.HORIZON)
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	var ate := maxf(rot.state.trail_from, rot.state.trail_to)
	var rasto := Rect2(de, chao - WorldPalette.RASTO, ate - de, WorldPalette.RASTO)
	return [_no_ecra(t, massa), _no_ecra(t, rasto)]


## Onde estao os INSTRUMENTOS do greybox no ecra (§67, GB-03). Quem mede a
## imagem tem de os saltar: sao texto branco, e uma regra sobre a luz do mundo
## medida por cima de um painel de texto media o painel.
func _instrumentos() -> Array:
	var fora: Array = []
	for camada in get_tree().get_nodes_in_group(&"instrumentos"):
		var control := camada as Control
		if control != null and control.visible:
			var r := control.get_global_rect()
			fora.append([r.position.x, r.position.y, r.size.x, r.size.y])
	return fora


func _no_ecra(t: Transform2D, caixa: Rect2) -> Array:
	var canto := t * caixa.position
	var fim := t * caixa.end
	return [canto.x, canto.y, fim.x - canto.x, fim.y - canto.y]


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
