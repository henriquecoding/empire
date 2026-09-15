# tests/data_test.gd — a base de dados de conteudo (docs/content/CONTENT_DATABASE.md).
# Integridade dos CSV e dos .tres, e os numeros que o dossie escreve com todas as letras.
# A sincronia CSV <-> .tres e verificada a parte, no CI, por tools/csv_to_tres.gd --check.
extends GdUnitTestSuite

const Codec := preload("res://tools/csv_codec.gd")
const Model := preload("res://tests/support/reference_model.gd")
const REGISTRY := "res://data/source/_tables.csv"


func _rows(table: String) -> Array[Dictionary]:
	return Codec.read_rows("res://data/source/%s.csv" % table)


func _ids(table: String) -> Array:
	return _rows(table).map(func(r: Dictionary) -> String: return r["id"])


func _unit(id: String) -> UnitData:
	return load("res://data/units/%s.tres" % id)


func _curve() -> EconomyCurve:
	return load("res://data/economy/curve.tres")


func _profile(id: String) -> EconomyProfile:
	return load("res://data/economy/profiles/%s.tres" % id)


func test_cada_linha_tem_o_seu_tres() -> void:
	for t in Codec.read_rows(REGISTRY):
		if not "{id}" in t["out"]:
			assert_bool(FileAccess.file_exists(t["out"])).is_true()
			continue
		for id in _ids(t["table"]):
			var path := String(t["out"]).replace("{id}", id)
			assert_bool(FileAccess.file_exists(path)).override_failure_message(path).is_true()


func test_curva_sem_campos_em_falta() -> void:
	var keys := _rows("economy").map(func(r: Dictionary) -> String: return r["key"])
	for name in Codec.property_map(EconomyCurve.new()):
		assert_bool(name in keys).override_failure_message("economy.csv sem %s" % name).is_true()


func test_colunas_propostas_existem() -> void:
	for t in Codec.read_rows(REGISTRY):
		var rows := _rows(t["table"])
		var cols: Array = rows[0].keys() if t["layout"] == "rows" else _ids_kv(rows)
		for r in rows:
			for field in String(r.get("_proposed", "")).split("|", false):
				var msg := (
					"%s/%s: _proposed cita '%s'" % [t["table"], r.get("id", r.get("key")), field]
				)
				assert_bool(field in cols).override_failure_message(msg).is_true()


func _ids_kv(rows: Array[Dictionary]) -> Array:
	return rows.map(func(r: Dictionary) -> String: return r["key"])


func test_referencias_resolvem() -> void:
	var units := _ids("units")
	var buildings := _ids("buildings")
	var creatures := _ids("creatures")
	var jobs := _ids("jobs")
	for u in _rows("units"):
		_expect_in(u["trained_at"], buildings, "units.trained_at", true)
		for job in Codec.split_list(u["job_affinity"]):
			_expect_in(job.split(":")[0], jobs, "units.job_affinity", false)
	for p in _rows("peoples"):
		_expect_in(p["unique_unit"], units, "peoples.unique_unit", false)
		_expect_in(p["biome"], _ids("biomes"), "peoples.biome", false)
		_expect_in(p["playable_class"], _ids("classes"), "peoples.playable_class", false)
		for s in Codec.split_list(p["segment_kit"]):
			_expect_in(s, _ids("segments"), "peoples.segment_kit", false)
	for b in _rows("biomes"):
		for c in Codec.split_list(b["creature_table"]):
			_expect_in(c, creatures, "biomes.creature_table", false)
		for w in Codec.split_list(b["wildlife"]):
			_expect_in(w, _ids("wildlife"), "biomes.wildlife", false)
	for c in _rows("classes"):
		_expect_in(c["base_unit"], units, "classes.base_unit", false)
	for k in _rows("crafts"):
		_expect_in(k["house"], buildings, "crafts.house", false)
		_expect_in(k["capacity_craft"], units, "crafts.capacity_craft", false)


func _expect_in(value: String, pool: Array, where: String, allow_empty: bool) -> void:
	if allow_empty and value == "":
		return
	var msg := "%s: '%s' nao existe" % [where, value]
	assert_bool(value in pool).override_failure_message(msg).is_true()


func test_segmentos_do_mesmo_tipo_coincidem() -> void:
	var seen := {}
	for s in _rows("segments"):
		var sig := "%s/%s" % [s["weight"], s["rules"]]
		if seen.has(s["kind"]):
			assert_str(sig).override_failure_message(s["id"]).is_equal(seen[s["kind"]])
		seen[s["kind"]] = sig


func test_relogio_do_05() -> void:
	var clock: ClockData = load("res://data/economy/clock.tres")
	var total := 0.0
	for d in clock.phase_durations:
		total += d
	assert_int(clock.phase_durations.size()).is_equal(6)
	assert_float(total).is_equal(clock.day_seconds)
	assert_float(total).is_equal(360.0)
	assert_float(total - clock.phase_durations[5]).is_equal(255.0)  # §29: seconds_until(NIGHT)
	assert_bool(clock.day_seconds >= clock.day_seconds_min).is_true()
	assert_bool(clock.day_seconds <= clock.day_seconds_max).is_true()


func test_todas_as_chaves_de_texto_existem() -> void:
	# §44, "a regra do texto": nenhum .tres tem texto visivel, so chaves.
	var strings := {}
	for r in Codec.read_rows("res://data/i18n/strings.csv"):
		strings[r["keys"]] = r
		var msg := "%s: falta PT ou EN" % r["keys"]
		assert_bool(r["pt_PT"] != "" and r["en"] != "").override_failure_message(msg).is_true()
		if r["_max_chars"] != "":
			var limit := int(r["_max_chars"])
			for lang in ["pt_PT", "en"]:
				var over := "%s/%s passa de %d caracteres" % [r["keys"], lang, limit]
				assert_bool(r[lang].length() <= limit).override_failure_message(over).is_true()
	for t in Codec.read_rows(REGISTRY):
		if t["layout"] != "rows":
			continue
		for r in _rows(t["table"]):
			for col in ["display_key", "title_key", "body_key"]:
				if r.has(col) and r[col] != "":
					var miss := (
						"%s/%s: %s sem entrada em strings.csv" % [t["table"], r["id"], r[col]]
					)
					assert_bool(strings.has(r[col])).override_failure_message(miss).is_true()
