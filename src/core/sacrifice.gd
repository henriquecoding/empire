# src/core/sacrifice.gd — alimentar a Podridao (§05, Q-127, Q-016). Tirado do NightWatch,
# que chegou as 250 linhas do §28 com a coroa no chao (Q-167).
#
# §05: "Alimentar — deixar sacrificios (animais, tropas fracas, ouro) reduz a massa.
# Sinistro, eficaz, e mecanicamente honesto" (Q-127). As moedas que o REI largou sem
# outro destino, pousadas dentro da mancha, somem nela. A do prato de uma oferta aberta
# e da oferta; a que caiu de quem morreu nao e sacrificio.
class_name Sacrifice
extends RefCounted

const METADE := 0.5


static func feed(rot: RotSystem, voice: OfferWatch, moedas: CoinSystem) -> void:
	var meia := rot.state.width * METADE
	var prato := voice.offers
	var meio_prato := SimFactory.rot_profile().offer_plate_px * METADE
	var comidas := PackedInt32Array()
	var valor := 0
	for c in moedas.count():
		if moedas.settled[c] == 0 or moedas.from_king[c] == 0 or moedas.targets[c] >= 0:
			continue
		if moedas.bands[c] != int(Band.Kind.SURFACE):
			continue
		if absf(moedas.xs[c] - rot.position_x()) > meia:
			continue
		var aberto := prato.phase == OfferSystem.Phase.OPEN
		if aberto and absf(moedas.xs[c] - prato.plate_x) <= meio_prato:
			continue
		comidas.append(moedas.ids[c])
		valor += moedas.amounts[c]
	if comidas.is_empty():
		return
	for coin_id in comidas:
		moedas.remove(coin_id)
	var tirada := minf(rot.state.mass, valor * SimFactory.rot_profile().sacrifice_mass_per_coin)
	rot.state.mass -= tirada
	voice.debt.feed_lume(valor)  # compra a noite de hoje e alimenta o Lume (ADR 0034)
	EventBus.queue(&"rot_fed", [tirada, &"coins"])
