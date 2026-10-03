# src/core/crown_watch.gd — a coroa no chao, no jogo (§16, §74; Q-167, o dono a
# 30/09/2026; relatorio Kingdom, K2).
#
# A cola entre o CrownDrop (puro) e o SimLoop. Quando o combate mata o rei, a morte
# dele nao se anuncia: a coroa cai ao pe do corpo. Nenhuma tropa passa a ser conduzida
# para a ir buscar (ADR 0052: so imperadores se jogam); sem ninguem que a apanhe, o rei
# levanta-se na alvorada, se nenhuma criatura hostil a levou (Q-167).
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
	var raios := Vector2(regras.crown_grab_px, SimFactory.curve().coin_pickup_px)
	var aliadas := SimLoop.field.song.allies  # o convertido nao rouba a coroa (UN-11)
	match coroa.tick(bichos, raios, mancha, SimLoop.units, Assume.driven(), aliadas):
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


## O rei morre de vez, no sitio onde caiu: e a morte que o combate nao anunciou. Larga o
## que o corpo dele larga — o do Rei, da Nia ou do Arqueiro (ADR 0052).
static func _perdida(coroa: CrownDrop) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	var corpo := SimLoop.units.data_ids[i] if i != UnitSystem.NENHUM else Monarchy.REI
	var dados := Registry.entry(&"units", corpo) as UnitData
	var larga := PackedStringArray()
	for d in dados.drops_on_death:
		larga.append(String(d))
	EventBus.queue(&"unit_died", [SimLoop.king_id, coroa.x, coroa.band, larga])
