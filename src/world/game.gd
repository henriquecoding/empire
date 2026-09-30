# src/world/game.gd — a cena de jogo (F0-10, ADR 0005).
#
# A ADR 0005 escreve o contrato: a boot.tscn carrega o Registry, o idioma e o
# save, decide que game.tscn instanciar, e so depois entrega. Isto e o que ela
# entrega.
#
# O que este ficheiro faz e curto de proposito: semeia, manda o Greybox montar a
# regiao, aponta a camara ao monarca e liga o tremor de ecra do §24. Nenhuma
# regra de jogo passa por aqui; se aparecer uma, pertence a um sistema de
# src/sim/ (a mesma nota que a boot.gd ja tinha).
class_name Game
extends Node2D

## §24: "so para o muro a cair e o Ariete a acertar. Nunca para golpes normais.
## Amplitude max. 4 px, e com opcao de desligar (§26)."
const TREMOR_PX := 4.0
const TREMOR_S := 0.25
const MEIO := 0.5
## `godot --path . -- --novo` comeca uma partida do zero mesmo havendo save.
const NOVO := "--novo"
## `-- --semente 42` fixa a semente de um jogo novo. Uma captura que nao a fixa
## nao se repete: a semente por omissao e o relogio (planejamento 26/09, §8).
const SEMENTE := "--semente"

## Um jogo novo pedido de dentro do jogo, que sobrevive ao recarregar da cena: o
## `--novo` da linha de comandos, dito pelo botao da derrota (GB-16).
static var _recomecar := false

var _tremor: float = 0.0
var _acabou := false
## O legado aplicado espera pelo primeiro save do jogo novo para se gastar (CONT-01).
var _chegada := false

@onready var _camara: CameraRig = $CameraRig
@onready var _mundo: Node2D = $Mundo
@onready var _monarca: Node2D = $Monarca


func _ready() -> void:
	# O render interpola (§40, I5): grava as posicoes DEPOIS de o SimLoop dar o
	# passo, e por isso corre atras dele — um autoload vem primeiro na arvore,
	# mas uma ordem implicita e uma ordem que muda sozinha (ADR 0020).
	process_physics_priority = SimLoop.process_physics_priority + 1
	Smoothing.reset()
	Registry.load_all()
	LegacyStore.settle()  # um fim ou um comeco que um fecho interrompeu (CONT-01)
	if not _retomar():
		SimLoop.start(_semente())
		Greybox.build()
		# §16: o que a partida perdida deixou (Q-134), ou quem atravessou com o rei
		# (Q-135). Sem legado, nao muda nada.
		var legado := LegacyStore.pending()
		Legacy.apply(legado, SimLoop.state, SimLoop.builds, SimLoop.field.classes)
		var tropas := SimFactory.by_id(&"units")
		Legacy.arrive(legado, SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, SimLoop.core_x)
		var noite := SimLoop.night
		CampaignMemory.apply(legado, noite.voice.debt, noite.harvest, SimLoop.field.succession)
		_chegada = not legado.is_empty()
		# §26: o dia ao ritmo de quem joga. Um jogo novo nasce com a duracao da
		# ultima escolha, pela fila como qualquer outra (§61, GB-24).
		var segundos := Preferences.shared().number(Preferences.DAY_SECONDS)
		if segundos > 0.0:
			SimLoop.intents.queue(IntentQueue.Kind.DAY_LENGTH, {&"seconds": segundos})
	_camara.set_region(-SimLoop.wild_px, SimLoop.world_width + SimLoop.wild_px)  # Q-154
	# Poe o marcador onde o monarca esta ANTES de o entregar a camara: o follow()
	# assenta a camara na posicao do alvo, e um alvo ainda na origem punha o
	# primeiro segundo de cada partida a viajar da borda do mapa ate ao castelo.
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


## Quem fecha a janela ou deixa a aplicacao nao perde o dia (SavePoint, D11).
func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		SavePoint.now()


func _na_pausa(pausado: bool) -> void:
	if pausado:
		SavePoint.now()


func _physics_process(_delta: float) -> void:
	Smoothing.record_all()
	# Depois do primeiro tick, com a duracao do dia ja consumida da fila. Ate haver
	# um save do jogo novo, um fecho volta a aplicar o legado a um mundo novo — e se
	# este falhar, o da alvorada gasta-o no arranque seguinte (CONT-01).
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


## A semente da partida. O §42 manda mostra-la no ecra e deixar copiar (o Inspector).
func _semente() -> int:
	return seed_from(OS.get_cmdline_user_args(), Time.get_unix_time_from_system() as int)


## A semente pedida na linha de comandos, ou `omissao` se nao ha uma valida.
static func seed_from(args: PackedStringArray, omissao: int) -> int:
	var i := args.find(SEMENTE)
	if i >= 0 and i + 1 < args.size() and args[i + 1].is_valid_int():
		return args[i + 1].to_int()
	return omissao


## Retoma o autosave mais recente, se houver (ADR 0005: a boot carrega o save e
## so depois entrega). Devolve falso quando nao ha nada para retomar.
##
## Duas razoes para comecar de novo mesmo havendo save: `--novo` na linha de
## comandos, que e o que um teste de greybox precisa para repetir uma noite; e um
## nucleo em ruina, porque retomar uma partida ja perdida nao e retomar nada.
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


## A camara segue um Node2D (§59), e quem o jogador conduz — o rei, ou a classe
## assumida (§08) — e uma LINHA DE COLUNAS (§52). O no "Monarca" copia o x dela uma
## vez por frame: o x que se ve, entre dois ticks (GB-10), e nao o do tick.
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


## §24: "com opcao de desligar (§26)". Pergunta-se a cada vez e nao se guarda:
## desligar na pausa vale ja para o muro seguinte (GB-13).
func _tremer() -> void:
	if Preferences.on(Preferences.SCREEN_SHAKE):
		_tremor = TREMOR_S


## §10, numa frase: "se cair, cai a partida". O §46 nao tem sinal de derrota (regra
## 7 do AGENTS.md): o mundo diz-o, com o nucleo em ruina. Parar AQUI e nao no
## SimLoop e deliberado: quem mede uma derrota (o §66) precisa de continuar a
## contar. Quem joga tem cena; quem mede, nao (Q-081).
func _no_desabamento(_building_id: int, _x: float) -> void:
	if Defeat.happened():
		_acabar()


## O rei caiu: sem herdeiro e a mesma derrota que o nucleo (§16, Defeat); com ele
## pronto, a pausa pergunta se se continua com um novo monarca (Q-146).
func _na_morte(unit_id: int, _x: float, _faixa: int, _larga: PackedStringArray) -> void:
	if unit_id == SimLoop.king_id:
		if Defeat.happened():
			_acabar()
		else:
			SimLoop.set_paused(true)


func end_reign() -> void:  # deixar a coroa cair em vez do herdeiro (Q-146)
	SimLoop.field.succession.declined = true
	_acabar()


## O fim do ciclo — o Lume apagado, ou o ultimo povo vassalo: a campanha acaba, e
## o jogo novo leva o legado da travessia (Q-135, Q-156, Q-103).
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
	var fica := SimFactory.curve().decay_structures_kept
	_fim(Legacy.of(SimLoop.state, SimLoop.builds, fica))


## O que fica escreve-se antes de a pausa abrir o ecra que o diz (§16, Q-134). Um
## legado que nao se escreveu deixa os saves onde estavam, e o ecra di-lo (CONT-01).
## Uma vez so: o nucleo e o rei podem cair no mesmo tick.
func _fim(legado: Dictionary) -> void:
	if _acabou:
		return
	_acabou = true
	LegacyStore.leave(legado)
	SimLoop.set_paused(true)
	$Entrada.set_process_unhandled_input(false)


## §16: perder nao se desfaz com um save — "decay em vez de reset". O que o
## botao da derrota pede e um jogo novo, e nao a ultima alvorada: os saves ja se
## apagaram, e o jogo novo recebe o legado (Q-088, Q-134). Chamado pelo grupo
## `jogo`, porque quem o pede e a interface e ela nao importa daqui (§70).
func new_game() -> void:
	_recomecar = true
	get_tree().reload_current_scene()


## Uma linha no arranque, e uma so. E o recibo do export: o CI corre o binario
## com --quit-after e fica com isto no registo, em vez de "nao rebentou".
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
