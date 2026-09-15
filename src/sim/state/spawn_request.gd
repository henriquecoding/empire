# src/sim/state/spawn_request.gd — o pedido que a Podridao devolve (§51).
#
# "Devolve pedidos; nao instancia nada" (F1-08). A simulacao nao tem nos para
# instanciar e nao conhece o catalogo de eventos: diz o que quer e quem a chama
# e que o faz acontecer. E a mesma convencao do tick_decisions() das tropas.
class_name SpawnRequest
extends RefCounted

var creature_id: StringName = &""
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE


func _init(id: StringName, onde: float, faixa: Band.Kind) -> void:
	creature_id = id
	x = onde
	band = faixa
