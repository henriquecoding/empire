# src/world/scenery_plane.gd — um plano de fundo pintado: ceu, nuvens, longe, meio ou perto
# (a entrega de cenarios em camadas de 08/10/2026; ADR 0081).
#
# Vive dentro de um Parallax2D: anda mais devagar do que o mundo, e o quadro de um reino
# nao tem sitio nele. O que tem sitio e a fronteira entre dois povos. Este plano pinta, por
# cima da terra de cada povo, o reino desse povo; na fronteira, projetada no ecra, um da lugar
# ao outro numa faixa de 2 x MISTURA px. Com a fronteira longe da camara, o plano e um reino
# so e nao se redesenha; com ela no ecra, redesenha-se a cada passo dela.
#
# O mosaico ancora-se uma vez: o meio do quadro do reino fica atras do meio da regiao, onde
# a sede nasce, como o dono compos cada reino a volta dela.
class_name SceneryPlane
extends Node2D

## Que luz leva cada camada (SceneryLight): o ceu e as nuvens sao ceu; as arvores de perto
## estao no meio, como o bosque que ja la estava.
const LUZ := {
	&"sky": SceneryLight.Depth.SKY,
	&"clouds": SceneryLight.Depth.SKY,
	&"far": SceneryLight.Depth.FAR,
	&"mid": SceneryLight.Depth.MID,
	&"near": SceneryLight.Depth.MID,
}
## O ceu e opaco: o reino que chega cobre o que fica, e so ele se esvai. As outras camadas
## tem buracos, e esvaem-se as duas.
const OPACA := &"sky"
## A janela anda aos degraus de DEGRAU px do plano, com MARGEM px de folga de cada lado.
const DEGRAU := 256.0
const MARGEM := 512.0
const MISTURA := SceneryMap.MISTURA
const FATIAS := 32
const MEIO := 0.5

@export var camada: StringName = &"far"

var _janela := Vector2.ZERO
var _origem := NAN
var _chave: Array = []
## Os reinos da esquerda para a direita, e as fronteiras entre eles em x do plano.
var _reinos: Array[StringName] = []
var _fronteiras := PackedFloat32Array()
var _usadas: Array[Texture2D] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = SceneryLight.material(LUZ.get(camada, SceneryLight.Depth.FAR))


func _process(_delta: float) -> void:
	visible = SceneryArt.painted()
	if not visible:
		return
	if ClockService.clock != null:
		SceneryLight.refresh(self)
	var camara := get_viewport().get_camera_2d()
	if camara == null:
		return
	var plano := get_global_transform_with_canvas().affine_inverse()
	var mundo := get_viewport().get_canvas_transform()
	var ecra := get_viewport_rect()
	var esquerda := (plano * ecra.position).x
	var direita := (plano * ecra.end).x
	var mapa := SceneryArt.map()
	if is_nan(_origem):
		_origem = _ancora((esquerda + direita) * MEIO, camara.get_screen_center_position().x)
	_janela = Vector2(
		floorf(esquerda / DEGRAU) * DEGRAU - MARGEM, ceilf(direita / DEGRAU) * DEGRAU + MARGEM
	)
	var de_mundo := (mundo.affine_inverse() * ecra.position).x - MISTURA
	var ate_mundo := (mundo.affine_inverse() * ecra.end).x + MISTURA
	_reinos = [mapa.biome_at(de_mundo)]
	_fronteiras = PackedFloat32Array()
	for f in mapa.borders:
		if f[SceneryMap.X] > de_mundo and f[SceneryMap.X] < ate_mundo:
			_fronteiras.append(roundf((plano * (mundo * Vector2(f[SceneryMap.X], 0.0))).x))
			_reinos.append(f[SceneryMap.DIREITA])
	var chave := [_reinos.duplicate(), _fronteiras, _janela, _origem]
	if chave != _chave:
		_chave = chave
		queue_redraw()


func _draw() -> void:
	_usadas.clear()
	var opaca := camada == OPACA
	for i in _reinos.size():
		var de := _fronteiras[i - 1] if i > 0 else -INF
		var ate := _fronteiras[i] if i < _fronteiras.size() else INF
		var cheio := Vector2(
			maxf(_janela.x, de + (MISTURA if i > 0 else 0.0)),
			minf(_janela.y, ate + (MISTURA if opaca else -MISTURA))
		)
		_pintar(_reinos[i], cheio, 1.0)
		if i > 0:
			_esvair(_reinos[i], de, 1.0)
		if i < _fronteiras.size() and not opaca:
			_esvair(_reinos[i], ate, -1.0)


## A faixa de uma fronteira em `x`: o reino entra (sentido 1, da esquerda para a direita)
## ou sai (sentido -1), em FATIAS degraus de alfa.
func _esvair(cena: StringName, x: float, sentido: float) -> void:
	var fatia := 2.0 * MISTURA / float(FATIAS)
	for k in FATIAS:
		var de := x - MISTURA + fatia * float(k)
		var alfa := (float(k) + MEIO) / float(FATIAS)
		_pintar(cena, Vector2(de, de + fatia), alfa if sentido > 0.0 else 1.0 - alfa)


func _pintar(cena: StringName, faixa: Vector2, alfa: float) -> void:
	var a := maxf(faixa.x, _janela.x)
	var b := minf(faixa.y, _janela.y)
	if b <= a:
		return
	var janela := Vector3(_origem, a, b)
	var tex: Texture2D
	if camada == OPACA:
		tex = SceneryArt.draw_mirrored(self, cena, camada, janela, SceneryArt.TUDO, alfa)
	else:
		tex = SceneryArt.draw_layer(self, cena, camada, janela, SceneryArt.TUDO, alfa)
	if tex != null and not _usadas.has(tex):
		_usadas.append(tex)


## Onde comeca o quadro, em x do plano, para o meio dele ficar atras do meio da regiao: o
## plano anda `escala` vezes o que a camara anda.
func _ancora(meio_agora: float, camara_x: float) -> float:
	var pai := get_parent() as Parallax2D
	var escala := pai.scroll_scale.x if pai != null else 1.0
	var largura := SceneryArt.width(SceneryArt.map().biome_at(camara_x))
	var meio_da_regiao := SimLoop.world_width * MEIO
	return roundf(meio_agora + escala * (meio_da_regiao - camara_x) - largura * MEIO)
