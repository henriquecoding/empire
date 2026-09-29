# src/core/pace.gd — a que ritmo corre o tick, visto de fora (§24, Q-034).
#
# A roda do rei abranda o tempo a metade enquanto esta aberta, e isso desliga-se
# nas opcoes (Q-034, aprovada pelo dono a 28/09/2026). Nao se abranda mexendo no
# delta: o §19 corre ao passo fixo e o §42 reproduz uma partida pela semente, e
# um delta a metade dava outra partida. Abranda-se saltando passos — metade dos
# frames de fisica correm um passo, e cada passo e o mesmo passo de sempre.
#
# Nao entra no save nem na simulacao: e quantos passos por segundo de relogio de
# parede, e isso e do jogador e nao do jogo.
class_name Pace
extends RefCounted

## Passos por frame de fisica: 1 e o tempo real, 0,5 e metade.
## Uma fraccao de passo que a soma de 0,5 + 0,5 nao fecha nao pode perder um passo:
## e aritmetica de virgula, e nao ritmo.
const FOLGA := 0.0001

static var scale := 1.0
static var _acumulado := 0.0


## Verdadeiro se este frame de fisica corre um passo da simulacao.
static func due() -> bool:
	_acumulado += clampf(scale, 0.0, 1.0)
	if _acumulado + FOLGA < 1.0:
		return false
	_acumulado -= 1.0
	return true


## Volta ao tempo real, sem resto de ritmo nenhum (uma partida nova, um teste).
static func reset() -> void:
	scale = 1.0
	_acumulado = 0.0
