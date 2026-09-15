# src/sim/data/journal_data.gd — os 12 diarios de campanha (§17).
# Encontrados por ordem de conquista, nao de escrita. Texto em data/i18n/.
class_name JournalData
extends Resource

@export var id: StringName
@export var act: int = 0
@export var order: int = 0
@export var title_key: String
@export var body_key: String

@export_group("v6 · onde esta e o que e (§79)")
## &"ruin", &"fortress" ou &"chapter" — onde o fragmento e encontrado.
@export var where_kind: StringName = &""
## O id do povo (fortaleza) ou do capitulo (§77).
@export var where_id: StringName = &""
## O objeto fisico: uma lista de manutencao, um manifesto, uma escala de turnos.
@export var object_key: String = ""
## O que deixa perceber. Nunca explica A Podridao (§17, regra de ouro).
@export var reveals_key: String = ""
