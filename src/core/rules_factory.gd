# src/core/rules_factory.gd — as regras que as respostas do painel trouxeram (ADR 0027).
#
# Do mesmo feitio do SimFactory, e separado dele so para ele caber nas 250 linhas
# do §28: le o Registry e da aos sistemas puros o que eles precisam, ja pronto.
class_name RulesFactory
extends RefCounted


## O RecruitSystem com o desconto do povo de cada regiao (§04, Q-007), a ler a
## regiao do estado em que se joga, e quem anda atras do rei (Q-063).
static func recruits(estado: GameState) -> RecruitSystem:
	var recrutas := RecruitSystem.new(SimFactory.curve())
	recrutas.cost_deltas = recruit_deltas()
	recrutas.state = estado
	for recurso in Registry.entries(SimFactory.TABELA_TROPAS):
		if (recurso as UnitData).tags.has(&"follows_king"):
			recrutas.followers[(recurso as UnitData).id] = true
	return recrutas


## O `recruit_cost_delta` do povo de cada regiao, pela ordem das regioes.
static func recruit_deltas() -> PackedInt32Array:
	var deltas := PackedInt32Array()
	for id in SimFactory.campaign_peoples():
		var povo := Registry.entry(&"peoples", StringName(id)) as PeopleData
		deltas.append(int(povo.economy_modifiers.get(&"recruit_cost_delta", 0)))
	return deltas


## O que cada estatua guarda (secrets.csv, `teaches`): chave -> id do segredo.
static func discovery_gates() -> Dictionary:
	var gates := {}
	for recurso in Registry.entries(&"lore/secrets"):
		var dados := recurso as SecretData
		if dados.teaches != &"":
			gates[dados.teaches] = dados.id
	return gates


## O que estraga por dia em cada tipo de obra (Q-012), so as que estragam.
static func spoilage() -> Dictionary:
	var estraga := {}
	for recurso in Registry.entries(&"buildings"):
		var obra := recurso as BuildingData
		if obra.spoil_per_day > 0.0:
			estraga[obra.id] = obra.spoil_per_day
	return estraga


## O que o perfil de ganancia em que o rei esta faz ao preco dos impulsos: o
## tirano paga metade (§15, Q-014). O perfil e o da gama onde a ganancia cai.
static func impulse_cost_mult(ganancia: int) -> float:
	for recurso in Registry.entries(&"crown/greed"):
		var perfil := recurso as GreedProfile
		if ganancia >= perfil.greed_range.x and ganancia <= perfil.greed_range.y:
			return perfil.impulse_cost_mult
	return 1.0
