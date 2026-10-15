# src/world/hunt_poses.gd — o que a caca faz no ecra, quadro a quadro (ADR 0083).
#
# A Herd ja diz tudo pelo passo: quem foge vai a move_speed, quem pasta segue o vaivem a
# graze_speed e quase para nas pontas dele. Aqui le-se a velocidade que se ve: a fugir
# corre, a pastar anda, e nas pontas do vaivem — quase parado — come, e depois descansa.
# O javali provocado carrega a correr e, quando bate, ameaca (a accao propria dele).
# O javali atordoado pelo muro fica parado. A Herd anda a 30 ticks por segundo e o ecra
# a 60: um bicho cujo x nao mudou num frame nao parou — so parou se nao mudou em PARADO_S.
class_name HuntPoses
extends RefCounted

## Sem mudar de x durante isto, o bicho esta parado (em segundos: quatro ticks da Herd).
const PARADO_S := 0.15
## Abaixo desta fraccao do graze_speed, o bicho come; acima desta, corre.
const DEVAGAR := 0.3
const DEPRESSA := 1.25
## Um frame do ecra (60 por segundo): o passo mais curto que se mede.
const FRAME_MIN_S := 1.0 / 60.0
const IDLE := &"idle"
const WALK := &"walk"
const RUN := &"run"
const FEED := &"feed"
const SPECIAL := &"special"
const X := 0
const QUANDO := 1
const VELOCIDADE := 2

static var _relogio := AnimClock.new()
static var _passos: Dictionary = {}


## O quadro do bicho da toca `toca`, que esta em `x`, em `agora` segundos do ecra.
static func frame_of(
	perfil: StringName, toca: float, x: float, dados: WildlifeData, manada: Herd, agora: float
) -> int:
	var golpe := AnimatedArt.seconds(perfil, SPECIAL)
	var accao := action_of(dados, _speed(toca, x, agora), manada, toca, golpe)
	if accao == SPECIAL:
		var desde_golpe := dados.attack_interval - float(manada.cooldowns.get(toca, 0.0))
		return AnimatedArt.frame(perfil, SPECIAL, desde_golpe)
	var desde := _relogio.play(toca, accao, agora)
	var comer := AnimatedArt.seconds(perfil, FEED)
	if accao == FEED and desde >= comer:
		return AnimatedArt.frame(perfil, IDLE, desde - comer)
	return AnimatedArt.frame(perfil, accao, agora + toca if accao != FEED else desde)


## A accao de um bicho que anda a `velocidade` px/s; `golpe_s` e quanto dura a ameaca do
## javali (a accao propria dele), que se ve desde que ele bate (puro, para o teste).
static func action_of(
	dados: WildlifeData, velocidade: float, manada: Herd, toca: float, golpe_s: float
) -> StringName:
	if float(manada.stunned.get(toca, 0.0)) > 0.0:
		return IDLE
	var falta := float(manada.cooldowns.get(toca, 0.0))
	if manada.provoked.has(toca) and falta > 0.0 and dados.attack_interval - falta < golpe_s:
		return SPECIAL
	if velocidade > dados.graze_speed * DEPRESSA:
		return RUN
	if velocidade > dados.graze_speed * DEVAGAR:
		return WALK
	return FEED


## Esquece as tocas que ja nao tem bicho. So se lembram as que se viram, e uma toca que
## perde o bicho volta a ter outro: so ha que podar quando ha mais lembradas do que tocas.
static func keep_only(tocas: Array[float]) -> void:
	if _passos.size() <= tocas.size():
		return
	var vivas := {}
	for toca in tocas:
		vivas[toca] = true
	_relogio.keep_only(vivas)
	for toca: float in _passos.keys():
		if not vivas.has(toca):
			_passos.erase(toca)


## A velocidade que se ve: a ultima mudanca de x a dividir pelo tempo que levou.
static func _speed(toca: float, x: float, agora: float) -> float:
	var passo: Array = _passos.get(toca, [])
	if passo.is_empty() or agora < float(passo[QUANDO]):  # um jogo novo: o relogio voltou a 0
		_passos[toca] = [x, agora, 0.0]
		return 0.0
	if not is_equal_approx(float(passo[X]), x):
		var dt := maxf(agora - float(passo[QUANDO]), FRAME_MIN_S)
		passo[VELOCIDADE] = absf(x - float(passo[X])) / dt
		passo[X] = x
		passo[QUANDO] = agora
	elif agora - float(passo[QUANDO]) > PARADO_S:
		passo[VELOCIDADE] = 0.0
	return float(passo[VELOCIDADE])
