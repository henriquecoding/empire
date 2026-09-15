# src/sim/data/chaos_modifier_data.gd — biomas caoticos como modificadores de rota (§17).
# Gerado de data/source/chaos_modifiers.csv. Aplicam-se a segmentos `chaotic` (§21).
class_name ChaosModifierData
extends Resource

@export var id: StringName
@export var display_key: String
@export var damage_mult: float = 1.0
@export var health_loss_per_day: float = 0.0
@export var mercenary_price_mult: float = 1.0
@export var debt_interest_mult: float = 1.0
@export var swaps_bands: bool = false
@export var no_light: bool = false
@export var only_class: StringName = &""  # quem se orienta sem luz
