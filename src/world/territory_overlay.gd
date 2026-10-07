# src/world/territory_overlay.gd — o territorio que o jogo conhece, desenhado por cima do
# mundo, so com o inspetor aberto (CV-39 e EX-07 do plano de cenarios; ADR 0078).
#
# Le as mesmas fontes e as mesmas respostas do TerritoryWatch que decidem se uma obra se
# levanta (ADR 0077): a agua, as arvores de pe e a rocha das passagens como barras no
# chao, e cada sitio de obra com o alcance da regra e se cabe. Nao ha aqui uma segunda
# lista de rios: e o que permite ver se o rio pintado e o rio contado coincidem. E
# diagnostico — nada disto aparece a quem joga, e nao muda estado nenhum.
class_name TerritoryOverlay
extends Node2D

const SOURCES := &"sources"
const SITES := &"sites"
const CORES := {&"water": Atlas.INFO, &"forest": Atlas.VALID, &"rock": Atlas.SECONDARY}
const BARRA := 6.0
const MARCO := 14.0
const ALCANCE := 2.0
const ALFA := 0.8
## Abaixo do pe na superficie, e junto ao fundo do corte no subsolo.
const PE := 6.0
const FUNDO := 18.0
const REVER_S := 0.5

var _marcas := {}
var _rever := 0.0


## As fontes e os sitios do territorio de agora, com a resposta de cada sitio.
static func marks() -> Dictionary:
	var sitios := []
	if SimLoop.field == null:
		return {SOURCES: [], SITES: sitios}
	var respostas: Dictionary = TerritoryWatch.profile()[TerritoryProfile.SITES]
	for s: Dictionary in TerritoryWatch.sites():
		var marca := s.duplicate()
		var r: Dictionary = respostas.get(int(s[TerritoryProfile.ID]), {})
		marca[PlacementRules.ALLOWED] = r.get(PlacementRules.ALLOWED, false)
		sitios.append(marca)
	return {SOURCES: TerritoryWatch.sources(), SITES: sitios}


func _ready() -> void:
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
	visible = false


func _process(delta: float) -> void:
	visible = Inspector.shown and SimLoop.state != null
	if not visible:
		_rever = 0.0
		return
	_rever -= delta
	if _rever <= 0.0:
		_rever = REVER_S
		_marcas = marks()
		queue_redraw()


func _draw() -> void:
	for f: Dictionary in _marcas.get(SOURCES, []):
		var span: Vector2 = f[PlacementRules.SPAN]
		var y := _y(int(f[PlacementRules.BAND]))
		var cor: Color = CORES.get(f[PlacementRules.NEED], Atlas.TEXT)
		var largura := maxf(ALCANCE, span.y - span.x)
		draw_rect(Rect2(span.x, y, largura, BARRA), Color(cor, ALFA))
	for s: Dictionary in _marcas.get(SITES, []):
		var x: float = s[TerritoryProfile.X]
		var y := _y(int(s[PlacementRules.BAND]))
		var alcance: float = s[TerritoryProfile.REACH]
		var cor := Atlas.VALID if s[PlacementRules.ALLOWED] else Atlas.DANGER
		draw_line(Vector2(x - alcance, y - MARCO), Vector2(x + alcance, y - MARCO), cor, ALCANCE)
		draw_line(Vector2(x, y - MARCO * 2), Vector2(x, y + BARRA), cor, ALCANCE)


static func _y(band: int) -> float:
	if band == int(Band.Kind.UNDERGROUND):
		return Band.SCREEN_BOTTOM - FUNDO
	return Band.GROUND_LINE + PE
