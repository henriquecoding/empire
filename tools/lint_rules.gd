# tools/lint_rules.gd — as regras que os portoes G1, G2 e G4 aplicam (§40, §64, §70).
# Uma so implementacao: usada por tools/lint_sim.gd (linha de comandos) e por
# tests/architecture_test.gd (suite gdUnit4, no CI).
extends RefCounted

## I1 — src/sim/ e logica pura (§40).
const G1_FORBIDDEN := ["extends Node", "get_tree()", "Engine.", ".tscn", "Input."]
## §70 — as setas so descem: a simulacao nao conhece nada acima dela.
const UPWARD := [
	"res://src/core",
	"res://src/world",
	"res://src/actors",
	"res://src/ui",
	"res://src/net",
	"EventBus",
	"RngService",
	"Registry",
	"SaveService",
	"ClockService",
	"CameraRig",
	"BandLayers",
	"ParallaxStack",
	"UnitView",
]
## I2 — aleatoriedade so pelo RngService (§42).
const G2_PATTERN := "\\b(randi|randf|randomize|randi_range|randf_range)\\s*\\("
const G2_ALLOWED := "res://src/core/rng_service.gd"
## I4 — literais permitidos fora das constantes (§47).
const G4_ALLOWED := ["0", "1", "-1", "0.0", "1.0", "2"]
## Os Resource de dados tem valores por omissao que o .tres gerado sobrepoe sempre;
## band.gd e o ficheiro das constantes de plano (§47). Ver docs/adr/0008.
const G4_SKIP := ["res://src/sim/data/", "res://src/sim/band.gd"]
## I6 — o save nunca usa load() (ADR 0007). Um .tres arbitrario pode trazer
## script embutido: load() num caminho de save e execucao remota de codigo.
const G6_FILE := "res://src/core/save_service.gd"
const G6_FORBIDDEN := ["load(", "ResourceLoader", "ResourceSaver"]


static func gd_files(root: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(root.path_join(f))
	for d in dir.get_directories():
		out.append_array(gd_files(root.path_join(d)))
	return out


## Remove comentarios (mantem strings: e nelas que estao os caminhos res://).
static func strip_comments(src: String) -> String:
	var lines: PackedStringArray = []
	for line in src.split("\n"):
		var cut := line.find("#")
		lines.append(line if cut < 0 else line.substr(0, cut))
	return "\n".join(lines)


## Remove comentarios e o conteudo das strings (para procurar codigo e numeros).
static func code_only(src: String) -> String:
	var strip := RegEx.create_from_string("\"[^\"]*\"|'[^']*'")
	return strip.sub(strip_comments(src), '""', true)


static func check_g1(root: String = "res://src/sim") -> Array[String]:
	var out: Array[String] = []
	for f in gd_files(root):
		var code := strip_comments(FileAccess.get_file_as_string(f))
		for token in G1_FORBIDDEN + UPWARD:
			if token in code:
				out.append("G1 %s: usa '%s'" % [f, token])
	return out


static func check_g2(root: String = "res://src") -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string(G2_PATTERN)
	for f in gd_files(root):
		if f == G2_ALLOWED:
			continue
		if re.search(code_only(FileAccess.get_file_as_string(f))) != null:
			out.append("G2 %s: aleatoriedade fora do RngService" % f)
	return out


static func check_g4(root: String = "res://src") -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("(?<![\\w.])-?\\d+(\\.\\d+)?(?![\\w.])")
	for f in gd_files(root):
		if G4_SKIP.any(func(p: String) -> bool: return f.begins_with(p)):
			continue
		var n := 0
		for line in code_only(FileAccess.get_file_as_string(f)).split("\n"):
			n += 1
			if line.strip_edges().begins_with("const "):
				continue
			for m in re.search_all(line):
				if not m.get_string() in G4_ALLOWED:
					out.append("G4 %s:%d: literal %s — vai para data/" % [f, n, m.get_string()])
	return out


## I6 — o save so passa pelo canal da ADR 0007. Verifica tres coisas: que o
## ficheiro existe (apaga-lo nao pode ser forma de calar o portao), que nao
## nomeia nenhuma forma de load, e que cada store_var/get_var desliga mesmo os
## objetos — `false` explicito, para que a regra se veja na linha.
static func check_g6() -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(G6_FILE):
		out.append("G6 %s: nao existe" % G6_FILE)
		return out

	var n := 0
	for linha in strip_comments(FileAccess.get_file_as_string(G6_FILE)).split("\n"):
		n += 1
		for token in G6_FORBIDDEN:
			if token in linha:
				out.append("G6 %s:%d: usa '%s' — ADR 0007" % [G6_FILE, n, token])
		if "store_var(" in linha and not ", false)" in linha:
			out.append("G6 %s:%d: store_var sem `, false` — ADR 0007" % [G6_FILE, n])
		if "get_var(" in linha and not "get_var(false)" in linha:
			out.append("G6 %s:%d: get_var sem `false` — ADR 0007" % [G6_FILE, n])
	return out
