# src/sim/systems/repair_work.gd — reparar com a moeda fisica (§55, §25, Q-108).
#
# A mesma regra de construir, aplicada ao caminho de volta: a reparacao paga-se
# com moedas que caem na obra e avanca com quem la esta, nao com o tempo. A
# ruina volta a andaime e levanta-se outra vez no nivel que tinha; a obra tocada
# fica de pe — continua a travar — e ganha vida a medida que e trabalhada.
#
# Puro e estatico: o BuildSystem chama-o e devolve os mesmos acontecimentos.
class_name RepairWork
extends RefCounted


## Paga a reparacao com as moedas `apanhadas` (ids ja em cima da obra).
static func absorb(
	moedas: CoinSystem, vaga: BuildSlot, apanhadas: PackedInt32Array
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var custo := vaga.repair_cost()
	if vaga.mending or custo == BuildSlot.NENHUM or apanhadas.is_empty():
		return eventos
	var valor := 0
	for coin_id in apanhadas:
		valor += moedas.amounts[moedas.index_of(coin_id)]
		moedas.remove(coin_id)
	vaga.paid += valor
	eventos.append(
		{BuildSystem.CHAVE: BuildSystem.EV_PAGA, BuildSystem.VAGA: vaga, BuildSystem.QUANTO: valor}
	)
	if vaga.paid < custo:
		return eventos
	vaga.paid -= custo
	vaga.mending = true
	vaga.progress = 0.0
	if vaga.state == BuildSlot.State.RUIN:
		vaga.state = BuildSlot.State.SCAFFOLD
	eventos.append({BuildSystem.CHAVE: BuildSystem.EV_INICIADA, BuildSystem.VAGA: vaga})
	return eventos


## `maos` segundos de trabalho presente. A ruina anda como uma obra do seu
## nivel; a obra de pe ganha vida a razao de uma obra inteira por `works`.
static func tick(vaga: BuildSlot, maos: float) -> Array[Dictionary]:
	if maos <= 0.0:
		return []
	var trabalho := vaga.works[vaga.level - 1]
	vaga.progress += maos
	if vaga.state == BuildSlot.State.DAMAGED:
		var cura := int(vaga.progress / trabalho * vaga.max_health())
		if cura <= 0:
			return []
		vaga.progress -= cura * trabalho / vaga.max_health()
		vaga.health = mini(vaga.max_health(), vaga.health + cura)
		if vaga.health < vaga.max_health():
			return []
	elif vaga.progress < trabalho:
		vaga.state = BuildSlot.State.BUILDING
		return [
			{
				BuildSystem.CHAVE: BuildSystem.EV_PROGRESSO,
				BuildSystem.VAGA: vaga,
				BuildSystem.RACIO: vaga.progress / trabalho
			}
		]
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	vaga.progress = 0.0
	vaga.mending = false
	return [{BuildSystem.CHAVE: BuildSystem.EV_REPARADA, BuildSystem.VAGA: vaga}]
