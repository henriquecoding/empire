extends Node


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(32, 16)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.45, 0.60, 0.30, 0.5))
	var texture := ImageTexture.create_from_image(image)
	for i in 2:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(8 + i * 16, 8)
		sprite.modulate = Color(0.7, 0.8, 0.9, 0.8)
		if i == 1:
			var material := ShaderMaterial.new()
			material.shader = load("res://shaders/palette_lut.gdshader")
			material.set_shader_parameter("mix", 0.0)
			sprite.material = material
		viewport.add_child(sprite)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var rendered := viewport.get_texture().get_image()
	var plain := rendered.get_pixel(8, 8)
	var graded := rendered.get_pixel(24, 8)
	var error := maxf(absf(plain.r - graded.r), absf(plain.g - graded.g))
	error = maxf(error, maxf(absf(plain.b - graded.b), absf(plain.a - graded.a)))
	print("shader identity: plain=%s graded=%s max_error=%f" % [plain, graded, error])
	get_tree().quit(0 if error <= 1.0 / 255.0 else 1)
