# tools/captura_bichos.gd — criaturas postas em fila para a fotografia.
#
# Fora do jogo, como o tools/captura_obras.gd. E um "estado preparado rotulado"
# (planejamento de 26/09, §7): a ficha diz que criatura foi posta onde, e por
# isso a fotografia nao passa por natural. Existe para se ver, numa so imagem,
# se as sete criaturas de creatures.csv se distinguem pela forma e pelo porte —
# e como a noite as mostra perto e longe de uma luz.
extends RefCounted


## `--bichos "crawler@-300,brute@120"` poe cada criatura a esse x do rei, parada:
## a velocidade fica a zero para que a fila nao se desfaca durante a fotografia.
func prepare(pedido: String) -> PackedStringArray:
	var feito := PackedStringArray()
	if pedido.is_empty() or SimLoop.state == null:
		return feito
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var base := SimLoop.units.xs[rei] if rei != UnitSystem.NENHUM else SimLoop.core_x
	for par in pedido.split(",", false):
		var partes := par.split("@")
		var dados := Registry.entry(&"creatures", StringName(partes[0])) as CreatureData
		if dados == null or partes.size() < 2:
			push_error("captura: criatura %s nao existe" % par)
			continue
		var x := base + float(partes[1])
		if dados.id == &"tender":  # o Zelador anda pela voz dela, nao pelas colunas (§75)
			SimLoop.night.voice.tender.active = true
			SimLoop.night.voice.tender.x = x
			feito.append("Zelador em x=%d" % int(x))
			continue
		SimLoop.creatures.spawn(SimLoop.state, dados, x, x)
		SimLoop.creatures.speeds[SimLoop.creatures.count() - 1] = 0.0
		feito.append("criatura %s em x=%d, parada" % [partes[0], int(x)])
	return feito
