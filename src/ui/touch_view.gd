# src/ui/touch_view.gd — o que os controlos de toque mostram, botao a botao (ADR 0047).
#
# O TouchArt sabe desenhar um botao; isto sabe o que cada um diz agora: a arma e a
# habilidade de quem se conduz (ADR 0045), a recarga, o INTERAGIR destacado quando o
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


## O que os controlos mostram agora, como uma lista de passos de desenho: o TouchControls
## so redesenha quando ela muda. Parados, os botoes voltavam a medir e a desenhar o texto
## todos os frames, e custavam mais do que o mundo que tapam (auditoria de 08/10/2026).
static func plan(pad: TouchPad, brilho: bool, zoom: float) -> Array:
	var l := pad.layout
	var raio := l.stick_radius()
	var plano: Array = [[&"", zoom]]  # a escala nao se desenha, mas muda o rotulo
	if pad.stick.held:
		plano.append([&"stick", pad.stick.base, raio, pad.stick.offset, pad.runs()])
	else:
		plano.append([&"stick", l.stick_home(), raio, 0.0, false])
	# O FIXAR (UX-03): aceso com a alavanca fixa, que e quando o ecra espreita.
	var fixa := {
		&"premido": l.fixed,
		&"icone": &"pino",
		&"rotulo": _nome(&"TOUCH_FIX"),
		&"cor": Atlas.VALID if l.fixed else Atlas.SECONDARY,
	}
	plano.append([&"button", l.centre(TouchLayout.Role.FIX), l.radius(TouchLayout.Role.FIX), fixa])
	# O CORRER acende-se enquanto se prime; cansado, apaga-se (Q-193).
	var cansado := SimLoop.field != null and SimLoop.field.stamina.tired
	var corre := {
		&"premido": pad.running and not cansado,
		&"icone": &"corre",
		&"rotulo": _nome(&"TOUCH_RUN"),
		&"cor": Atlas.VALID if pad.running and not cansado else Atlas.SECONDARY,
		&"apagado": cansado,
	}
	plano.append([&"button", l.centre(TouchLayout.Role.RUN), l.radius(TouchLayout.Role.RUN), corre])
	var classe := HeroWatch.current()
	var rei := Assume.king()
	for papel: TouchLayout.Role in TouchPad.ACCOES.keys() + [TouchLayout.Role.PAUSE]:
		var estado := {
			&"premido": pad.holds(papel),
			&"icone": ICONES.get(papel, &""),
			&"rotulo": _nome(Glyphs.BOTOES[Glyphs.Device.TOUCH][_glifo(papel)]),
			&"cor": family(papel),
			&"duplo": combat(papel),
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
				estado[&"pronto"] = MonarchHud.skill_ready(Assume.driven())
				if classe == &"monarch":
					estado[&"pronto"] = (
						1.0 if InputRouter.impulse_refusal(&"vigil").is_empty() else 0.0
					)
			TouchLayout.Role.ASSUME:
				estado[&"brilho"] = brilho
			TouchLayout.Role.WHEEL:
				estado[&"apagado"] = not rei
			TouchLayout.Role.PAUSE:
				estado[&"rotulo"] = ""
		plano.append([&"button", l.centre(papel), l.radius(papel), estado])
	if pad.holds(TouchLayout.Role.WHEEL) and rei:
		var n := SimLoop.field.crown.ids().size()
		var alcance := TouchPad.RODA_PX * l.scale
		var centro := l.centre(TouchLayout.Role.WHEEL)
		plano.append([&"wheel", centro, alcance, n, InputRouter.pointed])
	return plano


## Desenha os passos de um plan(): cada um e uma funcao do TouchArt e os argumentos dela.
static func paint(ci: CanvasItem, plano: Array) -> void:
	for passo: Array in plano:
		if not StringName(passo[0]).is_empty():
			Callable(TouchArt, passo[0]).callv([ci] + passo.slice(1))


## A familia de cada comando (ADR 0078): a moeda e economia, o Interagir e contexto, o
## ataque e a habilidade sao combate, e o resto navega. A cor muda o aro e o icone; o
## sitio e o gesto de cada botao ficam onde estavam (§9.1 do plano mestre da HUD).
static func family(papel: TouchLayout.Role) -> Color:
	match papel:
		TouchLayout.Role.DROP:
			return Atlas.COIN
		TouchLayout.Role.ASSUME:
			return Atlas.INFO
		TouchLayout.Role.ATTACK, TouchLayout.Role.SKILL:
			return Atlas.TEXT
	return Atlas.SECONDARY


## O combate tem tambem forma propria, o aro duplo: a familia nao depende so da cor.
static func combat(papel: TouchLayout.Role) -> bool:
	return papel in [TouchLayout.Role.ATTACK, TouchLayout.Role.SKILL]


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
	return TranslationServer.translate(chave).capitalize()
