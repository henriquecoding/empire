class_name SpriteLighting
extends RefCounted

const SHADER := preload("res://shaders/sprite_lighting.gdshader")
const MAPS := "res://src/actors/lighting_maps/"

static var _surfaces: Dictionary = {}


static func material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	return result


## These lights use world coordinates. Each band owns its shader parameters.
static func sync(target: ShaderMaterial, light: Lighting, canvas: CanvasItem) -> void:
	if light.dark <= 0.0 or light.glows.is_empty():
		target.set_shader_parameter(&"luzes", 0)
		return
	var values := SceneryLight.uniforms(light, Transform2D.IDENTITY, PresentationBounds.of(canvas))
	for name: StringName in values:
		target.set_shader_parameter(name, values[name])
	target.set_shader_parameter(
		&"ambiente", Vector3(light.ambient.r, light.ambient.g, light.ambient.b)
	)
	target.set_shader_parameter(&"luz_celula", float(SimFactory.rot_profile().lantern_dither_px))


## CanvasTexture selects the aligned surface atlas for each batched draw.
static func with_surface(diffuse: Texture2D, filename: String) -> Texture2D:
	if not _surfaces.has(filename):
		var path := MAPS + filename.get_file().get_basename() + "_surface.png"
		if not ResourceLoader.exists(path):
			return diffuse
		var data := load(path) as Texture2D
		if data == null or data.get_size() != diffuse.get_size():
			return diffuse
		var result := CanvasTexture.new()
		result.diffuse_texture = diffuse
		result.normal_texture = data
		result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_surfaces[filename] = result
	return _surfaces[filename]
