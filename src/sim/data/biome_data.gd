# src/sim/data/biome_data.gd — §11, §21, §44. Gerado de data/source/biomes.csv.
class_name BiomeData
extends Resource

@export var id: StringName
@export var display_key: String
@export var people: StringName
@export var creature_table: Array[StringName] = []  # CreatureData ids
@export var resources: Array[StringName] = []  # water, forest, rock, fertile...
@export var atmosphere_preset: StringName = &"open"  # open | closed (§11)
@export var parallax_preset: StringName = &"open"  # ParallaxLayerData.preset
@export var region_screens: Vector2i = Vector2i()  # §21
@export var music_profile: StringName = &""
@export var wildlife: Array[StringName] = []  # WildlifeData ids
## Se a regiao deste bioma entra na campanha. Os dois povos do pedido do dono (o
## gelo e o pantano, Q-010 e Q-013) existem nos dados e ficam fora ate a Q-152.
@export var in_campaign: bool = true
## A borda do mundo do lado cujo ultimo povo e deste bioma (§21 Bordo; Q-173):
## cliff, sea, gorge ou wall — o `subject` de um segmento `edge` do segments.csv.
@export var edge_subject: StringName = &"cliff"
