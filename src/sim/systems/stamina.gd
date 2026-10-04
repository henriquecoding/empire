# src/sim/systems/stamina.gd — o folego de quem corre a pe (Q-193).
#
# O dono, a 03/10/2026: "so corre ao manter o botao apertado e assim como Kingdom tem um
# limite, depois de certo periodo fica cansado e tem que andar normalmente ate se
# recuperar, o imperador evoluido tem a resistencia maior tambem". Correr gasta um
# segundo de folego por segundo; esgotado, quem se conduz fica cansado e so volta a
# correr com o folego cheio. Andar recupera-o, e parar mais depressa, como a montaria do
# Kingdom a pastar (Q-208). Os numeros vem do economy.csv.
class_name Stamina
extends RefCounted

## Ainda nao se correu: o primeiro passo enche o folego com o limite de quem corre.
const POR_MEDIR := -1.0

## Os segundos de corrida que restam.
var left: float = POR_MEDIR
## Esgotou o folego: anda ate o recuperar todo.
var tired := false
## A tecla de correr, com quem se conduz a andar: escrita pela entrada, lida no passo.
var wants := false
## Quem se conduz esta parado: recupera ao ritmo de quem descansa (Q-208).
var still := false
var rested := false
var boost := 1.0


## Um passo. `quer` e a tecla de correr com quem se conduz a andar. `cap` e quantos
## segundos se corre com o folego cheio; `refill` quantos se leva a enche-lo do zero.
## Devolve se corre neste passo.
func step(quer: bool, dt: float, cap: float, refill: float, rest_mult := 1.0) -> bool:
	if cap <= 0.0:
		return quer
	if left == POR_MEDIR:
		left = cap
	if quer and not tired and rested:
		boost = rest_mult
		left = cap * boost
		rested = false
	var limit := cap * boost
	var recovering := left < limit
	var corre := quer and not tired
	if corre:
		left = maxf(0.0, left - dt)
		if left <= 0.0:
			tired = true
			boost = 1.0
	else:
		left = minf(limit, left + (limit / refill * dt if refill > 0.0 else limit))
		if left >= limit:
			tired = false
			if still and recovering:
				rested = true
	return corre


## Quanto folego resta, de 0 a 1 — para o HUD.
func ratio(cap: float) -> float:
	if cap <= 0.0 or left == POR_MEDIR:
		return 1.0
	return clampf(left / (cap * boost), 0.0, 1.0)


func to_dict() -> Dictionary:
	return {&"left": left, &"tired": tired, &"rested": rested, &"boost": boost}


func from_dict(saved: Dictionary) -> void:
	left = float(saved.get(&"left", POR_MEDIR))
	tired = bool(saved.get(&"tired", false))
	rested = bool(saved.get(&"rested", false))
	boost = maxf(1.0, float(saved.get(&"boost", 1.0)))
	wants = false
	still = false
