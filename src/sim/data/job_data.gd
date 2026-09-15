# src/sim/data/job_data.gd — os postos de trabalho do §20, §29 (prompt 4) e §52.
# Gerado de data/source/jobs.csv. Os postos publicam vagas; a urgencia por fase
# e o termo `urgencia(fase)` do score.
class_name JobData
extends Resource

@export var id: StringName
@export var display_key: String
@export var priority: float = 0.0
## Urgencia por fase: DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT.
@export var urgency_by_phase: PackedFloat32Array = PackedFloat32Array()
@export var band: Band.Kind = Band.Kind.SURFACE
@export var building_category: StringName = &""
