# tools/csv_codec.gd — converte celulas de CSV para o tipo de cada propriedade.
# Usado por tools/csv_to_tres.gd. Convencoes (docs/content/CONTENT_DATABASE.md):
#   listas "a|b|c" · Vector2 "x|y" · Dictionary "chave:valor|chave:valor"
#   enums pelo nome (SURFACE) · booleanos true/false · celula vazia = valor por omissao
extends RefCounted

const SEP := "|"


## Mapa nome -> tipo/hint das propriedades exportadas de um recurso.
static func property_map(res: Resource) -> Dictionary:
	var out := {}
	for p in res.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[p["name"]] = p
	return out


static func convert(res: Resource, prop: Dictionary, raw: String) -> Variant:
	var t: int = prop["type"]
	var text := raw.strip_edges()
	match t:
		TYPE_INT:
			return _to_int(text, prop)
		TYPE_FLOAT:
			return _to_float(text)
		TYPE_BOOL:
			return _to_bool(text)
		TYPE_STRING:
			return text
		TYPE_STRING_NAME:
			return StringName(text)
		TYPE_VECTOR2:
			var v := split_list(text)
			return Vector2(_to_float(v[0]), _to_float(v[1]))
		TYPE_VECTOR2I:
			var w := split_list(text)
			return Vector2i(_to_int(w[0], {}), _to_int(w[1], {}))
		TYPE_ARRAY:
			return _to_array(res.get(prop["name"]), split_list(text))
		TYPE_PACKED_FLOAT32_ARRAY:
			var pf := PackedFloat32Array()
			for s in split_list(text):
				pf.append(_to_float(s))
			return pf
		TYPE_DICTIONARY:
			return _to_dict(split_list(text))
		TYPE_OBJECT:
			return ResourceLoader.load(text) if text != "" else null
	push_error("tipo sem conversor: %s (%d)" % [prop["name"], t])
	return null


## Le um CSV (UTF-8, cabecalho na primeira linha) como lista de dicionarios.
static func read_rows(path: String) -> Array[Dictionary]:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "nao consegui abrir %s" % path)
	var header := f.get_csv_line()
	var rows: Array[Dictionary] = []
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() == 1 and line[0].strip_edges() == "":
			continue
		var row := {}
		for i in header.size():
			row[header[i]] = line[i] if i < line.size() else ""
		rows.append(row)
	return rows


static func group_to_packed(values: Array) -> PackedFloat32Array:
	var pf := PackedFloat32Array()
	for s in values:
		pf.append(_to_float(s))
	return pf


static func split_list(text: String) -> PackedStringArray:
	if text == "":
		return PackedStringArray()
	return text.split(SEP)


static func _to_float(s: String) -> float:
	assert(s.strip_edges().is_valid_float(), "nao e numero: '%s'" % s)
	return s.to_float()


static func _to_bool(s: String) -> bool:
	var l := s.to_lower()
	assert(l in ["true", "false", "1", "0"], "nao e booleano: '%s'" % s)
	return l in ["true", "1"]


static func _to_int(s: String, prop: Dictionary) -> int:
	var text := s.strip_edges()
	if text.is_valid_int():
		return text.to_int()
	if prop.get("hint", 0) == PROPERTY_HINT_ENUM:
		var i := 0
		for item in String(prop["hint_string"]).split(","):
			var kv := item.split(":")
			var value := kv[1].to_int() if kv.size() > 1 else i
			if kv[0] == text:
				return value
			i += 1
	if Band.Kind.has(text):
		return Band.Kind[text]
	assert(false, "nao e inteiro nem enum conhecido: '%s'" % text)
	return 0


static func _to_array(default: Array, items: PackedStringArray) -> Array:
	var out: Array = default.duplicate()
	out.clear()
	var elem := out.get_typed_builtin()
	for s in items:
		match elem:
			TYPE_INT:
				out.append(_to_int(s, {}))
			TYPE_FLOAT:
				out.append(_to_float(s))
			TYPE_STRING_NAME:
				out.append(StringName(s.strip_edges()))
			_:
				out.append(s.strip_edges())
	return out


static func _to_dict(items: PackedStringArray) -> Dictionary:
	var out := {}
	for item in items:
		var kv := item.split(":", true, 1)
		assert(kv.size() == 2, "par chave:valor invalido: '%s'" % item)
		var v := kv[1].strip_edges()
		out[StringName(kv[0].strip_edges())] = v.to_float() if v.is_valid_float() else StringName(v)
	return out
