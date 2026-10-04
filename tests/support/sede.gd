# tests/support/sede.gd — a sede ja erguida, para os testes que medem o reino depois da
# fundacao (ADR 0059).
#
# Ate 03/10/2026 o nucleo nascia castelo, e muitos testes do mundo inteiro medem uma
# mecanica que nao e a abertura — a lareira, a forja, a reparacao, a derrota — sobre esse
# castelo. Com a fundacao, o jogo novo comeca numa Clareira. Estes testes erguem a sede
# primeiro, as claras: o castelo de antes e a Fortaleza, o topo da escada de hoje. Os
# testes da abertura nao usam isto — usam o estandarte e trabalho presencial, como quem joga.
extends RefCounted

const FORTALEZA := -1


## Ergue a sede da regiao ate `estagio`; por omissao, a Fortaleza. Devolve-a.
static func erguer(estagio: int = FORTALEZA) -> BuildSlot:
	if SimLoop.arrival.active and SimLoop.arrival.choice == &"":
		LastCartWatch.claim(&"road")
	var sede := RealmLadder.seat(SimLoop.builds)
	sede.raise_to(sede.costs.size() if estagio == FORTALEZA else estagio)
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[r] = sede.x
	SimLoop.units.clear_target(SimLoop.king_id)
	return sede


## Companhia ja contratada: fixture dos testes de combate e sucessao, nao da abertura.
static func companhia() -> void:
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	var c := units.count() - 1
	units.owners[c] = units.owners[r]
	units.xs[c] = units.xs[r]
	units.clear_target(units.ids[c])
	Monarchy.embody(units, c, Registry.entry(&"units", MonarchWatch.data().companion))
	MonarchWatch.bond(SimLoop.king_id, units.ids[c])
	SimLoop.companion.paid = LastCartWatch.rules().companion_cost


## Evolucao paga antiga: so os saves anteriores ao prologo conservam este gesto.
static func campanha_anterior() -> void:
	LastCartWatch.claim(&"road")
	SimLoop.arrival.active = false
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[r] = SimLoop.core_x
	SimLoop.units.clear_target(SimLoop.king_id)
	companhia()
