# src/sim/systems/torchlight.gd — o archote do rei, e o que vem do escuro (Q-029).
#
# O dono aprovou a fogueira e acrescentou-lhe uma coisa (Q-029, 28/09/2026): "e
# possivel adquirir um item que o jogador pode carregar com ele para ajudar a
# explorar; esse item tem limite de uso, e se o jogador explora a noite sem item
# e muito perigoso, pois podem aparecer inimigos de qualquer lugar".
#
# O item e o archote. Compra-se numa fogueira de pe com o Verbo 1 (uma moeda,
# `torch_cost`), leva-se ate `torch_max`, e acende-se sozinho quando o rei entra
# no escuro de noite: arde `torch_burn_s` segundos e acaba. No escuro e sem
# archote, de `dark_ambush_s` em `dark_ambush_s` segundos nasce uma criatura ao
# lado dele (`dark_ambush_px`), ate `dark_ambush_max` por noite. O escuro e fora
# do nucleo, fora das muralhas de pe e fora do raio de qualquer luz tua.
#
# Puro. Os numeros sao do RotProfile; quem sorteia o lado e quem invoca e o
# DarkWatch (core), porque a simulacao nao toca no RngService.
class_name Torchlight
extends RefCounted

var torches := 0
## Segundos que o archote aceso ainda arde. Zero e apagado.
var burning := 0.0

var _espera := 0.0
var _emboscadas := 0
var _perfil: RotProfile


func _init(perfil: RotProfile) -> void:
	_perfil = perfil
	_espera = perfil.dark_ambush_s


## Leva mais archotes, ate ao maximo. Devolve quantos levou.
func buy(quantos: int) -> int:
	var levados := clampi(quantos, 0, maxi(0, _perfil.torch_max - torches))
	torches += levados
	return levados


func lit() -> bool:
	return burning > 0.0


## Um passo. Verdadeiro se, agora, o escuro traz alguem ao rei.
func tick(delta: float, noite: bool, no_escuro: bool) -> bool:
	if not noite:
		burning = 0.0
		_espera = _perfil.dark_ambush_s
		_emboscadas = 0
		return false
	if not no_escuro:
		return false
	if burning > 0.0:
		burning = maxf(0.0, burning - delta)
		return false
	if torches > 0:
		torches -= 1
		burning = _perfil.torch_burn_s
		return false
	_espera -= delta
	if _espera > 0.0 or _emboscadas >= _perfil.dark_ambush_max:
		return false
	_espera = _perfil.dark_ambush_s
	_emboscadas += 1
	return true


## Se este x, na superficie, esta no escuro: fora do nucleo (`meia` a volta do
## centro), fora das muralhas de pe e fora do raio de qualquer luz tua.
static func in_dark(x: float, obras: BuildSystem, nucleo_x: float, meia: float) -> bool:
	var d := absf(x - nucleo_x)
	if d <= meia:
		return false
	for obra in obras.standing():
		if obra.band != Band.Kind.SURFACE:
			continue
		var raio := float(obra.effects.get(&"light_radius", 0.0))
		if raio > 0.0 and absf(obra.x - x) <= raio:
			return false
		var mesmo_lado := signf(obra.x - nucleo_x) == signf(x - nucleo_x)
		if obra.two_paths() and mesmo_lado and absf(obra.x - nucleo_x) >= d:
			return false
	return true


func to_dict() -> Dictionary:
	return {&"torches": torches, &"burning": burning}


func from_dict(d: Dictionary) -> void:
	torches = int(d.get(&"torches", torches))
	burning = float(d.get(&"burning", burning))
