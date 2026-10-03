# src/ui/monarch_hud.gd — o que o painel de combate diz do monarca (ADR 0052): quem reina,
# a recarga do canto do Bardo da Nia e as flechas da aljava do Imperador Arqueiro.
class_name MonarchHud
extends RefCounted

const MIN_INTERVAL := 0.01


## O nome de quem reina: o do perfil, ou o do herdeiro com a geracao — a sucessora da Nia
## nao volta a chamar-se Nia (Q-202).
static func title() -> String:
	var dados := MonarchWatch.data()
	var geracao := SimLoop.field.monarchy.generation if SimLoop.field != null else 0
	if geracao == 0:
		return _tr(StringName(dados.display_key))
	var heir := _tr(StringName(dados.heir_key))
	return _tr(&"MONARCH_HEIR_TITLE").format({"heir": heir, "n": geracao + 1})


## Quanto da recarga da habilidade ja passou, de 0 a 1. O canto da Nia e o do Bardo dela.
static func skill_ready(who: int) -> float:
	var units := SimLoop.units
	var quem := who
	if who == SimLoop.king_id and MonarchWatch.skill() == MonarchWatch.CANTO:
		var b := SimLoop.field.monarchy.companion_index(units, who)
		quem = units.ids[b] if b >= 0 else UnitSystem.NENHUM
	var i := units.index_of(quem)
	if i < 0:
		return 0.0
	var falta := float(SimLoop.field.song.cooldowns.get(quem, 0.0))
	var corpo := Registry.entry(&"units", units.data_ids[i]) as UnitData
	return clampf(1.0 - falta / maxf(MIN_INTERVAL, corpo.attack_interval), 0.0, 1.0)


## " · Flechas 12/30" para quem tem aljava, ou "" (Q-200).
static func arrows(who: int) -> String:
	var units := SimLoop.units
	var i := units.index_of(who)
	if i < 0:
		return ""
	var corpo := Registry.entry(&"units", units.data_ids[i]) as UnitData
	if corpo == null or corpo.ammo <= 0:
		return ""
	var restam := SimLoop.field.supply.left(units, i, corpo)
	return " · " + _tr(&"COMBAT_ARROWS").format({"left": restam, "max": corpo.ammo})


static func _tr(chave: StringName) -> String:
	return TranslationServer.translate(chave)
