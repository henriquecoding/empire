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
## script embutido: load() num caminho de save e execucao remota de codigo. As
## preferencias (§45) sao o outro ficheiro que o jogo le de user://, e a mesma
## porta: o ConfigFile desserializa Object(...) e Resource(...) (GB-13).
const G6_FILES := ["res://src/core/save_service.gd", "res://src/core/preferences.gd"]
const G6_FORBIDDEN := ["load(", "ResourceLoader", "ResourceSaver", "ConfigFile"]


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
		var por_fechar := 0
		for line in code_only(FileAccess.get_file_as_string(f)).split("\n"):
			n += 1
			# Uma declaracao `const` que nao cabe numa linha continua a ser uma
			# declaracao. Sem contar o que ela deixa por fechar, o portao
			# chumbava a unica saida que ele proprio manda usar — por o numero
			# num `const` — e obrigava a escreve-la numa linha so.
			if por_fechar > 0 or line.strip_edges().begins_with("const "):
				por_fechar = maxi(0, por_fechar + bracket_balance(line))
				continue
			for m in re.search_all(line):
				if not m.get_string() in G4_ALLOWED:
					out.append("G4 %s:%d: literal %s — vai para data/" % [f, n, m.get_string()])
	return out


## Quantos parenteses, chavetas e rectos ficam por fechar nesta linha. Negativo
## quando ela fecha mais do que abre. Le-se sobre `code_only`, e por isso um
## parentesis dentro de uma string ou de um comentario nao conta.
static func bracket_balance(linha: String) -> int:
	var n := 0
	for c in linha:
		if c in "([{":
			n += 1
		elif c in ")]}":
			n -= 1
	return n


## I6 — o save so passa pelo canal da ADR 0007. Verifica tres coisas: que o
## ficheiro existe (apaga-lo nao pode ser forma de calar o portao), que nao
## nomeia nenhuma forma de load, e que cada store_var/get_var desliga mesmo os
## objetos — `false` explicito, para que a regra se veja na linha.
static func check_g6() -> Array[String]:
	var out: Array[String] = []
	for ficheiro: String in G6_FILES:
		out.append_array(_g6_de(ficheiro))
	return out


static func _g6_de(ficheiro: String) -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(ficheiro):
		out.append("G6 %s: nao existe" % ficheiro)
		return out

	var n := 0
	for linha in strip_comments(FileAccess.get_file_as_string(ficheiro)).split("\n"):
		n += 1
		for token in G6_FORBIDDEN:
			if token in linha:
				out.append("G6 %s:%d: usa '%s' — ADR 0007" % [ficheiro, n, token])
		if "store_var(" in linha and not ", false)" in linha:
			out.append("G6 %s:%d: store_var sem `, false` — ADR 0007" % [ficheiro, n])
		if "get_var(" in linha and not "get_var(false)" in linha:
			out.append("G6 %s:%d: get_var sem `false` — ADR 0007" % [ficheiro, n])
	return out
