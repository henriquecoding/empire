# src/core/crown_watch.gd — a coroa no chao, no jogo (§16, §74; Q-167, o dono a
# 30/09/2026; relatorio Kingdom, K2).
#
# A cola entre o CrownDrop (puro) e o SimLoop. Quando o combate mata o rei, a morte
# dele nao se anuncia: a coroa cai ao pe do corpo, e quem o jogador conduz passa a ser
# o corpo de classe mais perto, se houver (§16: "podes assumir outro imediatamente").
# Se uma criatura leva a coroa, ou a mancha a come (e o Lume come-a com ela), o rei
# morre de vez: o unit_died sai entao, e o resto do §16 — o herdeiro ou o fim — segue
# como sempre. Se quem se conduz a apanha, ou se a alvorada chega com ela no chao, o
# rei levanta-se (unit_revived, §46).
class_name CrownWatch
extends RefCounted

const METADE := 0.5


## Passo 6: o combate diz que `e` e a morte do rei. Verdadeiro se a coroa caiu, e a
## morte fica por anunciar.
static func fell(e: Dictionary) -> bool:
	if SimLoop.field == null or int(e[CombatSystem.DE]) != SimLoop.king_id:
		return false
	var coroa := SimLoop.field.crown_drop
	if coroa.down:
		return false
	coroa.fall(float(e[CombatSystem.ONDE]), int(e[CombatSystem.FAIXA]))
	_outro(SimLoop.units, SimLoop.field.roster, coroa.x)
	return true


## Passo 2: o que acontece a coroa no chao neste tick.
static func tick(bichos: CreatureSystem, rot: RotSystem) -> void:
	var coroa := SimLoop.field.crown_drop if SimLoop.field != null else null
	if coroa == null or not coroa.down:
		return
	var regras := RulesFactory.rules()
	var mancha := Vector2.ZERO
	if rot.active():
		var meia := rot.state.width * METADE
		mancha = Vector2(rot.position_x() - meia, rot.position_x() + meia)
	var apanha := SimFactory.curve().coin_pickup_px
	var quem := Assume.driven()
	match coroa.tick(bichos, regras.crown_grab_px, mancha, SimLoop.units, quem, apanha):
		CrownDrop.Fate.TAKEN:
			_perdida(coroa)
		CrownDrop.Fate.CONSUMED:
			SimLoop.night.voice.debt.feed_lume(regras.crown_lume_feed)  # ADR 0034
			_perdida(coroa)
		CrownDrop.Fate.RECOVERED:
			_levantar()


## A alvorada, antes de os corpos criarem raiz (§74): a coroa que ninguem levou volta.
static func dawn() -> void:
	if SimLoop.field != null and SimLoop.field.crown_drop.dawn() == CrownDrop.Fate.RECOVERED:
		_levantar()


## Se a coroa esta no chao, a espera: a partida ainda nao acabou (Defeat).
static func waiting() -> bool:
	return SimLoop.field != null and SimLoop.field.crown_drop.down


static func _levantar() -> void:
	if CrownDrop.rise(SimLoop.units, SimLoop.king_id, RulesFactory.rules().crown_rise_health):
		EventBus.queue(&"unit_revived", [SimLoop.king_id])


## O rei morre de vez, no sitio onde caiu: e a morte que o combate nao anunciou.
static func _perdida(coroa: CrownDrop) -> void:
	var dados := Registry.entry(&"units", &"monarch") as UnitData
	var larga := PackedStringArray()
	for d in dados.drops_on_death:
		larga.append(String(d))
	EventBus.queue(&"unit_died", [SimLoop.king_id, coroa.x, coroa.band, larga])


## Quem o jogador conduz passa ao corpo de classe teu mais perto de `x`, vivo — se nao
## conduzia ja um.
static func _outro(unidades: UnitSystem, roster: Roster, x: float) -> void:
	var r := unidades.index_of(SimLoop.king_id)
	if unidades.pilot != UnitSystem.NENHUM or r == UnitSystem.NENHUM:
		return
	var melhor := UnitSystem.NENHUM
	for i in unidades.count():
		if i == r or not unidades.alive(i) or unidades.owners[i] != unidades.owners[r]:
			continue
		var classe := roster.class_of_body(unidades.data_ids[i])
		if classe == &"" or classe == Roster.REI:
			continue
		if melhor == UnitSystem.NENHUM or absf(unidades.xs[i] - x) < absf(unidades.xs[melhor] - x):
			melhor = i
	if melhor != UnitSystem.NENHUM:
		unidades.pilot = unidades.ids[melhor]
