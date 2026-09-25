# tools/greybox_biomas.gd — fotografa a greybox de cada bioma (GB-02).
#
#     xvfb-run -a godot --path . --resolution 1280x720 tools/greybox_biomas.tscn
#
# Uma imagem por bioma de biomes.csv, em build/greybox/<bioma>.png, a 1280x720:
# e a imagem que a rampa de densidade do GB-03 mede, e a que se compara quando
# um bioma for pintado. Fora do jogo, nunca exportado (§70).
extends Node

const SAIDA := "build/greybox"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + SAIDA))
	var vista := BiomeGreybox.new()
	add_child(vista)
	var ids := Array(Registry.ids(&"biomes")).map(func(i: StringName) -> String: return String(i))
	ids.sort()
	for id: String in ids:
		vista.biome = StringName(id)
		vista.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var png := "%s/%s.png" % [SAIDA, id]
		var erro := get_viewport().get_texture().get_image().save_png(png)
		print("greybox_biomas: %s (erro %d)" % [png, erro])
	get_tree().quit()
