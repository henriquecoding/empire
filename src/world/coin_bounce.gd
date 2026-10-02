# src/world/coin_bounce.gd — a fisica que se ve da moeda (§24; GB-19; o dono, 02/10).
#
# "Moeda largada — arco parabolico, som com pitch variavel, pequeno bounce e
# sombra... e a animacao mais importante do jogo." E o dono, a 02/10/2026: as
# moedas "devem ter fisica e parecer-se com o que sao", como no Kingdom.
#
# A fisica da moeda decide ONDE ela pousa, e isso e o §55 — uma obra existe quando
# uma moeda cai nela. Aqui nao se toca nisso: o x e o da simulacao, sempre. O que
# e daqui e o que o ecra acrescenta por cima do arco dela, e so na vertical e no
# rodar:
#
#   · sai da MAO, e nao do chao: o arco da simulacao comeca no chao, e o que se ve
#     comeca a altura de uma mao e desce ate ele ao longo do voo;
#   · GIRA no ar — de frente, de lado, de frente —, que e o que faz de um disco
#     dourado uma moeda e nao uma bola;
#   · RESSALTA ao pousar, cada salto uma fraccao do anterior (RESTITUICAO), ate
#     ficar abaixo de um pixel; e BALANCA no chao ate assentar de frente;
#   · e quando sai da simulacao — apanhada, ou paga a uma obra —, SOBE e apaga-se,
#     para se ver que foi levada e nao que desapareceu.
#
# Os tempos nao sao numeros novos: cada salto dura o voo da altura dele na
# gravidade que a economy.csv ja da ao arco. As alturas sao desta casa, e greybox.
class_name CoinBounce
extends RefCounted

## A altura do primeiro salto, em px, e quanto cada salto guarda do anterior.
const ALTO := 12.0
const RESTITUICAO := 0.5
## Abaixo disto um salto ja nao se ve, e a moeda fica.
const MINIMO := 1.0
## A altura da mao de onde a moeda sai, em px acima do chao.
const MAO := 30.0
## O rodar no ar, em radianos por segundo, e quanto tempo balanca depois de pousar.
const GIRO := 14.0
const ASSENTA := 0.7
## O que sobe e se apaga quando a moeda e levada: quanto sobe, e em quanto tempo.
const LEVADA := {"sobe": 14.0, "dura": 0.3}

var _gravidade: float
var _no_ar: Dictionary = {}
var _pousou: Dictionary = {}
## id -> quando se viu no ar pela primeira vez: o rodar conta dai.
var _largou: Dictionary = {}
## id -> o ultimo sitio em que se viu, para a levar a subir quando sai.
var _visto: Dictionary = {}
## [onde, quando] das que sairam ha pouco.
var _levadas: Array = []


func _init(gravidade: float) -> void:
	_gravidade = maxf(gravidade, 1.0)


## As alturas dos saltos, do primeiro ao ultimo que ainda se ve.
static func hops() -> PackedFloat32Array:
	var saltos := PackedFloat32Array()
	var alto := ALTO
	while alto >= MINIMO:
		saltos.append(alto)
		alto *= RESTITUICAO
	return saltos


## Quanto dura um salto de `alto` px: 2·√(2h/g).
func hop_duration(alto: float) -> float:
	# O 2 e o da formula, e nao balanceamento — como no CoinSystem.apex_px().
	return 2 * sqrt(2 * alto / _gravidade)


## Quanto dura o primeiro salto.
func duration() -> float:
	return hop_duration(ALTO)


## Quanto duram os saltos todos, ate a moeda ficar.
func settle_time() -> float:
	var soma := 0.0
	for alto in hops():
		soma += hop_duration(alto)
	return soma


## O que se viu desta moeda agora: a altura dela e o tempo do ecra. So salta a
## que se VIU no ar e depois no chao — uma pousada desde o principio nao caiu.
func observe(coin_id: int, altura: float, agora: float, onde := Vector2.ZERO) -> void:
	_visto[coin_id] = onde
	if altura > 0.0:
		_no_ar[coin_id] = true
		if not _largou.has(coin_id):
			_largou[coin_id] = agora
	elif _no_ar.erase(coin_id):
		_pousou[coin_id] = agora


## Quanto acima do chao desenhar esta moeda por causa dos saltos.
func offset(coin_id: int, agora: float) -> float:
	if not _pousou.has(coin_id):
		return 0.0
	var t: float = agora - _pousou[coin_id]
	for alto in hops():
		var dura := hop_duration(alto)
		if t < dura:
			return alto * sin(PI * t / dura)
		t -= dura
	return 0.0


## Quanto da mao ainda falta descer: a fraccao do voo que falta, pela velocidade
## vertical da simulacao — v0 a sair, -v0 a chegar. A altura e MAO vezes isto.
static func hand(vy: float, impulso: float) -> float:
	if impulso <= 0.0:
		return 0.0
	return clampf((vy + impulso) / (impulso + impulso), 0.0, 1.0)


## A largura da face que se ve (1 de frente, 0 de lado): gira no ar, e balanca no
## chao ate assentar de frente. Uma moeda que nunca se viu no ar esta de frente.
func face(coin_id: int, agora: float) -> float:
	if not _largou.has(coin_id):
		return 1.0
	var gira := absf(cos((agora - float(_largou[coin_id])) * GIRO))
	if _no_ar.has(coin_id):
		return gira
	var pousou: float = _pousou.get(coin_id, agora - ASSENTA)
	var resta := clampf(1.0 - (agora - pousou) / ASSENTA, 0.0, 1.0)
	if resta <= 0.0:
		_largou.erase(coin_id)
	return 1.0 - (1.0 - gira) * resta


## Esquece as que foram apanhadas ou absorvidas por uma obra, e guarda-as para as
## levar a subir (taken).
func forget_except(vivas: PackedInt32Array, agora := 0.0) -> void:
	var ficam := {}
	for coin_id in vivas:
		ficam[coin_id] = true
	for coin_id: int in _visto.keys():
		if not ficam.has(coin_id):
			_levadas.append([_visto[coin_id], agora])
	for mapa: Dictionary in [_no_ar, _pousou, _largou, _visto]:
		for coin_id: int in mapa.keys():
			if not ficam.has(coin_id):
				mapa.erase(coin_id)
	_levadas = _levadas.filter(func(l: Array) -> bool: return agora - float(l[1]) < LEVADA.dura)


## As que sairam ha pouco: [onde, quanto ja subiu (0..1)].
func taken(agora: float) -> Array:
	var saida := []
	for levada: Array in _levadas:
		saida.append([levada[0], clampf((agora - float(levada[1])) / LEVADA.dura, 0.0, 1.0)])
	return saida


func tracked() -> int:
	return _no_ar.size() + _pousou.size()
