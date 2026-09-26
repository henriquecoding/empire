# src/sim/state/slot_variant.gd — as duas variantes de uma melhoria (auditoria
# P-N; §10; Q-136).
#
# A escolha A/B da muralha (§10) e o padrao que a auditoria de 26/09 quis estender
# antes de ligar edificios novos (Thronefall): a torre de arqueiros escolhe entre
# alcance (a de sempre) e cadencia; o canteiro entre render (o de sempre) e
# resguardo — o rasto da Podridao nao o arrasa nem o para. A variante B e o
# `variant_params` de buildings.csv sobre o effect_params. Escolhe-se com o Verbo
# 2 enquanto o sitio esta vazio e sem moeda: "nunca da para ter as duas".
#
# Puro e estatico: le e escreve o BuildSlot.
class_name SlotVariant
extends RefCounted

const A := 0
const B := 1


## O que a obra faz, pela variante escolhida.
static func effects(obra: BuildSlot) -> Dictionary:
	return obra.effects.merged(obra.effects_b, true) if obra.variant == B else obra.effects


## Se ainda se escolhe: ha outra variante, o sitio esta vazio e sem moeda.
static func open(obra: BuildSlot) -> bool:
	return not obra.effects_b.is_empty() and obra.state == BuildSlot.State.EMPTY and obra.paid == 0


## Troca de variante. Falso se ja nao se escolhe.
static func choose(obra: BuildSlot) -> bool:
	if not open(obra):
		return false
	obra.variant = B if obra.variant == A else A
	return true
