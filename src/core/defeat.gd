# src/core/defeat.gd — quando e que a partida acabou (§10, §16).
#
# Duas maneiras, e ate a auditoria de 26/09 so havia uma: "se o nucleo cair, cai a
# partida" (§10). A outra e o rei. O §16 da-lhe sucessao — herdeiro ao amanhecer,
# ou interregno. Sem herdeiro formado, um rei morto deixava o mundo a correr sem
# ninguem para comandar (D6): a morte dele e o fim da partida, com o mesmo ecra
# que o nucleo caido. Com herdeiro formado, espera-se pela alvorada e ele nasce no
# castelo (Q-133, Q-137).
#
# Uma regra so, lida por quem pausa, por quem desenha o menu e por quem decide se
# um save se retoma — antes eram tres `fallen(NUCLEO)` espalhados.
class_name Defeat
extends RefCounted


## Verdadeiro se a partida em curso ja acabou.
static func happened() -> bool:
	if SimLoop.state == null:
		return false
	if SimLoop.builds.fallen(BuildSlot.NUCLEO):
		return true
	return king_fell() and not SimLoop.field.succession.possible(SimLoop.builds)


## O rei que estava em campo ja nao esta de pe. Sem rei posto em campo (um teste,
## uma ferramenta) nao ha rei para cair.
static func king_fell() -> bool:
	if SimLoop.king_id == UnitSystem.NENHUM:
		return false
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return i == UnitSystem.NENHUM or SimLoop.units.healths[i] <= 0
