# tests/support/sede.gd — a sede ja erguida, para os testes que medem o reino depois da
# fundacao (ADR 0059).
#
# Ate 03/10/2026 o nucleo nascia castelo, e muitos testes do mundo inteiro medem uma
# mecanica que nao e a abertura — a lareira, a forja, a reparacao, a derrota — sobre esse
# castelo. Com a fundacao, o jogo novo comeca numa Clareira. Estes testes erguem a sede
# primeiro, as claras: o castelo de antes e a Fortaleza, o topo da escada de hoje. Os
# testes da abertura nao usam isto — fundam com moedas, como quem joga.
extends RefCounted

const FORTALEZA := -1


## Ergue a sede da regiao ate `estagio`; por omissao, a Fortaleza. Devolve-a.
static func erguer(estagio: int = FORTALEZA) -> BuildSlot:
	var sede := RealmLadder.seat(SimLoop.builds)
	sede.raise_to(sede.costs.size() if estagio == FORTALEZA else estagio)
	return sede
