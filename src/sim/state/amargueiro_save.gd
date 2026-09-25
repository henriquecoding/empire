# src/sim/state/amargueiro_save.gd — as arvores do §74 em tipos base, e de volta.
#
# Os nomes dos campos sao os da tabela da §84 (amargueiro_x, _band, _tier, _day,
# _title): a ADR 0007 fechou o save em store_var/get_var(false), e o D-14 guarda
# que tudo o que a Parte XIII grava cabe nessa regra. Aqui acrescenta-se o que a
# §84 nao lista e nao se deriva: o destino, as noites de pe e a serra a meio.
#
# Vive a parte do AmargueiroSystem porque a serra e um slot do BuildSystem, e
# repo-la e a unica coisa do sistema que precisa de saber a ordem do load.
class_name AmargueiroSave
extends RefCounted


static func write(bosque: AmargueiroSystem, obras: BuildSystem) -> Dictionary:
	return {
		&"amargueiro_x": bosque.xs,
		&"amargueiro_band": bosque.bands,
		&"amargueiro_tier": bosque.tiers,
		&"amargueiro_day": bosque.days,
		&"amargueiro_title": bosque.titles,
		&"amargueiro_nights": bosque.nights,
		&"amargueiro_fate": bosque.fates,
		&"amargueiro_saw": _serras(bosque, obras),
		&"bitter_wood": bosque.bitter_wood,
	}


## Uma coluna curta ou em falta degrada para "sem arvores" em vez de recusar o
## save (§62): um indice so existe se existir em todas.
static func read(bosque: AmargueiroSystem, d: Dictionary, obras: BuildSystem) -> void:
	var xs: PackedFloat32Array = d.get(&"amargueiro_x", PackedFloat32Array())
	var bands: PackedInt32Array = d.get(&"amargueiro_band", PackedInt32Array())
	var tiers: PackedInt32Array = d.get(&"amargueiro_tier", PackedInt32Array())
	var days: PackedInt32Array = d.get(&"amargueiro_day", PackedInt32Array())
	var titles: PackedStringArray = d.get(&"amargueiro_title", PackedStringArray())
	var nights: PackedInt32Array = d.get(&"amargueiro_nights", PackedInt32Array())
	var fates: PackedInt32Array = d.get(&"amargueiro_fate", PackedInt32Array())
	var serras: Array = d.get(&"amargueiro_saw", [])
	var n := mini(xs.size(), mini(bands.size(), mini(tiers.size(), days.size())))
	n = mini(n, mini(titles.size(), mini(nights.size(), fates.size())))
	for i in n:
		var k := bosque.plant(xs[i], bands[i], tiers[i], days[i], titles[i])
		bosque.nights[k] = nights[i]
		bosque.fates[k] = fates[i]
		var guardada: Dictionary = serras[i] if i < serras.size() else {}
		if guardada.is_empty():
			continue
		var vaga := obras.post(bosque.saw(k))
		var estado := guardada.duplicate()
		estado.erase(&"id")
		vaga.from_dict(estado)
		bosque.slot_ids[k] = vaga.id
	bosque.bitter_wood = d.get(&"bitter_wood", bosque.bitter_wood)


## O estado da serra de cada arvore, ou um dicionario vazio onde ainda nao pegou.
static func _serras(bosque: AmargueiroSystem, obras: BuildSystem) -> Array:
	var saida := []
	for i in bosque.count():
		var s := obras.index_of(bosque.slot_ids[i])
		saida.append(obras.slots[s].to_dict() if s != BuildSystem.NENHUM else {})
	return saida
