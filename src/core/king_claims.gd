# src/core/king_claims.gd — a moeda do rei com outro alvo que o chao (§74, §08,
# Q-029, Q-114). Tirado do FieldWork, que chegou as 250 linhas do §28.
class_name KingClaims
extends RefCounted


## Uma moeda do rei com outro alvo que o chao: uma arvore a consagrar (§74) ou
## o nucleo, para a classe evoluir (§08, Q-114). Nos dois a moeda volta ao saco.
static func of(
	campo: FieldWork,
	largada: Dictionary,
	estado: GameState,
	noite: NightWatch,
	obras: BuildSystem,
	unidades: UnitSystem,
	rei: int
) -> bool:
	if noite.consecrate_at(estado, largada, rei) or noite.dark.buy_at(largada, obras):
		return true  # uma arvore a consagrar, ou archotes numa fogueira (Q-029)
	if not campo.classes.can_evolve(estado.royal_seeds) or not _no_nucleo(largada, obras):
		return false
	campo.classes.evolve(estado)
	var i := unidades.index_of(rei)
	if i != UnitSystem.NENHUM:
		unidades.carried_coins[i] += int(largada[EventRelay.QUANTO])
	return true


static func _no_nucleo(largada: Dictionary, obras: BuildSystem) -> bool:
	var x: float = largada[EventRelay.ONDE]
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO and vaga.band == int(largada[EventRelay.FAIXA]):
			return absf(vaga.x - x) <= vaga.width * BuildSystem.METADE
	return false
