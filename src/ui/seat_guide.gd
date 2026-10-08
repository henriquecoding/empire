# src/ui/seat_guide.gd — o que o painel de contexto diz no marco da sede (ADR 0059).
#
# O plano do reino (§23.1): ao interagir com a sede, dizer o proximo beneficio e o
# compromisso — "Melhorar para Povoado — 8 moedas. Permite construir Casa de Treino,
# galinheiro e torres. As obras e os profissionais sao pagos a parte." E, quando o
# monarca pode evoluir, dizer para onde vai a moeda antes de ela sair da mao, e como se
# troca (§23.2). Tirado do GameplayGuide, que nao cabia nas 250 linhas do §28.
class_name SeatGuide
extends RefCounted

## Quantas obras o painel nomeia do que um estagio abre; o resto fica em reticencias.
const NOMEADAS := 3
const RETICENCIAS := "…"
const SEPARADOR := ", "


## O texto do marco da sede: fundar, melhorar, a obra em curso, a reparacao, ou o
## monarca a evoluir, com a troca de alvo quando ha escolha.
static func context(site: BuildSlot, values: Dictionary) -> String:
	var pode := (
		not SimLoop.arrival.active
		and MonarchWatch.can_evolve(SimLoop.field, SimLoop.state.royal_seeds)
	)
	if FoundationWatch.aims_monarch():
		var evolui := GameplayGuide.evolve(site, values)
		return evolui + "\n" + _tr(&"CONTEXT_SEAT_TO_SEAT").format(values)
	var texto := _seat(site, values)
	if pode:
		texto += "\n" + _tr(&"CONTEXT_SEAT_TO_MONARCH").format(values)
	return texto


## Uma obra que a sede ainda nao abre: diz o estagio que falta, e nao so "bloqueada".
static func locked(site: BuildSlot, values: Dictionary) -> String:
	values["stage"] = stage_name(RealmLadder.required(site))
	return _tr(&"CONTEXT_STAGE_LOCKED").format(values)


## O nome do estagio com esta ordem.
static func stage_name(ordem: int) -> String:
	var estagio := RulesFactory.realm_stage(ordem)
	return _tr(StringName(estagio.display_key)) if estagio != null else ""


static func _seat(site: BuildSlot, values: Dictionary) -> String:
	values["stage"] = stage_name(site.level)
	values["next"] = stage_name(site.level + 1)
	values["cost"] = PriceTag.owed_by(site)
	if site.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
		return _tr(&"CONTEXT_SEAT_BUILDING").format(values)
	if site.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN]:
		values["name"] = values.stage
		var chave := &"CONTEXT_REPAIRING" if site.mending else &"CONTEXT_REPAIR"
		return _tr(chave).format(values)
	if site.next_cost() == BuildSlot.NENHUM:
		return _tr(&"CONTEXT_SEAT_TOP").format(values)
	if site.level == RealmLadder.CLAREIRA:
		return _tr(&"CONTEXT_SEAT_FOUND").format(values)
	var missing := RealmMilestones.missing()
	if missing != &"":
		values["feat"] = _tr(&"ARRIVAL_MATURITY_" + String(missing).to_upper())
		return _tr(&"ARRIVAL_MATURITY").format(values)
	values["opens"] = opens(site.level + 1)
	var texto := _tr(&"CONTEXT_SEAT_UPGRADE").format(values)
	var atual := RulesFactory.realm_stage(site.level)
	var proximo := RulesFactory.realm_stage(site.level + 1)
	if atual != null and proximo != null and proximo.wall_rings > atual.wall_rings:
		texto += "\n" + _tr(&"CONTEXT_SEAT_NEW_WALLS")
	return texto


## As primeiras obras que o estagio abre, pelos nomes, e reticencias se ha mais.
static func opens(ordem: int) -> String:
	var estagio := RulesFactory.realm_stage(ordem)
	if estagio == null:
		return ""
	var nomes := PackedStringArray()
	for chave in estagio.unlocks:
		if nomes.size() == NOMEADAS:
			nomes.append(RETICENCIAS)
			break
		nomes.append(_name_of(chave))
	return SEPARADOR.join(nomes)


static func _name_of(chave: StringName) -> String:
	if Registry.has_entry(&"buildings", chave):
		return _tr(StringName((Registry.entry(&"buildings", chave) as BuildingData).display_key))
	if Registry.has_entry(&"walls", chave):
		return _tr(StringName((Registry.entry(&"walls", chave) as WallData).display_key))
	return String(chave)


static func _tr(key: StringName) -> String:
	return GuideHints.translate(key)
