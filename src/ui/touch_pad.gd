# src/ui/touch_pad.gd — quem e cada dedo, e o que ele quer premido (ADR 0047).
#
# Um dedo e da alavanca, de um botao ou do mundo desde que pousa ate que se levanta: um
# polegar que escorrega uns pixeis no meio de um continuo nao o interrompe. O que sai
# daqui sao as accoes do InputMap — as mesmas que o teclado e o comando premem —, e o
# que o mundo pediu: espreitar (o pan) e apontar (os toques). Ninguem aqui mexe no jogo:
# quem faz das accoes intencoes e o InputRouter e o CombatInput (§61).
#
# Logica pura: os dedos entram por parametro, e um teste conduz cinco ao mesmo tempo
# sem arvore nem ecra (ADR 0009).
class_name TouchPad
extends RefCounted

## O botao e a accao do §24 que ele prime. A habilidade da classe e o mark_target, que
## o CombatInput le (ADR 0045).
const ACCOES := {
	TouchLayout.Role.DROP: &"verb_drop",
	TouchLayout.Role.ATTACK: &"attack",
	TouchLayout.Role.ASSUME: &"verb_assume",
	TouchLayout.Role.SKILL: &"mark_target",
	TouchLayout.Role.WHEEL: &"king_wheel",
}
const ANDAR := [&"move_left", &"move_right", &"king_run"]
## Ate onde um dedo no mundo ainda e um toque, e nao um arrastar.
const TOQUE_PX := 24.0
## O arrastar que chega a borda da roda: o stick todo inclinado (InputRouter.RODA_ZONA).
const RODA_PX := 90.0

var layout := TouchLayout.new()
var stick := TouchStick.new()
## Para onde o dedo aponta a roda, como o stick do comando: comprimento 1 a RODA_PX.
var aim := Vector2.ZERO
## Os toques no mundo desde o ultimo take(), em coordenadas de ecra.
var taps: Array[Vector2] = []
## Quanto o mundo foi arrastado desde o ultimo take(), em px: a camara anda isto.
var pan := 0.0
## Um dedo deixou o mundo depois de o arrastar: a camara pode voltar.
var let_go := false
var pause_tapped := false
## O FIXAR foi tocado: a alavanca troca entre solta e fixa (UX-03).
var fix_tapped := false
## O CORRER esta ligado: quem anda corre, ate se tocar outra vez nele.
var running := false

var _papel := {}
var _origem := {}
## As accoes que um dedo premiu desde o ultimo take(): um toque mais curto do que um
## frame fica premido um frame, porque o InputRouter le o verb_drop no _process.
var _premidas := {}


## Um dedo pousou. Devolve o papel; o mundo nao fica registado — so o que nenhum menu
## levou chega a press_world(), pelo _unhandled_input.
func press(i: int, p: Vector2) -> TouchLayout.Role:
	var papel := layout.role_at(p)
	if papel != TouchLayout.Role.WORLD and papel != TouchLayout.Role.NONE:
		_registar(i, p, papel)
	return papel


func press_world(i: int, p: Vector2) -> void:
	_registar(i, p, TouchLayout.Role.WORLD)


func tracks(i: int) -> bool:
	return _papel.has(i)


## O papel de um dedo, ou NONE se nao e de ninguem.
func role_of(i: int) -> TouchLayout.Role:
	return _papel.get(i, TouchLayout.Role.NONE)


## Se algum dedo esta pousado neste papel.
func holds(papel: TouchLayout.Role) -> bool:
	return papel in _papel.values()


func drag(i: int, p: Vector2, relativo: Vector2) -> bool:
	if not _papel.has(i):
		return false
	match _papel[i]:
		TouchLayout.Role.STICK:
			stick.move(p)
			if not layout.fixed:
				stick.base = layout.stick_base(stick.base)
		TouchLayout.Role.WHEEL:
			var c := layout.centre(TouchLayout.Role.WHEEL)
			aim = (p - c) / (RODA_PX * layout.scale)
		TouchLayout.Role.WORLD:
			# So com a alavanca fixa: solta, arrastar e andar, e nunca espreitar (UX-03).
			if layout.fixed:
				pan -= relativo.x
	return true


func lift(i: int, p: Vector2) -> bool:
	if not _papel.has(i):
		return false
	var papel: TouchLayout.Role = _papel[i]
	var de: Vector2 = _origem[i]
	_papel.erase(i)
	_origem.erase(i)
	match papel:
		TouchLayout.Role.STICK:
			if not holds(TouchLayout.Role.STICK):
				stick.end()
		TouchLayout.Role.PAUSE:
			pause_tapped = pause_tapped or _dentro(p, papel)
		TouchLayout.Role.FIX:
			fix_tapped = fix_tapped or _dentro(p, papel)
		TouchLayout.Role.RUN:
			running = running != _dentro(p, papel)
		TouchLayout.Role.WORLD:
			if p.distance_to(de) < TOQUE_PX:
				taps.append(p)
			else:
				let_go = layout.fixed
	return true


## Cada accao que o toque pode premir, e se a quer premida agora.
func wanted() -> Dictionary:
	var quer := {}
	for papel: TouchLayout.Role in ACCOES:
		var accao: StringName = ACCOES[papel]
		quer[accao] = holds(papel) or _premidas.has(accao)
	var eixo := stick.axis()
	quer[&"move_left"] = eixo < 0.0
	quer[&"move_right"] = eixo > 0.0
	quer[&"king_run"] = runs()
	return quer


## Se quem anda corre: a alavanca ate ao fim, ou qualquer passo com o CORRER ligado.
func runs() -> bool:
	return stick.axis() != 0.0 and (running or stick.runs())


## O frame acabou: o que foi pedido ao mundo ja foi entregue.
func take() -> void:
	_premidas.clear()
	taps.clear()
	pan = 0.0
	let_go = false
	pause_tapped = false
	fix_tapped = false


## A pausa, um menu ou outra mao: ninguem fica com nada premido.
func reset() -> void:
	_papel.clear()
	_origem.clear()
	stick.end()
	aim = Vector2.ZERO
	running = false
	take()


func _registar(i: int, p: Vector2, papel: TouchLayout.Role) -> void:
	if _papel.has(i):
		lift(i, p)
	_papel[i] = papel
	_origem[i] = p
	if papel == TouchLayout.Role.STICK:
		var onde := layout.stick_home() if layout.fixed else layout.stick_base(p)
		stick.begin(p, onde, layout.stick_radius(), layout.scale, layout.fixed)
	elif papel == TouchLayout.Role.WHEEL:
		aim = Vector2.ZERO
	if ACCOES.has(papel):
		_premidas[ACCOES[papel]] = true


## Um toque que acaba onde comecou: o dedo levantou-se ainda em cima do botao.
func _dentro(p: Vector2, papel: TouchLayout.Role) -> bool:
	return p.distance_to(layout.centre(papel)) <= layout.reach(papel)
