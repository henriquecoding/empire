# tools/vistoria.gd — uma partida longa, vigiada tick a tick (§45, §63).
#
# Fora do jogo: `tools/` esta no exclude_filter do export.
#
# A suite prova que cada sistema faz o que promete. Isto e outra coisa: monta o
# greybox INTEIRO — a regiao, a gente, o relogio, a noite — e corre dias
# seguidos a perguntar, a cada passo, se o estado ainda faz sentido. E o que
# apanha o defeito que nenhum teste de unidade ve, porque nasce de dois sistemas
# certos a falar um com o outro.
#
#     godot --headless --path . scenes/tests/vistoria.tscn -- --dias 12
#
# Nao afina nada e nao corrige nada: imprime, e sai com 1 se encontrou alguma
# coisa. O que ele encontra ou vira defeito e correccao, ou vira pergunta em
# docs/QUESTIONS.md — a regra do AGENTS.md nao muda por isto ser uma ferramenta.
extends Node

const PASSO := 1.0 / 30.0
const DIAS := 8
const SEMENTE := 20260916

## Quanto um corpo pode sair da regiao antes de isso ser defeito. Meia largura
## de ecra: a camara nao chega la, e o §21 diz que a regiao tem principio e fim.
const MARGEM := 640.0

## Quantos segundos uma tropa pode ficar parada longe do alvo antes de contar
## como presa. Uma tropa em posto esta parada de direito; uma a caminho, nao.
const PRESA_S := 20.0
const PRESA_PX := 2.0

## Uma linha da marcha. Os campos entram em tres grupos — o relogio, o campo e o
## estado — porque e por grupos que a tabela se le.
const LINHA := "  %3d | %-10s | %4d/%-5d | %6d | %6d | %6d | %5d | %d"

var _achados: Array[String] = []
var _parada_desde: Dictionary = {}
var _luta_desde: Dictionary = {}
var _fase: int = -1
var _dias: int = DIAS
var _ultima_linha: int = -1


func _ready() -> void:
	_dias = int(_argumento("dias", DIAS))
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)
	Greybox.build()
	print("\nvistoria — %d dias no greybox com piloto, semente %d" % [_dias, SEMENTE])
	print("  dia | fase       |  meus/tropas | bichos | moedas | nucleo | rei | achados")
	_correr()
	_relatorio()


func _correr() -> void:
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var total := float(_dias) * relogio.day_seconds
	var passos := int(total / PASSO)
	for _i in passos:
		# §10: "se cair, cai a partida". Quem para o relogio e a `game.gd`, e isto
		# nao tem cena — sem esta pergunta media dias de uma partida perdida, e
		# foi o que fez nas primeiras corridas: sete (Q-081).
		if SimLoop.builds.fallen(BuildSlot.NUCLEO):
			print("\n  o castelo-arvore caiu ao dia %d — a partida acabou" % SimLoop.state.day)
			break
		if not SimLoop.running():
			_nota("a simulacao parou sozinha ao dia %d" % SimLoop.state.day)
			break
		Autopilot.step(SimLoop)
		SimLoop.step(PASSO)
		_vigiar()
		_marco()


## O que se pergunta a cada passo. Sao invariantes e nao afinacao: qualquer uma
## delas falsa e um estado que o jogo nao sabe desenhar nem gravar.
func _vigiar() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		_no_mundo("tropa", unidades.ids[i], unidades.xs[i])
		_vida("tropa", unidades.ids[i], unidades.healths[i], unidades.max_healths[i])
		_presa(i)
	var bichos := SimLoop.creatures
	for i in bichos.count():
		_no_mundo("bicho", bichos.ids[i], bichos.xs[i])
		_vida("bicho", bichos.ids[i], bichos.healths[i], bichos.max_healths[i])
	var moedas := SimLoop.coins
	for i in moedas.count():
		_no_mundo("moeda", moedas.ids[i], moedas.xs[i])
	_ids_unicos()
	_fases()
	_luta_sem_alvo()


## §21: a regiao tem principio e fim. Um corpo fora dela nao se ve, nao se
## alcanca, e continua a contar para tudo o que o tick soma.
func _no_mundo(que: String, id: int, x: float) -> void:
	if not is_finite(x):
		_nota("%s %d tem x = %s" % [que, id, x])
		return
	if x < -MARGEM or x > SimLoop.world_width + MARGEM:
		_nota("%s %d saiu da regiao: x = %.0f de %.0f" % [que, id, x, SimLoop.world_width])


func _vida(que: String, id: int, vida: int, tecto: int) -> void:
	if vida < 0 or vida > tecto:
		_nota("%s %d tem %d de vida em %d" % [que, id, vida, tecto])


## Uma tropa viva, longe do alvo e parada ha muito tempo. Nao e regra do dossie:
## e a pergunta que um jogador faz quando ve alguem encostado a nada.
func _presa(i: int) -> void:
	var unidades := SimLoop.units
	var id := unidades.ids[i]
	# Quem esta a bater nao anda, e isso e o §50 e nao um defeito: "parar a bater
	# e a leitura que o §50 defende". O primeiro relato desta vistoria foi o
	# monarca a aguentar cinco Rastejantes seguidos — 24 s de pe, e certo.
	var luta := unidades.states[i] == UnitFsm.State.FIGHT
	var chegou := absf(unidades.target_xs[i] - unidades.xs[i]) <= PRESA_PX
	if not unidades.alive(i) or luta or chegou:
		_parada_desde.erase(id)
		return
	var antes: Array = _parada_desde.get(id, [unidades.xs[i], 0.0])
	if absf(float(antes[0]) - unidades.xs[i]) > PRESA_PX:
		_parada_desde[id] = [unidades.xs[i], 0.0]
		return
	var quanto := float(antes[1]) + PASSO
	_parada_desde[id] = [antes[0], quanto]
	if quanto > PRESA_S and quanto <= PRESA_S + PASSO:
		var longe := unidades.target_xs[i] - unidades.xs[i]
		var onde := "x=%.0f com alvo a %.0f px" % [unidades.xs[i], longe]
		_nota(
			"tropa %d parada ha %.0f s em %s (estado %d)" % [id, quanto, onde, unidades.states[i]]
		)


## O impasse que o `unit_fsm.gd` deixa em aberto: "if atual == FIGHT: return
## atual" — a FSM nunca sai de FIGHT sozinha, e quem a tira de la e o
## `target_picker._estado()`. Esse SALTA quem nao tem dono e quem nao da dano.
## Uma tropa que entrasse em FIGHT e deixasse de ser vista por ele ficava presa
## para sempre: nao anda (§50) e nao bate. Hoje nao acontece; isto e o alarme.
func _luta_sem_alvo() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		if unidades.states[i] != UnitFsm.State.FIGHT or not unidades.alive(i):
			continue
		if SimLoop.creatures.count() > 0:
			_luta_desde.erase(unidades.ids[i])
			continue
		# Um tick de FIGHT sem criaturas e normal e nao e defeito: o `choose`
		# poe o estado e o `resolve` mata a ultima criatura no MESMO passo, e
		# quem limpa e o `choose` do passo seguinte. O que nao pode e durar.
		var quanto: float = float(_luta_desde.get(unidades.ids[i], 0.0)) + PASSO
		_luta_desde[unidades.ids[i]] = quanto
		if quanto > PRESA_S:
			var quem := "tropa %d (%s)" % [unidades.ids[i], unidades.data_ids[i]]
			_nota("%s ficou em FIGHT sem criaturas ao dia %d" % [quem, SimLoop.state.day])


## §45: um id nasce de um contador so. Dois corpos com o mesmo id e um save que
## se repoe trocado, e ninguem da por isso ate ser tarde.
func _ids_unicos() -> void:
	var vistos := {}
	for col in [SimLoop.units.ids, SimLoop.creatures.ids, SimLoop.coins.ids]:
		for id in col:
			if vistos.has(id):
				_nota("o id %d esta em duas coleccoes" % id)
				return
			vistos[id] = true


## §48: as seis fases andam por ordem e dao a volta. Uma fase saltada e um dia
## em que a economia nao correu, e o §49 corre UMA vez por fase.
func _fases() -> void:
	var agora := int(ClockService.clock.current_phase())
	if agora == _fase:
		return
	var fases := 6
	if _fase >= 0 and agora != (_fase + 1) % fases:
		_nota("a fase saltou de %d para %d" % [_fase, agora])
	_fase = agora


## Uma linha por fase, para que se veja a partida a andar e nao so o fim dela.
func _marco() -> void:
	if int(ClockService.clock.current_phase()) != _fase or not _nova_fase():
		return
	var relogio: Array = [SimLoop.state.day, Hud.FASES[_fase]]
	var campo: Array = [_meus(), SimLoop.units.count(), SimLoop.creatures.count()]
	var estado: Array = [SimLoop.coins.count(), _nucleo(), _do_rei(), _achados.size()]
	print(LINHA % (relogio + campo + estado))


func _nova_fase() -> bool:
	var chave := SimLoop.state.day * 10 + _fase
	if chave == _ultima_linha:
		return false
	_ultima_linha = chave
	return true


## Quantos sao TEUS. O total nao muda com o recrutamento — um vagabundo
## recrutado continua a ser a mesma linha — e por isso o total nao diz se o
## minuto 0:20 do §25 esta a acontecer. Este diz.
func _meus() -> int:
	var n := 0
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO and SimLoop.units.alive(i):
			n += 1
	return n


## A que distancia de casa esta o rei, em px. O §07 da-lhe um raio de presenca
## dentro do qual ninguem foge e o §25 poe quem nao tem posto a segui-lo: sem
## esta coluna, uma noite perdida por ma jogada le-se como defeito do tick.
func _do_rei() -> int:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return int(absf(SimLoop.units.xs[i] - SimLoop.core_x)) if i != UnitSystem.NENHUM else -1


func _nucleo() -> int:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga.health
	return 0


func _nota(o_que: String) -> void:
	# Uma vez cada: uma anomalia por tick durante uma noite enche o ecra e
	# esconde as outras.
	if not _achados.has(o_que):
		_achados.append(o_que)


func _relatorio() -> void:
	if _achados.is_empty():
		print("\nvistoria: %d dias sem nada a apontar" % _dias)
		get_tree().quit()
		return
	print("\nvistoria: %d coisa(s) a apontar" % _achados.size())
	for a in _achados:
		print("  · %s" % a)
	get_tree().quit(1)


func _argumento(nome: String, por_omissao: float) -> float:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--" + nome)
	return float(args[i + 1]) if i >= 0 and i + 1 < args.size() else por_omissao
