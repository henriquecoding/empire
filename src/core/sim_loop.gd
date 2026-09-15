# src/core/sim_loop.gd — os onze passos do §43, pela ordem escrita (ADR 0020).
#
# O UNICO _physics_process da simulacao. 30 passos por segundo, metade do render
# (§19), e dentro de cada passo a ordem e fixa e esta escrita aqui — porque uma
# ordem implicita e uma ordem que muda sozinha quando alguem reorganiza um
# ficheiro.
#
# Os passos que ainda nao existem estao presentes como linha, com o ticket que
# os preenche. Um passo que falta e uma linha que falta, e nao um sistema que
# ninguem chama e de que ninguem da pela ausencia.
extends Node

## O estado autoritativo em execucao (§45). Quem o le e quem o grava passa por
## aqui; ninguem guarda uma copia.
var state: GameState

## As tropas, em colunas (§52). Vive aqui porque e o tick que a faz andar.
var units: UnitSystem

## As moedas no chao e no ar (§61, o Verbo 1). Criado a pedido: precisa do
## EconomyCurve do Registry, e nenhum autoload pode depender do _ready() de
## outro ter corrido primeiro (ADR 0020, regra 8b do AGENTS.md).
var coins: CoinSystem:
	get:
		if _coins == null:
			_coins = CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
		return _coins

## O minuto 0:20 do §25 (F1-04). Criado a pedido pela mesma razao das moedas.
var recruits: RecruitSystem:
	get:
		if _recruits == null:
			_recruits = RecruitSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
		return _recruits

## Quem e "tu" no "ele segue-te" do §25. Enquanto nao ha cena de jogo, e quem
## arranca a partida que o diz; o -1 e um jogo sem rei em campo, e nesse caso
## ninguem segue ninguem.
var king_id: int = UnitSystem.NENHUM

## §62: autosave no DAWN de cada dia. Desliga-se em testes e em ferramentas.
var autosave_enabled: bool = true

var _coins: CoinSystem
var _recruits: RecruitSystem
var _running: bool = false


func _ready() -> void:
	state = GameState.new()
	units = UnitSystem.new()
	EventBus.dawn_broke.connect(_no_amanhecer)


## Comeca um jogo novo: semeia, poe o relogio a andar, e da o primeiro dia.
func start(semente: int) -> void:
	state = GameState.new()
	state.seed = semente
	units = UnitSystem.new()
	_coins = null  # um jogo novo comeca sem moedas no chao
	king_id = UnitSystem.NENHUM  # e sem rei em campo ate alguem o pôr la
	RngService.configure(semente)
	ClockService.start()
	_running = true


## Retoma um save. Repoe o estado, o relogio e a sequencia de cada fluxo — o
## ESTADO dos fluxos, nao a semente, senao a noite recomeca (§42).
func resume(estado: GameState, rng_states: Dictionary) -> void:
	state = estado
	RngService.configure(estado.seed)
	RngService.restore(rng_states)
	ClockService.seek(estado.day, estado.clock_elapsed)
	_running = true


func stop() -> void:
	_running = false
	ClockService.stop()


func running() -> bool:
	return _running


## Um passo. Publico para que um teste possa correr um dia inteiro em
## milissegundos sem esperar por _physics_process.
func step(delta: float) -> void:
	state.tick += 1

	ClockService.step(delta)  # 1 · GameClock.advance — todo o tick
	# 2 · RotSystem — todo o tick .......................... F1-08
	# 3 · JobSystem — uma vez por fase ..................... F1-05
	# 4 · quem quer a moeda e quem anda atras do rei: os dois ESCREVEM alvo, que
	#     e o que o passo 4 escreve ("estado, alvo, intencao de movimento"). Vem
	#     antes da FSM para que ela ja decida sobre o alvo deste tick.
	recruits.seek_coins(units, coins, state.tick)
	recruits.follow(units, king_id)
	for mudanca in units.tick_decisions(state.tick):  # 4 · FSM, 1/6 por tick
		EventBus.queue(
			&"unit_state_changed", [mudanca[&"unit_id"], mudanca[&"from"], mudanca[&"to"]]
		)
	units.tick_movement(delta)  # 5 · MovementSystem — todo o tick
	coins.tick(delta)  # 5 · o arco e a queda, antes de o passo 8 as ler
	_apanhar_do_chao()  # 5 · apanhar e ser recrutado sao consequencia de chegar
	# 6 · CombatSystem — todo o tick ....................... F1-07
	# 7 · EconomySystem — uma vez por fase ................. F1-10
	# 8 · BuildSystem — todo o tick ........................ F1-01
	# 9 · DebtSystem e DiplomacySystem — uma vez por dia ... F1-14
	# 10 · KingAISystem — uma vez por dia, por imperio ..... F2

	_espelhar_relogio()
	EventBus.flush()  # 11 · fim do tick, com o estado ja consolidado


## O Verbo 1 (§61). A ponte entre o sistema puro e o que ele nao pode tocar: o
## sorteio do desvio sai do fluxo `economy` — onde a moeda cai afeta a simulacao,
## por isso e determinista — e o evento sai do catalogo da §46.
func drop_coin(x: float, faixa: Band.Kind, quanto: int, origem: StringName) -> int:
	var desvio := RngService.float_range(&"economy", -CoinSystem.DESVIO_MAX, CoinSystem.DESVIO_MAX)
	var coin_id := coins.drop(state, x, faixa, quanto, desvio)
	EventBus.queue(&"coin_dropped", [x, int(faixa), quanto, origem])
	return coin_id


## Apanhar, tambem pelo catalogo. `espaco` e o que falta encher no saco, e vem
## de UnitData.coin_capacity — a capacidade nao esta escrita em lado nenhum aqui.
func collect_coins(unit_id: int, x: float, faixa: Band.Kind, espaco: int) -> int:
	var valores := coins.amounts_by_id()
	var apanhadas := coins.collect(x, faixa, espaco)
	var total := coins.value_of(apanhadas, valores)
	if total > 0:
		EventBus.queue(&"coin_collected", [unit_id, total])
	return total


## Passo 5 do §43, a seguir ao movimento: quem chegou a uma moeda apanha-a, e
## quem ainda nao era de ninguem e acabou de apanhar o seu preco passa a ser teu.
##
## As duas coisas sao consequencia de ter CHEGADO, e por isso correm depois do
## movimento e nao antes. O §43 nao tem um passo para a apanha — a Q-063 diz
## porque e que ela mora aqui, como a Q-061 disse do arco.
func _apanhar_do_chao() -> void:
	if coins.count() == 0:
		return
	var dono_do_rei := _dono_do_rei()
	# Por id crescente (§42): duas unidades a caminho da mesma moeda tem de dar
	# sempre a mesma vencedora, e a ordem das colunas nao e estavel.
	var por_id := units.ids.duplicate()
	por_id.sort()
	for unit_id in por_id:
		var i := units.index_of(unit_id)
		var moeda := units.target_ids[i]
		if moeda == UnitSystem.NENHUM or not units.alive(i):
			continue
		var espaco := units.coin_capacities[i] - units.carried_coins[i]
		if espaco <= 0:
			continue
		var era_de_ninguem := recruits.vagrant(units, i)
		var apanhado := coins.collect_one(moeda, units.xs[i], units.bands[i] as Band.Kind, espaco)
		if apanhado <= 0:
			continue
		units.target_ids[i] = UnitSystem.NENHUM
		units.carried_coins[i] += apanhado
		EventBus.queue(&"coin_collected", [unit_id, apanhado])
		if not era_de_ninguem:
			continue
		var preco := units.recruit_costs[i]
		if recruits.hire(units, unit_id, dono_do_rei, apanhado, preco):
			# O §46 da o coin_spent a "Build, recrutamento" — e este e o
			# recrutamento. Nao ha sinal para "deixou de ser de ninguem": o
			# unit_promoted e do JobSystem no catalogo, e usa-lo aqui era
			# inventar. Fica na Q-063.
			EventBus.queue(&"coin_spent", [preco, &"recruit"])


## De quem sao os recrutados. Sem rei em campo nao ha recrutamento: a moeda foi
## apanhada na mesma — o §25 desenha isso — mas nao comprou ninguem.
func _dono_do_rei() -> int:
	var rei := units.index_of(king_id)
	if rei == UnitSystem.NENHUM:
		return RecruitSystem.SEM_DONO
	return units.owners[rei]


func _physics_process(delta: float) -> void:
	if not _running:
		return
	step(delta)


## O relogio e dono do dia e do tempo decorrido; o GameState e o que se grava.
## Copiar aqui, uma vez por tick, evita que os dois divirjam sem ninguem ver.
func _espelhar_relogio() -> void:
	state.day = ClockService.clock.day
	state.clock_elapsed = ClockService.clock.elapsed


func _no_amanhecer(dia: int) -> void:
	# O dia 1 e o amanhecer com que o jogo comeca: gravar ai seria gravar antes
	# de ter acontecido alguma coisa.
	if autosave_enabled and _running and dia > 1:
		SaveService.autosave(state, RngService.snapshot())
