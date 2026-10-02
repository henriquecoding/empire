# src/world/strike_pose.gd — o golpe em tres tempos, para o corpo o mostrar.
#
# Ate aqui um golpe nao tinha corpo: a simulacao decidia o acerto no tick e o
# ecra ficava igual, com a arte a mostrar o repouso por nao ter a tag `attack`
# (ActorAction). Isto e a anatomia classica de um ataque — antecipacao, golpe e
# recuperacao (GDKeys, "Anatomy of an Attack"; o foreswing/backswing do Dota) —
# feita com o que a simulacao JA guarda:
#
#   antecipacao  os ultimos WINDUP_S do cooldown de quem esta engajado. E o que
#                deixa ler uma criatura a armar-se antes de a pancada cair.
#   golpe        os primeiros STRIKE_S depois do ataque, curto e seco.
#   recuperacao  o regresso ao repouso.
#
# Puro: recebe quanto tempo passou desde o ataque e quanto falta para o proximo,
# e devolve deslocamento, esticao e angulo da arma. Nao decide nada — o golpe
# cai quando a simulacao o faz cair, e a pose so o anuncia e o acompanha.
class_name StrikePose
extends RefCounted

enum Style { MELEE, RANGED, HEAVY }
enum Phase { REST, WINDUP, STRIKE, RECOVER }

## Sem golpe recente, ou sem proximo golpe: o tempo que nunca chega.
const NUNCA := INF

## A antecipacao tem de durar o tempo de um olho a ler (~250 ms, GDKeys); o golpe
## tem de ser "instantaneo"; a recuperacao devolve o corpo antes do seguinte.
const WINDUP_S := 0.24
const STRIKE_S := 0.07
const RECOVER_S := 0.26

## Quanto o corpo puxa para tras ao armar e quanto avanca ao bater, em px. O
## arco nao avanca: da um coice ao soltar a corda (o "gun kickback" da Vlambeer).
const RECUO := {Style.MELEE: 4.0, Style.RANGED: 2.0, Style.HEAVY: 9.0}
const AVANCO := {Style.MELEE: 7.0, Style.RANGED: -3.0, Style.HEAVY: 14.0}
## O esticao do golpe: enrola-se alto e estreito, bate largo e baixo.
const ESTICAO := {Style.MELEE: 0.12, Style.RANGED: 0.06, Style.HEAVY: 0.18}
const ENROLA := 0.6
## A arma: sobe para tras a armar e passa para a frente a bater (rad).
const ERGUE := {Style.MELEE: -1.0, Style.RANGED: 0.0, Style.HEAVY: -1.2}
const SEGUE := {Style.MELEE: 0.45, Style.RANGED: 0.0, Style.HEAVY: 0.6}
## O peso de uma pancada em quem a leva: o recuo e o tremor escalam com isto.
const FORCA := {Style.MELEE: 1.0, Style.RANGED: 0.6, Style.HEAVY: 1.8}
## O hitstop por corpo, em s: quem bate fica no frame do impacto e quem leva
## treme. Ligeiro 3 frames, pesado 6-7 (as Capcom de 1989-93 andam pelos 6).
const PARAGEM := {Style.MELEE: 0.05, Style.RANGED: 0.0, Style.HEAVY: 0.11}

## Daqui para cima uma tropa sem arco ainda e de longe (px); e daqui para cima
## um corpo e pesado (o `scale_tier` do §22).
const LONGE_PX := 100
const PESADO := 3
const TAGS_PESADAS: Array[StringName] = [&"siege", &"colossal", &"heavy"]


static func of_unit(dados: UnitData) -> Style:
	if dados == null:
		return Style.MELEE
	if Silhouette.of_unit(dados) == Silhouette.Mark.ARCO or dados.range_px >= LONGE_PX:
		return Style.RANGED
	return Style.HEAVY if dados.scale_tier >= PESADO else Style.MELEE


static func of_creature(dados: CreatureData) -> Style:
	if dados == null:
		return Style.MELEE
	for tag in TAGS_PESADAS:
		if dados.tags.has(tag):
			return Style.HEAVY
	return Style.HEAVY if dados.scale_tier >= PESADO else Style.MELEE


## Em que tempo do golpe esta o corpo. `desde` e o tempo desde o ultimo ataque;
## `falta` e o cooldown de quem esta engajado (NUNCA se nao esta). O golpe que ja
## caiu manda sobre a preparacao do seguinte.
static func phase(desde: float, falta: float) -> Phase:
	if desde < STRIKE_S:
		return Phase.STRIKE
	if desde < STRIKE_S + RECOVER_S:
		return Phase.RECOVER
	if falta < WINDUP_S:
		return Phase.WINDUP
	return Phase.REST


## Quanto o corpo anda na direccao do alvo (px; negativo e para tras).
static func lunge(estilo: Style, desde: float, falta: float) -> float:
	var recuo: float = -RECUO[estilo]
	var avanco: float = AVANCO[estilo]
	match phase(desde, falta):
		Phase.WINDUP:
			return recuo * _sai(_armado(falta))
		Phase.STRIKE:
			return lerpf(recuo, avanco, desde / STRIKE_S)
		Phase.RECOVER:
			return avanco * (1.0 - _volta(desde))
	return 0.0


## A escala do corpo, com os pes no chao: x na direccao do golpe, y para cima.
static func stretch(estilo: Style, desde: float, falta: float) -> Vector2:
	var s: float = ESTICAO[estilo]
	var enrolado := Vector2(1.0 - s * ENROLA, 1.0 + s * ENROLA)
	var batido := Vector2(1.0 + s, 1.0 - s)
	match phase(desde, falta):
		Phase.WINDUP:
			return Vector2.ONE.lerp(enrolado, _sai(_armado(falta)))
		Phase.STRIKE:
			return enrolado.lerp(batido, desde / STRIKE_S)
		Phase.RECOVER:
			return batido.lerp(Vector2.ONE, _volta(desde))
	return Vector2.ONE


## O angulo da arma em volta da mao (rad; positivo e para a frente).
static func swing(estilo: Style, desde: float, falta: float) -> float:
	var ergue: float = ERGUE[estilo]
	var segue: float = SEGUE[estilo]
	match phase(desde, falta):
		Phase.WINDUP:
			return ergue * _sai(_armado(falta))
		Phase.STRIKE:
			return lerpf(ergue, segue, desde / STRIKE_S)
		Phase.RECOVER:
			return segue * (1.0 - _volta(desde))
	return 0.0


static func strength(estilo: Style) -> float:
	return FORCA[estilo]


static func hold(estilo: Style) -> float:
	return PARAGEM[estilo]


## Quanto da preparacao ja passou, de 0 a 1. Um cooldown a zero e um golpe que
## cai neste tick: o corpo fica enrolado ate ele cair.
static func _armado(falta: float) -> float:
	return clampf(1.0 - falta / WINDUP_S, 0.0, 1.0)


## Sai depressa e assenta: a pose da antecipacao fica parada antes do golpe, que
## e o que a deixa ler.
static func _sai(p: float) -> float:
	return 1.0 - (1.0 - p) * (1.0 - p)


static func _volta(desde: float) -> float:
	return smoothstep(0.0, 1.0, (desde - STRIKE_S) / RECOVER_S)
