class_name BandView
extends Node2D

@export var band: Band.Kind = Band.Kind.SURFACE

var _tropas: Dictionary = {}
var _bichos: Dictionary = {}
var _edificios: Dictionary = {}
var _relogio: ClockData
var _podre: RotProfile
var _luz := Lighting.new()
var _visual_time := 0.0
var _last_light_bucket := -1


func _ready() -> void:
	_tropas = SimFactory.by_id(&"units")
	_bichos = SimFactory.by_id(&"creatures")
	_edificios = SimFactory.by_id(&"buildings")
	_relogio = Registry.entry(&"economy", &"clock") as ClockData
	_podre = SimFactory.rot_profile()


func _process(delta: float) -> void:
	_visual_time += delta
	var relogio := ClockService.clock
	_luz.set_phase(_relogio, int(relogio.current_phase()), relogio.phase_progress())
	var bucket := int(relogio.phase_progress() * 8.0)
	var rot := SimLoop.night.rot if SimLoop.state != null else null
	if rot != null and rot.active():
		var raio := WorldLight.radius(_podre, SimLoop.state.day)
		_luz.set_lamp(rot.position_x(), raio, WorldLight.stops(_podre)[WorldLight.PARAGENS - 1])
	else:
		_luz.clear_lamp()
	if bucket != _last_light_bucket:
		_last_light_bucket = bucket
	queue_redraw()


func _draw() -> void:
	# O TerrainBackdrop trata o cenário; esta faixa trata apenas elementos vivos.
	if SimLoop.state == null:
		return
	if band == Band.Kind.SURFACE:
		_passagens()
		_podridao()
	_fogueiras()
	BuildView.draw_on(self, band, _edificios, _luz)
	_moedas()
	_criaturas()
	_tropa()


func _terreno() -> void:
	pass


func _passagens() -> void:
	var topo := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	var largura := WorldPalette.PASSAGEM_W
	for x in SimLoop.passages:
		var canto := Vector2(x - largura * WorldPalette.MEIA, topo)
		var cor := WorldPalette.tint(WorldPalette.PASSAGEM, _luz.scenery(1.0))
		draw_rect(Rect2(canto, Vector2(largura, fundo - topo)), cor)


func _podridao() -> void:
	RotView.draw_on(self, SimLoop.night.rot, _podre, SimLoop.state.day, _luz)


func _fogueiras() -> void:
	var cores := WorldLight.stops(_podre)
	for vaga in SimLoop.builds.slots:
		var raio := WorldLight.hearth_radius(vaga)
		if vaga.band != band or raio <= 0.0:
			continue
		RotView.lamp(self, Vector2(vaga.x, WorldPalette.ground_of(int(vaga.band))), raio, cores)


func _moedas() -> void:
	var moedas := SimLoop.coins
	for i in moedas.count():
		if moedas.bands[i] != int(band):
			continue
		var y := WorldPalette.ground_of(int(band)) - moedas.heights[i] - WorldPalette.MOEDA_R
		var cor := _luz.body(WorldPalette.MOEDA, moedas.xs[i])
		draw_circle(Vector2(moedas.xs[i], y), WorldPalette.MOEDA_R, cor)


func _criaturas() -> void:
	var bichos := SimLoop.creatures
	var candeira := _candeeiro()
	var chao := BandLight.ground_ratio(_relogio)
	for i in bichos.count():
		if bichos.bands[i] != int(band):
			continue
		var dados: CreatureData = _bichos.get(bichos.data_ids[i])
		if dados == null:
			continue
		var forma := Silhouette.of_creature(dados)
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(forma, bichos.xs[i], int(band), alto)
		var acesa := WorldLight.lit(bichos.xs[i], candeira.x, candeira.y)
		var corpo := _luz.body(WorldPalette.BICHO, bichos.xs[i])
		var cor := WorldLight.reveal(corpo, acesa, chao)
		draw_colored_polygon(Outline.shape(forma, caixa, 0), cor)
		ActorArt.draw_creature(self, caixa, forma, cor, _visual_time)
		if acesa:
			Gauge.health(
				self, caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i]))
			)


func _candeeiro() -> Vector2:
	var rot := SimLoop.night.rot
	if not rot.active():
		return Vector2(0.0, INF)
	return Vector2(rot.position_x(), WorldLight.radius(_podre, SimLoop.state.day))


func _tropa() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		if unidades.bands[i] != int(band):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados == null:
			continue
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(Silhouette.Form.CAIXA, unidades.xs[i], int(band), alto)
		var cor := _luz.body(WorldPalette.unit_color(unidades, i), unidades.xs[i])
		ActorArt.draw_unit(self, caixa, dados, unidades, i, cor, _visual_time)
		_saco(caixa, unidades, i)
		if unidades.alive(i):
			Gauge.health(
				self, caixa, float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i]))
			)


func _saco(caixa: Rect2, unidades, i: int) -> void:
	if not unidades.alive(i):
		return
	Gauge.purse(self, caixa, unidades.carried_coins[i], unidades.coin_capacities[i])
