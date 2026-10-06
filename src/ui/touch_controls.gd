# src/ui/touch_controls.gd — jogar com os dedos (ADR 0047, UX-02).
#
# O toque e o quarto dispositivo do §26, e prime as mesmas accoes do InputMap que o
# teclado e o comando: este no nao chama drop_coin nem ataca ninguem. Le os dedos,
# pergunta ao TouchPad o que eles querem premido, e mete as diferencas no Input como
# InputEventAction — que o InputRouter e o CombatInput leem como leriam uma tecla (§61).
# So o mundo tem duas coisas que nenhuma tecla faz: arrastar espreita (a camara livre
# do §24, pelo grupo dela) e tocar aponta a habilidade de quem mira, como o botao
# direito do rato.
#
# Os botoes reclamam o dedo no _input, antes dos menus; o mundo e o que sobra, no
# _unhandled_input — um toque no painel de combate e do painel, e nao do mundo.
class_name TouchControls
extends Control

## Quanto vibra um botao ao pousar o dedo, e a alavanca ao comecar a correr, em ms.
const VIBRA_MS := {"botao": 12, "corre": 18}
## De quanto em quanto tempo se pergunta ao guia se o INTERAGIR tem que fazer.
const GUIA_S := 0.25
## As classes cuja habilidade aponta a um sitio (ADR 0045): o toque no mundo e a mira.
const MIRAM := [&"archer", &"bard"]

## O dedo na roda, como o stick do comando: o InputRouter._stick() le-o.
static var aim := Vector2.ZERO
## Se os controlos estao no ecra: o ultimo gesto foi um toque.
static var active := false
## Uma linha no registo, a primeira vez que aparecem — e o que o verificador do site le.
static var _anunciado := false

var pad := TouchPad.new()
var _premidas := {}
var _corria := false
var _guia := 0.0
var _brilho := false
## O dedo arrastou o mundo e a camara ainda nao foi mandada voltar.
var _espreita := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	active = Glyphs.initial() == Glyphs.Device.TOUCH
	aim = Vector2.ZERO
	WideTouch.apply(get_tree().root, active)
	_medir()
	EventBus.game_paused.connect(func(_pausa: bool) -> void: _largar_tudo())
	get_tree().root.size_changed.connect(_ao_rodar)


func _input(evento: InputEvent) -> void:
	_mao(evento)
	if not active or not playing():
		return
	if evento is InputEventScreenTouch:
		var dedo := evento as InputEventScreenTouch
		if dedo.pressed:
			pad.press(dedo.index, dedo.position)
			if pad.tracks(dedo.index):
				_vibrar(VIBRA_MS.botao)
				get_viewport().set_input_as_handled()
			return
		var do_mundo := pad.role_of(dedo.index) == TouchLayout.Role.WORLD
		if pad.lift(dedo.index, dedo.position) and not do_mundo:
			get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag:
		var dedo := evento as InputEventScreenDrag
		if pad.drag(dedo.index, dedo.position, dedo.relative):
			get_viewport().set_input_as_handled()


## O que nenhum botao nem menu levou e o mundo.
func _unhandled_input(evento: InputEvent) -> void:
	if not active or not playing() or not evento is InputEventScreenTouch:
		return
	var dedo := evento as InputEventScreenTouch
	if dedo.pressed and not pad.tracks(dedo.index):
		pad.press_world(dedo.index, dedo.position)


## Se o jogo esta a correr sem um menu por cima: a pausa, a escolha de classe, a
## viagem e a derrota sao Controls do motor, e tocam-se pelo rato emulado.
static func playing() -> bool:
	return (
		SimLoop.state != null
		and SimLoop.running()
		and not ClassSelection.active
		and not TravelPanel.active
		and not Defeat.happened()
	)


func _process(delta: float) -> void:
	visible = active and playing()
	if not visible:
		_largar_tudo()
		return
	if not _anunciado:
		_anunciado = true
		print("Empire · toque: controlos no ecra")
	_medir()
	_premir(pad.wanted())
	if pad.pause_tapped:
		_emitir(&"pause", true)
	if pad.fix_tapped:
		_fixar(not pad.layout.fixed)
	for toque: Vector2 in pad.taps:
		_apontar(toque)
	if not is_zero_approx(pad.pan):
		get_tree().call_group(CameraRig.GRUPO, &"drag", pad.pan)
		_espreita = true
	if pad.let_go:
		_devolver_camara()
	aim = pad.aim
	pad.take()
	_guia -= delta
	if _guia <= 0.0:
		_guia = GUIA_S
		_brilho = (
			TravelWatch.at_gate()
			or GameplayGuide.context(Glyphs.Device.TOUCH).contains(tr(&"TOUCH_ASSUME"))
		)
	queue_redraw()


## Mete no Input so o que mudou. A pausa e um toque: premida num frame, largada no seguinte.
func _premir(quer: Dictionary) -> void:
	if _premidas.get(&"pause", false):
		_emitir(&"pause", false)
	for accao: StringName in quer:
		if quer[accao] != _premidas.get(accao, false):
			_emitir(accao, quer[accao])
	var corre: bool = quer[&"king_run"]
	if corre and not _corria:
		_vibrar(VIBRA_MS.corre)
	_corria = corre


func _emitir(accao: StringName, premida: bool) -> void:
	var e := InputEventAction.new()
	e.action = accao
	e.pressed = premida
	e.strength = 1.0 if premida else 0.0
	Input.parse_input_event(e)
	_premidas[accao] = premida


## Ninguem fica com nada premido do outro lado de um menu, nem com a roda a disparar
## um impulso ao voltar: largar a roda numa pausa cancela-a, como largar o Y ao centro.
func _largar_tudo() -> void:
	if _premidas.get(&"king_wheel", false):
		InputRouter.pointed = -1
	for accao: StringName in _premidas:
		if _premidas[accao]:
			_emitir(accao, false)
	pad.reset()
	aim = Vector2.ZERO
	_corria = false
	_devolver_camara()


## Fixar ou soltar a alavanca (UX-03). Fica nas preferencias, como o canhoto; ao soltar,
## a camara que estava a espreitar volta.
func _fixar(fixa: bool) -> void:
	Preferences.shared().set_enabled(Preferences.TOUCH_FIXED, fixa)
	pad.layout.fixed = fixa
	_vibrar(VIBRA_MS.botao)
	if not fixa:
		_devolver_camara()


## Um dedo que saiu do mundo, ou que um menu levou a meio do arrastar: a camara volta.
func _devolver_camara() -> void:
	if _espreita:
		_espreita = false
		get_tree().call_group(CameraRig.GRUPO, &"let_go")


## Tocar num bicho aponta a habilidade de quem mira (ADR 0045): o Arqueiro marca, o Bardo
## encanta. A Vigilia do Monarca nao aponta, e por isso um toque no mundo nao a gasta.
func _apontar(toque: Vector2) -> void:
	if not HeroWatch.current() in MIRAM:  # o Rei decreta a Vigilia, que nao aponta
		return
	var x := (get_viewport().get_canvas_transform().affine_inverse() * toque).x
	CombatInput.cursor_aim = false
	CombatInput.queue_skill(x)


## A mao que esta a jogar: um toque mostra os controlos, uma tecla ou um comando tira-os.
func _mao(evento: InputEvent) -> void:
	var nome := ""
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
		nome = Input.get_joy_name(evento.device)
	var antes := Glyphs.Device.TOUCH if active else Glyphs.Device.KEYBOARD
	var agora := Glyphs.device_of(evento, antes, nome) == Glyphs.Device.TOUCH
	if agora == active:
		return
	active = agora
	WideTouch.apply(get_tree().root, active)
	if not active:
		_largar_tudo()


## Um telemovel posto ao alto ou deixado para outra aplicacao pausa: a noite nao vem
## enquanto se le uma mensagem. So no toque — no computador, mudar de janela nao pausa.
func _notification(o_que: int) -> void:
	if o_que in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_pausar()


func _ao_rodar() -> void:
	WideTouch.apply(get_tree().root, active)
	var janela := DisplayServer.window_get_size()
	if janela.y > janela.x:
		_pausar()


func _pausar() -> void:
	if active and playing():
		SimLoop.set_paused(true)


## O ecra, o tamanho e o lado, lidos a cada frame: mudar nas opcoes vale ja. Num canvas
## reduzido os botoes crescem como a pausa cresce (ADR 0040), ate ao maximo da TouchLayout.
func _medir() -> void:
	var prefs := Preferences.shared()
	var factor := maxf(PauseLayout.MIN_SCALE, get_viewport().get_final_transform().get_scale().x)
	pad.layout.screen = get_viewport_rect().size
	pad.layout.ui_scale = maxf(1.0, 1.0 / factor)
	pad.layout.scale = prefs.number(Preferences.TOUCH_SCALE) * pad.layout.ui_scale
	pad.layout.left_handed = prefs.enabled(Preferences.TOUCH_LEFT)
	pad.layout.fixed = prefs.enabled(Preferences.TOUCH_FIXED)


## So o Android vibra no browser; o iPhone nao tem a API, e o motor queixava-se a cada toque.
func _vibrar(ms: int) -> void:
	var android := OS.has_feature("web_android") or OS.has_feature("android")
	if android and Preferences.on(Preferences.TOUCH_HAPTICS):
		Input.vibrate_handheld(ms)


func _draw() -> void:
	TouchView.draw(self, pad, _brilho)
