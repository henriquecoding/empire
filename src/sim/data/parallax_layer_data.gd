# src/sim/data/parallax_layer_data.gd — as seis camadas (§22, §59), por preset (§11).
# Gerado de data/source/parallax_layers.csv. Os deltas sao relativos ao plano de jogo.
class_name ParallaxLayerData
extends Resource

@export var id: StringName
@export var preset: StringName = &"open"  # open | closed
@export var layer: int = 0  # 1 ceu .. 6 primeiro plano
@export var node_name: StringName
@export var z_index: int = 0
@export var motion_scale: float = 0.0  # fracoes binarias exatas (§22)
@export var saturation_delta: float = 0.0
@export var value_delta: float = 0.0
@export var hue_shift_deg: float = 0.0
@export var min_detail_px: int = 0
@export var outline_px: int = 0
@export var colors_per_16px: Vector2i = Vector2i()
