# src/ui/touch_view.gd — o que os controlos de toque mostram, botao a botao (ADR 0047).
#
# O TouchArt sabe desenhar um botao; isto sabe o que cada um diz agora: a arma e a
# habilidade de quem se conduz (ADR 0045), a recarga, o INTERAGIR a pulsar quando o
# guia diz que ha que fazer, e a roda apagada quando nao e o rei que a tem (§24).
class_name TouchView
extends RefCounted

const ICONES := {
	TouchLayout.Role.DROP: &"moeda",
	TouchLayout.Role.ASSUME: &"passar",
	TouchLayout.Role.WHEEL: &"coroa",
	TouchLayout.Role.PAUSE: &"pausa",
}
## O icone de cada nome de ataque e de habilidade (CombatGlyphs; ADR 0045, ADR 0052).
const ARMAS := {
	&"COMBAT_SWORD": &"espada",
	&"COMBAT_HATCHETS": &"espada",
	&"COMBAT_ARROW": &"flecha",
	&"COMBAT_LUTE": &"alaude",
}
const DONS := {
	&"IMPULSE_VIGIL": &"vigilia",
	&"COMBAT_MARK": &"mira",
	&"COMBAT_CHARM": &"canto",
	&"COMBAT_ROYAL_SONG": &"canto",
}


static func draw(ci: CanvasItem, pad: TouchPad, brilho: bool) -> void:
	var l := pad.layout
	var raio := l.stick_radius()
	if pad.stick.held:
		TouchArt.stick(ci, pad.stick.base, raio, pad.stick.offset, pad.runs())
	else:
		TouchArt.stick(ci, l.stick_home(), raio, 0.0, false)
	# O FIXAR (UX-03): aceso a ouro com a alavanca fixa, que e quando o ecra espreita.
	var fixa := {
		&"premido": l.fixed,
		&"icone": &"pino",
		&"rotulo": _nome(&"TOUCH_FIX"),
		&"cor": GameHud.GOLD if l.fixed else GameHud.TEXT,
	}
	TouchArt.button(ci, l.centre(TouchLayout.Role.FIX), l.radius(TouchLayout.Role.FIX), fixa)
	# O CORRER acende-se a ouro enquanto se prime; cansado, apaga-se (Q-193).
	var cansado := SimLoop.field != null and SimLoop.field.stamina.tired
	var corre := {
		&"premido": pad.running and not cansado,
		&"icone": &"corre",
		&"rotulo": _nome(&"TOUCH_RUN"),
		&"cor": GameHud.MUTED if cansado else GameHud.GOLD if pad.running else GameHud.TEXT,
	}
	TouchArt.button(ci, l.centre(TouchLayout.Role.RUN), l.radius(TouchLayout.Role.RUN), corre)
	var classe := HeroWatch.current()
	var rei := Assume.king()
	for papel: TouchLayout.Role in TouchPad.ACCOES.keys() + [TouchLayout.Role.PAUSE]:
		var estado := {
			&"premido": pad.holds(papel),
			&"icone": ICONES.get(papel, &""),
			&"rotulo": _nome(Glyphs.BOTOES[Glyphs.Device.TOUCH][_glifo(papel)]),
			&"cor": GameHud.GOLD if papel == TouchLayout.Role.DROP else GameHud.TEXT,
		}
		match papel:
			TouchLayout.Role.ATTACK:
				var arma := CombatGlyphs.attack_name(classe)
				estado[&"icone"] = ARMAS.get(arma, &"espada")
				estado[&"rotulo"] = _nome(arma)
				estado[&"pronto"] = _pronto()
			TouchLayout.Role.SKILL:
				var dom := CombatGlyphs.skill_name(classe)
				estado[&"icone"] = DONS.get(dom, &"mira")
				estado[&"rotulo"] = _nome(dom)
				estado[&"apagado"] = not DONS.has(dom)
			TouchLayout.Role.ASSUME:
				estado[&"brilho"] = brilho
			TouchLayout.Role.WHEEL:
				estado[&"apagado"] = not rei
			TouchLayout.Role.PAUSE:
				estado[&"rotulo"] = ""
		TouchArt.button(ci, l.centre(papel), l.radius(papel), estado)
	if pad.holds(TouchLayout.Role.WHEEL) and rei:
		var n := SimLoop.field.crown.ids().size()
		var alcance := TouchPad.RODA_PX * l.scale
		TouchArt.wheel(ci, l.centre(TouchLayout.Role.WHEEL), alcance, n, InputRouter.pointed)


## A linha de Glyphs.ACCOES que diz o nome deste botao.
static func _glifo(papel: TouchLayout.Role) -> int:
	match papel:
		TouchLayout.Role.DROP:
			return Glyphs.ACCOES.find(&"HINT_DROP")
		TouchLayout.Role.ASSUME:
			return Glyphs.ACCOES.find(&"HINT_ASSUME")
		TouchLayout.Role.WHEEL:
			return Glyphs.ACCOES.find(&"HINT_WHEEL")
		TouchLayout.Role.ATTACK:
			return Glyphs.ACCOES.find(&"HINT_ATTACK")
		TouchLayout.Role.SKILL:
			return Glyphs.ACCOES.find(&"HINT_MARK")
	return Glyphs.ACCOES.find(&"HINT_PAUSE")


## Quanto da recarga da arma ja passou, como o painel de combate o mostra (ADR 0045).
static func _pronto() -> float:
	var quem := Assume.driven()
	var i := SimLoop.units.index_of(quem)
	var perfil := SimLoop.combat.manual.profile(SimLoop.units, quem)
	if i < 0 or perfil.is_empty():
		return 1.0
	var intervalo := maxf(CombatBar.MIN_INTERVAL, float(perfil.get(&"interval", 1.0)))
	return clampf(1.0 - SimLoop.units.cooldowns[i] / intervalo, 0.0, 1.0)


static func _nome(chave: StringName) -> String:
	return TranslationServer.translate(chave).to_upper()
