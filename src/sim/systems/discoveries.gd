# src/sim/systems/discoveries.gd — o que so se sabe fazer depois de achar (§17, Q-016).
#
# O dono aprovou e pediu mais fundo: "mecanicas e habilidades que so sao
# descobertas e podem ser usadas se o jogador encontrou explorando" (Q-016,
# 28/09/2026). Cada estatua enterrada do secrets.csv guarda UMA coisa — a coluna
# `teaches` — e enquanto nao for achada essa coisa nao existe no teu jogo: a obra
# nao aceita moeda, o gesto nao faz nada. Achada, e do imperio, e vai com o
# legado (o `found` do GameState atravessa e sobrevive a derrota, §16).
#
# A chave e o id de uma obra (a Forja, a escora) ou o nome de um gesto (o
# sacrificio). O que nenhuma estatua guarda e sabido desde o principio: o nucleo
# do jogo — os dois verbos, as muralhas, recrutar — nunca fica atras de uma.
#
# Puro. Quem escreve o mapa e o SimFactory, a partir dos dados.
class_name Discoveries
extends RefCounted

## chave -> id do segredo que a ensina.
static var gates: Dictionary = {}


## Se isto ja se sabe fazer neste imperio.
static func known(estado: GameState, chave: StringName) -> bool:
	var segredo: Variant = gates.get(chave)
	return segredo == null or estado == null or String(segredo) in estado.found


## Quem ensina esta chave, ou vazio se nada a guarda.
static func teacher(chave: StringName) -> StringName:
	return gates.get(chave, &"")
