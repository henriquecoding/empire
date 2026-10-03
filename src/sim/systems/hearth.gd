# src/sim/systems/hearth.gd — a lareira do nucleo, que afasta a Podridao e custa (Q-190).
#
# O dono, a 03/10/2026: "ha um custo para manter ela acesa, nao e barato, o jogador tem
# que conseguir recursos e administrar bem seu dinheiro para manter isso funcionando".
# Ao crepusculo a lareira come o preco da noite da bolsa do monarca que reina; paga,
# arde ate a alvorada e faz recuar, a volta do nucleo, quem tem a massa que ela aguenta
# (ADR 0034). Sem as moedas, fica apagada nessa noite: nao alumia nem afasta ninguem.
class_name Hearth
extends RefCounted

var lit := false


## Ao crepusculo. Devolve as moedas que gastou: o preco todo, ou nada.
func kindle(bolsa: int, custo: int) -> int:
	lit = custo <= 0 or bolsa >= custo
	return custo if lit and custo > 0 else 0


func dawn() -> void:
	lit = false


## A zona do LightWard a volta do nucleo, ou vazia se apagada.
func zone(nucleo_x: float, raio: float, repele: int, abranda: float) -> Vector4:
	if not lit or raio <= 0.0:
		return Vector4.ZERO
	return Vector4(nucleo_x - raio, nucleo_x + raio, float(repele), abranda)
