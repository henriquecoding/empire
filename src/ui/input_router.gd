class_name InputRouter
extends Node

## Uma moeda de cada vez. O §02 nao da outra unidade ao Verbo 1: a moeda E a
## unidade, e largar duas era ja uma decisao de interface. Largar em CONTINUO
## (§24) nao quebra isto — continuam a sair uma a uma, so que sozinhas.
const UMA := 1
const FONTE := &"player"
## Quanto o stick tem de sair do centro para apontar um segmento. E a tolerancia
## do gesto, como o deadzone do project.godot — nao e balanceamento.
const RODA_ZONA := 0.5

## O segmento que o stick aponta com a roda premida, ou -1. O Inspector marca-o.
static var pointed: int = -1

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
	if ClassSelection.active or TravelPanel.active:
		return
	if evento.is_action_pressed(&"pause"):
		if not Defeat.happened():
			SimLoop.set_paused(SimLoop.running())
		get_viewport().set_input_as_handled()
		return
	if not SimLoop.running():
		return
	var impulso := wheel_choice(evento, Input.is_action_pressed(&"king_wheel"))
	if impulso >= 0:
		_impulso(impulso)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"verb_assume"):
		if TravelWatch.at_gate():
			get_tree().call_group(&"travel_menu", &"open")
		else:
			SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
		get_viewport().set_input_as_handled()


## §24: "Tab (manter) -> 1-5". Com a roda premida, a tecla de numero escolhe o
## impulso (0 e o primeiro); qualquer outra coisa e -1.
static func wheel_choice(evento: InputEvent, roda: bool) -> int:
	if not roda or not evento is InputEventKey or not evento.pressed or evento.echo:
		return -1
	var tecla: int = (evento as InputEventKey).physical_keycode
	return tecla - KEY_1 if tecla >= KEY_1 and tecla <= KEY_9 else -1


## §24: "selecionar e apontar o stick e largar". O segmento para onde `v` aponta,
## a contar do de cima e no sentido do relogio, entre `n`; -1 perto do centro.
static func wheel_segment(v: Vector2, n: int) -> int:
	if n <= 0 or v.length() < RODA_ZONA:
		return -1
	var angulo := fposmod(atan2(v.x, -v.y), TAU)
	return roundi(angulo / (TAU / n)) % n


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
	if TravelPanel.active:
		_andar(0.0)
		_repeticao = 0.0
		return
	if not SimLoop.running():
		_repeticao = 0.0
		return
	# Correr (Q-149, Q-169): quem se conduz corre ao king_run_mult; montado, o cavalo anda
	# e galopa aos dele.
	var correr := Input.is_action_pressed(&"king_run")
	var a_pe := _curva_lida().king_run_mult
	SimLoop.units.piloted_pace = SimLoop.field.mount.pace(Assume.driven(), correr, a_pe)
	# Com a roda premida o stick aponta e o rei para: a roda "e o corpo dele" (§24).
	# E o tempo abranda, se o jogador nao o desligou (Q-034).
	var roda := Input.is_action_pressed(&"king_wheel")
	Pace.scale = (
		_relogio_lido().wheel_time_scale
		if roda and Preferences.on(Preferences.WHEEL_SLOWDOWN)
		else 1.0
	)
	if roda:
		var segmento := wheel_segment(_stick(), SimLoop.field.crown.ids().size())
		pointed = segmento  # ao centro nao aponta nada: largar Y ai cancela
		_andar(0.0)
	else:
		# Largar o Y usa o que o stick apontava. Lido aqui e nao no evento: o
		# Inspector trata o evento do Y antes de ele chegar a este no.
		if pointed >= 0:
			_impulso(pointed)
		pointed = -1
		_andar(Input.get_axis(&"move_left", &"move_right"))
	_repeticao = maxf(0.0, _repeticao - delta)
	if ClassSelection.release_pending:
		if Input.is_action_pressed(&"verb_drop"):
			return
		ClassSelection.release_pending = false
	if not Input.is_action_pressed(&"verb_drop") or JournalPanel.holds_drop():
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
	return _curva_lida().coin_drop_repeat_s


func _relogio_lido() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _curva_lida() -> EconomyCurve:
	if _curva == null:
		_curva = SimFactory.curve()
	return _curva


## Mover e escrever um alvo, e nao empurrar uma posicao: o passo 5 e que leva
## toda a gente, e o monarca nao e excecao (§43).
func _andar(direccao: float) -> void:
	var quem := Assume.driven()  # o rei, ou o corpo de classe assumido (§08)
	var i := SimLoop.units.index_of(quem)
	if i == UnitSystem.NENHUM:
		return
	if is_zero_approx(direccao):
		SimLoop.units.clear_target(quem)
		return
	var limites := Assume.limits(quem)  # a borda do mundo, e a trela do rei (Q-150)
	var x := SimLoop.units.xs[i] + direccao * SimLoop.world_width
	SimLoop.units.set_target_x(quem, clampf(x, limites.x, limites.y))


## Um impulso que nao se pode usar diz porque, no painel, e nao entra na fila
## (Q-113): nada muda de estado e o saco fica igual.
func _impulso(indice: int) -> void:
	var ids := SimLoop.field.crown.ids()
	if indice >= ids.size():
		return
	if not Assume.king():  # a roda e o corpo do rei (§24)
		get_tree().call_group(&"painel", &"say", tr(&"UI_WHEEL_KING_ONLY"))
		return
	var porque := impulse_refusal(ids[indice])
	if porque.is_empty():
		SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": ids[indice]})
	else:
		get_tree().call_group(&"painel", &"say", porque)


## A frase do que falta para usar o impulso `id` hoje, ou "" se pode.
static func impulse_refusal(id: StringName) -> String:
	var coroa := SimLoop.field.crown
	var dia := ClockService.clock.day
	var perfil := RulesFactory.impulse_cost_mult(SimLoop.state.greed)
	var preco := coroa.price(id, dia, perfil)
	var chave := coroa.refusal(id, dia, SimLoop.units, SimLoop.king_id, preco)
	if chave == &"":
		return ""
	var nome := TranslationServer.translate(StringName("IMPULSE_" + String(id).to_upper()))
	return TranslationServer.translate(chave).format({"name": nome, "cost": preco})


## O stick esquerdo de quem o estiver a usar: o que mais saiu do centro.
static func _stick() -> Vector2:
	var melhor := Vector2.ZERO
	for d in Input.get_connected_joypads():
		var v := Vector2(
			Input.get_joy_axis(d, JOY_AXIS_LEFT_X), Input.get_joy_axis(d, JOY_AXIS_LEFT_Y)
		)
		melhor = v if v.length() > melhor.length() else melhor
	return melhor


func _largar() -> void:
	var i := SimLoop.units.index_of(Assume.driven())
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
	var i := SimLoop.units.index_of(Assume.driven())
	return SimLoop.units.xs[i] if i != UnitSystem.NENHUM else SimLoop.core_x
