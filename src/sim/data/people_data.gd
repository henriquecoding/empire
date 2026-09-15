# src/sim/data/people_data.gd — §04, §22, §44. Gerado de data/source/peoples.csv.
# "Se um povo precisar de codigo proprio, o sistema esta mal desenhado." (§04)
class_name PeopleData
extends Resource

@export var id: StringName
@export var display_key: String
@export var terrain: StringName
@export var biome: StringName

@export_group("Arquitetura")
@export var architecture_source: String  # fonte arquitectonica real (§22)
@export var roof_silhouette: String  # remate do telhado (§22)
@export var landmark: StringName  # o marco da regiao (§21)
@export var segment_kit: Array[StringName] = []  # SegmentData ids, 5-8 (§04)
@export var palette_ramp: StringName
@export var has_walls: bool = true
@export var wall_material: StringName

@export_group("Jogo")
@export var economy_strength: StringName
@export var economy_modifiers: Dictionary = {}
@export var defense_trait: StringName
@export var unique_unit: StringName
@export var playable_class: StringName

@export_group("Inicio")
@export var starting_units: Array[StringName] = []
@export var starting_buildings: Array[StringName] = []

@export_group("v6 · a cancao e o marco (§78, §81)")
## A textura da cancao do povo: vozes e instrumentos (§81).
@export var song_texture: String = ""
## Como soa durante a Colheita — mais alto do que seria natural, em menor (§78).
@export var colheita_song: String = ""
## Ao ficar com o povo, o marco dele cria raiz: vira Amargueiro e nao se corta.
@export var landmark_roots: bool = false
