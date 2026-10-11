# src/core/territory_watch.gd — o territorio decide o que se levanta (o relatorio de
# 06/10/2026, achados A01 a A04; ADR 0077).
#
# Ate aqui o pesqueiro existia porque o segmento de partida tem `resource = water`, e a
# fundacao livre levava-o com a sede para onde ela fosse, com agua ou sem ela. Agora a
# agua tem sitio no mundo, e a obra que precisa dela pergunta ao PlacementRules se a tem
# ao alcance. As fontes:
#   · a agua que o segmento de partida autora (o lago do castelo-arvore, biomes.csv), que
#     fica onde esta quando a sede se muda e anda com o terreno quando o terreno anda;
#   · a agua dos segmentos de agua das terras, a volta do assunto, e o mar de uma borda;
#   · as arvores de pe, uma a uma (a floresta);
#   · a rocha la em baixo: o porao de cada passagem, entre as muralhas a volta dela — a
#     mesma regra com que o UnderWatch mete o poco de minerio no porao (Q-130) — e as
#     cavernas das falhas de rocha.
# A previsao (`preview`) e a confirmacao (`apply`) usam a mesma conta. O que fica em cada
# sitio (`terrain_bar`) e derivado e nao vai no save: recalcula-se ao montar, ao fundar,
# ao carregar e quando nasce terra nova.
class_name TerritoryWatch
extends RefCounted

const AGUA := &"water"
const FLORESTA := &"forest"
const ROCHA := &"rock"
const MAR := &"sea"
static var open_access := PackedFloat32Array()


static func refresh_access(opened: PackedFloat32Array) -> void:
	if opened != open_access:
		apply()


static func rules() -> TerritoryRules:
	return Registry.entry(&"economy", &"territory") as TerritoryRules


## As fontes do mundo das necessidades `needs` (todas, se vazio); `shift` desloca as
## muralhas da sede (a previsao da fundacao livre).
static func sources(shift := 0.0, needs: Dictionary = {}) -> Array:
	var fontes := []
	if SimLoop.field == null:
		return fontes
	var regras := rules()
	var superficie := int(Band.Kind.SURFACE)
	if needs.is_empty() or needs.has(AGUA):
		_agua(fontes, regras)
	if needs.is_empty() or needs.has(FLORESTA):
		var w := SimLoop.field.woodland
		for i in w.count():
			if w.standing(i):
				fontes.append(
					PlacementRules.source(
						"tree_%d" % w.ids[i], FLORESTA, superficie, Vector2(w.xs[i], w.xs[i])
					)
				)
	if needs.is_empty() or needs.has(ROCHA):
		_rocha(fontes, shift)
	return fontes


## Os sitios de obra que precisam de uma fonte; os da sede ficam onde ficariam com `shift`.
static func sites(shift := 0.0) -> Array:
	var regras := rules()
	var sitios := []
	for vaga in SimLoop.builds.slots:
		if not Registry.has_entry(&"buildings", vaga.kind):
			continue  # a sede, o muro, as estacas: nao sao edificios do buildings.csv
		var dados := Registry.entry(&"buildings", vaga.kind) as BuildingData
		if dados.requires_biome_feature.is_empty():
			continue
		var need := dados.requires_biome_feature
		var x := vaga.x + (shift if vaga.territory == 0 else 0.0)
		sitios.append(
			TerritoryProfile.site(
				vaga.id, need, x, int(vaga.band), reach(regras, need), minimum(regras, need)
			)
		)
	return sitios


static func reach(regras: TerritoryRules, need: StringName) -> float:
	match need:
		AGUA:
			return regras.water_reach_px
		FLORESTA:
			return regras.forest_reach_px
		ROCHA:
			return regras.rock_reach_px
	return 0.0


static func minimum(regras: TerritoryRules, need: StringName) -> int:
	return regras.forest_min if need == FLORESTA else 1


## So se juntam as fontes que algum sitio pede: hoje nenhum pede floresta, e a previsao
## corre no painel sem percorrer as arvores.
static func profile(shift := 0.0) -> Dictionary:
	var sitios := sites(shift)
	var needs := {}
	for s: Dictionary in sitios:
		needs[s[PlacementRules.NEED]] = true
	if needs.is_empty():
		return TerritoryProfile.of(sitios, [])
	return TerritoryProfile.of(sitios, sources(shift, needs))


## O perfil se a sede se fundasse em `x`, sem o terreno se mexer (ADR 0066).
static func preview(x: float) -> Dictionary:
	return profile(x - SimLoop.core_x)


## Cada sitio fica com a razao por que o territorio o recusa, ou vazia.
static func apply() -> void:
	if SimLoop.field == null:
		return
	open_access = Passages.open(SimLoop.passages, SimLoop.builds)
	var respostas: Dictionary = profile()[TerritoryProfile.SITES]
	for vaga in SimLoop.builds.slots:
		var r: Dictionary = respostas.get(vaga.id, {})
		var razoes: Array = r.get(PlacementRules.REASONS, [])
		vaga.terrain_bar = razoes[0] if not razoes.is_empty() else &""


## Se o sitio de partida autora agua: e daqui que o Greybox poe o pesqueiro.
static func fits(dados: BuildingData, x: float) -> bool:
	var need := dados.requires_biome_feature
	var regras := rules()
	var fontes := sources(0.0, {need: true})
	var r := PlacementRules.evaluate(
		need, x, int(Band.Kind.SURFACE), fontes, reach(regras, need), minimum(regras, need)
	)
	return r[PlacementRules.ALLOWED]


static func _agua(fontes: Array, regras: TerritoryRules) -> void:
	var superficie := int(Band.Kind.SURFACE)
	for k in SimLoop.field.waters.size():
		var x := SimLoop.field.waters[k]
		var meia := regras.water_half_px
		fontes.append(
			PlacementRules.source(
				"home_water_%d" % k, AGUA, superficie, Vector2(x - meia, x + meia)
			)
		)
	_terras(fontes, regras.wild_water_half_px)


static func _terras(fontes: Array, meia: float) -> void:
	var w := SimLoop.field.wilds
	var largura := SimLoop.world_width
	var limites := w.limits(largura)
	var superficie := int(Band.Kind.SURFACE)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in w.count(lado):
			var r := w.at(lado, k)
			var id := "wild_%d_%d" % [lado, k]
			if r[WildSegments.TIPO] == AGUA:
				var x := w.subject_x(lado, k, largura)
				fontes.append(
					PlacementRules.source(id, AGUA, superficie, Vector2(x - meia, x + meia))
				)
			elif r[WildSegments.ASSUNTO] == MAR:
				var x0 := w.x_of(lado, k, largura)
				var mar := (
					Vector2(limites.y, x0 + w.width)
					if lado == WorldPlan.LESTE
					else Vector2(x0, limites.x)
				)
				fontes.append(PlacementRules.source(id, AGUA, superficie, mar))


## O porao de cada passagem, entre as muralhas a volta dela, e as cavernas das terras.
static func _rocha(fontes: Array, shift: float) -> void:
	var subsolo := int(Band.Kind.UNDERGROUND)
	var muros := PackedFloat32Array()
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths() and vaga.territory == 0:
			muros.append(vaga.x + shift)
	for k in SimLoop.passages.size():
		var tecto := UnderWatch.between_walls(SimLoop.passages[k], muros)
		var source := PlacementRules.source(UnderWatch.CELLAR_KEY % k, ROCHA, subsolo, tecto)
		source[PlacementRules.ACCESS] = Passages.open(SimLoop.passages, SimLoop.builds).has(
			SimLoop.passages[k]
		)
		fontes.append(source)
	var under := SimLoop.field.under
	for i in under.count():
		if under.kind_of(i) != UndergroundSites.CAVE or not under.usable(i):
			continue
		var span: Vector2 = (
			under.span(i) if under.generated(i) else under.sites[i][UndergroundSites.NEED]
		)
		fontes.append(PlacementRules.source(under.key_of(i), ROCHA, subsolo, span))
