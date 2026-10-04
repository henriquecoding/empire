class_name RealmOutskirts
extends RefCounted

## Autoria do nivel: a banca fundadora, dentro do primeiro recinto (ADR 0063).
const MARTELO_X := -552.0
## O ultimo recinto protege o celeiro, a casa do herdeiro e os servicos de expedicao.
const MUROS_X := [-1960.0, 2040.0]


static func author() -> void:
	var martelos := Registry.entry(&"buildings", &"hammer_rack") as BuildingData
	SimLoop.builds.post(Greybox.slot_of(martelos, SimLoop.core_x + MARTELO_X))
	for x in MUROS_X:
		SimLoop.builds.post(WallSite.slot(SimLoop.core_x + x))
