# src/sim/data/storage_data.gd — Q-153. Gerado de data/source/storages.csv.
# O armazenamento de um personagem jogavel (§08): o que leva, quanto de cada, e
# onde o traz no corpo. A camada `Equipments` dos teus ficheiros e o desenho dele.
class_name StorageData
extends Resource

@export var id: StringName
@export var display_key: String
## Item -> quantos cabem. As moedas nao entram: vao no saco do corpo
## (UnitData.coin_capacity, §02), que toda a gente tem, e nao so quem se joga.
@export var holds: Dictionary = {}
## Onde se traz no corpo: &"hip" | &"back" | &"side" | &"saddle". So apresentacao.
@export var worn: StringName = &"hip"
