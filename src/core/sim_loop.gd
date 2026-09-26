# src/core/sim_loop.gd — os onze passos do §43, pela ordem escrita (ADR 0020).
extends Node

## O estado autoritativo em execucao (§45). Quem o le e quem o grava passa por
## aqui; ninguem guarda uma copia.
var state: GameState

## Tropas e criaturas mantem coleccoes distintas (§51, §52).
var units: UnitSystem
var creatures: CreatureSystem

## As obras (§55), os postos (§52) e os segredos (§17). O mundo escreve-lhes
## os sitios; o tick fa-los andar.
var builds: BuildSystem
var jobs: JobBoard
var secrets := SecretSites.new()

var combat: CombatSystem
var morale: MoraleSystem
var economy: EconomySystem

## A mancha e o que ela invoca (§51). O ciclo dela e o passo 2 e vive no
## NightWatch: nascer, andar, invocar e recuar sao o que o passo FAZ, e nao
## quatro passos novos na lista.
var night: NightWatch

## As moedas (§61, o Verbo 1) e o minuto 0:20 do §25. Nascem no start() e nao
## no _ready(): precisam do Registry, e isso e a regra 8b (ADR 0020).
var coins: CoinSystem
var recruits: RecruitSystem
var field: FieldWork
var hunting: HuntingSystem

var intents := IntentQueue.new()

## Quem e "tu" no "ele segue-te" do §25. O -1 e um jogo sem rei em campo.
var king_id: int = UnitSystem.NENHUM

## O que o mundo diz a simulacao sobre si proprio: onde fica o nucleo, onde
## acaba a regiao, e em que x se pode mudar de faixa (§11, §21). Escritos pela
## cena, lidos pelo tick.
var core_x: float = 0.0
var world_width: float = 0.0
var passages: PackedFloat32Array = PackedFloat32Array()

## §62: autosave no DAWN de cada dia. Desliga-se em testes e em ferramentas.
var autosave_enabled: bool = true

## O que a noite levou (§46), do crepusculo ao amanhecer. Anuncia-se no §48.
var tally := NightTally.new()

var _running: bool = false
var _fase: int = UnitSystem.NENHUM
var _brecha: bool = false


func _ready() -> void:
	state = GameState.new()
	units = UnitSystem.new()
	creatures = CreatureSystem.new()
	builds = BuildSystem.new()
	EventBus.dawn_broke.connect(_no_amanhecer)
	tally.listen()
	# §07: um muro a cair poe a fugir quem esta fraco e e barato. O sinal so e
	# entregue no passo 11, e por isso a brecha conta no tick seguinte.
	EventBus.wall_breached.connect(func(_wall_id: int) -> void: _brecha = true)


## Comeca um jogo novo: semeia, poe o relogio a andar, e da o primeiro dia.
func start(semente: int) -> void:
	state = GameState.new()
	state.seed = semente
	_montar()
	king_id = UnitSystem.NENHUM  # sem rei em campo ate alguem o pôr la
	RngService.configure(semente)
	state.chapters = SimFactory.chapter_plan(SimFactory.campaign_regions())  # §77, fluxo world
	ClockService.start()
	_running = true


## Retoma um save. Repoe o estado, o relogio e a sequencia de cada fluxo — o
## ESTADO dos fluxos, nao a semente, senao a noite recomeca (§42). As coleccoes
## entram a seguir, com load_world(), depois de a regiao estar montada.
func resume(estado: GameState, rng_states: Dictionary) -> void:
	state = estado
	_montar()
	RngService.configure(estado.seed)
	RngService.restore(rng_states)
	ClockService.seek(estado.day, estado.clock_elapsed, estado.day_seconds)
	_running = true


## As coleccoes da §45 em tipos base, e de volta (§62). O que entra no ficheiro
## e a lista do SimSave; aqui so se sabe quais os sistemas que existem.
func world() -> Dictionary:
	var saved := SimSave.world(units, creatures, coins, builds, night, king_id)
	saved.merge(field.to_dict())
	return saved


func load_world(mundo: Dictionary) -> void:
	king_id = SimSave.restore(units, creatures, coins, builds, night, mundo)
	field.from_dict(mundo)


func stop() -> void:
	_running = false
	ClockService.stop()


func running() -> bool:
	return _running


## A pausa do §24, que nao e o stop(): o relogio fica onde esta e volta a andar.
func set_paused(pausado: bool) -> void:
	_running = not pausado
	ClockService.running = not pausado
	EventBus.queue(&"game_paused", [pausado])
	EventBus.flush()  # sem tick nao ha passo 11 que entregue isto


## Um passo. Publico: um teste corre um dia inteiro sem esperar por _physics_process.
func step(delta: float) -> void:
	state.tick += 1
	_largar(Verbs.consume(intents, units, creatures, combat, king_id, passages, builds, field))

	ClockService.step(delta)  # 1 · GameClock.advance — todo o tick
	var mudou := _mudanca_de_fase()
	night.tick(delta, _fase, mudou, state, creatures, Vector2(core_x, world_width))  # 2
	jobs.refresh(builds, units, _fase)  # 3 · fase, obras ou recrutamento alterados
	field.prepare(ClockService.clock.day, core_x, world_width, units, _fase)
	# 4 · quem quer a moeda, quem anda atras do rei e quem luta: os tres ESCREVEM
	#     alvo, que e o que o passo 4 escreve ("estado, alvo, intencao de
	#     movimento"). Vem antes da FSM para que ela ja decida sobre o alvo deste
	#     tick.
	recruits.seek_coins(units, coins, state.tick)
	recruits.follow(units, king_id)
	field.plan(units, _fase < GameClock.Phase.DUSK)
	EventRelay.combat(combat.choose(units, creatures, builds, passages))
	EventRelay.morale(morale.tick(units, king_id, core_x, _brecha))  # 4 · §07
	_brecha = false
	EventRelay.units(units.tick_decisions(state.tick))  # 4 · FSM, 1/6 por tick
	# 5 · MovementSystem — todo o tick. O king_id vai junto porque o §24 da ao
	#     comando "Mover" o contexto "Sempre": quem uma pessoa conduz nao fica
	#     preso em FIGHT como fica quem a §52 conduz. A alvorada solta os postos
	#     atras da luz (§24, DawnCascade).
	units.tick_movement(delta, king_id, ClockService.dawn_front())
	creatures.tick_movement(delta)
	coins.tick(delta)  # 5 · o arco e a queda, antes de alguem ler o chao
	# 5 · apanhar, pagar uma obra e ser recrutado sao os tres consequencia de uma
	#     chegada — da moeda ou de quem a vai buscar — e por isso vem a seguir ao
	#     movimento e nao no passo do sistema que os trata (Q-063, Q-064). A obra
	#     e servida primeiro: o §55 diz que ela existe quando uma moeda CAI nela,
	#     e quem larga uma moeda em cima de um canteiro nao a quer de volta.
	EventRelay.builds(builds.absorb(coins, state, night.amargueiros))
	field.absorb(coins, builds, units)
	EventRelay.pickup(recruits.pickup(units, coins, king_id))
	Verbs.sweep(units, coins, king_id)
	EventRelay.secrets(secrets.tick(units, king_id, state))
	_largar(EventRelay.combat(night.feats(combat.resolve(units, creatures, builds, _roll))))  # 6
	var luz := _fase < GameClock.Phase.DUSK
	_largar(field.resolve(units, builds, delta, luz, ClockService.clock, king_id))
	if mudou:  # 7 · EconomySystem — uma vez por fase, e nunca por frame
		_largar(EventRelay.economy(economy.on_phase(builds, _fase, night.trail()), builds))
	EventRelay.builds(builds.tick(delta, units))  # 8 · BuildSystem — todo o tick
	# 9 · DebtSystem e DiplomacySystem — uma vez por dia ... XIII-04, F2
	# 10 · KingAISystem — uma vez por dia, por imperio ..... F2

	_espelhar_relogio()
	EventBus.flush()  # 11 · fim do tick, com o estado ja consolidado


## O Verbo 1 (§61). O sorteio do desvio sai do fluxo `economy` — onde a moeda cai
## afeta a simulacao, por isso e determinista — e o evento sai da §46.
func drop_coin(x: float, faixa: Band.Kind, quanto: int, origem: StringName) -> int:
	var desvio := RngService.float_range(&"economy", -CoinSystem.DESVIO_MAX, CoinSystem.DESVIO_MAX)
	var coin_id := coins.drop(state, x, faixa, quanto, desvio, origem == Verbs.JOGADOR)
	EventBus.queue(&"coin_dropped", [x, int(faixa), quanto, origem])
	return coin_id


func _montar() -> void:
	units = UnitSystem.new()
	creatures = CreatureSystem.new()
	builds = BuildSystem.new()
	jobs = SimFactory.job_board()
	combat = SimFactory.combat(jobs)
	morale = SimFactory.morale()
	economy = SimFactory.economy()
	coins = CoinSystem.new(SimFactory.curve())  # um jogo novo comeca sem moedas
	night = NightWatch.new(units, builds, coins, jobs)
	recruits = RecruitSystem.new(SimFactory.curve())
	field = FieldWork.new(economy, morale, combat)
	hunting = field.hunting
	tally.reset()
	_fase = UnitSystem.NENHUM
	_brecha = false
	intents.clear()


## O roll do §50, no fluxo `combat`: um tiro falhado nao muda o que se invoca.
func _roll() -> float:
	return RngService.unit_float(&"combat")


## Verdadeiro quando a fase mudou NESTE passo. Lido do relogio e nao de um sinal:
## os sinais so sao entregues no passo 11, e os passos 3 e 7 correm antes disso.
func _mudanca_de_fase() -> bool:
	var agora := int(ClockService.clock.current_phase())
	if agora == _fase:
		return false
	_fase = agora
	return true


func _largar(moedas: Array[Dictionary]) -> void:
	for m in moedas:
		var do_rei: bool = m[EventRelay.PORQUE] == Verbs.JOGADOR
		if do_rei and field.claims(m, state, night, builds, units, king_id):
			continue
		drop_coin(
			m[EventRelay.ONDE], m[EventRelay.FAIXA], m[EventRelay.QUANTO], m[EventRelay.PORQUE]
		)


func _physics_process(delta: float) -> void:
	if not _running:
		return
	step(delta)


## O relogio e dono do dia e do tempo decorrido; o GameState e o que se grava.
## Copiar aqui, uma vez por tick, evita que os dois divirjam sem ninguem ver.
func _espelhar_relogio() -> void:
	state.day = ClockService.clock.day
	state.clock_elapsed = ClockService.clock.elapsed
	state.day_seconds = ClockService.clock.day_seconds()


func _no_amanhecer(dia: int) -> void:
	var noite := tally.of_night(dia)
	if _running and not noite.is_empty():
		EventBus.queue(&"night_survived", noite)
	# O dia 1 e o amanhecer com que o jogo comeca: gravar ai nao guarda nada.
	if autosave_enabled and _running and dia > 1:
		SaveService.autosave(state, RngService.snapshot(), world())
