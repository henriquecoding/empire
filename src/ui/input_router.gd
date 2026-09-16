# src/ui/input_router.gd — a entrada, e o contrato do §61 numa frase: "a entrada
# nunca muda estado diretamente".
#
# Nenhuma linha deste ficheiro chama drop_coin, mata ninguem ou constroi coisa
# alguma. Cada tecla enfileira uma INTENCAO, e o inicio do tick seguinte
# consome-a. E o que faz o jogo determinista apesar de haver um humano: dada a
# mesma seed e a mesma sequencia de intencoes, a partida repete-se exatamente.
#
# O mapa de comando e o do §24, e as accoes ja estavam declaradas no
# project.godot desde o F0-02 — cinco delas sem ninguem a le-las. Este ficheiro
# e quem passou a ler.
#
# Duas coisas correm no frame e nao no tick, e e de proposito: andar e marcar
# alvo sao GESTOS, e um gesto lido a 60 Hz fixos chega sempre um bocado depois
# da mao. O que se escreve continua a ser um alvo e uma intencao — o passo 5 do
# §43 e que leva a gente — e por isso o frame nao muda o que a simulacao faz,
# so quando ela fica a saber.
#
# O que continua por ligar, e nao e esquecimento: a roda do rei espera pelos
# seis sistemas que os seus segmentos abrem (Fase 2).
class_name InputRouter
extends Node

## Uma moeda de cada vez. O §02 nao da outra unidade ao Verbo 1: a moeda E a
## unidade, e largar duas era ja uma decisao de interface.
const UMA := 1
const FONTE := &"player"

## §24: "manter para largar em continuo". Uma moeda a cada oitavo de segundo —
## depressa o bastante para encher uma obra sem martelar a tecla, devagar o
## bastante para se ver cada moeda a cair e para se parar a tempo.
const REPETICAO_S := 0.12

var _repeticao := 0.0


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pause"):
		if not SimLoop.builds.fallen(BuildSlot.NUCLEO):
			SimLoop.set_paused(SimLoop.running())
		get_viewport().set_input_as_handled()
		return
	if not SimLoop.running():
		return
	if evento.is_action_pressed(&"verb_assume"):
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed(&"mark_target"):
		SimLoop.intents.queue(IntentQueue.Kind.MARK_TARGET, {&"x": _rato_em_x()})
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not SimLoop.running():
		_repeticao = 0.0
		return
	_andar(Input.get_axis(&"move_left", &"move_right"))
	_repeticao = maxf(0.0, _repeticao - delta)
	if not Input.is_action_pressed(&"verb_drop"):
		_repeticao = 0.0
		return
	if _repeticao <= 0.0:
		_largar()
		_repeticao = REPETICAO_S


## Mover e escrever um alvo, e nao empurrar uma posicao: o passo 5 e que leva
## toda a gente, e o monarca nao e excecao (§43).
func _andar(direccao: float) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM:
		return
	if is_zero_approx(direccao):
		SimLoop.units.clear_target(SimLoop.king_id)
		return
	SimLoop.units.set_target_x(
		SimLoop.king_id,
		clampf(SimLoop.units.xs[i] + direccao * SimLoop.world_width, 0.0, SimLoop.world_width)
	)


func _largar() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM:
		return
	(
		SimLoop
		. intents
		. queue(
			IntentQueue.Kind.DROP_COIN,
			{
				&"x": SimLoop.units.xs[i],
				&"band": SimLoop.units.bands[i] as Band.Kind,
				&"amount": UMA,
				&"source": FONTE,
			}
		)
	)


func _rato_em_x() -> float:
	return get_viewport().get_camera_2d().get_global_mouse_position().x
