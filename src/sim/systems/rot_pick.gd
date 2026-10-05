# src/sim/systems/rot_pick.gd — o que a Podridao pode pagar, e o que escolhe (§51, ADR 0071).
#
# A regra do §51 e uma so: a mais cara que cabe e cujo dia minimo ja passou. A ADR 0071
# acrescenta-lhe a estreia: uma especie que acabou de abrir vem poucas vezes, e mais a
# cada noite — o primeiro Alado e um Alado, e nao nove (Q-240). E a mesma regra para
# tudo o que a Podridao paga: o que ela invoca, o bicho que levanta e o que o escuro
# traz ao rei (§05: "a unica fonte de criaturas, com orcamento").
#
# Puro e estatico: le o perfil e o estado da mancha, e escreve so no estado dela.
class_name RotPick
extends RefCounted

## A tag da criatura que o poco de minerio chama mais cedo (§06, Q-131).
const ATRAIDA := &"attracted_by_mine"


## A mais cara que cabe, cujo dia ja passou, que ainda tem lugar na estreia e cuja
## faixa esta aberta. `tabela` vem por custo decrescente: a primeira que serve e ela.
static func choose(
	tabela: Array[CreatureData],
	perfil: RotProfile,
	dia: int,
	estado: RotState,
	lure_days: int,
	underground_open: bool
) -> CreatureData:
	for c in tabela:
		var fechado := c.band == Band.Kind.UNDERGROUND and not underground_open
		if not fechado and fits(c, perfil, dia, estado, lure_days):
			return c
	return null


## Se a mancha pode pagar esta criatura nesta noite: o dia dela, a massa e a estreia.
static func fits(
	c: CreatureData, perfil: RotProfile, dia: int, estado: RotState, lure_days: int
) -> bool:
	var abre := opens(c, lure_days)
	if abre > dia or c.mass_cost > estado.mass:
		return false
	var teto := perfil.debut_cap(dia, abre)
	return teto < 0 or int(estado.came.get(c.id, 0)) < teto


## A noite em que a especie pode vir pela primeira vez: o dia minimo, mais cedo se o
## poco a chama (Q-131).
static func opens(c: CreatureData, lure_days: int) -> int:
	return c.min_day - (lure_days if c.tags.has(ATRAIDA) else 0)


## Paga-a: a massa sai, e a especie conta mais uma nesta noite.
static func take(estado: RotState, c: CreatureData) -> void:
	estado.mass -= c.mass_cost
	estado.came[c.id] = int(estado.came.get(c.id, 0)) + 1
