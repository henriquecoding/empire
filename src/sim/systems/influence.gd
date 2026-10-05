# src/sim/systems/influence.gd — o que a floresta faz a quem esta perto (ADR 0070).
#
# Uma regra de influencia responde a seis perguntas (§8.5 do relatorio de vegetacao):
# quem e a origem, quem recebe, qual e o alcance, que condicao, que efeito, e como se
# acumulam varias origens. Aqui ha duas, e as duas leem-se no ecra antes de se decidir:
#
#   · o bosque apoia a coleta — arvores `forage` a `grove_feeds_radius` das provisoes;
#     com `grove_feeds_min` delas, a coleta da `grove_feeds_bonus` moeda a mais por dia,
#     nunca mais do que `grove_feeds_cap` (o maximo, nao a soma);
#   · a floresta abriga a caca — arvores `shelter` a `shelter_radius` de uma toca que
#     vive de arvores; abaixo de `shelter_min` a toca adormece e nao da bicho.
#
# A distancia e a do mundo, ao longo da faixa: um muro nao corta a influencia (decidido
# assim, por agora, e escrito na ADR).
#
# Puro: as especies e os numeros entram ja lidos.
class_name Influence
extends RefCounted

const FORAGE := &"forage"
const SHELTER := &"shelter"


## As especies (id -> true) que levam a etiqueta `tag`: quem pode ser origem.
static func kinds(flora: Array, tag: StringName) -> Dictionary:
	var saida := {}
	for especie: FloraData in flora:
		if especie.tags.has(tag):
			saida[especie.id] = true
	return saida


## O efeito de uma regra com `have` origens no alcance: `add` se chegam ao `minimum`,
## nunca mais do que `cap`; nada abaixo do minimo.
static func bonus(have: int, minimum: int, add: int, cap: int) -> int:
	return clampi(add, 0, maxi(0, cap)) if have >= minimum else 0


## Quantas origens se perdem se a arvore `lost` (indice) cair: 1 se ela conta para o
## destino em `x`, 0 se nao. E a previsao que o painel mostra antes de pagar o corte.
static func would_lose(
	woodland: Woodland, lost: int, x: float, radius: float, kinds_set: Dictionary
) -> int:
	if not woodland.standing(lost):
		return 0
	var conta := kinds_set.has(StringName(woodland.species[lost]))
	return 1 if conta and absf(woodland.xs[lost] - x) <= radius else 0
