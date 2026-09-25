# src/sim/systems/dawn_cascade.gd — as tropas saem dos postos atras da luz (§24).
#
# "Amanhecer — sino + varrimento de luz da esquerda para a direita a 900 px/s +
# as tropas a sairem dos postos em cascata, nao todas ao mesmo tempo." O passo 3
# do §43 da o alvo do dia a toda a gente no mesmo tick; a cascata e o passo 5 a
# deixar sair primeiro quem a luz ja apanhou (GB-21, Q-089).
#
# Nao guarda estado nenhum: a frente e o relogio vezes a velocidade do
# clock.csv, e o relogio ja esta no save. Uma partida retomada a meio de uma
# alvorada solta as mesmas tropas no mesmo tick que a continua (§61).
class_name DawnCascade
extends RefCounted


## Onde vai a frente da luz, em x de mundo. INF fora da alvorada — ninguem
## espera — e com a velocidade a zero, que desliga a cascata. A alvorada comeca
## no segundo zero do dia (§48), e por isso o decorrido do dia e o dela.
static func front(fase: int, decorrido: float, velocidade: float) -> float:
	if fase != GameClock.Phase.DAWN or velocidade <= 0.0:
		return INF
	return decorrido * velocidade
