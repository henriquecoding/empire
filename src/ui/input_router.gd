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
# O que continua por ligar, e nao e esquecimento: manter para largar em continuo
# (§24) espera pelo BuildSystem a aceitar pagamento por nivel de uma vez; a roda
# do rei espera pelos seis sistemas que os seus segmentos abrem (Fase 2).
class_name InputRouter
extends Node

## Uma moeda de cada vez. O §02 nao da outra unidade ao Verbo 1: a moeda E a
## unidade, e largar duas era ja uma decisao de interface.
const UMA := 1
const FONTE := &"player"


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pause"):
		if not SimLoop.builds.fallen(BuildSlot.NUCLEO):
			SimLoop.set_paused(SimLoop.running())
		get_viewport().set_input_as_handled()
		return
	if not SimLoop.running():
		return
	if evento.is_action_pressed(&"verb_drop"):
		_largar()
	elif evento.is_action_pressed(&"verb_assume"):
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	elif evento.is_action_pressed(&"mark_target"):
		SimLoop.intents.queue(IntentQueue.Kind.MARK_TARGET, {&"x": _rato_em_x()})


func _physics_process(_delta: float) -> void:
	if not SimLoop.running():
		return
	_andar(Input.get_axis(&"move_left", &"move_right"))


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
