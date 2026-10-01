class_name Game
extends Node2D

const TREMOR_PX := 4.0
const TREMOR_S := 0.25
const MEIO := 0.5
const NOVO := "--novo"
const SEMENTE := "--semente"

static var _recomecar := false

var _tremor: float = 0.0
var _acabou := false
var _chegada := false

@onready var _camara: CameraRig = $CameraRig
@onready var _mundo: Node2D = $Mundo
@onready var _monarca: Node2D = $Monarca


func _ready() -> void:
	process_physics_priority = SimLoop.process_physics_priority + 1
	Smoothing.reset()
	Registry.load_all()
	LegacyStore.settle()  # um fim ou um comeco que um fecho interrompeu (CONT-01)
	if not _retomar():
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
	print(_recibo())


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		SavePoint.now()


func _na_pausa(pausado: bool) -> void:
	if pausado:
		SavePoint.now()


func _physics_process(_delta: float) -> void:
	Smoothing.record_all()
	if _chegada:
		_chegada = false
		if SavePoint.now() >= 0:
			LegacyStore.settle()


func _process(delta: float) -> void:
	_seguir()
	if _tremor <= 0.0:
		return
	_tremor = maxf(0.0, _tremor - delta)
	var forca := TREMOR_PX * (_tremor / TREMOR_S)
	_mundo.position = Vector2(RngService.float_range(RngService.VISUAL, -forca, forca), 0.0)


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
	var slot := SaveService.latest_slot()
	var novo := _recomecar or OS.get_cmdline_user_args().has(NOVO)
	_recomecar = false
	if slot < 0 or novo:
		return false
	var estado := SaveService.restore(slot)
	if estado == null:
		return false
	SimLoop.resume(estado, SaveService.restore_rng(slot))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(slot))
	if Defeat.happened() or SimLoop.state.crossed or SimLoop.units.count() == 0:
		return false
	return true


func _seguir() -> void:
	var quem := Assume.driven()
	var i := SimLoop.units.index_of(quem)
	if i == UnitSystem.NENHUM:
		return
	var faixa := int(SimLoop.units.bands[i])
	var x := Smoothing.x_of(Smoothing.Group.UNITS, quem, SimLoop.units.xs[i])
	_monarca.position = Vector2(x, WorldPalette.ground_of(faixa))


func _no_rompimento(_wall_id: int) -> void:
	_tremer()


func _tremer() -> void:
	if Preferences.on(Preferences.SCREEN_SHAKE):
		_tremor = TREMOR_S


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
	_tremer()
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
