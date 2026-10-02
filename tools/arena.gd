# tools/arena.gd — uma escaramuca preparada, fotografada frame a frame.
#
# Fora do jogo, como a captura.gd. O combate acontece a noite, longe do rei e no
# escuro, e uma captura so nao diz se um golpe se le: precisa de uma SEQUENCIA.
# Isto poe tropas tuas e criaturas frente a frente, de dia e ao pe do rei, e
# grava um PNG a cada `--cada` frames, recortado a volta da luta.
#
#   xvfb-run -a godot --path . tools/arena.tscn -- --novo --semente 7 --classe monarch \
#     --saida build/arena --quadros 24 --cada 3 [--avancar 310] [--registo]
#
# O `--classe` salta a escolha inicial de classe (ADR 0045), que de outro modo
# parava a partida a espera de quem escolhe.
#
# O estado e preparado a mao e nao natural: serve para ver a apresentacao, e
# nao mede balanceamento nenhum.
extends Node

const JOGO := "res://scenes/game.tscn"
const SAIDA := "build/arena"
const MEU := 1
## Onde se luta, a contar do nucleo: entre dois muros, longe das luzes que
## seguram as criaturas (ADR 0034). Quem e teu e nao tem posto ia esperar ao
## nucleo (Retinue), e por isso as tropas sao seguras no sitio a cada passo.
const ONDE := 950.0
## Prepara-se depois do primeiro tick: a mudanca de fase do arranque dissolve as
## criaturas que ja la estivessem (NightWatch).
const PREPARAR_NO_FRAME := 3
const TROPAS := [[&"spearman", 0.0], [&"spearman", 14.0], [&"archer", -70.0], [&"archer", -90.0]]
const BICHOS := [[&"crawler", 150.0], [&"crawler", 175.0], [&"brute", 215.0], [&"winged", 190.0]]
## O recorte, em px de ecra, a volta do rei: o que interessa e a linha da luta.
const RECORTE := Rect2(480.0, 330.0, 640.0, 220.0)
const AMPLIAR := 2
const PASSO := 1.0 / 30.0

var _saida := SAIDA
var _quadros := 24
var _cada := 3
var _espera := 40
var _frame := 0
var _gravados := 0
## Tropa da arena -> o x onde fica.
var _postas: Dictionary = {}


func _ready() -> void:
	var args := _argumentos()
	_saida = String(args.get("saida", SAIDA))
	_quadros = int(args.get("quadros", _quadros))
	_cada = maxi(1, int(args.get("cada", _cada)))
	_espera = int(args.get("espera", _espera))
	DirAccess.make_dir_recursive_absolute(_saida)
	_ready_fisica()
	add_child(load(JOGO).instantiate())


func _preparar() -> void:
	# `--avancar <s>` anda a simulacao antes da luta: a noite e outra leitura.
	for _i in int(float(_argumentos().get("avancar", 0.0)) / PASSO):
		SimLoop.step(PASSO)
	var x := SimLoop.core_x + ONDE
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[rei] = x - 150.0
	SimLoop.units.clear_target(SimLoop.king_id)
	for par in TROPAS:
		var dados := Registry.entry(&"units", par[0]) as UnitData
		var id := SimLoop.units.spawn(SimLoop.state, dados, MEU, x + float(par[1]))
		_postas[id] = x + float(par[1])
	for par in BICHOS:
		var dados := Registry.entry(&"creatures", par[0]) as CreatureData
		SimLoop.creatures.spawn(SimLoop.state, dados, x + float(par[1]), SimLoop.core_x)
	Smoothing.reset()
	var jogo := get_child(0)
	var monarca := jogo.get_node(^"Monarca") as Node2D
	monarca.position = Vector2(x, WorldPalette.ground_of(int(Band.Kind.SURFACE)))
	(jogo.get_node(^"CameraRig") as CameraRig).follow(monarca)


func _ready_fisica() -> void:
	process_physics_priority = SimLoop.process_physics_priority + 1


## Depois do passo do SimLoop: quem e da arena fica onde foi posto.
func _physics_process(_delta: float) -> void:
	for id in _postas:
		var i := SimLoop.units.index_of(id)
		if i != UnitSystem.NENHUM and SimLoop.units.alive(i):
			SimLoop.units.xs[i] = _postas[id]
			SimLoop.units.target_xs[i] = _postas[id]


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == PREPARAR_NO_FRAME:
		_preparar()
	if _frame < _espera or (_frame - _espera) % _cada != 0:
		return
	_gravar()


func _gravar() -> void:
	await RenderingServer.frame_post_draw
	var imagem := get_viewport().get_texture().get_image().get_region(RECORTE)
	imagem.resize(
		imagem.get_width() * AMPLIAR, imagem.get_height() * AMPLIAR, Image.INTERPOLATE_NEAREST
	)
	imagem.save_png("%s/%03d.png" % [_saida, _gravados])
	if OS.get_cmdline_user_args().has("--registo"):
		_registo()
	_gravados += 1
	if _gravados >= _quadros:
		print("arena: %d quadros em %s" % [_gravados, _saida])
		get_tree().quit()


## O que a simulacao tem neste quadro, para conferir com a imagem.
func _registo() -> void:
	var u := SimLoop.units
	var c := SimLoop.creatures
	var linha := "q%02d" % _gravados
	for i in u.count():
		if absf(u.xs[i] - SimLoop.core_x - ONDE) < 400.0 and u.owners[i] == MEU:
			linha += " u%d:%s@%d/%d" % [u.ids[i], u.data_ids[i], int(u.xs[i]), u.healths[i]]
	for k in c.count():
		linha += " c%d:%s@%d/%d" % [c.ids[k], c.data_ids[k], int(c.xs[k]), c.healths[k]]
	print(linha)


func _argumentos() -> Dictionary:
	var saida := {}
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with("--") and i + 1 < args.size() and not args[i + 1].begins_with("--"):
			saida[args[i].trim_prefix("--")] = args[i + 1]
	return saida
