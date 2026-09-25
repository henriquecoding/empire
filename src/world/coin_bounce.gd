# src/world/coin_bounce.gd — o pequeno bounce da moeda (§24; GB-19).
#
# "Moeda largada — arco parabolico, som com pitch variavel, pequeno bounce e
# sombra... e a animacao mais importante do jogo." O GB-09 deixou o bounce de
# fora por uma boa razao: a fisica da moeda decide ONDE ela pousa, e isso e o
# §55 — uma obra existe quando uma moeda cai nela. Aqui nao se toca nisso. O
# salto e so vertical e so no ecra: a moeda pousa onde a simulacao a pousou, e
# da ali um pulo pequeno antes de ficar.
#
# A duracao nao e um numero novo: e o voo de um salto de ALTO px na gravidade que
# a economy.csv ja da ao arco. So a altura e desta casa, e e greybox.
class_name CoinBounce
extends RefCounted

## A altura do salto, em px. Um sexto do apice do arco (23 px): pequeno, como o
## §24 o pede, e ainda maior do que o raio da moeda.
const ALTO := 4.0

var _gravidade: float
var _no_ar: Dictionary = {}
var _pousou: Dictionary = {}


func _init(gravidade: float) -> void:
	_gravidade = maxf(gravidade, 1.0)


## Quanto dura o salto: 2·√(2h/g).
func duration() -> float:
	# O 2 e o da formula, e nao balanceamento — como no CoinSystem.apex_px().
	return 2 * sqrt(2 * ALTO / _gravidade)


## O que se viu desta moeda agora: a altura dela e o tempo do ecra. So salta a
## que se VIU no ar e depois no chao — uma pousada desde o principio nao caiu.
func observe(coin_id: int, altura: float, agora: float) -> void:
	if altura > 0.0:
		_no_ar[coin_id] = true
	elif _no_ar.erase(coin_id):
		_pousou[coin_id] = agora


## Quanto acima do chao desenhar esta moeda por causa do salto.
func offset(coin_id: int, agora: float) -> float:
	if not _pousou.has(coin_id):
		return 0.0
	var t: float = agora - _pousou[coin_id]
	if t >= duration():
		_pousou.erase(coin_id)
		return 0.0
	return ALTO * sin(PI * t / duration())


## Esquece as que foram apanhadas ou absorvidas por uma obra.
func forget_except(vivas: PackedInt32Array) -> void:
	var ficam := {}
	for coin_id in vivas:
		ficam[coin_id] = true
	for mapa: Dictionary in [_no_ar, _pousou]:
		for coin_id: int in mapa.keys():
			if not ficam.has(coin_id):
				mapa.erase(coin_id)


func tracked() -> int:
	return _no_ar.size() + _pousou.size()
