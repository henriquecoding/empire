# src/world/wilds_layer.gd — um plano das terras bravias: campo, horizonte ou nuvens.
#
# Irmao do EnramadosLayer, e pelas mesmas regras: coordenadas de mundo, a luz
# pelo `modulate` do ambiente, e o desenho feito uma vez. O campo e o horizonte
# so se redesenham quando a semente, a regiao ou o bioma mudam — quando se
# atravessa (Q-135) ou se retoma um save. As nuvens andam, e essas sim
# redesenham-se a cada frame (sao poucos rectangulos).
#
# O horizonte e as nuvens vivem dentro de um Parallax2D: a camara ve-os mais
# devagar, e por isso sao desenhados para la da regiao, para um lado e para o
# outro — como a serra do EnramadosLayer.
class_name WildsLayer
extends Node2D

enum Plano { CAMPO, HORIZONTE, NUVENS }

## O pe das plantas do campo, da frente (junto ao caminho) ao fundo; o do
## horizonte fica meio enterrado no campo, que se desenha por cima.
const CAMPO_Y := {"frente": 492.0, "tras": 436.0}
const HORIZONTE_Y := {"frente": 430.0, "tras": 425.0}
## Quantas larguras de regiao se desenham para cada lado do que esta em parallax.
const MARGEM := 1.0

## As nuvens: quantas, a que altura, o vento, e o sprite (x, y, largo, alto, tom).
const NUVENS := {"quantas": 18, "de_y": 40.0, "ate_y": 210.0, "vento": 6.0, "escala": 2.0}
const NUVEM := [[-14, 0, 28, 2, 1], [-12, -3, 24, 3, 0], [-8, -6, 16, 3, 0], [-3, -8, 8, 2, 0]]
const NUVEM_COR := [Color(0.93, 0.86, 0.73, 0.85), Color(0.79, 0.71, 0.56, 0.85)]
const SAL_NUVEM := 61

@export var plane: Plano = Plano.CAMPO

var _clock: ClockData
var _chave: Array = []
var _plantas := PackedFloat32Array()
var _tempo := 0.0


func _ready() -> void:
	_clock = Registry.entry(&"economy", &"clock") as ClockData
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if _clock != null and ClockService.clock != null:
		var relogio := ClockService.clock
		modulate = BandLight.ambient(_clock, int(relogio.current_phase()), relogio.phase_progress())
	if SimLoop.state == null:
		return
	var chave := [
		RngService.world_seed(), SimLoop.state.region, Wilds.biome_now(), SimLoop.world_width
	]
	if chave != _chave:
		_chave = chave
		_plantas = _gerar()
		queue_redraw()
	if plane == Plano.NUVENS:
		_tempo += delta
		queue_redraw()


func _gerar() -> PackedFloat32Array:
	var largura := SimLoop.world_width
	var bioma := Wilds.biome_now()
	var regiao := SimLoop.state.region
	if plane == Plano.NUVENS:
		var dados := PackedFloat32Array()
		for i in NUVENS.quantas:
			dados.append_array(RngService.scatter(hash([SAL_NUVEM, regiao, i]), Wilds.BICHO))
		return dados
	if plane == Plano.HORIZONTE:
		var camadas := Wilds.table(Wilds.HORIZONTE, bioma)
		var de := -largura * MARGEM
		var ate := largura * (1.0 + MARGEM)
		return Wilds.plants(camadas, de, ate, regiao, Wilds.SAL.horizonte, Wilds.woods())
	var campo := Wilds.table(Wilds.CAMPO, bioma)
	return Wilds.plants(campo, 0.0, largura, regiao, Wilds.SAL.campo, Wilds.woods())


func _draw() -> void:
	match plane:
		Plano.CAMPO:
			FloraArt.draw_all(self, _plantas, CAMPO_Y.frente, CAMPO_Y.tras, EnramadosLayer.FIELD)
		Plano.HORIZONTE:
			var nevoa := EnramadosLayer.NEAR
			FloraArt.draw_all(self, _plantas, HORIZONTE_Y.frente, HORIZONTE_Y.tras, nevoa)
		Plano.NUVENS:
			_nuvens()


## Cada nuvem tem o seu sitio, altura e velocidade, tirados da semente uma vez
## (em `_plantas`, aos triplos); o vento leva-as e o `wrapf` tra-las de volta do
## outro lado, longe da vista.
func _nuvens() -> void:
	var largura := maxf(SimLoop.world_width, float(EnramadosLayer.WIDTH))
	var de := -largura * MARGEM
	var ate := largura * (1.0 + MARGEM)
	for i in range(0, _plantas.size(), Wilds.BICHO):
		var anda := NUVENS.vento * (1.0 + _plantas[i + 1]) * _tempo
		var x := floorf(wrapf(lerpf(de, ate, _plantas[i]) + anda, de, ate))
		var y := floorf(lerpf(NUVENS.de_y, NUVENS.ate_y, _plantas[i + 2]))
		var s: float = NUVENS.escala * (1.0 + _plantas[i + 1])
		draw_set_transform(Vector2(x, y), 0.0, Vector2(floorf(s), floorf(s)))
		for r: Array in NUVEM:
			draw_rect(FloraArt.rect(r), NUVEM_COR[r[FloraArt.TOM]])
	draw_set_transform(Vector2.ZERO)
