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
const FAIXA := MISTURA * 2.0
const FATIAS := 32
## O sentido de uma faixa: o reino entra da esquerda para a direita, ou sai.
const ENTRA := 1.0
const SAI := -1.0
const MEIO := 0.5

@export var camada: StringName = &"far"

var _janela := Vector2.ZERO
var _origem := NAN
var _chave: Array = []
## Os reinos da esquerda para a direita, e as fronteiras entre eles em x do plano.
var _reinos: Array[StringName] = []
var _fronteiras := PackedFloat32Array()
var _usadas: Array[Texture2D] = []
## A origem do quadro de cada reino de `_reinos`: a do mosaico, ou a de um sitio (ADR 0086).
var _origens := PackedFloat32Array()
var _sitios: Dictionary = {}
## As vistas pintadas para uma hora desenham-se aqui, com a luz delas (ADR 0086).
var _pintada: Node2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var luz: SceneryLight.Depth = LUZ.get(camada, SceneryLight.Depth.FAR)
	material = SceneryLight.material(luz)
	_pintada = Node2D.new()
	_pintada.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pintada.material = SceneryLight.material(luz, true)
	_pintada.draw.connect(func() -> void: _desenhar(_pintada, true))
	add_child(_pintada)


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
	var meio := (esquerda + direita) * MEIO
	var centro := camara.get_screen_center_position().x
	var primeiro := mapa.stretch_at(de_mundo)
	_reinos = [primeiro.get(SceneryMap.CENA, &"")]
	_origens = PackedFloat32Array([_origem_de(primeiro, meio, centro)])
	_fronteiras = PackedFloat32Array()
	for f in mapa.borders:
		if f[SceneryMap.X] > de_mundo and f[SceneryMap.X] < ate_mundo:
			_fronteiras.append(roundf((plano * (mundo * Vector2(f[SceneryMap.X], 0.0))).x))
			_reinos.append(f[SceneryMap.DIREITA])
			_origens.append(_origem_de(mapa.stretch_at(f[SceneryMap.X] + MEIO), meio, centro))
	var pesos := OwnerScenery.signature(_reinos)
	var chave := [_reinos.duplicate(), _fronteiras, _janela, _origens, pesos]
	if chave != _chave:
		_chave = chave
		_usadas.clear()
		queue_redraw()
		_pintada.queue_redraw()


func _draw() -> void:
	_desenhar(self, false)


## Os reinos da esquerda para a direita, num dos dois nos: a base e as variantes de estacao
## aqui, as pintadas para uma hora no `_pintada`.
func _desenhar(canvas: CanvasItem, pintadas: bool) -> void:
	var opaca := camada == OPACA
	for i in _reinos.size():
		var de := _fronteiras[i - 1] if i > 0 else -INF
		var ate := _fronteiras[i] if i < _fronteiras.size() else INF
		var cheio := Vector2(
			maxf(_janela.x, de + (MISTURA if i > 0 else 0.0)),
			minf(_janela.y, ate + (MISTURA if opaca else -MISTURA))
		)
		var reino := Vector2(i, 1.0 if pintadas else 0.0)
		_pintar(canvas, reino, cheio, 1.0)
		if i > 0:
			_esvair(canvas, reino, de, ENTRA)
		if i < _fronteiras.size() and not opaca:
			_esvair(canvas, reino, ate, SAI)


## A faixa de uma fronteira em `x`: o reino entra (ENTRA, da esquerda para a direita) ou
## sai (SAI), em FATIAS degraus de alfa.
func _esvair(canvas: CanvasItem, reino: Vector2, x: float, sentido: float) -> void:
	var fatia := FAIXA / float(FATIAS)
	for k in FATIAS:
		var de := x - MISTURA + fatia * float(k)
		var alfa := (float(k) + MEIO) / float(FATIAS)
		_pintar(canvas, reino, Vector2(de, de + fatia), alfa if sentido > 0.0 else 1.0 - alfa)


## `reino` e (o indice em `_reinos`, 1 se sao as variantes pintadas).
func _pintar(canvas: CanvasItem, reino: Vector2, faixa: Vector2, alfa: float) -> void:
	var a := maxf(faixa.x, _janela.x)
	var b := minf(faixa.y, _janela.y)
	if b <= a:
		return
	var i := int(reino.x)
	var janela := Vector3(_origens[i], a, b)
	var opaca := camada == OPACA
	for c in OwnerScenery.now(_reinos[i]):
		if c[OwnerScenery.PINTADA] != (reino.y > 0.0):
			continue
		var peso := alfa * OwnerScenery.alpha(c, opaca)
		var vista: StringName = c[OwnerScenery.VISTA]
		var tex: Texture2D
		if opaca:
			tex = SceneryArt.draw_mirrored(canvas, vista, camada, janela, SceneryArt.TUDO, peso)
		else:
			tex = SceneryArt.draw_layer(canvas, vista, camada, janela, SceneryArt.TUDO, peso)
		if tex != null and not _usadas.has(tex):
			_usadas.append(tex)


## A origem do quadro de um troco: a do mosaico, ou, num sitio, a que poe o meio da agua
## dele atras dela quando a camara la esta (como o `_ancora` faz ao reino).
func _origem_de(troco: Dictionary, meio_agora: float, camara_x: float) -> float:
	if not troco.has(SceneryMap.ANCORA):
		return _origem
	var x: float = troco[SceneryMap.ORIGEM]
	if not _sitios.has(x):
		var pai := get_parent() as Parallax2D
		var escala := pai.scroll_scale.x if pai != null else 1.0
		var ancora: float = troco[SceneryMap.ANCORA]
		_sitios[x] = roundf(meio_agora + escala * (x + ancora - camara_x) - ancora)
	return _sitios[x]


## Onde comeca o quadro, em x do plano, para o meio dele ficar atras do meio da regiao: o
## plano anda `escala` vezes o que a camara anda.
func _ancora(meio_agora: float, camara_x: float) -> float:
	var pai := get_parent() as Parallax2D
	var escala := pai.scroll_scale.x if pai != null else 1.0
	var largura := SceneryArt.width(SceneryArt.map().biome_at(camara_x))
	var meio_da_regiao := SimLoop.world_width * MEIO
	return roundf(meio_agora + escala * (meio_da_regiao - camara_x) - largura * MEIO)
