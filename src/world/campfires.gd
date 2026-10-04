# src/world/campfires.gd — os sitios de fogueira da regiao (§05, Q-029).
#
# "Fogueira = o campfire das rondas noturnas, edificio de 3 moedas com o
# abrandamento do barril" (Q-029, aprovada). Uma por lado, por dentro da muralha
# correspondente: e onde se compra o archote para sair para o escuro. As posicoes sao
# autoria de nivel, como as do Greybox; os numeros sao do buildings.csv.
class_name Campfires
extends RefCounted

const FOGUEIRA := &"campfire"
const FOGUEIRAS_X := [-1300.0, 1936.0]


## Depois das obras da superficie e do subsolo: os ids delas nao mudam (§45).
static func author() -> void:
	var dados := Registry.entry(&"buildings", FOGUEIRA) as BuildingData
	for x in FOGUEIRAS_X:
		SimLoop.builds.post(Greybox.slot_of(dados, SimLoop.core_x + x))
