# src/world/scenery_strip.gd — o chao pintado, no espaco do mundo (a entrega de cenarios em
# camadas de 08/10/2026; ADR 0081).
#
# Duas partes, porque o subsolo se revela por baixo da linha onde se anda (ADR 0039):
#   · SUPERFICIE — a beira de erva e o caminho ate y 517, e o marco da transicao. Nunca sai.
#   · ABAIXO — a encosta abaixo do caminho, o terraco de baixo, a agua e a folhagem da
#     frente. E a terra do SoilCover: vive dentro dele, com o dither e a luz dele, e vai-se
#     quando o rei desce a um sitio.
#
# Cada troco do SceneryMap pinta a sua cena. Onde duas cenas diferentes se tocam, o reino
# entra na outra cena a esvair-se em FUNDIDO px, para a junta nao ser um corte a direito.
# So se pinta a volta da camara, e so se redesenha quando ela anda um segmento.
class_name SceneryStrip
extends Node2D

enum Parte { SUPERFICIE, ABAIXO }

## As camadas de cada parte, por ordem de desenho, e as linhas que cada parte ocupa.
const CAMADAS := {
	Parte.SUPERFICIE: [&"under"],
	Parte.ABAIXO: [&"under", &"terrain", &"water", &"foreground"],
}
const MARCO := &"landmark"
const CORTE := {
	Parte.SUPERFICIE: Vector2(0.0, float(Band.GROUND_LINE)),
	Parte.ABAIXO: Vector2(float(Band.GROUND_LINE), float(Band.SCREEN_BOTTOM)),
}
## A janela anda aos segmentos, com um ecra e meio de folga para cada lado.
const DEGRAU := 640.0
const MARGEM := 1920.0
## A junta entre duas cenas: quantos px e em quantas fatias.
const FUNDIDO := 48.0
const FATIAS := 12
const MEIO := 0.5
## Para que lado o reino entra na outra cena.
const PARA_A_DIREITA := 1.0
const PARA_A_ESQUERDA := -1.0

@export var parte: Parte = Parte.SUPERFICIE

var _janela := Vector2.ZERO
var _mapa: SceneryMap
var _usadas: Array[Texture2D] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if parte == Parte.SUPERFICIE:
		material = SceneryLight.material(SceneryLight.Depth.GROUND)


func _process(_delta: float) -> void:
	visible = SceneryArt.painted()
	if not visible:
		return
	if parte == Parte.SUPERFICIE and ClockService.clock != null:
		SceneryLight.refresh(self)
	var camara := get_viewport().get_camera_2d()
	if camara == null:
		return
	var centro := camara.get_screen_center_position().x
	var janela := Vector2(
		floorf((centro - MARGEM) / DEGRAU) * DEGRAU, ceilf((centro + MARGEM) / DEGRAU) * DEGRAU
	)
	var mapa := SceneryArt.map()
	if janela != _janela or mapa != _mapa:
		_janela = janela
		_mapa = mapa
		queue_redraw()


func _draw() -> void:
	_usadas.clear()
	if _mapa == null:
		return
	var trocos := _mapa.within(_janela.x, _janela.y)
	var corte: Vector2 = CORTE[parte]
	for camada: StringName in CAMADAS[parte]:
		for t in trocos:
			_guardar(SceneryArt.draw_layer(self, t[SceneryMap.CENA], camada, _de(t), corte))
		for i in range(1, trocos.size()):
			_juntar(trocos[i - 1], trocos[i], camada, corte)
	if parte == Parte.SUPERFICIE:
		for t in trocos:
			if t[SceneryMap.LIMIAR]:
				_guardar(SceneryArt.draw_once(self, t[SceneryMap.CENA], MARCO, _de(t), corte))
		if SimLoop.field != null:
			ResourceWater.draw(self, _janela)


## A janela de desenho de um troco: a origem do quadro e o pedaco dele que se ve.
func _de(t: Dictionary) -> Vector3:
	return Vector3(
		t[SceneryMap.ORIGEM], maxf(t[SceneryMap.DE], _janela.x), minf(t[SceneryMap.ATE], _janela.y)
	)


## A junta de dois trocos de cenas diferentes: o reino continua para dentro da outra cena,
## a esvair-se. Com dois reinos, entra o da esquerda; com uma transicao, entra o reino.
func _juntar(a: Dictionary, b: Dictionary, camada: StringName, corte: Vector2) -> void:
	if a[SceneryMap.CENA] == b[SceneryMap.CENA] or a[SceneryMap.ATE] != b[SceneryMap.DE]:
		return
	var x: float = b[SceneryMap.DE]
	var reino := a if not a[SceneryMap.LIMIAR] else b
	if reino[SceneryMap.LIMIAR]:
		return
	var sentido := PARA_A_DIREITA if reino == a else PARA_A_ESQUERDA
	var fatia := FUNDIDO / float(FATIAS)
	for i in FATIAS:
		var de := x + sentido * fatia * float(i)
		var ate := de + sentido * fatia
		var alfa := 1.0 - (float(i) + MEIO) / float(FATIAS)
		var janela := Vector3(0.0, minf(de, ate), maxf(de, ate))
		_guardar(SceneryArt.draw_layer(self, reino[SceneryMap.CENA], camada, janela, corte, alfa))


func _guardar(tex: Texture2D) -> void:
	if tex != null and not _usadas.has(tex):
		_usadas.append(tex)
