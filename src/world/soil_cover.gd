# src/world/soil_cover.gd — a terra por cima do corte de solo, que so se vai quando o rei
# desce (o pedido do dono de 30/09/2026; §11; ADR 0039).
#
# O dono: "o subsolo so fica aparente ao acessa-lo; quero que tenha vegetacao aparente
# sempre, ou lagos, caminhos, dentre outras coisas, mas o subsolo so aparece ao acessar".
# A §11 escreve o mesmo: "em baixo e so paisagem"; "uma cavidade nao descoberta
# desenha-se como terra normal. Ao encontrar a entrada, a terra dissolve-se com o shader
# de dither e revela o interior."
#
# Um no, na cena de jogo, entre a faixa do subsolo e a da superficie: tapa a cave, o
# tunel, as masmorras, quem esta la em baixo e os morcegos, e fica por baixo de quem
# anda em cima dela. A luz e a do cenario (SceneryLight), como o chao de cima. Com o rei
# la em baixo, o dither_reveal da §60 dissolve-a; com ele ca em cima, volta.
#
# O chao, os caminhos e os lagos desenham-se aqui; as plantas, num filho por troco (a
# Moita), que so se redesenha quando o troco dele muda — quando nasce um segmento, so o
# dele se faz — e que o motor deixa de fora quando esta longe da camara.
class_name SoilCover
extends Node2D


## As plantas de um troco. Usa o material do pai: o dither e o mesmo.
class Moita:
	extends Node2D

	var plantas := PackedFloat32Array()

	func _draw() -> void:
		LowlandArt.plants(self, plantas)


const MAX_WINDOWS := 32
const SHADER := "res://shaders/dither_reveal.gdshader"

## Quanto o corte de solo se ve agora, de 0 a 1: e o que a boca da passagem e os golpes
## la em baixo perguntam. Um so no o escreve; sem ele na cena, nada tapa o subsolo.
static var _aberto := 1.0
static var _windows := PackedVector4Array()

var _clock: ClockData
var _revelar := SoilReveal.new()
var _dither: ShaderMaterial
var _chave: Array = []
var _terra: Dictionary = {}
var _cache: Dictionary = {}
var _moitas: Dictionary = {}


## Quanto do corte de solo se ve: 0 tapado, 1 aberto.
static func opened() -> float:
	return _aberto


## Quanto o corte de solo se ve neste x: o de todo o lado, ou o de uma janela que o
## apanhe (o sitio onde o rei esta, uma boca visitada, Q-182, Q-186).
static func opened_at(x: float) -> float:
	var aberto := _aberto
	for window in _windows:
		if absf(x - window.x) <= window.y * BuildSystem.METADE:
			aberto = maxf(aberto, window.w if window.w > 0.0 else 1.0)
	return aberto


## Se o que esta nesta faixa esta tapado pela terra: so o subsolo, e so fechado de todo.
static func covers(faixa: int, x := INF) -> bool:
	for window in _windows:
		if absf(x - window.x) < window.y * BuildSystem.METADE:
			return false
	return faixa == int(Band.Kind.UNDERGROUND) and _aberto <= 0.0


func _ready() -> void:
	_clock = Registry.entry(&"economy", &"clock") as ClockData
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dither = ShaderMaterial.new()
	_dither.shader = load(SHADER)
	_dither.set_shader_parameter(&"matrix", SoilReveal.matrix())
	material = _dither


func _exit_tree() -> void:
	_aberto = 1.0
	_windows = PackedVector4Array()


func _process(delta: float) -> void:
	if _clock != null and ClockService.clock != null:
		SceneryLight.refresh(self)  # a luz e a do cenario, no mesmo shader (ADR 0048)
		SceneryLight.feed(_dither, SceneryLight.Depth.BELOW)
	if SimLoop.state == null or SimLoop.units == null:
		return
	_revelar.step(delta, SoilReveal.wants_open(SimLoop.units, Assume.driven()))
	var player := SimLoop.units.index_of(Assume.driven())
	var sitio := _sitio(player)
	_aberto = _revelar.progress if is_nan(sitio.x) else 0.0  # so ali, se ha sitio (Q-186)
	_dither.set_shader_parameter(&"progress", _aberto)
	if SimLoop.field != null and player >= 0:
		var mouths := Passages.open(SimLoop.passages, SimLoop.builds)
		mouths.append_array(UnderWatch.mouths(SimLoop.field))
		_windows = SimLoop.field.underground_sight.windows(
			mouths, SimLoop.creatures, SimLoop.units.xs[player], RulesFactory.rules()
		)
		if not is_nan(sitio.x) and _revelar.progress > 0.0:
			_windows.insert(0, SoilReveal.site_window(sitio, _revelar.progress))
		_windows = _windows.slice(0, MAX_WINDOWS)
		_dither.set_shader_parameter(&"window_count", _windows.size())
		var padded := _windows.duplicate()
		padded.resize(MAX_WINDOWS)
		_dither.set_shader_parameter(&"windows", padded)
	visible = _aberto < 1.0
	var revisao := SimLoop.field.wilds.revision if SimLoop.field != null else -1
	var mundo := [RngService.world_seed(), SimLoop.state.region, SimLoop.world_width]
	var chave := [mundo, Wilds.biome_now(), revisao]
	if chave == _chave:
		return
	if _chave.is_empty() or _chave[0] != mundo:
		_cache.clear()
	_chave = chave
	_refazer()


## As paredes do sitio onde esta quem se conduz, se esta la em baixo dentro de um; NAN se
## nao (sem sitio, a terra vai-se toda, como antes da Q-186).
func _sitio(player: int) -> Vector2:
	var nada := Vector2(NAN, NAN)
	if SimLoop.field == null or player < 0:
		return nada
	if int(SimLoop.units.bands[player]) != int(Band.Kind.UNDERGROUND):
		return nada
	var i := SimLoop.field.under.site_at(SimLoop.units.xs[player])
	return nada if i == UndergroundSites.NONE else SimLoop.field.under.span(i)


## A terra de novo, com as plantas dos trocos que ja estavam feitos tiradas da cache.
func _refazer() -> void:
	var terras: WildSegments = SimLoop.field.wilds if SimLoop.field != null else null
	var regiao := SimLoop.state.region
	var largura := SimLoop.world_width
	_terra = Lowland.of(terras, largura, regiao, Wilds.biome_now(), Lowland.avoided(), _cache)
	var trocos: Array = _terra[Lowland.TROCOS]
	var plantas: Array = _terra[Lowland.PLANTAS]
	var vistas := {}
	for i in trocos.size():
		var onde: float = trocos[i][Lowland.A]
		vistas[onde] = true
		if not _moitas.has(onde):
			var nova := Moita.new()
			nova.use_parent_material = true
			add_child(nova)
			_moitas[onde] = nova
		var moita: Moita = _moitas[onde]
		if moita.plantas != plantas[i]:
			moita.plantas = plantas[i]
			moita.queue_redraw()
	for onde: float in _moitas.keys():
		if not vistas.has(onde):
			(_moitas[onde] as Moita).queue_free()
			_moitas.erase(onde)
	queue_redraw()


func _draw() -> void:
	LowlandArt.ground(self, _terra)
