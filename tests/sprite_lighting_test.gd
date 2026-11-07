extends GdUnitTestSuite

const UNMAPPED := preload("res://art/export/_placeholder/contact_shadow_18.png")


func test_royal_atlases_use_nearest_and_share_the_albedo_grid() -> void:
	for profile: StringName in RoyalArt.CAST:
		var item := RoyalArt.entry(profile)
		var diffuse := load(RoyalArt.ROOT + String(item.texture)) as Texture2D
		var mapped := SpriteLighting.with_surface(diffuse, String(item.texture)) as CanvasTexture
		assert_object(mapped).is_not_null()
		assert_object(mapped.diffuse_texture).is_same(diffuse)
		assert_vector(mapped.normal_texture.get_size()).is_equal(diffuse.get_size())
		assert_int(mapped.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_object(SpriteLighting.with_surface(diffuse, String(item.texture))).is_same(mapped)


func test_assets_without_maps_keep_the_original_texture() -> void:
	assert_object(SpriteLighting.with_surface(UNMAPPED, "missing.png")).is_same(UNMAPPED)


func test_sprite_materials_keep_lights_separate_between_bands() -> void:
	var surface := SpriteLighting.material()
	var underground := SpriteLighting.material()
	var light := Lighting.new()
	var view := auto_free(Node2D.new()) as Node2D
	light.glows = [
		Glow.new(
			Vector2(32.0, 20.0),
			0,
			96.0,
			0.5,
			PackedColorArray([Color.BROWN, Color.ORANGE, Color.WHITE]),
			Flicker.Kind.FIRE
		)
	]
	light.dark = 1.0
	SpriteLighting.sync(surface, light, view)
	assert_int(surface.get_shader_parameter(&"luzes")).is_equal(1)
	SpriteLighting.sync(underground, Lighting.new(), view)
	assert_int(underground.get_shader_parameter(&"luzes")).is_equal(0)
	assert_int(surface.get_shader_parameter(&"luzes")).is_equal(1)
