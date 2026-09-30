# Fotografias e limites reais do menu, com o jogo e o renderer a correr.
extends Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	SimLoop.autosave_enabled = false
	add_child(load("res://scenes/game.tscn").instantiate())
	SimLoop.set_paused(true)
	var menu := get_child(0).get_node("Interface/Pausa") as PauseMenu
	if args.has("options"):
		menu.show_options()
	if args.has("game"):
		menu.show_options()
		menu._opcoes.show_tab(1)
	if args.has("reset"):
		menu._zero._abrir.pressed.emit()
	if args.has("defeat"):
		menu.open(true)
	TranslationServer.set_locale("pt_PT")
	if args.has("english"):
		TranslationServer.set_locale("en")
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := args[0]
	get_viewport().get_texture().get_image().save_png(path)
	var frame := menu._frame
	print(
		(
			"menu: page=%s physical=%s layout=%s scale=%s"
			% [
				menu._page,
				DisplayServer.window_get_size(),
				frame.size,
				frame.scale,
			]
		)
	)
	_validate(frame)
	get_tree().quit()


func _validate(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree():
			var control := child as Control
			if control is Button:
				print("button: %s rect=%s" % [control.text, control.get_global_rect()])
		_validate(child)
