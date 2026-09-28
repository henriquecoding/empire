# src/world/fauna_view.gd — os bichos de cenario, a mexer (§11, §22).
#
# Um no so para as tres faixas, desenhado por cima do segmento e por baixo da
# tropa: um passaro nao tapa quem se joga. Solta os bichos do Wilds quando a
# semente, a regiao ou o bioma mudam, e depois so os faz andar.
#
# O escuro nao salta: entra e sai a ESCURECER por segundo, e e ele que decide
# quem se ve — o pardal recolhe ao anoitecer e o pirilampo acende-se, tantos
# quantos o enxame dessa noite der (Wilds.swarm).
class_name FaunaView
extends Node2D

## Quanto escuro ha em cada fase; as que nao estao aqui sao dia.
const ESCURO := {GameClock.Phase.DAWN: 0.4, GameClock.Phase.DUSK: 0.6, GameClock.Phase.NIGHT: 1.0}
const ESCURECER := 0.25
## Antes do primeiro frame o escuro e o da fase, sem transicao.
const POR_SABER := -1.0

var _fauna := Fauna.new()
var _clock: ClockData
var _luz := Lighting.new()
var _tempo := 0.0
var _escuro := POR_SABER
var _chave: Array = []
var _enxame := 1.0
var _dia := -1


func _ready() -> void:
	_clock = Registry.entry(&"economy", &"clock") as ClockData
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if _clock == null or ClockService.clock == null or SimLoop.state == null:
		return
	_tempo += delta
	_soltar()
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	var alvo := float(ESCURO.get(fase, 0.0))
	_escuro = alvo if _escuro < 0.0 else move_toward(_escuro, alvo, delta * ESCURECER)
	if SimLoop.state.day != _dia:
		_dia = SimLoop.state.day
		_enxame = Wilds.swarm(_dia)
	_luz.set_phase(_clock, fase, relogio.phase_progress())
	var i := SimLoop.units.index_of(SimLoop.king_id)
	var rei_aqui := i != UnitSystem.NENHUM and int(SimLoop.units.bands[i]) == Band.Kind.SURFACE
	_fauna.tick(delta, SimLoop.units.xs[i] if rei_aqui else 0.0, rei_aqui)
	queue_redraw()


## Os bichos nascem dos arbustos e das tabelas do bioma, uma vez por regiao.
func _soltar() -> void:
	var bioma := Wilds.biome_now()
	var chave := [RngService.world_seed(), SimLoop.state.region, bioma, SimLoop.world_width]
	if chave == _chave:
		return
	_chave = chave
	var largura := SimLoop.world_width
	var regiao := SimLoop.state.region
	var campo := Wilds.table(Wilds.CAMPO, bioma)
	var plantas := Wilds.plants(campo, 0.0, largura, regiao, Wilds.SAL.campo, Wilds.woods())
	var lista := Wilds.animals(Wilds.table(Wilds.FAUNA, bioma), 0.0, largura, regiao, plantas)
	_fauna.populate(lista, largura)


func _draw() -> void:
	for b in _fauna.bichos:
		var alfa := Fauna.presence(b.kind, _escuro)
		if b.kind == Wilds.Animal.FIREFLY and b.variant > _enxame:
			continue
		FaunaArt.draw_on(self, b, _luz, alfa, _tempo)
