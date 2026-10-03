# src/world/stables.gd — o sitio do estabulo na regiao (§12; Q-169, o dono a 30/09/2026).
#
# O cavalo de tracao compra-se no estabulo (mounts.csv, `obtain_ref`). Fica a leste, alem
# do sino, no vao entre o acampamento e a bifurcacao — o unico da superficie com a
# largura de uma casa. A posicao e autoria de nivel, como as do Greybox; os numeros sao do
# buildings.csv.
class_name Stables
extends RefCounted

const ESTABULO := &"mount_stable"
const ESTABULOS_X := [1820.0]


## Depois da banca do arco: os ids das outras obras nao mudam (§45), e um save de antes
## do estabulo abre com ele por construir.
static func author() -> void:
	var dados := Registry.entry(&"buildings", ESTABULO) as BuildingData
	for x in ESTABULOS_X:
		SimLoop.builds.post(Greybox.slot_of(dados, SimLoop.core_x + x))
