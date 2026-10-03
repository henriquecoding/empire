extends Node

var state: GameState

var units: UnitSystem
var creatures: CreatureSystem

var builds: BuildSystem
var jobs: JobBoard
var secrets := SecretSites.new()

var combat: CombatSystem
var morale: MoraleSystem
var economy: EconomySystem

var night: NightWatch

var coins: CoinSystem
var recruits: RecruitSystem
var field: FieldWork
var hunting: HuntingSystem

var intents := IntentQueue.new()
## A sede: a carroca da chegada e o alvo da moeda no nucleo (ADR 0059).
var seat := RealmSeat.new()

var king_id: int = UnitSystem.NENHUM

var core_x: float = 0.0
var world_width: float = 0.0
var wild_px: float = 0.0
var passages: PackedFloat32Array = PackedFloat32Array()

var autosave_enabled: bool = true

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
	SpiritWatch.listen()  # o animo do reino (Q-102)
	# §07: a brecha poe a fugir quem esta fraco; conta no tick seguinte (passo 11).
	EventBus.wall_breached.connect(func(_wall_id: int) -> void: _brecha = true)


func start(semente: int) -> void:
	state = GameState.new()
	state.seed = semente
	RngService.configure(semente)  # antes de montar: o desconto por regiao le-a (Q-105)
	_montar()
	king_id = UnitSystem.NENHUM  # sem rei em campo ate alguem o pôr la
	SimFactory.draw_campaign(state)  # §77 os capitulos e §15 a ganancia, fluxo world
	ClockService.start()
	_running = true


func resume(estado: GameState, rng_states: Dictionary) -> void:
	state = estado
	RngService.configure(estado.seed)
	_montar()
	RngService.restore(rng_states)
	ClockService.seek(estado.day, estado.clock_elapsed, estado.day_seconds)
	_fase = int(ClockService.clock.current_phase())  # o save ja passou esta fase (D2)
	_running = true


func world() -> Dictionary:
	var saved := SimSave.world(units, creatures, coins, builds, night, king_id, jobs)
	saved.merge(field.to_dict())
	saved[FoundationWatch.SEDE] = seat.to_dict()
	return saved


func load_world(mundo: Dictionary) -> void:
	WorldWorks.restore(mundo.get(SimSave.OBRAS, []))
	king_id = SimSave.restore(units, creatures, coins, builds, night, mundo, jobs)
	field.from_dict(mundo)
	seat.from_dict(mundo.get(FoundationWatch.SEDE, {}))


func stop() -> void:
	_running = false
	ClockService.stop()


func running() -> bool:
	return _running


func set_paused(pausado: bool) -> void:
	if pausado:
		intents.clear()
		if combat != null:
			combat.manual.cancel()
	_running = not pausado
	ClockService.running = not pausado
	EventBus.queue(&"game_paused", [pausado])
	EventBus.flush()  # sem tick nao ha passo 11 que entregue isto


func step(delta: float) -> void:
	state.tick += 1
	var abertas := Passages.open(passages, builds)  # a escora fecha a boca (Q-132)
	_largar(Verbs.consume(intents, units, creatures, combat, king_id, abertas, builds, field))
	HeroWatch.tick(delta)

	ClockService.step(delta)  # 1 · GameClock.advance — todo o tick
	var mudou := _mudanca_de_fase()
	night.tick(delta, _fase, mudou, state, creatures, Vector2(core_x, world_width))  # 2
	jobs.refresh(builds, units, _fase)  # 3 · fase, obras ou recrutamento alterados
	field.prepare(ClockService.clock.day, core_x, world_width, units, _fase, state)
	# 4 · quem quer a moeda, quem espera no nucleo e quem luta: os tres ESCREVEM
	#     alvo, que e o que o passo 4 escreve ("estado, alvo, intencao de
	#     movimento"). Vem antes da FSM para que ela ja decida sobre o alvo deste
	#     tick.
	recruits.seek_coins(units, coins, state.tick)
	recruits.follow(units, king_id, core_x)
	field.plan(units, _fase < GameClock.Phase.DUSK)
	EventRelay.combat(combat.choose(units, creatures, builds, abertas))
	EventRelay.morale(morale.tick(units, king_id, core_x, _brecha))  # 4 · §07
	_brecha = false
	EventRelay.units(units.tick_decisions(state.tick))  # 4 · FSM, 1/6 por tick
	# 5 · MovementSystem — todo o tick. O king_id vai junto porque o §24 da ao
	#     comando "Mover" o contexto "Sempre": quem uma pessoa conduz nao fica
	#     preso em FIGHT como fica quem a §52 conduz. A alvorada solta os postos
	#     atras da luz (§24, DawnCascade).
	field.under.confine(units)  # 5 · la em baixo, ninguem passa das paredes (Q-186)
	units.piloted_pace = MonarchWatch.pace(delta)  # 5 · correr, com folego (Q-193)
	units.tick_movement(delta, Assume.driven(), ClockService.dawn_front(), HeroWatch.pace())
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
	FoundationWatch.collect()  # a carroca de provisoes da chegada (ADR 0059)
	EventRelay.secrets(secrets.tick(units, Assume.driven(), state))
	HuntWatch.stir(field, units, delta)  # 5 · a caca anda; o javali bate antes das mortes
	var strikes := HeroWatch.resolved(combat.resolve(units, creatures, builds, _roll))
	_largar(EventRelay.combat(night.feats(strikes)))  # 6
	var luz := _fase < GameClock.Phase.DUSK
	_largar(field.resolve(units, builds, delta, luz, ClockService.clock, king_id))
	if mudou:  # 7 · EconomySystem — uma vez por fase, e nunca por frame
		_largar(EventRelay.economy(economy.on_phase(builds, _fase, night.trail()), builds))
	EventRelay.builds(FoundationWatch.after(builds.tick(delta, units)))  # 8 · BuildSystem
	# 9 · DebtSystem e DiplomacySystem — uma vez por dia ... XIII-04, F2
	# 10 · KingAISystem — uma vez por dia, por imperio ..... F2

	_espelhar_relogio()
	EventBus.flush()  # 11 · fim do tick, com o estado ja consolidado


func drop_coin(x: float, faixa: Band.Kind, quanto: int, origem: StringName) -> int:
	var desvio := RngService.float_range(&"economy", -CoinSystem.DESVIO_MAX, CoinSystem.DESVIO_MAX)
	var coin_id := coins.drop(state, x, faixa, quanto, desvio, origem == Verbs.JOGADOR)
	CoinTarget.aim(coins, coin_id, builds, origem == Verbs.JOGADOR)
	EventBus.queue(&"coin_dropped", [x, int(faixa), quanto, origem])
	return coin_id


func _montar() -> void:
	units = UnitSystem.new()
	creatures = CreatureSystem.new()
	builds = BuildSystem.new()
	jobs = SimFactory.job_board()
	combat = SimFactory.combat(jobs)
	morale = SimFactory.morale()
	economy = SimFactory.economy(jobs)
	coins = CoinSystem.new(SimFactory.curve())  # um jogo novo comeca sem moedas
	night = NightWatch.new(units, builds, coins, jobs)
	recruits = RulesFactory.recruits(state)  # o desconto do povo da regiao (Q-007)
	field = FieldWork.new(economy, morale, combat, night)
	recruits.resting = field.upkeep.resting  # quem desertou nao volta logo (Q-144)
	hunting = field.hunting
	tally.reset()
	seat = RealmSeat.new()
	_fase = UnitSystem.NENHUM
	_brecha = false
	intents.clear()


func _roll() -> float:  # o roll do §50, no fluxo `combat`
	return RngService.unit_float(&"combat")


func _mudanca_de_fase() -> bool:
	var agora := int(ClockService.clock.current_phase())
	if agora == _fase:
		return false
	_fase = agora
	return true


func _largar(moedas: Array[Dictionary]) -> void:
	for m in moedas:
		var do_rei: bool = m[EventRelay.PORQUE] == Verbs.JOGADOR
		if do_rei and KingClaims.of(field, m, state, night, builds, units, king_id):
			continue
		var amount := int(m[EventRelay.QUANTO])
		var split: bool = (
			m[EventRelay.PORQUE] == EventRelay.FONTE_MORTE
			and m[EventRelay.FAIXA] == Band.Kind.UNDERGROUND
		)
		for k in amount if split else 1:
			drop_coin(
				m[EventRelay.ONDE],
				m[EventRelay.FAIXA],
				1 if split else amount,
				m[EventRelay.PORQUE]
			)


func _physics_process(delta: float) -> void:
	if _running and Pace.due():  # a roda abranda saltando passos (Q-034)
		step(delta)


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
