# tools/lint_sim.gd — portoes G1, G2 e G4 sem abrir o gdUnit4 (§64, §65).
# Uso: godot --headless --path . -s tools/lint_sim.gd
# As regras vivem em tools/lint_rules.gd; o CI corre-as tambem dentro da suite.
extends SceneTree

const Rules := preload("res://tools/lint_rules.gd")


func _init() -> void:
	var problems: Array[String] = []
	problems.append_array(Rules.check_g1())
	problems.append_array(Rules.check_g2())
	problems.append_array(Rules.check_g4())
	for p in problems:
		printerr(p)
	print("lint_sim: %d problema(s) em G1, G2 e G4" % problems.size())
	quit(1 if problems.size() > 0 else 0)
