# tools/csv_to_tres.gd — gera data/**/*.tres a partir de data/source/*.csv (§41, §44).
#
# Uso:
#   godot --headless --path . -s tools/csv_to_tres.gd            # gera e poda
#   godot --headless --path . -s tools/csv_to_tres.gd -- --check # so compara (CI)
#
# O registo das tabelas e data/source/_tables.csv. Colunas que comecam por "_"
# sao documentacao (_src, _proposed, _notes...) e nunca chegam ao .tres.
# Uma coluna que nao seja propriedade do recurso faz a ferramenta falhar: um
# erro de escrita no CSV nunca pode passar em silencio.
extends SceneTree

const Codec := preload("res://tools/csv_codec.gd")
const REGISTRY := "res://data/source/_tables.csv"

var _check := false
var _problems: Array[String] = []


func _init() -> void:
	_check = "--check" in OS.get_cmdline_user_args()
	for t in Codec.read_rows(REGISTRY):
		_run_table(t)
	for p in _problems:
		printerr(p)
	var verb := "verificadas" if _check else "geradas"
	print("csv_to_tres: tabelas %s, %d problema(s)" % [verb, _problems.size()])
	quit(1 if _problems.size() > 0 else 0)


func _run_table(t: Dictionary) -> void:
	# Um script que nao compila fazia a ferramenta seguir em frente e dizer
	# "0 problema(s)" no fim: o .tres ficava por gerar e o CI passava. Um portao
	# que nao consegue sequer ler o que verifica tem de chumbar, nao calar-se.
	var script: Script = load(t["script"])
	# NAO basta comparar com null: um script com erro de analise continua a
	# carregar como GDScript, e so falha quando se lhe chama new(). Antes desta
	# guarda a ferramenta seguia em frente, nao gerava o .tres, e dizia
	# "0 problema(s)" — um portao que nao consegue ler o que verifica calava-se.
	if script == null or not script.can_instantiate():
		_problems.append("%s: o script %s nao compila" % [t["table"], t["script"]])
		return
	var rows := Codec.read_rows("res://data/source/%s.csv" % t["table"])
	var groups := _parse_groups(t.get("groups", ""))
	var made: Array[String] = []
	if t["layout"] == "kv":
		var res: Resource = script.new()
		for r in rows:
			_set_prop(res, r["key"], r["value"], t["table"])
		made.append(_emit(res, t["out"]))
	else:
		for r in rows:
			var res: Resource = script.new()
			_fill(res, r, groups, t["table"])
			made.append(_emit(res, String(t["out"]).replace("{id}", r["id"])))
	if "{id}" in t["out"]:
		_prune(String(t["out"]).get_base_dir(), made)


func _fill(res: Resource, row: Dictionary, groups: Dictionary, table: String) -> void:
	var grouped := {}
	for target in groups:
		for col in groups[target]:
			grouped[col] = target
	for col in row:
		if col.begins_with("_") or grouped.has(col):
			continue
		if col == "id" and not "id" in res:
			continue
		_set_prop(res, col, row[col], table)
	for target in groups:
		var values: Array = []
		for col in groups[target]:
			values.append(row[col])
		res.set(target, Codec.group_to_packed(values))


func _set_prop(res: Resource, name: String, raw: String, table: String) -> void:
	var props := Codec.property_map(res)
	if not props.has(name):
		_problems.append(
			"%s: coluna '%s' nao existe em %s" % [table, name, res.get_script().resource_path]
		)
		return
	if raw.strip_edges() == "":
		return
	res.set(name, Codec.convert(res, props[name], raw))


func _emit(res: Resource, path: String) -> String:
	if _check:
		_compare(res, path)
		return path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(res, path)
	if err != OK:
		_problems.append("nao consegui gravar %s (erro %d)" % [path, err])
	return path


func _compare(res: Resource, path: String) -> void:
	if not FileAccess.file_exists(path):
		_problems.append("em falta: %s — corre a ferramenta sem --check" % path)
		return
	var old: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	for name in Codec.property_map(res):
		if res.get(name) != old.get(name):
			_problems.append(
				"%s: '%s' difere do CSV (%s ≠ %s)" % [path, name, old.get(name), res.get(name)]
			)


func _prune(dir_path: String, made: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for f in dir.get_files():
		var full := dir_path.path_join(f)
		if f.ends_with(".tres") and not full in made:
			if _check:
				_problems.append("orfao: %s ja nao tem linha no CSV" % full)
			else:
				dir.remove(f)
				print("removido (sem linha no CSV): %s" % full)


func _parse_groups(spec: String) -> Dictionary:
	var out := {}
	for part in spec.split(";", false):
		var kv := part.split("=")
		out[kv[0].strip_edges()] = Array(kv[1].split("+"))
	return out
