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
## unidade, e largar duas era ja uma decisao de interface. Largar em CONTINUO
## (§24) nao quebra isto — continuam a sair uma a uma, so que sozinhas.
const UMA := 1
const FONTE := &"player"

## §24: "manter para largar em continuo". Quanto falta para a moeda seguinte
## sair. O RITMO nao esta aqui: e o `coin_drop_repeat_s` da `economy.csv`, pela
## regra 3 do AGENTS.md — um numero que se afina em playtest vive em data/, como
## a gravidade e a dispersao do arco que estao ao lado dele (Q-083).
var _repeticao := 0.0
var _curva: EconomyCurve
## Se o gesto de marcar alvo esta premido. Um gatilho e analogico e emite um
## evento por cada posicao do caminho; sem isto um puxao marcava seis vezes.
var _marcar := false


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pause"):
		if not SimLoop.builds.fallen(BuildSlot.NUCLEO):
			SimLoop.set_paused(SimLoop.running())
		get_viewport().set_input_as_handled()
		return
	if not SimLoop.running():
		return
	var impulso := wheel_choice(evento, Input.is_action_pressed(&"king_wheel"))
	if impulso >= 0:
		var ids := SimLoop.field.crown.ids()
		if impulso < ids.size():
			SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": ids[impulso]})
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"verb_assume"):
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
		get_viewport().set_input_as_handled()
	elif evento.is_action(&"mark_target"):
		var marca := rising(evento, _marcar)
		_marcar = held(evento, _marcar)
		if marca:
			SimLoop.intents.queue(IntentQueue.Kind.MARK_TARGET, {&"x": _alvo_em_x(evento)})
		get_viewport().set_input_as_handled()


## §24: "Tab (manter) -> 1-5". Com a roda premida, a tecla de numero escolhe o
## impulso (0 e o primeiro); qualquer outra coisa e -1.
static func wheel_choice(evento: InputEvent, roda: bool) -> int:
	if not roda or not evento is InputEventKey or not evento.pressed or evento.echo:
		return -1
	var tecla: int = (evento as InputEventKey).physical_keycode
	return tecla - KEY_1 if tecla >= KEY_1 and tecla <= KEY_9 else -1


## Verdadeiro no instante em que o gesto de marcar comeca, e so nesse (GB-11).
static func rising(evento: InputEvent, estava: bool) -> bool:
	return held(evento, estava) and not estava


## Se o gesto de marcar fica premido depois deste evento. O eco do teclado nao
## e um gesto: `is_action_pressed` deixa-o de fora por omissao.
static func held(evento: InputEvent, estava: bool) -> bool:
	if not evento.is_action(&"mark_target"):
		return estava
	return evento.is_action_pressed(&"mark_target")


## O rato aponta; o comando nao tem cursor. O §24 da o gatilho direito ao comando
## e o botao direito ao rato, e so um dos dois sabe onde esta o bicho no ecra.
static func aims_with_cursor(evento: InputEvent) -> bool:
	return evento is InputEventMouse


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
		# Nunca mais depressa do que um frame: com o intervalo a zero — um CSV
		# mal preenchido — isto virava uma torneira e esvaziava o saco antes de
		# a primeira moeda chegar ao chao.
		_repeticao = maxf(_intervalo(), delta)


## O ritmo do continuo, lido a pedido e na primeira utilizacao (AGENTS.md, regra
## 8b): este no e filho da cena de jogo e o _ready() dele corre ANTES do dela —
## ou seja, antes do Registry.load_all() que ela chama.
func _intervalo() -> float:
	if _curva == null:
		_curva = SimFactory.curve()
	return _curva.coin_drop_repeat_s


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


## Onde o gesto aponta. Sem cursor, e o rei: o Verbs.mark escolhe o bicho mais
## perto deste x, e o mais perto de quem joga e o que o esta a ameacar (Q-086).
func _alvo_em_x(evento: InputEvent) -> float:
	if aims_with_cursor(evento):
		return get_viewport().get_camera_2d().get_global_mouse_position().x
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return SimLoop.units.xs[i] if i != UnitSystem.NENHUM else SimLoop.core_x
