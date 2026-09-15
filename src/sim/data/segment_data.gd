# src/sim/data/segment_data.gd — §21, §44, §54. Gerado de data/source/segments.csv.
# Uma linha por cena autorada. Linhas do mesmo `kind` repetem peso e regras —
# o teste de dados verifica que coincidem.
class_name SegmentData
extends Resource

@export var id: StringName
## start_base, opening, empty, forest, water, rock, ruin, mercenary_camp,
## fortress, chaotic, threshold, edge
@export var kind: StringName
@export var people: StringName
@export var weight: int = 0  # §21; 0 = colocado por regra, nunca sorteado
@export var scene: String
@export var width_px: int = 0
@export var build_slots: int = 0  # autorados na cena (§55); aqui so a contagem
@export var cavity_slots: int = 0  # 0-2 (§21)
@export var passages: int = 0  # 0-1 (§21)
@export var resource: StringName = &""
@export var rules: Array[StringName] = []  # restricoes de adjacencia (§21)
@export var min_per_region: int = 0
@export var max_per_region: int = 0
@export var min_region_index: int = 0  # caotico: so a partir da 2.a regiao
@export var subject: StringName = &""  # o assunto do segmento (§21, regra 2)
@export var fixed: bool = false  # cena fixa (abertura, §25)
