extends SceneTree


func _initialize() -> void:
	call_deferred("_inspect")


func _inspect() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not ProjectSettings.load_resource_pack(args[0]):
		push_error("Expected an exported PCK and an output report path")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://art/export/scenery_native/manifest.json")
	)
	if not parsed is Dictionary:
		push_error("The production scenery manifest is absent from the exported game")
		quit(1)
		return
	var errors: Array[String] = []
	var families := 0
	var textures := 0
	var omitted := 0
	for id: String in parsed.get("families", {}):
		var family: Dictionary = parsed.families[id]
		var campaign: Dictionary = family.get("campaign_layers", {})
		families += int(not campaign.is_empty())
		# Since ADR 0085 the campaign draws the owner's compositions: these stay in the project.
		for layer: String in campaign:
			if ResourceLoader.exists(String(campaign[layer].file)):
				errors.append("Replaced campaign texture shipped: " + String(campaign[layer].file))
			omitted += 1
		for entry: Dictionary in family.layers.values():
			if ResourceLoader.exists(String(entry.file)):
				errors.append("Review texture shipped: " + String(entry.file))
			omitted += 1
		if ResourceLoader.exists("res://art/export/scenery_native/" + id + "/modules_64.tres"):
			errors.append("Editor module atlas shipped: " + id)
	var owner: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://art/export/scenery_owner/manifest.json")
	)
	if not owner is Dictionary:
		errors.append("The owner's scenery manifest is absent from the exported game")
		owner = {}
	var kingdoms: int = owner.get("kingdoms", {}).size()
	for biome: String in owner.get("kingdoms", {}):
		var replaced := "res://art/export/scenery/" + biome + "/sky.png"
		if ResourceLoader.exists(replaced):
			errors.append("Replaced kingdom texture shipped: " + replaced)
		omitted += 1
	for view: String in owner.get("views", {}):
		for entry: Dictionary in owner.views[view].layers.values():
			if not ResourceLoader.exists(String(entry.file)):
				errors.append("Missing runtime texture: " + String(entry.file))
			textures += 1
	if families != 8 or kingdoms != 8 or textures == 0:
		errors.append("The packaged campaign does not cover all biomes")
	var pack := FileAccess.open(args[0], FileAccess.READ)
	var report := {
		"pack": args[0].get_file(),
		"bytes": pack.get_length(),
		"engine": Engine.get_version_info().string,
		"campaign_biomes": kingdoms,
		"runtime_textures": textures,
		"review_textures_excluded": omitted,
		"errors": errors,
		"passed": errors.is_empty(),
	}
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)
