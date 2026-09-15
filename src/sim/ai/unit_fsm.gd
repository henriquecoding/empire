# src/sim/ai/unit_fsm.gd — a maquina de estados de cinco casos (§52, camada B).
#
# Cinco estados, e nada de behavior trees para tropas comuns. A §52 e explicita
# sobre porque: "e o algoritmo do Kingdom, e a previsibilidade e a
# funcionalidade". Num jogo de controlo indireto o jogador precisa de antecipar
# para onde vao as suas tropas; uma IA que otimiza melhor mas surpreende e pior.
#
# Puro e sem estado: recebe o que sabe, devolve o estado seguinte. E por isso
# que se testa sem unidades, sem mundo e sem motor.
class_name UnitFsm
extends RefCounted

enum State { GOTO, WORK, FIGHT, FLEE, DEAD }

## Quantas unidades reavaliam por tick: uma em cada AI_SLICE (§47, §52). Nao se
## afina em playtest — e desempenho, e a §63 diz que e o primeiro numero a mexer
## quando a simulacao estoura o orcamento.
const AI_SLICE := 6


## Verdadeiro se esta unidade decide neste tick. A §52 da a formula tal e qual:
## uma unidade decide cinco vezes por segundo a 30 Hz, o que e impercetivel, e
## corta a IA para um sexto do custo. O movimento e o combate continuam a correr
## todos os ticks — e so a DECISAO que e fatiada.
static func decides(unit_id: int, tick: int) -> bool:
	return unit_id % AI_SLICE == tick % AI_SLICE


## O estado seguinte. `chegou` e verdadeiro quando a unidade esta exatamente no
## alvo — o movimento aterra la, e por isso nao ha tolerancia nenhuma a inventar.
##
## Os casos que faltam sao os que os seus tickets trazem, e nao esquecimentos:
## FIGHT entra com o CombatSystem (F1-07), FLEE com a moral e o raio do rei
## (F1-12), e a ressurreicao ate ao amanhecer com o ClassSystem.
static func next(atual: State, vida: int, tem_alvo: bool, chegou: bool) -> State:
	if vida <= 0:
		return State.DEAD
	if atual == State.DEAD:
		# So se sai de DEAD por ressurreicao, e ressuscitar e repor a vida —
		# nao e uma transicao que a FSM possa decidir sozinha.
		return State.DEAD
	if atual == State.FIGHT or atual == State.FLEE:
		return atual
	if not tem_alvo:
		return State.WORK
	return State.WORK if chegou else State.GOTO


## O nome do estado, para registos e para o ecra de depuracao.
static func name_of(estado: State) -> StringName:
	return [&"GOTO", &"WORK", &"FIGHT", &"FLEE", &"DEAD"][int(estado)]
