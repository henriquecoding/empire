# src/world/frontier_view.gd — a camara so ve o mundo que ja foi gerado (o pedido do dono
# de 30/09/2026; ADR 0038).
#
# Como a distancia de visao do Minecraft: o que nao foi gerado nao se ve. A camara livre
# (§24) podia espreitar para la do que existe; aqui a regiao dela acompanha o que o
# WildSegments ja gerou, e a borda do mundo e o fim da regiao da camara.
class_name FrontierView
extends Node

var _visto := Vector2.INF


func _process(_delta: float) -> void:
	if SimLoop.field == null:
		return
	var mundo := SimLoop.field.wilds.extent(SimLoop.world_width)
	if mundo == _visto:
		return
	var camara := get_viewport().get_camera_2d() as CameraRig
	if camara == null:
		return
	_visto = mundo
	camara.set_region(mundo.x, mundo.y)
