# src/world/volley.gd — as flechas que se veem voar (§07, §24, §50).
#
# Ate aqui um arqueiro a 200 px matava sem se ver nada a sair dele: o acerto era
# decidido no tick e o flash acendia-se no alvo no mesmo frame. E a primeira
# coisa da "Art of Screenshake" — o projectil tem de se ver — e a do Kingdom:
# a noite le-se pelas flechas no ar.
#
# A simulacao continua a mandar: o `attack_launched` traz o acerto JA decidido
# (§50: "a apresentacao nunca decide se acertou"). O voo e so do ecra — sai do
# arco, faz um arco e:
#
#   acertou  persegue o alvo (o acerto ja esta decidido) e, ao chegar, entrega o
#            golpe a quem o mostra: o flash, a particula e o empurrao acendem-se
#            quando a flecha chega, e nao quando foi solta
#   falhou   cai ao lado do alvo e fica cravada no chao um bocado — a falha
#            tambem se le, e o §07 diz que o arqueiro em campo falha 2 em 3
#
# Puro como o CoinBounce: o tempo e o sitio dos alvos entram de fora, e por isso
# mede-se sem frames nem noite.
class_name Volley
extends RefCounted

## Px por segundo: 200 px (o alcance do arqueiro) em ~0,4 s.
const VELOCIDADE := 520.0
const VOO := Vector2(0.16, 0.42)
## O arco do voo: uma fraccao da distancia, com tecto.
const ARCO := {"fraccao": 0.22, "tecto": 46.0}
## Quanto tempo uma flecha falhada fica cravada, e quantas cabem no chao.
const CRAVADA_S := 1.4
const CRAVADAS_MAX := 64
const SOME_S := 0.4
## A flecha, em px: haste, rasto de velocidade e o quanto se enterra.
const FLECHA := {"haste": 9.0, "rasto": 16.0, "enterra": 0.4, "traco": 1.0, "pena": 3.0}
const HASTE := Color(0.93, 0.88, 0.76)
const PENA := Color(0.78, 0.31, 0.24)
const RASTO := Color(0.93, 0.88, 0.76, 0.35)

## As chaves de uma chegada.
const ALVO := &"alvo"
const SENTIDO := &"sentido"

var _voo: Array[Dictionary] = []
var _cravadas: Array[Dictionary] = []


## Uma flecha sai de `de` para o alvo em `para`. Uma falha vai para `para` mais
## `desvio` (sorteado por quem chama, no fluxo visual), e por isso quem chama da
## a uma falha o `para` no CHAO, que e onde ela se crava.
func launch(
	de: Vector2, alvo_id: int, para: Vector2, acertou: bool, agora: float, desvio: float
) -> void:
	var dur := clampf(absf(para.x - de.x) / VELOCIDADE, VOO.x, VOO.y)
	(
		_voo
		. append(
			{
				"de": de,
				"alvo": alvo_id,
				"para": para if acertou else para + Vector2(desvio, 0.0),
				"t0": agora,
				"dur": dur,
				"hit": acertou,
			}
		)
	)


func flying() -> int:
	return _voo.size()


func stuck() -> int:
	return _cravadas.size()


## Avanca o voo. `onde` diz onde esta AGORA um alvo (Callable(id) -> Vector2, ou
## Vector2.INF se ja nao esta): uma flecha que acerta segue-o. Devolve as
## chegadas que acertaram, para quem as mostra.
func step(agora: float, onde: Callable) -> Array[Dictionary]:
	var chegadas: Array[Dictionary] = []
	var vivas: Array[Dictionary] = []
	for seta in _voo:
		if seta.hit:
			var aqui: Vector2 = onde.call(seta.alvo)
			if aqui != Vector2.INF:
				seta.para = aqui
		if agora - float(seta.t0) < float(seta.dur):
			vivas.append(seta)
			continue
		if seta.hit:
			chegadas.append({ALVO: seta.alvo, SENTIDO: ImpactView.aim(seta.de.x, seta.para.x)})
		else:
			_cravar(seta, agora)
	_voo = vivas
	_cravadas = _cravadas.filter(func(c: Dictionary) -> bool: return agora - c.t0 < CRAVADA_S)
	return chegadas


## Onde esta uma flecha, a fraccao `u` do voo: uma parabola entre os dois pontos.
static func point(de: Vector2, para: Vector2, u: float) -> Vector2:
	var alto := minf(absf(para.x - de.x) * ARCO.fraccao, ARCO.tecto)
	return de.lerp(para, u) - Vector2(0.0, alto * 4.0 * u * (1.0 - u))


## Para onde aponta, que e a tangente da parabola.
static func heading(de: Vector2, para: Vector2, u: float) -> Vector2:
	var alto := minf(absf(para.x - de.x) * ARCO.fraccao, ARCO.tecto)
	var d := (para - de) - Vector2(0.0, alto * 4.0 * (1.0 - 2.0 * u))
	return d.normalized() if d.length() > 0.0 else Vector2.RIGHT


func draw(canvas: CanvasItem, agora: float) -> void:
	for seta in _voo:
		var u := clampf((agora - float(seta.t0)) / float(seta.dur), 0.0, 1.0)
		var ponta := point(seta.de, seta.para, u)
		var rumo := heading(seta.de, seta.para, u)
		canvas.draw_line(ponta - rumo * FLECHA.rasto, ponta, RASTO, FLECHA.traco)
		_flecha(canvas, ponta, rumo, 1.0)
	for c in _cravadas:
		var resta := CRAVADA_S - (agora - float(c.t0))
		_flecha(canvas, c.ponta, c.rumo, clampf(resta / SOME_S, 0.0, 1.0))


## A corda puxada: a flecha encostada ao arco, a recuar com a preparacao. E a
## antecipacao de quem dispara — o aviso de que uma flecha vai sair.
static func draw_nocked(canvas: CanvasItem, mao: Vector2, lado: float, puxado: float) -> void:
	var ponta := mao + Vector2(lado * FLECHA.haste * (1.0 - puxado * 0.5), 0.0)
	_flecha(canvas, ponta, Vector2(lado, 0.0), 1.0)


static func _flecha(canvas: CanvasItem, ponta: Vector2, rumo: Vector2, alfa: float) -> void:
	var cauda := ponta - rumo * FLECHA.haste
	canvas.draw_line(cauda, ponta, Color(HASTE, alfa), FLECHA.traco + 1.0)
	canvas.draw_line(cauda, cauda + rumo * FLECHA.pena, Color(PENA, alfa), FLECHA.traco + 1.0)


func _cravar(seta: Dictionary, agora: float) -> void:
	var rumo := heading(seta.de, seta.para, 1.0)
	var ponta: Vector2 = seta.para + rumo * FLECHA.haste * FLECHA.enterra
	_cravadas.append({"ponta": ponta, "rumo": rumo, "t0": agora})
	if _cravadas.size() > CRAVADAS_MAX:
		_cravadas.pop_front()
