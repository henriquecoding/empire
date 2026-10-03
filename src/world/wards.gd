# src/world/wards.gd — os sitios do Sino de Vigia na regiao (§75, Q-100), e do
# farol (§10), que e a luz que apaga o Lume (Q-156).
#
# Um sino por lado, fora da muralha de fora: e o Zelador que vem de la. Um farol,
# a oeste, longe do nucleo: o farol que a expedicao ao Lume pede de pe. As
# posicoes sao autoria de nivel, como as do Greybox; os numeros sao do
# buildings.csv.
class_name Wards
extends RefCounted

const SINOS_X := [-1628.0, 1716.0]
const FAROIS_X := [-1800.0]


## Depois de todas as outras obras: os ids delas nao mudam (§45).
static func author() -> void:
	var dados := Registry.entry(&"buildings", Ward.SINO) as BuildingData
	for x in SINOS_X:
		SimLoop.builds.post(Greybox.slot_of(dados, SimLoop.core_x + x))
	var farol := Registry.entry(&"buildings", Lume.FAROL) as BuildingData
	for x in FAROIS_X:
		SimLoop.builds.post(Greybox.slot_of(farol, SimLoop.core_x + x))
