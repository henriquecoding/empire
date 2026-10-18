# src/world/owner_sites.gd — onde ficam o porto, o lago e o rio do dono (ADR 0085, Q-259).
#
# Cada sitio pintado fica na agua que o territorio ja conta: a de casa e a de cada segmento
# de agua das terras geradas. A vista e a do bioma dessa agua (OwnerScenery.sites); o meio
# da agua pintada fica no x da fonte. Onde ha sitio, a agua funcional ja se ve na pintura e o
# ResourceWater nao a desenha por cima.
class_name OwnerSites
extends RefCounted


## Os sitios do mundo de agora, para SceneryMap.with_sites.
static func water(casa: StringName) -> Array:
	var vistas := OwnerScenery.sites()
	var saida := []
	if SimLoop.field == null or vistas.is_empty():
		return saida
	for x: float in SimLoop.field.waters:
		_um(saida, vistas, casa, x)
	var terras := SimLoop.field.wilds
	if terras == null:
		return saida
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var registo := terras.at(lado, k)
			if registo[WildSegments.TIPO] == TerritoryWatch.AGUA:
				var x := terras.subject_x(lado, k, SimLoop.world_width)
				_um(saida, vistas, SceneryMap.biome_of(registo), x)
	return saida


## Se a agua que comeca em `x` ja esta pintada por um sitio (o quadro dele cobre-a toda).
static func covered(x: float) -> bool:
	var t := SceneryArt.map().stretch_at(x)
	return t.has(SceneryMap.ANCORA) and x >= t[SceneryMap.DE] and x < t[SceneryMap.ATE]


static func _um(saida: Array, vistas: Dictionary, bioma: StringName, x: float) -> void:
	if not vistas.has(bioma):
		return
	var v: Dictionary = vistas[bioma]
	(
		saida
		. append(
			{
				SceneryMap.X: x,
				SceneryMap.CENA: v[OwnerScenery.VISTA],
				SceneryMap.MEIA: v[OwnerScenery.MEIA],
				SceneryMap.ANCORA: v[OwnerScenery.ANCORA],
			}
		)
	)
