# src/core/king_claims.gd — a moeda do rei com outro alvo que o chao (§74, §08,
# Q-029, Q-114). Tirado do FieldWork, que chegou as 250 linhas do §28.
class_name KingClaims
extends RefCounted


## Uma moeda do rei com outro alvo que o chao: uma arvore a consagrar (§74) ou
## o nucleo, para o monarca evoluir — o Rei pela classe dele, a Nia pelo Bardo e o
## Arqueiro pela marca (§08, Q-114, ADR 0052). Nos dois a moeda volta ao saco. No
## nucleo, so com o monarca escolhido pelo Verbo 2 no marco (ADR 0059).
static func of(
	campo: FieldWork,
	largada: Dictionary,
	estado: GameState,
	noite: NightWatch,
	obras: BuildSystem,
	unidades: UnitSystem,
	rei: int
) -> bool:
	if CellarWatch.deposit(largada) or CompanionWatch.pay(largada):
		return true
	if noite.consecrate_at(estado, largada, rei) or noite.dark.buy_at(largada, obras):
		return true  # uma arvore a consagrar, ou archotes numa fogueira (Q-029)
	if ForestWork.mark(largada):
		return true  # uma arvore para um construtor abater (ADR 0070)
	if not FoundationWatch.aims_monarch() or not _no_nucleo(largada, obras):
		return false  # sem o monarca escolhido no marco, a moeda e da sede (ADR 0059)
	MonarchWatch.evolve(campo, estado)
	var i := unidades.index_of(rei)
	if i != UnitSystem.NENHUM:
		unidades.carried_coins[i] += int(largada[EventRelay.QUANTO])
	return true


static func _no_nucleo(largada: Dictionary, obras: BuildSystem) -> bool:
	var x: float = largada[EventRelay.ONDE]
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO and vaga.band == int(largada[EventRelay.FAIXA]):
			return absf(vaga.x - x) <= vaga.catch_half()
	return false
