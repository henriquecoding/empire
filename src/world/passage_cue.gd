# src/world/passage_cue.gd — onde o Verbo 2 pega, dito no sitio (§11, §24, §25).
#
# O §25 poe a passagem ao minuto 10:00 — "encontras a passagem para o corte de
# solo... e o momento em que o jogo deixa de ser Kingdom" — e o §32 mede-a: se a
# mediana de underground_discovered passar dos 20 minutos, "a passagem esta mal
# sinalizada e a tua maior diferenciacao esta a ser perdida por metade dos
# jogadores". Ate aqui a passagem era uma risca de 8 px, e nada dizia que o E
# fazia alguma coisa ali. A Q-066 ja o previa: se falhasse, era a sinalizacao.
#
# E o mesmo contrato do PriceTag, e pela mesma razao: aparece EXACTAMENTE onde o
# gesto pega — a conta e o Verbs.destination(), a mesma do assume() — e aponta
# para onde ele leva. Sem palavra e sem tecla escrita (§24: "um icone, nunca uma
# palavra"): uma seta, para baixo quando se desce e para cima quando se sobe.
#
# Pisca devagar, como a silhueta fantasma do minuto 3:30 do §25 — "a silhueta e o
# convite". Nao leva luz (Q-080): e um instrumento, e vai-se com o ART-01. A cor e
# a da risca da passagem, mais clara — matiz 195° e saturacao 0,34 —, e fica fora
# da faixa das duas frias do §80 (200° a 290°, acima de 0,35) mesmo a meio da noite.
class_name PassageCue
extends RefCounted

## O indice do bico no poligono da seta. Os outros dois pontos sao a base.
const BICO := 0

## Geometria de greybox, como as alturas do Silhouette. ACIMA poe a seta por cima
## da coroa do rei (escala 3, §25) — e o sitio para onde o olho ja esta a olhar.
const ACIMA := 84.0
const LARGO := 18.0
const ALTO := 15.0
const HASTE := 10.0
const TRACO := 4.0
const MEIA := 0.5
## O pulso: quanto tempo leva um piscar, e ate onde apaga. Nunca apaga de todo —
## um sinal que desaparece metade do tempo e um sinal que se perde metade do tempo.
const PULSO_RAD_S := 5.0
const MINIMO := 0.45
const COR := Color(0.62, 0.86, 0.94)


## A seta da faixa do rei, se ele estiver onde o Verbo 2 pega. `tempo` e o do
## ecra, e nao o do jogo: o pulso e derivado e descartavel (§45).
static func draw_on(canvas: CanvasItem, faixa: Band.Kind, tempo: float) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM or int(SimLoop.units.bands[i]) != int(faixa):
		return
	var para := Verbs.destination(SimLoop.units, SimLoop.king_id, SimLoop.passages)
	if para == Verbs.NENHUMA:
		return
	var x := nearest(SimLoop.units.xs[i], SimLoop.passages)
	var centro := Vector2(x, WorldPalette.ground_of(int(faixa)) - ACIMA)
	var cor := COR
	cor.a = lerpf(MINIMO, 1.0, MEIA + MEIA * sin(tempo * PULSO_RAD_S))
	var seta := arrow(centro, int(faixa), para)
	var sentido := signf(seta[BICO].y - centro.y)
	var cauda := centro - Vector2(0.0, sentido * (ALTO * MEIA + HASTE))
	canvas.draw_line(cauda, centro, cor, TRACO)
	canvas.draw_colored_polygon(seta, cor)


## Um triangulo com o bico virado para a faixa de destino. As faixas crescem para
## baixo no enum como crescem no ecra (§11), e por isso o sinal da diferenca e o
## sentido do bico.
static func arrow(centro: Vector2, de: int, para: int) -> PackedVector2Array:
	var sentido := signf(float(para - de))
	var bico := centro + Vector2(0.0, sentido * ALTO * MEIA)
	var base := centro - Vector2(0.0, sentido * ALTO * MEIA)
	var lado := Vector2(LARGO * MEIA, 0.0)
	return PackedVector2Array([bico, base - lado, base + lado])


## A passagem mais perto deste x — a que o gesto apanha.
static func nearest(x: float, passagens: PackedFloat32Array) -> float:
	var melhor := x
	var perto := INF
	for passagem in passagens:
		if absf(passagem - x) < perto:
			perto = absf(passagem - x)
			melhor = passagem
	return melhor
