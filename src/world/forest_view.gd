# src/world/forest_view.gd — a floresta no plano de accao, e o que ela faz a quem esta
# perto (ADR 0070).
#
# As arvores desenham-se por tras das obras e de quem anda, no mesmo canvas das obras e
# com a mesma luz (SceneryLight). Quando o monarca esta ao pe de uma arvore, a vista
# mostra a quem ela serve antes de a moeda sair: um losango por cima de cada destino que
# perde uma origem se ela cair (as provisoes, a toca do veado) e o chao entre os dois.
# A vista normal nao leva numeros; os numeros estao no painel (ForestGuide).
#
# E daqui que o cenario sabe que chao ficou vazio: a clareira da fundacao (ADR 0066) e a
# volta de cada tronco que ja la nao esta. A flora comum gerada pela semente nao volta a
# nascer em nenhum dos dois. As flores sao da primavera e do verao.
class_name ForestView
extends RefCounted

## Quanto uma arvore passa do pe dela para cada lado, para decidir se se ve.
const MEIA := 48.0
const LOSANGO := {"meio": 6.0, "alto": 46.0}
const LINHA := 2.0
const COR := Color("e3c877")
const TRANSLUCIDO := 0.55


static func draw_on(canvas: CanvasItem, band: Band.Kind, luz: Lighting, tempo: float) -> void:
	if band != Band.Kind.SURFACE or SimLoop.field == null:
		return
	var w := SimLoop.field.woodland
	if w.count() == 0:
		return
	var vista := PresentationBounds.of(canvas)
	var chao := WorldPalette.ground_of(band)
	var estacao := season()
	var especies := _species()
	for i in w.count():
		if not PresentationBounds.sees(vista, w.xs[i], MEIA):
			continue
		var especie: FloraData = especies.get(StringName(w.species[i]))
		if especie != null:
			var pe := Vector2(w.xs[i], chao)
			TreeArt.draw(canvas, pe, especie, w.states[i], estacao, tempo, w.ids[i], luz)
	_preview(canvas, w, chao)


## A estacao de agora, ou a primavera sem relogio (um teste, uma captura fria).
static func season() -> int:
	if SimLoop.field == null or ClockService.clock == null:
		return Seasons.SPRING
	return SimLoop.field.seasons.at(ClockService.clock.day)


## O chao sem flora comum: a clareira da fundacao e a volta de cada tronco que ja caiu.
static func ground_spans() -> Array[Vector2]:
	var vazio: Array[Vector2] = SimLoop.arrival.clear_manifest.duplicate()
	if SimLoop.field != null:
		vazio.append_array(SimLoop.field.woodland.gone_spans(ForestWatch.rules().flora_clear_px))
	return vazio


## A flora comum de `plantas` (quadruplos do Wilds) sem o chao vazio e, fora da
## primavera e do verao, sem flores.
static func field_flora(plantas: PackedFloat32Array) -> PackedFloat32Array:
	var limpas := SiteValidator.flora(plantas, ground_spans())
	if season() < Seasons.AUTUMN:
		return limpas
	var saida := PackedFloat32Array()
	for i in range(0, limpas.size(), Wilds.PLANTA):
		if int(limpas[i]) != Wilds.Plant.FLOWER:
			saida.append_array(limpas.slice(i, i + Wilds.PLANTA))
	return saida


## A chave de quem desenha a flora comum: muda quando o chao vazio ou a estacao mudam.
static func flora_key() -> Array:
	var revisao := SimLoop.field.woodland.revision if SimLoop.field != null else -1
	return [SimLoop.arrival.clear_manifest, revisao, season() >= Seasons.AUTUMN]


## Os destinos que a arvore ao pe do monarca serve: as provisoes que a coleta usa e as
## tocas que vivem de arvores, quando ela conta para eles.
static func targets(i: int) -> Array[float]:
	var saida: Array[float] = []
	var w := SimLoop.field.woodland
	var regras := ForestWatch.rules()
	var flora := ForestWatch.flora()
	var o := SimLoop.arrival
	var come := Influence.kinds(flora, Influence.FORAGE)
	if o.active and Influence.would_lose(w, i, o.cache_x, regras.grove_feeds_radius, come) > 0:
		saida.append(o.cache_x)
	var abrigo := Influence.kinds(flora, Influence.SHELTER)
	var tocas := SimLoop.field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] != String(ForestWatch.ARVORE):
			continue
		if Influence.would_lose(w, i, tocas.xs[k], regras.shelter_radius, abrigo) > 0:
			saida.append(tocas.xs[k])
	return saida


static func _preview(canvas: CanvasItem, w: Woodland, chao: float) -> void:
	var u := SimLoop.units
	var rei := u.index_of(Assume.driven())
	if rei < 0 or u.bands[rei] != int(Band.Kind.SURFACE):
		return
	var i := w.nearest(u.xs[rei], ForestWatch.rules().tree_reach_px)
	if i < 0:
		return
	var cor := Color(COR, TRANSLUCIDO)
	for x in targets(i):
		var topo := Vector2(x, chao - LOSANGO.alto)
		var m: float = LOSANGO.meio
		var losango := PackedVector2Array(
			[
				topo + Vector2(0, -m),
				topo + Vector2(m, 0),
				topo + Vector2(0, m),
				topo + Vector2(-m, 0)
			]
		)
		canvas.draw_colored_polygon(losango, cor)
		canvas.draw_line(Vector2(w.xs[i], chao), Vector2(x, chao), cor, LINHA)


static func _species() -> Dictionary:
	var saida := {}
	for especie: FloraData in ForestWatch.flora():
		saida[especie.id] = especie
	return saida
