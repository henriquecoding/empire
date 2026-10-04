class_name RealmOutskirts
extends RefCounted

## A banca do martelo fica dentro do primeiro recinto, com folga para a Fortaleza.
const MARTELO_X := -288.0
## O ultimo recinto protege o celeiro, a casa do herdeiro e os servicos de expedicao.
const MUROS_X := [-2080.0, 2080.0]


static func author() -> void:
	var martelos := Registry.entry(&"buildings", &"hammer_rack") as BuildingData
	SimLoop.builds.post(Greybox.slot_of(martelos, SimLoop.core_x + MARTELO_X))
	for x in MUROS_X:
		SimLoop.builds.post(WallSite.slot(SimLoop.core_x + x))
