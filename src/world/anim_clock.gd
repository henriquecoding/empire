# src/world/anim_clock.gd — o que cada corpo esta a fazer no ecra, e desde quando (ADR 0083).
#
# Uma accao que nao se repete (o susto, o bicar, o roubo) tem de comecar no quadro 0 no
# instante em que comeca, e nao a meio do ciclo do relogio do ecra. Cada desenhador tem o
# seu: a chave e quem ele desenha (o id da criatura, a toca do bicho). Descartavel (§45).
class_name AnimClock
extends RefCounted

const ACCAO := 0
const DESDE := 1

var _vistos: Dictionary = {}


## Os segundos que `chave` leva em `accao` em `agora`; uma accao nova comeca agora. Um
## relogio que andou para tras (a cena recarregada num jogo novo) tambem e um comeco.
func play(chave: Variant, accao: StringName, agora: float) -> float:
	var visto: Array = _vistos.get(chave, [])
	if visto.is_empty() or visto[ACCAO] != accao or agora < float(visto[DESDE]):
		visto = [accao, agora]
		_vistos[chave] = visto
	return maxf(0.0, agora - float(visto[DESDE]))


## A accao que `chave` mostrou da ultima vez, ou vazio.
func showing(chave: Variant) -> StringName:
	var visto: Array = _vistos.get(chave, [])
	return visto[ACCAO] if not visto.is_empty() else &""


## Esquece quem nao esta em `vivos`.
func keep_only(vivos: Dictionary) -> void:
	for chave: Variant in _vistos.keys():
		if not vivos.has(chave):
			_vistos.erase(chave)
