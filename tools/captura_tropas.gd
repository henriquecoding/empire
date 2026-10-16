extends RefCounted


## Estado preparado para comparar escala; a ficha rotula cada tropa acrescentada.
static func prepare(pedido: String) -> PackedStringArray:
	var feito := PackedStringArray()
	for par in pedido.split(",", false):
		var partes := par.split("@")
		if partes.size() != 2:
			continue
		var dados := Registry.entry(&"units", StringName(partes[0])) as UnitData
		if dados == null:
			continue
		var x := SimLoop.core_x + float(partes[1])
		var id := SimLoop.units.spawn(SimLoop.state, dados, Greybox.MEU_IMPERIO, x)
		SimLoop.units.speeds[SimLoop.units.index_of(id)] = 0.0
		feito.append("tropa %s em x=%d, parada" % [partes[0], int(x)])
	return feito


## `--montaria draft_horse` da a montaria ao reino, no estabulo; `draft_horse@rei` poe o rei
## em cima dela (ADR 0083). Preparado, e a ficha di-lo.
static func mount(pedido: String) -> PackedStringArray:
	var feito := PackedStringArray()
	var partes := pedido.split("@")
	if pedido.is_empty() or SimLoop.field == null:
		return feito
	SimLoop.field.mount.owned = StringName(partes[0])
	feito.append("montaria %s comprada" % partes[0])
	if partes.size() > 1 and partes[1] == "rei":
		SimLoop.field.mount.rider = SimLoop.king_id
		feito.append("o rei montado")
	return feito
