# src/sim/state/rot_state.gd — A Podridao como estado, tal e qual a §51 o escreve.
#
# E um RefCounted de campos e nada mais: a §51 desenha-o assim e o §45 exige que
# o que se grava seja estado e nao um no. Quem lhe mexe e o RotSystem; quem o le
# e a apresentacao, que nunca escreve.
class_name RotState
extends RefCounted

## Falso entre o amanhecer e o crepusculo: a mancha recua, nao morre (§51).
var active: bool = false

## Centro da mancha, em x de mundo. O §45 nao guarda Y para nada que ande, e uma
## mancha que anda no chao nao e excecao.
var x: float = 0.0
var width: float = 0.0

## O orcamento de invocacao, e a unica fonte de criaturas do jogo (§51).
var mass: float = 0.0

## -1 esquerda, +1 direita. O dia 12 traz duas manchas (§51) e isso e duas
## instancias, uma por lado — nao um lado "ambos" dentro de uma.
var side: int = 0

## Segundos ate a proxima invocacao. Negativo quer dizer "por armar": o sorteio
## do intervalo vem de fora, como o desvio do arco da moeda (§42, §70).
var next_summon_at: float = 0.0

## O rasto, do sitio onde nasceu ate onde ja chegou. Persiste ate ao DAWN
## seguinte e e o que o §49 le para saber que um edificio nao produz hoje.
## Segundos que ainda fica parada: a oferta "Da-me o que ja nao anda" (§75).
var paused_for: float = 0.0

var trail_from: float = 0.0
var trail_to: float = 0.0


## So tipos base, para o save (§62). O perfil e a tabela de criaturas nao entram:
## sao dados do jogo, e o jogo carrega-os outra vez.
func to_dict() -> Dictionary:
	return {
		&"active": active,
		&"x": x,
		&"width": width,
		&"mass": mass,
		&"side": side,
		&"next_summon_at": next_summon_at,
		&"paused_for": paused_for,
		&"trail_from": trail_from,
		&"trail_to": trail_to,
	}


func from_dict(d: Dictionary) -> void:
	active = d.get(&"active", active)
	x = d.get(&"x", x)
	width = d.get(&"width", width)
	mass = d.get(&"mass", mass)
	side = d.get(&"side", side)
	next_summon_at = d.get(&"next_summon_at", next_summon_at)
	paused_for = d.get(&"paused_for", paused_for)
	trail_from = d.get(&"trail_from", trail_from)
	trail_to = d.get(&"trail_to", trail_to)
