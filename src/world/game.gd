class_name Game
extends Node2D

## §24: "so para o muro a cair e o Ariete a acertar. Nunca para golpes normais.
## Amplitude max. 4 px, e com opcao de desligar (§26)." O trauma e o ScreenShake;
## o do Ariete vem do BattleView, e o muro a cair e a derrota sao estes.
const TREMOR_MURO := 0.9
const TREMOR_FIM := 1.0
const NOVO := "--novo"
const SEMENTE := "--semente"

static var _recomecar := false

var _tremor := ScreenShake.new()
var _acabou := false
var _chegada := false
var _selector: ClassSelection

@onready var _camara: CameraRig = $CameraRig
@onready var _mundo: Node2D = $Mundo
@onready var _monarca: Node2D = $Monarca


func _ready() -> void:
	process_physics_priority = SimLoop.process_physics_priority + 1
	Smoothing.reset()
	Registry.load_all()
	LegacyStore.settle()  # um fim ou um comeco que um fecho interrompeu (CONT-01)
	var fresh := not _retomar()
	if fresh:
		SimLoop.start(_semente())
		Greybox.build()
		var legado := LegacyStore.pending()
		DecayWork.restore(legado)
		Legacy.apply(legado, SimLoop.state, SimLoop.builds, SimLoop.field.classes)
		var tropas := SimFactory.by_id(&"units")
		Legacy.arrive(legado, SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, SimLoop.core_x)
		var noite := SimLoop.night
		CampaignMemory.apply(legado, noite.voice.debt, noite.harvest, SimLoop.field.succession)
		_chegada = not legado.is_empty()
		var segundos := Preferences.shared().number(Preferences.DAY_SECONDS)
		if segundos > 0.0:
			SimLoop.intents.queue(IntentQueue.Kind.DAY_LENGTH, {&"seconds": segundos})
	_camara.set_region(-SimLoop.wild_px, SimLoop.world_width + SimLoop.wild_px)  # Q-154
	_seguir()
	_camara.follow(_monarca)
	EventBus.wall_breached.connect(_no_rompimento)
	EventBus.building_destroyed.connect(_no_desabamento)
	EventBus.unit_died.connect(_na_morte)
	EventBus.segment_entered.connect(_na_travessia)
	EventBus.game_paused.connect(_na_pausa)
	if PauseMenu.heir_waits():  # retomado com a escolha do herdeiro por fazer (Q-146)
		SimLoop.set_paused(true)
	var fase := func() -> float: return RngService.float_range(RngService.VISUAL, 0.0, TAU)
	_tremor = ScreenShake.new(Vector4(fase.call(), fase.call(), fase.call(), fase.call()))
	add_child(SfxDirector.new())  # os sons provisorios (ADR 0054)
	_mundo.add_child(TerritoryOverlay.new())  # so com o inspetor aberto (ADR 0078)
	if fresh:
		_starting_choice()
	elif Resume.recovered:
		($Interface/HUD as GameHud).say(tr(&"SAVE_RECOVERED"))
	print(_recibo())


func _notification(what: int) -> void:
	if (
		not ClassSelection.active
		and what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]
	):
		SavePoint.now()


func _na_pausa(pausado: bool) -> void:
	if pausado:
		SavePoint.now()


func _physics_process(_delta: float) -> void:
	Smoothing.record_all()
	if ClassSelection.active:
		return
	if _chegada:
		_chegada = false
		if SavePoint.now() >= 0:
			LegacyStore.settle()


func _process(delta: float) -> void:
	_seguir()
	_mundo.position = _tremor.step(delta)


func _semente() -> int:
	var legacy := LegacyStore.pending()
	return (
		int(legacy[&"map_seed"])
		if legacy.has(&"map_seed")
		else seed_from(OS.get_cmdline_user_args(), Time.get_unix_time_from_system() as int)
	)


static func seed_from(args: PackedStringArray, omissao: int) -> int:
	var i := args.find(SEMENTE)
	if i >= 0 and i + 1 < args.size() and args[i + 1].is_valid_int():
		return args[i + 1].to_int()
	return omissao


func _retomar() -> bool:
	var novo := _recomecar or OS.get_cmdline_user_args().has(NOVO)
	_recomecar = false
	return false if novo else Resume.latest()


func _seguir() -> void:
	var quem := Assume.driven()
	var i := SimLoop.units.index_of(quem)
	if i == UnitSystem.NENHUM:
		return
	var faixa := int(SimLoop.units.bands[i])
	var x := Smoothing.x_of(Smoothing.Group.UNITS, quem, SimLoop.units.xs[i])
	_monarca.position = Vector2(x, WorldPalette.ground_of(faixa))


func _no_rompimento(_wall_id: int) -> void:
	shake(TREMOR_MURO)


## §24: "com opcao de desligar (§26)". Pergunta-se a cada vez e nao se guarda:
## desligar na pausa vale ja para o muro seguinte (GB-13). Publico: o Ariete a
## acertar chega pelo grupo `jogo`, do BattleView.
func shake(trauma: float) -> void:
	if Preferences.on(Preferences.SCREEN_SHAKE):
		_tremor.add(trauma)


func _no_desabamento(_building_id: int, _x: float) -> void:
	if Defeat.happened():
		_acabar()


func _na_morte(unit_id: int, _x: float, _faixa: int, _larga: PackedStringArray) -> void:
	if unit_id == SimLoop.king_id:
		if Defeat.happened():
			_acabar()
		else:
			SimLoop.set_paused(true)


func end_reign() -> void:  # deixar a coroa cair em vez do herdeiro (Q-146)
	SimLoop.field.succession.declined = true
	_acabar()


func _na_travessia(_segmento: StringName, tipo: StringName) -> void:
	if tipo != Lume.TIPO and tipo != Realm.TODOS:  # o fim do ciclo (Q-156, Q-103)
		return
	var tropas := SimFactory.by_id(&"units")
	var perto := SimFactory.curve().crossing_party_px
	var legado := Legacy.crossing(
		SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, perto, SimLoop.field.classes
	)
	Legacy.end_campaign(legado)
	var noite := SimLoop.night
	if CampaignMemory.carries(not legado.has(Legacy.PLANO), noite.epilogue()):
		legado.merge(CampaignMemory.of(noite.voice.debt, noite.harvest, SimLoop.field.succession))
	_fim(legado)


func _acabar() -> void:
	shake(TREMOR_FIM)
	_fim(DecayWork.of())


func _fim(legado: Dictionary) -> void:
	if _acabou:
		return
	_acabou = true
	LegacyStore.leave(legado)
	SimLoop.set_paused(true)
	$Entrada.set_process_unhandled_input(false)


func new_game() -> void:
	_recomecar = true
	get_tree().reload_current_scene()


func _starting_choice() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--classe")
	if index >= 0 and index + 1 < args.size() and Registry.has_entry(&"monarchs", args[index + 1]):
		_chosen(StringName(args[index + 1]))
		return
	SimLoop.stop()
	_selector = ClassSelection.new(_chosen)
	$Interface.add_child(_selector)


func _chosen(id: StringName) -> void:
	if not MonarchWatch.begin(id):
		return
	print("Empire · monarca inicial %s" % id)
	if _selector != null:
		_selector.hide()
		_selector.queue_free()
	ClassSelection.active = false
	SimLoop.set_paused(false)
	if SimLoop.autosave_enabled:
		SavePoint.now()


func _recibo() -> String:
	return (
		"Empire · semente %d · regiao %d px · %d sitios de obra · %d em campo"
		% [
			RngService.world_seed(),
			int(SimLoop.world_width),
			SimLoop.builds.count(),
			SimLoop.units.count(),
		]
	)
