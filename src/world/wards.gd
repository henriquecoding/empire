# src/world/wards.gd — os sitios do Sino de Vigia na regiao (§75, Q-100).
#
# Um por lado, fora da muralha de fora: e o Zelador que vem de la. As posicoes sao
# autoria de nivel, como as do Greybox; os numeros sao do buildings.csv.
class_name Wards
extends RefCounted

const SINOS_X := [-1560.0, 1560.0]


## Depois de todas as outras obras: os ids delas nao mudam (§45).
static func author() -> void:
	var dados := Registry.entry(&"buildings", Ward.SINO) as BuildingData
	for x in SINOS_X:
		SimLoop.builds.post(Greybox.slot_of(dados, SimLoop.core_x + x))
