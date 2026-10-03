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
