# src/actors/fallen_art.gd — os corpos que a alvorada leva (§16, Q-096).
#
# Q-096 (o dono, 29/09/2026): "cria raizes nas tropas caidas, e elas somem
# suavemente a seguir". Uma tropa morta fica nas colunas ate a alvorada; quando
# sai, o ultimo desenho dela desvanece neste tempo, com raizes a crescer-lhe por
# baixo. Saiu do UnitArtBatch para ele caber nas 250 linhas com a pose do golpe.
class_name FallenArt
extends RefCounted

const FADE_SECONDS := 1.6
const DEAD_ALPHA := 0.35
const ROOT := Color("2b1d14")
const ROOTS := [Vector2(-6, 3), Vector2(-2, 5), Vector2(3, 4), Vector2(7, 2)]

var _art := OriginalArt.new()
## Os corpos que se veem (id -> o ultimo desenho), e os que estao a desvanecer.
var _bodies: Dictionary = {}
var _fading: Dictionary = {}


## O ultimo desenho de um corpo caido, para o desvanecer quando ele sair.
func keep(id: int, desenho: Dictionary) -> void:
	_bodies[id] = desenho


func draw(canvas: CanvasItem, band: Band.Kind, live: Dictionary, time: float) -> void:
	for id in _bodies.keys():
		if not live.has(id) and _bodies[id]["band"] == int(band):
			_fading[id] = _bodies[id]
			_fading[id]["t0"] = time
			_bodies.erase(id)
	for id in _fading.keys():
		var corpo: Dictionary = _fading[id]
		if corpo["band"] != int(band):
			continue
		var resto := 1.0 - (time - float(corpo["t0"])) / FADE_SECONDS
		if resto <= 0.0:
			_fading.erase(id)
			continue
		var cor := Color(1.0, 1.0, 1.0, DEAD_ALPHA * resto)
		var pe: Vector2 = corpo["foot"]
		var pose := OriginalArt.posed(pe, 1.0, Vector2.ONE, corpo["angle"])
		_art.draw_posed(canvas, corpo["profile"], cor, corpo["frame"], pose)
		var raiz := Color(ROOT, 1.0 - resto)
		for ponta: Vector2 in ROOTS:
			canvas.draw_line(pe, pe + ponta, raiz)
