# src/sim/data/secret_data.gd — os quatro tipos de segredo (§17).
# Gerado de data/source/secrets.csv. Os segredos sao o tutorial (§17, §25).
class_name SecretData
extends Resource

@export var id: StringName
@export var display_key: String
@export var band: Band.Kind = Band.Kind.UNDERGROUND
@export var location: StringName  # behind_passage, under_vegetation, fortress, chaotic_biome
@export var reward_seeds: int = 0
@export var reward: StringName = &""  # lore_fragment, teach_mechanic, journal, unlock
@export var teaches: StringName = &""  # mecanica ensinada (estatuas)
