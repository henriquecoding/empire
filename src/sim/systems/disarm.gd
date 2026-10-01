# src/sim/systems/disarm.gd — quem tem arma larga-a antes de morrer (§16, §50; Q-168, o
# dono a 30/09/2026; relatorio Kingdom, K3).
#
# A proposta aprovada: "a 0 de vida, quem tem arma larga-a e foge como trabalhador; so
# morre quem cai sem arma." E o Kingdom: o primeiro golpe tira a ferramenta, e o
# jogador perde investimento e nao gente. O arqueiro que cai larga o arco e passa a
# trabalhador, com a vida dele, a fugir para o nucleo; a banca do arco arma-o outra vez
# por 2 moedas (Q-165). O §50 continua: "toda a morte larga" — e isto larga a arma.
#
# So tropas: o rei e os corpos das classes jogaveis tem o §16 deles. Quem ja e
# trabalhador nao tem arma a largar, e morre.
#
# Puro: as tropas, os dados e o refugio (o nucleo) entram de fora.
class_name Disarm
extends RefCounted

const NENHUM := -1
## O acontecimento, com as chaves do CombatSystem.
const EV := 7
const ARMA := &"weapon"


## Se quem tem estes dados larga a arma em vez de morrer.
static func armed(dados: UnitData) -> bool:
	if dados == null or dados.weapon_kind == &"" or not dados.drops_on_death.has(ARMA):
		return false
	return not (dados.tags.has(&"playable") or dados.tags.has(&"king"))


## As tropas a 0 de vida, ainda por anunciar, que tem arma: passam a `trabalhador`, com
## a vida inteira dele, a fugir para `refugio`. O saco fica ate onde o dele leva, e o
## resto cai.
## Devolve um acontecimento por cada uma, por id crescente (§42).
static func spare(
	unidades: UnitSystem,
	dados: Dictionary,
	trabalhador: UnitData,
	refugio: float,
	refuges: Dictionary = {}
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	if trabalhador == null:
		return eventos
	var ids := unidades.ids.duplicate()
	ids.sort()
	for unit_id in ids:
		var i := unidades.index_of(unit_id)
		if unidades.healths[i] > 0 or unidades.states[i] == UnitFsm.State.DEAD:
			continue
		var tinha: UnitData = dados.get(unidades.data_ids[i])
		if not armed(tinha):
			continue
		var sobra := maxi(0, unidades.carried_coins[i] - trabalhador.coin_capacity)
		(
			eventos
			. append(
				{
					CombatSystem.CHAVE: EV,
					CombatSystem.DE: unit_id,
					CombatSystem.ONDE: unidades.xs[i],
					CombatSystem.FAIXA: int(unidades.bands[i]),
					CombatSystem.QUEM: tinha.id,
					CombatSystem.MOEDAS: sobra,  # o que ja nao cabe no saco cai (§50)
				}
			)
		)
		unidades.data_ids[i] = trabalhador.id
		unidades.max_healths[i] = trabalhador.max_health
		unidades.healths[i] = trabalhador.max_health
		unidades.speeds[i] = trabalhador.move_speed
		unidades.coin_capacities[i] = trabalhador.coin_capacity
		unidades.carried_coins[i] -= sobra
		unidades.recruit_costs[i] = trabalhador.recruit_cost
		unidades.job_ids[i] = NENHUM
		unidades.cooldowns[i] = 0.0
		unidades.states[i] = UnitFsm.State.FLEE
		unidades.set_target_x(unit_id, float(refuges.get(unit_id, refugio)))
	return eventos
