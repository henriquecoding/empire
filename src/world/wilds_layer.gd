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
#
# O campo e o horizonte desenham-se em talhoes (FloraArt.chunks), um filho por talhao:
# o motor deixa de fora os que estao longe da camara, e quando nasce um segmento so se
# refazem os talhoes que mudaram. Eram o mundo gerado inteiro num no so (03/10/2026).
class_name WildsLayer
extends Node2D

enum Plano { CAMPO, HORIZONTE, NUVENS }


## As plantas de um talhao. Usa o material do pai: a luz do plano e a mesma.
class Talhao:
	extends Node2D

	var plantas := PackedFloat32Array()
	var frente := 0.0
	var tras := 0.0
	var nevoa := Color.WHITE

	func _draw() -> void:
		FloraArt.draw_all(self, plantas, frente, tras, nevoa)


## O pe das plantas do campo, da frente (junto ao caminho) ao fundo; o do
## horizonte fica meio enterrado no campo, que se desenha por cima.
const CAMPO_Y := {"frente": 492.0, "tras": 436.0}
const HORIZONTE_Y := {"frente": 430.0, "tras": 425.0}
## Quantas larguras de regiao se desenham para cada lado do que esta em parallax.
const MARGEM := 1.0
## A largura de um talhao, em px do plano.
const TALHAO := 1024.0

## As nuvens: quantas, a que altura, o vento, e o sprite (x, y, largo, alto, tom).
const NUVENS := {"quantas": 18, "de_y": 40.0, "ate_y": 210.0, "vento": 6.0, "escala": 2.0}
const NUVEM := [[-14, 0, 28, 2, 1], [-12, -3, 24, 3, 0], [-8, -6, 16, 3, 0], [-3, -8, 8, 2, 0]]
const NUVEM_COR := [Color(0.93, 0.86, 0.73, 0.85), Color(0.79, 0.71, 0.56, 0.85)]
const SAL_NUVEM := 61

## Que luz leva cada plano (SceneryLight): o campo e o chao do jogo, o horizonte
## e o meio, e as nuvens sao ceu.
const LUZ_DO_PLANO := [SceneryLight.Depth.GROUND, SceneryLight.Depth.MID, SceneryLight.Depth.SKY]

@export var plane: Plano = Plano.CAMPO

var _clock: ClockData
var _chave: Array = []
var _plantas := PackedFloat32Array()
var _tempo := 0.0
var _talhoes: Dictionary = {}


func _ready() -> void:
	_clock = Registry.entry(&"economy", &"clock") as ClockData
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = SceneryLight.material(LUZ_DO_PLANO[plane])


func _process(delta: float) -> void:
	# O horizonte, as nuvens e o mato do campo sao os dos reinos pintados (ADR 0081). Os
	# passaros pousam onde pousavam: a Fauna tira os arbustos das tabelas, nao daqui.
	visible = not SceneryArt.painted()
	if not visible:
		return
	if _clock != null and ClockService.clock != null:
		SceneryLight.refresh(self)  # a luz ja nao e o `modulate`: e o shader (ADR 0048)
	if SimLoop.state == null:
		return
	var revisao := SimLoop.field.wilds.revision if SimLoop.field != null else -1
	var chave := [
		RngService.world_seed(),
		SimLoop.state.region,
		Wilds.biome_now(),
		SimLoop.world_width,
		revisao,
		ForestView.flora_key()
	]
	if chave != _chave:
		_chave = chave
		_plantas = _gerar()
		_repartir()
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
		var alcance := _alcance(largura)
		return Wilds.plants(
			camadas, alcance.x, alcance.y, regiao, Wilds.SAL.horizonte, Wilds.woods()
		)
	var campo := Wilds.table(Wilds.CAMPO, bioma)
	var plantas := Wilds.plants(campo, 0.0, largura, regiao, Wilds.SAL.campo, Wilds.woods())
	if SimLoop.field != null:  # e o campo das terras geradas, povo a povo (Q-173)
		plantas.append_array(WildGround.plants(SimLoop.field.wilds, largura, regiao))
	return ForestView.field_flora(plantas)  # a clareira e as estacoes (ADR 0066, 0070)


## A linha de arvores cobre o mundo ja gerado, visto ao ritmo do parallax dela (Q-173).
func _alcance(largura: float) -> Vector2:
	var mundo := Vector2(0.0, largura)
	if SimLoop.field != null:
		mundo = SimLoop.field.wilds.extent(largura)
	var pai := get_parent() as Parallax2D
	var escala := pai.scroll_scale.x if pai != null else 1.0
	var margem := largura * MARGEM
	return Vector2(
		minf(-margem, mundo.x * escala - margem), maxf(largura + margem, mundo.y * escala + margem)
	)


func _draw() -> void:
	if plane == Plano.NUVENS:
		_nuvens()


## As plantas pelos talhoes: so se redesenha o que mudou, e o que ja nao ha sai.
func _repartir() -> void:
	if plane == Plano.NUVENS:
		queue_redraw()
		return
	var campo := plane == Plano.CAMPO
	var pe: Dictionary = CAMPO_Y if campo else HORIZONTE_Y
	var partes := FloraArt.chunks(_plantas, TALHAO)
	for de: float in partes:
		var talhao: Talhao = _talhoes.get(de)
		if talhao == null:
			talhao = Talhao.new()
			talhao.use_parent_material = true
			talhao.frente = pe.frente
			talhao.tras = pe.tras
			talhao.nevoa = EnramadosLayer.FIELD if campo else EnramadosLayer.NEAR
			add_child(talhao)
			_talhoes[de] = talhao
		if talhao.plantas != partes[de]:
			talhao.plantas = partes[de]
			talhao.queue_redraw()
	for de: float in _talhoes.keys():
		if not partes.has(de):
			(_talhoes[de] as Talhao).queue_free()
			_talhoes.erase(de)


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
