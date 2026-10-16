class_name NativeSceneryStage
extends Node2D

const PLANES := {"sky": 0.03125, "clouds": 0.07, "far": 0.125, "mid": 0.25, "near": 0.5}
const VARIANT_SHADER := preload("res://shaders/native_scenery_variant.gdshader")
@export var view_id := "enramados_base"
@export var constructed := true
@export var show_workers := true

var family_id := ""
var functional: Node2D
var structures: Node2D
var workers: Node2D
var _layers: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var variant := NativeSceneryCatalog.variant(view_id)
	family_id = String(variant.get("family", "enramados"))
	var data := NativeSceneryCatalog.family(family_id)
	var recipe: Dictionary = variant.get("recipe", {})
	var depth := -50
	for layer: String in PLANES:
		var plane := Parallax2D.new()
		plane.name = layer.capitalize()
		plane.z_index = depth
		depth += 10
		plane.scroll_scale = Vector2(float(PLANES[layer]), 1.0)
		add_child(plane)
		_add_layer(plane, layer, data, recipe)
	_add_layer(self, "water_back", data, recipe)
	var world := Node2D.new()
	world.name = "World"
	add_child(world)
	functional = _group(world, "Functional")
	structures = _group(world, "Structures")
	workers = _group(world, "Workers")
	for layer in ["water", "under", "terrain", "crossings", "foreground"]:
		_add_layer(functional, layer, data, recipe)
	for layer in ["structures", "props"]:
		_add_layer(structures, layer, data, recipe)
	_floors(data)
	_ladders(data)
	_workers(data)
	set_constructed(constructed)


func _group(parent: Node, label: String) -> Node2D:
	var child := Node2D.new()
	child.name = label
	parent.add_child(child)
	return child


func _add_layer(parent: Node, layer: String, data: Dictionary, recipe: Dictionary) -> void:
	var entry: Dictionary = data.layers.get(layer, {})
	if entry.is_empty():
		return
	var sprite := Sprite2D.new()
	sprite.name = layer.capitalize()
	if layer == "water_back":
		sprite.z_index = -15
	sprite.centered = false
	sprite.texture = load(String(entry.file)) as Texture2D
	sprite.position = Vector2(float(entry.rect[0]), float(entry.rect[1]))
	sprite.scale = Vector2(float(entry.scale[0]), float(entry.scale[1]))
	sprite.material = _material(recipe, layer)
	if layer == "water":
		sprite.position.y += float(recipe.get("water_offset_y", 0))
	parent.add_child(sprite)
	_layers[layer] = sprite


func _material(recipe: Dictionary, layer: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = VARIANT_SHADER
	material.set_shader_parameter("tint", Color(String(recipe.get("tint", "#ffffff"))))
	var plants := layer in ["near", "mid", "foreground"]
	material.set_shader_parameter("autumn", plants and bool(recipe.get("autumn", false)))
	material.set_shader_parameter("frost", plants and bool(recipe.get("frost", false)))
	material.set_shader_parameter("aurora", layer == "sky" and bool(recipe.get("aurora", false)))
	material.set_shader_parameter(
		"warm_lights", layer in ["structures", "props"] and bool(recipe.get("warm_lights", false))
	)
	return material


func _floors(data: Dictionary) -> void:
	_floor(0.0, 1280.0, WorldPalette.ground_of(Band.Kind.SURFACE), "SurfaceFloor")
	for index in data.lower_spans.size():
		var span: Array = data.lower_spans[index]
		_floor(
			float(span[0]),
			float(span[1]),
			WorldPalette.ground_of(Band.Kind.UNDERGROUND),
			"LowerFloor%d" % index
		)


func _floor(left: float, right: float, y: float, label: String) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.position = Vector2((left + right) * 0.5, y + 2.0)
	body.collision_layer = Band.L_TERRAIN
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, 4.0)
	shape.shape = rect
	body.add_child(shape)
	functional.add_child(body)


func _ladders(data: Dictionary) -> void:
	for mouth: float in data.passages:
		var sprite := Sprite2D.new()
		sprite.texture = load(String(data.ladder)) as Texture2D
		sprite.centered = false
		sprite.position = Vector2(mouth - 24.0, 517.0)
		sprite.scale = Vector2(
			48.0 / sprite.texture.get_width(), 102.0 / sprite.texture.get_height()
		)
		functional.add_child(sprite)


func _workers(data: Dictionary) -> void:
	for span: Array in data.lower_spans:
		var actor := NativeSceneryActor.new()
		actor.position = Vector2(
			float(span[0]) + 80.0, WorldPalette.ground_of(Band.Kind.UNDERGROUND)
		)
		workers.add_child(actor)


func set_constructed(value: bool) -> void:
	constructed = value
	if structures != null:
		structures.visible = value
	if workers != null:
		workers.visible = value and show_workers


func layer_node(layer: String) -> Sprite2D:
	return _layers.get(layer) as Sprite2D
