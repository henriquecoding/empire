# tools/captura_moedas.gd — moedas largadas para a fotografia.
#
# Fora do jogo, como o captura_obras e o captura_bichos. Um "estado preparado
# rotulado" (planejamento de 26/09, §7): a ficha diz que moedas foram largadas onde.
# Existe para se ver numa imagem a moeda no ar, a ressaltar e pousada — uma, uma
# pilha e um saco.
extends RefCounted

var _pedido := ""
var _antes := 0


## `--moedas "-80@1,40@4,120@12"` larga, a esse x do rei, uma moeda com essa quantia;
## `200@coroa` larga la a coroa.
## Com `--moedas_antes N`, larga-as N frames antes da fotografia (step), para se
## apanhar a moeda no ar; sem ele, ja.
func prepare(pedido: String, antes := 0) -> PackedStringArray:
	_pedido = pedido
	_antes = antes
	if antes > 0:
		return PackedStringArray(["moedas largadas %d frames antes da fotografia" % antes])
	return _largar()


## Um frame da fotografia: larga as moedas quando faltarem `_antes` frames.
func step(restam: int) -> void:
	if _antes > 0 and restam == _antes:
		_largar()


func _largar() -> PackedStringArray:
	var feito := PackedStringArray()
	var pedido := _pedido
	if pedido.is_empty() or SimLoop.state == null:
		return feito
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var base := SimLoop.units.xs[rei] if rei != UnitSystem.NENHUM else SimLoop.core_x
	for par in pedido.split(",", false):
		var partes := par.split("@")
		var x := base + float(partes[0])
		if partes.size() > 1 and partes[1] == "coroa":
			SimLoop.field.crown_drop.fall(x, Band.Kind.SURFACE)
			feito.append("coroa largada em x=%d" % int(x))
			continue
		var quantia := int(partes[1]) if partes.size() > 1 else 1
		SimLoop.coins.drop(SimLoop.state, x, Band.Kind.SURFACE, quantia, 0.0)
		feito.append("moeda de %d largada em x=%d" % [quantia, int(x)])
	return feito
