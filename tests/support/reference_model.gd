# tests/support/reference_model.gd — o modelo de referencia do §06 e do §07, em codigo.
#
# E a mesma matematica do simulador da §06 e das tabelas do §07, lida dos .tres.
# Serve dois propositos: (1) os testes de design correm desde o dia zero, antes
# de existir o EconomySystem (F1-10) e o CombatSystem; (2) quando esses sistemas
# existirem, tem de bater com este modelo — ou a divergencia vai a ADR.
extends RefCounted


static func upkeep(troops: int, c: EconomyCurve) -> float:
	if troops <= c.upkeep_free_troops:
		return 0.0
	var tier1 := mini(troops, c.upkeep_tier1_limit) - c.upkeep_free_troops
	var tier2 := maxi(0, troops - c.upkeep_tier1_limit)
	return tier1 * c.upkeep_tier1_rate + tier2 * c.upkeep_tier2_rate


static func net_income(p: EconomyProfile, day: int, c: EconomyCurve) -> float:
	var base := c.curve_income_flat + p.sources * c.curve_income_per_source
	var network := 1.0 + c.trade_network_bonus * maxi(0, p.routes - 1)
	var production := base * pow(c.income_growth, day - 1)
	var trade := p.routes * c.trade_route_income * pow(c.trade_growth, day - 1) * network
	return (production + trade) * (1.0 - p.greed / 100.0) - upkeep(p.troops, c)


static func night_cost(day: int, c: EconomyCurve) -> float:
	return c.night_cost_base * pow(c.night_cost_growth, day - 1)


## Primeiro dia em que sobreviver custa mais do que se produz; 0 = nunca em `days`.
static func suffocation_day(p: EconomyProfile, c: EconomyCurve, days: int = 30) -> int:
	for d in range(1, days + 1):
		if night_cost(d, c) > net_income(p, d, c):
			return d
	return 0


static func rot_speed(day: int, r: RotProfile) -> float:
	return r.speed_base + r.speed_per_day * day


## A massa da §74, termo a termo. Os tres ultimos argumentos sao o que o jogador
## escreveu de dia: arvores anonimas, arvores nomeadas e recusas na janela.
static func rot_mass(
	day: int,
	fortresses: int,
	r: RotProfile,
	amargueiros := 0,
	named_amargueiros := 0,
	refusals := 0
) -> float:
	var base := r.mass_base + r.mass_per_day * day + r.mass_per_fortress * fortresses
	var trees := (
		r.mass_per_amargueiro * amargueiros + r.mass_per_named_amargueiro * named_amargueiros
	)
	var refused := r.refusal_mass * mini(refusals, int(r.refusal_cap / maxf(r.refusal_mass, 1.0)))
	return base + trees + minf(refused, r.refusal_cap)


## Tempo medio ate matar (§07): golpes necessarios x intervalo / precisao.
static func ttk(attacker: UnitData, target_health: int, accuracy: float) -> float:
	var hits := ceili(float(target_health) / attacker.damage)
	return hits * attacker.attack_interval / accuracy
