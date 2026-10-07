# src/ui/atlas_rule.gd — as linhas de territorio como separador (ADR 0078).
#
# Tres tracos de comprimentos diferentes, o motivo que o Atlas do Imperio repete por baixo
# de um titulo. E decoracao: nao diz faixa nenhuma, e por isso nao tem cor de estado.
class_name AtlasRule
extends Control

var color := Atlas.INK_SOFT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = Atlas.RULE_HEIGHT


func _draw() -> void:
	Atlas.rule(self, Vector2.ZERO, size.x, color)
