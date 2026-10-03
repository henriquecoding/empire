# src/core/rules_factory.gd — as regras que as respostas do painel trouxeram (ADR 0027).
#
# Do mesmo feitio do SimFactory, e separado dele so para ele caber nas 250 linhas
# do §28: le o Registry e da aos sistemas puros o que eles precisam, ja pronto.
class_name RulesFactory
extends RefCounted


## As regras das respostas do painel de 30/09/2026 (rules.csv, ADR 0041).
static func rules() -> RulesCurve:
	return Registry.entry(&"economy", &"rules") as RulesCurve


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


static func segment_kits() -> Array[SegmentData]:
	var result: Array[SegmentData] = []
	for data in Registry.entries(&"segments"):
		result.append(data as SegmentData)
	return result


static func biome_peoples() -> Dictionary:
	var result := {}
	for data: PeopleData in Registry.entries(&"peoples"):
		result[data.biome] = data.id
	return result


## Os estagios da sede (realm_stages.csv), pela ordem: da Clareira a Fortaleza (ADR 0059).
static func realm_stages() -> Array[RealmStageData]:
	var estagios: Array[RealmStageData] = []
	for recurso in Registry.entries(&"realm_stages"):
		estagios.append(recurso as RealmStageData)
	estagios.sort_custom(
		func(a: RealmStageData, b: RealmStageData) -> bool: return a.order < b.order
	)
	return estagios


## O estagio de realm_stages.csv com esta ordem, ou null.
static func realm_stage(ordem: int) -> RealmStageData:
	for estagio in realm_stages():
		if estagio.order == ordem:
			return estagio
	return null


## O que cada estagio abre (a coluna `unlocks`), e o id de cada nivel do muro, para o
## RealmLadder perguntar pelo degrau seguinte de qualquer obra (ADR 0059).
static func install_realm_gates() -> void:
	var gates := {}
	for estagio in realm_stages():
		for chave in estagio.unlocks:
			gates[chave] = estagio.order
	RealmLadder.gates = gates
	var niveis := PackedStringArray()
	for nivel in SimFactory.walls_by_level():
		niveis.append(String(nivel.id))
	RealmLadder.wall_levels = niveis
	RealmGrowth.sites = SimFactory.by_id(&"realm_sites")
