# src/sim/systems/royal_hunt.gd — os imperadores tambem cacam (ADR 0057).
#
# O dono, a 03/10/2026: "os imperadores tambem devem conseguir atacar e colher esse
# dinheiro". O golpe de quem se conduz que nao acha criatura vai ao bicho a frente
# dele, ao alcance da arma: a espada do Rei, as machadinhas da Nia, a flecha do
# Imperador Arqueiro (que ja se gastou ao disparar). O imperador que ninguem conduz
# caca sozinho o que lhe passa ao alcance, sem sair do sitio. Nos dois casos a caca
# cai no chao, moeda a moeda, e e de quem a pisar (Gleaning).
class_name RoyalHunt
extends RefCounted

## A tag de quem e imperador (units.csv): os tres monarcas da ADR 0052.
const IMPERADOR := &"king"
const METADE := 0.5


## O golpe falhado `golpe` (PlayerStrike.last) no bicho mais perto a frente, ao
## alcance. O golpe acerta no corpo (Q-218): ate meia sombra do bicho para la do alcance
## e para tras de quem bate. Devolve as moedas que caem.
static func swing(hunt: HuntingSystem, golpe: Dictionary) -> Array[Dictionary]:
	if int(golpe.get(&"band", Band.Kind.SURFACE)) != Band.Kind.SURFACE:
		return []
	var de := float(golpe[&"x"])
	var lado := float(golpe[&"direction"])
	var alcance := float(golpe[&"range"])
	var melhor := HuntingSystem.SEM_INTRO
	var perto := INF
	for prey in hunt.rabbits:
		var frente := (hunt.herd.where(prey) - de) * lado
		var meia := _meia(hunt, prey)
		if frente >= -meia and frente <= alcance + meia and frente < perto:
			melhor = prey
			perto = frente
	if perto == INF or int(golpe.get(&"damage", 0)) <= 0:
		return []
	return hunt.hurt(melhor, int(golpe[&"damage"]), int(golpe[&"who"]), true)


## Os imperadores que ninguem conduz, de dia, batem no bicho que tenham ao alcance. Quem
## dispara flechas gasta-as da aljava dele (`supply`, Q-200), e sem flechas nao caca.
static func idle(
	hunt: HuntingSystem,
	units: UnitSystem,
	profiles: Dictionary,
	driven: int,
	daylight: bool,
	supply: Supply = null
) -> Array[Dictionary]:
	var moedas: Array[Dictionary] = []
	if not daylight or hunt.rabbits.is_empty():
		return moedas
	for i in units.count():
		var dados: UnitData = profiles.get(units.data_ids[i])
		if dados == null or not dados.tags.has(IMPERADOR) or units.ids[i] == driven:
			continue
		if not units.alive(i) or units.healths[i] <= 0 or units.cooldowns[i] > 0.0:
			continue
		if units.owners[i] == RecruitSystem.SEM_DONO or units.bands[i] != Band.Kind.SURFACE:
			continue
		if units.states[i] in [UnitFsm.State.FIGHT, UnitFsm.State.FLEE]:
			continue
		var golpe := _reach(hunt, units.xs[i], dados.range_px)
		if golpe == HuntingSystem.SEM_INTRO:
			continue
		if dados.ammo > 0:
			if supply == null or not supply.can_shoot(units, i, dados):
				continue
			supply.shoot(units, i, dados)
		units.cooldowns[i] = dados.attack_interval
		moedas.append_array(hunt.hurt(golpe, maxi(1, dados.damage), units.ids[i], true))
	return moedas


## O bicho mais perto de `x` com a pele ao `alcance` (Q-218).
static func _reach(hunt: HuntingSystem, x: float, alcance: float) -> float:
	var melhor := HuntingSystem.SEM_INTRO
	var perto := INF
	for prey in hunt.rabbits:
		var gap := absf(hunt.herd.where(prey) - x)
		if gap <= alcance + _meia(hunt, prey) and gap < perto:
			melhor = prey
			perto = gap
	return melhor


## Meio corpo do bicho da toca `prey`, no chao: a sombra de contacto dele (Q-218).
static func _meia(hunt: HuntingSystem, prey: float) -> float:
	return float(hunt.species_at(prey).shadow_width) * METADE
