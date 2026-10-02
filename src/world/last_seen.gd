# src/world/last_seen.gd — o ultimo desenho de cada criatura (§07, §50).
#
# O `creature_died` traz o x, e a criatura ja saiu das colunas no tick em que
# morreu: a forma, a cor e a pele dela so existem no ultimo frame em que foi
# desenhada. Guarda-se aqui, para a morte (DeathBurst) a desfazer no sitio onde
# estava, e para uma flecha (BattleView) seguir o corpo que se ve. Saiu do
# CombatFx para ele caber nas 250 linhas. Descartavel (§45).
class_name LastSeen
extends RefCounted

## [quando, caixa, forma, cor, pele, frente]; a pele e [perfil, para onde olha,
## tinta, se estava a luz], ou vazia quando a criatura nao e um sprite; a frente e
## para onde olhava, para a morte a desfazer virada para o mesmo lado.
const QUANDO := 0
const CAIXA := 1
const FORMA := 2
const COR := 3
const PELE := 4
const FRENTE := 5
const PELE_PERFIL := 0
const PELE_FRENTE := 1
const PELE_TINTA := 2
const PELE_ACESO := 3

static var _vistos: Dictionary = {}


static func reset() -> void:
	_vistos.clear()


## Esquece quem nao se ve desde antes de `t`.
static func forget_before(t: float) -> void:
	for id in _vistos.keys():
		if float(_vistos[id][QUANDO]) < t:
			_vistos.erase(id)


static func remember(id: int, caixa: Rect2, forma: int, cor: Color, frente := 1.0) -> void:
	_vistos[id] = [CombatFx.clock, caixa, forma, cor, [], frente]


## A pele de uma criatura, para a morte a desfazer com a animacao `die` dela em
## vez do contorno.
static func dress(id: int, perfil: StringName, frente: float, tinta: Color, aceso: bool) -> void:
	if _vistos.has(id):
		_vistos[id][PELE] = [perfil, frente, tinta, aceso]


static func seen(id: int) -> Array:
	return _vistos.get(id, [])
