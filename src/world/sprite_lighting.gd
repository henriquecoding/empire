class_name SpriteLighting
extends RefCounted

static var _material: ShaderMaterial


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/sprite_lighting.gdshader")
	return _material
