# src/sim/systems/title_perks.gd — o que um titulo da no combate (§76; Q-102).
#
# "+10% cadencia" e "+2 dano contra cerco", lidos do grants() do TitleSystem. Fora
# do CombatSystem, que chegou as 250 linhas do §28. Puro e estatico.
class_name TitlePerks
extends RefCounted


## Quanto mais depressa dispara quem tem "+10% cadencia" (1,1); 1 sem titulo.
static func rate(bonus: Dictionary) -> float:
	var ritmo := float(bonus.get(&"attack_rate", 1.0))
	return ritmo if ritmo > 0.0 else 1.0


## O dano a mais contra uma criatura de cerco (a tag `siege`), ou zero.
static func vs_siege(
	bonus: Dictionary, criaturas: CreatureSystem, dados: Dictionary, alvo: int
) -> int:
	if not bonus.has(&"damage_vs_siege"):
		return 0
	var c := criaturas.index_of(alvo)
	if c < 0:
		return 0
	var perfil: CreatureData = dados.get(criaturas.data_ids[c])
	return int(bonus[&"damage_vs_siege"]) if perfil != null and perfil.tags.has(&"siege") else 0
