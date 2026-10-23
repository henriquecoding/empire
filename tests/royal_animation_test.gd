extends GdUnitTestSuite

const ROOT := "res://art/export/royals/"
const CAST := [
	&"royal_king",
	&"royal_squire",
	&"royal_nia",
	&"royal_bard",
	&"royal_archer",
	&"royal_quiver",
	&"royal_shadow",
	&"royal_dancer"
]


func test_v15_delivery_is_used_by_the_live_renderer() -> void:
	var art := OriginalArt.new()
	for profile: StringName in CAST.slice(0, 6):
		assert_str(String(art.entry(profile).get("root", ""))).is_equal(ROOT)


func test_all_delivered_frames_and_native_timings_are_imported() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(ROOT + "manifest.json")
	)
	var total := 0
	for profile: StringName in CAST:
		var item: Dictionary = manifest.assets[String(profile)]
		var sheet := (load(ROOT + item.texture) as Texture2D).get_image()
		total += item.durations_ms.size()
		assert_int(int(item.size[0])).is_in([64, 80])
		for k in item.durations_ms.size():
			var origin: Array = item.frame_origins[k]
			var rect := Rect2i(origin[0], origin[1], item.size[0], item.size[1])
			assert_bool(Rect2i(Vector2i.ZERO, sheet.get_size()).encloses(rect)).is_true()
			assert_bool(sheet.get_region(rect).is_invisible()).is_false()
			assert_int(int(item.durations_ms[k])).is_greater(0)
	assert_int(total).is_equal(822)


func test_action_boundaries_preserve_variable_durations_and_last_pose() -> void:
	var art := OriginalArt.new()
	var item := art.entry(&"royal_king")
	assert_float(art.action_seconds(&"royal_king", &"attack")).is_equal_approx(1.44, 0.001)
	var first := int(item.tags.hit.from_frame)
	assert_int(art.frame_at(&"royal_king", 0.0, &"hit", false)).is_equal(first)
	assert_int(art.frame_at(&"royal_king", 10.0, &"hit", false)).is_equal(
		int(item.tags.hit.to_frame)
	)


func test_left_direction_uses_delivered_frame_and_its_own_foot_pivot() -> void:
	var art := OriginalArt.new()
	for profile: StringName in CAST:
		var item := art.entry(profile)
		var first := int(item.tags.idle.from_frame)
		var right := RoyalArt.sample(profile, first, 1.0)
		var left := RoyalArt.sample(profile, first, -1.0)
		assert_int(left.frame).is_equal(int(item.mirrors[str(first)]))
		assert_float(left.target.position.x + right.target.position.x).is_equal(
			-float(item.size[0] - 1)
		)
		assert_float(left.target.position.y).is_equal(right.target.position.y)


func test_garden_has_stable_independent_roots_and_its_own_wither_stages() -> void:
	var garden := RoyalGarden.new()
	garden.begin(true)
	assert_int(garden.plants.size()).is_equal(28)
	var starts := {}
	for plant: Dictionary in garden.plants:
		starts[plant.startMs] = true
		assert_int(RoyalGarden.stage(plant, (float(plant.startMs) - 1.0) / 1000.0)).is_equal(-1)
		assert_int(RoyalGarden.stage(plant, float(plant.startMs) / 1000.0)).is_equal(0)
		assert_int(RoyalGarden.stage(plant, float(plant.witherMs) / 1000.0)).is_equal(8)
		assert_int(RoyalGarden.stage(plant, 12.0)).is_equal(-1)
		var texture := load(ROOT + "plants/" + String(plant.variant) + ".png") as Texture2D
		assert_vector(texture.get_size()).is_equal(Vector2(192, 56))
	assert_int(starts.size()).is_equal(28)
	assert_str(String(RoyalGarden.body(0.0).action)).is_equal("sit")
	assert_str(String(RoyalGarden.body(4.0).action)).is_equal("heal")
	assert_str(String(RoyalGarden.body(8.3).action)).is_equal("stand")


func test_hit_and_revival_finish_the_delivered_clip_before_returning_to_idle() -> void:
	var units := UnitSystem.new()
	var state := GameState.new()
	var id := units.spawn(state, Registry.entry(&"units", &"monarch") as UnitData, 1, 0.0)
	var i := units.index_of(id)
	var motion := RoyalMotion.new()
	var art := OriginalArt.new()
	var item := art.entry(&"royal_king")
	var clock := CombatFx.clock
	CombatFx.clock = 10.0
	motion._damaged(id, 1, -1)
	assert_int(motion.frame(units, i, &"royal_king", false, 0)).is_equal(
		int(item.tags.hit.from_frame)
	)
	CombatFx.clock = 10.3
	assert_int(motion.frame(units, i, &"royal_king", false, 0)).is_greater(
		int(item.tags.hit.from_frame)
	)
	CombatFx.clock = 11.0
	assert_int(motion.frame(units, i, &"royal_king", false, 0)).is_equal(0)
	motion._revived(id)
	assert_int(motion.frame(units, i, &"royal_king", false, 0)).is_equal(
		int(item.tags.rise.from_frame)
	)
	CombatFx.clock = clock


func test_gallery_button_opens_a_visible_stage_and_can_close_back_to_selection() -> void:
	RngService.configure(20261019)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 800)
	auto_free(viewport)
	add_child(viewport)
	var menu := ClassSelection.new()
	viewport.add_child(menu)
	await get_tree().process_frame
	var button: Button
	for candidate: Node in menu.find_children("*", "Button", true, false):
		if (candidate as Button).text == tr(&"ANIM_GALLERY_TITLE"):
			button = candidate as Button
	assert_object(button).is_not_null()
	button.pressed.emit()
	await get_tree().process_frame
	var gallery := menu.get_child(menu.get_child_count() - 1) as RoyalGallery
	assert_object(gallery).is_not_null()
	assert_bool(RoyalGallery.active).is_true()
	assert_float(gallery.size.x).is_greater(200.0)
	assert_float(gallery.size.y).is_greater(200.0)
	for candidate: Node in gallery.find_children("*", "Button", true, false):
		var action_button := candidate as Button
		var font := action_button.get_theme_font("font")
		var font_size := action_button.get_theme_font_size("font_size")
		var text_width := (
			font.get_string_size(action_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		)
		assert_float(action_button.size.x).is_greater_equal(text_width)
	gallery._select_character(6)
	assert_str(String(gallery._stage.profile)).is_equal("royal_shadow")
	assert_str(String(gallery._stage.action)).is_equal("heal_sequence")
	gallery.close()
	await get_tree().process_frame
	assert_bool(RoyalGallery.active).is_false()


func test_delivered_impact_markers_match_the_simulated_attack_release() -> void:
	var previous: Dictionary = CombatFx._ataques.duplicate(true)
	var art := OriginalArt.new()
	var who := -900
	for profile: StringName in [&"royal_king", &"royal_nia", &"royal_archer"]:
		var item := art.entry(profile)
		var marker := int(item.events.attack[0].frame)
		CombatFx.attacked(
			who, StrikePose.Style.RANGED if profile == &"royal_archer" else StrikePose.Style.MELEE
		)
		var frame := CombatFx.attack_frame(art, profile, who, INF)
		assert_int(frame).is_equal(int(item.tags.attack.from_frame) + marker)
		who -= 1
	CombatFx._ataques = previous
