# src/world/bow_racks.gd — o sitio da banca do arco na regiao (Q-165; relatorio
# Kingdom de 29/09, K1).
#
# A regiao tinha tres arqueiros para sempre. No Kingdom o arco custa 2 e qualquer
# aldeao o apanha; aqui a banca e uma casa de oficio (TrainingSystem) que forma
# arqueiros sem dia de treino. Fica a leste, ao pe da torre de arqueiros, no unico
# vao da superficie perto do nucleo — entre a torre (680) e o galinheiro (820). A
# posicao e autoria de nivel, como as do Greybox; os numeros sao do buildings.csv.
class_name BowRacks
extends RefCounted

const BANCA := &"bow_rack"
const BANCAS_X := [742.0]


## Depois de todas as outras obras, sinos incluidos: os ids delas nao mudam (§45), e
## um save de antes da banca abre com ela por construir.
static func author() -> void:
	var dados := Registry.entry(&"buildings", BANCA) as BuildingData
	for x in BANCAS_X:
		SimLoop.builds.post(Greybox.slot_of(dados, SimLoop.core_x + x))
