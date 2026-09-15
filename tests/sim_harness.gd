# tests/sim_harness.gd — o cenario fechado do §07, em headless e a passo fixo.
#
# O §07 escreve a receita por extenso, e e a unica do dossie que se MONTA em vez
# de se ler: "monta um cenario fechado: um muro, seis arqueiros, uma noite de
# 105 s, vagas de Rastejantes crescentes. Ajusta ate a noite ser ganha com 1-2
# mortes no dia 5 e perdida sem torre no dia 8. Este microteste e a fundacao de
# todo o balanceamento posterior — e cabe num unico ficheiro de teste."
#
# Isto e esse instrumento, e o §66 da-lhe este nome. A regiao — o que la esta —
# e o `tests/support/closed_region.gd`; aqui fica o que se FAZ com ela: armar o
# dia, correr a noite ao passo fixo do §19, e devolver o que ela deu.
#
# Nao mede por sua conta: as mortes e os muros vem do `night_survived` da §46 —
# o mesmo numero que o `docs/qa/PLAYTEST_PLAN.md` manda ler a mao. Um instrumento
# com contabilidade propria diverge do jogo sem ninguem dar por isso.
#
# O que este ficheiro NAO faz, de proposito: afinar. O F1-15 entrega o
# instrumento; mexer nos numeros e o F1-16, e eles vivem em data/source/.
extends RefCounted

const Region := preload("res://tests/support/closed_region.gd")

const PASSO := 1.0 / 30.0
const SEMENTE := 20260915
const UM_MILHAO := 1000000.0

## As chaves do que uma noite devolve. Constantes e nao texto solto: quem le o
## resultado e um teste, e um teste que erra a chave passa a medir um `null`.
const DIA := &"day"
const MORTES := &"deaths"
const MUROS := &"walls_lost"
const INVOCADAS := &"summoned"
const ABATES := &"kills"
const CONTACTO := &"reached_wall"
const DE_PE := &"held"
const GUARDADO := &"defended"

# ── O cenario. Sao as pecas que o §07 nomeia, e mais nenhuma.
## "seis arqueiros" (§07).
var archers: int = 6
var spearmen: int = 0
## "perdida SEM TORRE no dia 8" (§07): a torre e a variavel da experiencia, e e
## por isso que e uma bandeira e nao um numero.
var tower: bool = false
## §07: "o Alado obriga a torre alta" — e a unica obra que atinge a faixa aerea
## (Q-006). Medida aos dez dias, o que ela vale hoje sao os DOIS POSTOS que
## publica, e nao a altura: o Alado atravessa tudo e nao morde nada (Q-075).
var high_tower: bool = false
## Um muro por flanco. Uma noite mede-se com o do lado por onde ela vem — o "um
## muro" do §07 — mas dias seguidos trazem um sorteio de lado por noite (§51), e
## esses pedem os dois.
var both_flanks: bool = false
## "vagas de Rastejantes crescentes" (§07), e so isso. Com a tabela inteira a
## noite 5 do §07 nao tem combate nenhum para medir — o Alado do dia 4 nao se
## deixa atingir por quem esta no chao (Q-006). `false` devolve a mancha do
## jogo, que e o que o §66 mede.
var crawlers_only: bool = true
## O degrau do §10 de cada muralha — esquerda, direita; um valor so poe o mesmo
## degrau dos dois lados. Dez dias de jogo sao dez dias a subi-la, e um degrau
## por flanco e o que deixa pôr um Bastiao — "unico por imperio" (§10) — e ferro
## no outro lado, em vez de medir sempre uma defesa que o jogo nao deixa ter.
var wall_levels: PackedInt32Array = PackedInt32Array([1])
var seed: int = SEMENTE

var _mortes: int = 0
var _muros: int = 0
var _invocadas: int = 0
var _contacto: int = 0
var _vivas: int = 0


## Uma noite do dia pedido, de crepusculo a amanhecer. Devolve o que ela deu.
##
## Os abates sao as invocadas menos as que ainda estavam vivas no ultimo passo
## antes do amanhecer. Nao se contam pelo `creature_died`: o NightWatch emite-o
## TAMBEM por cada criatura que se dissolve a alvorada (§51), e com ele uma noite
## em que ninguem disparou um tiro dava a tabela cheia de abates.
func night(dia: int) -> Dictionary:
	arm(dia)
	var chegou := _ate(GameClock.Phase.NIGHT)
	var guardado := chegou and _ha_muro_no_caminho()
	_ate(GameClock.Phase.DAWN)
	# O `night_survived` e enfileirado pelo ouvinte do `dawn_broke`, ou seja
	# DURANTE a entrega — e a fila do passo 11 serve isso no tick seguinte, de
	# proposito. Sem esta entrega a mais, a noite acabava sempre a zeros.
	EventBus.flush()
	return {
		DIA: dia,
		MORTES: _mortes,
		MUROS: _muros,
		INVOCADAS: _invocadas,
		ABATES: _invocadas - _vivas,
		CONTACTO: _contacto,
		DE_PE: not SimLoop.builds.fallen(BuildSlot.NUCLEO),
		GUARDADO: guardado,
	}


## Monta o cenario e poe o relogio a um passo do crepusculo do dia pedido.
## Publico porque medir o custo de um tick precisa de um mundo montado e de mais
## nada — correr a noite inteira primeiro so acrescentava ruido a medicao.
func arm(dia: int) -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(seed)
	if crawlers_only:
		_so_rastejantes()
	_ouvir()
	_mortes = 0
	_muros = 0
	_invocadas = 0
	_contacto = 0
	_vivas = 0
	Region.build(_flanco(), archers, spearmen, _torres(), both_flanks, wall_levels)
	# O dia entra nos dois sitios, como no resume() do SimLoop: o relogio e dono
	# dele, mas quem o le a meio do tick e o GameState, e o espelho so corre no
	# fim (passo 11). Sem esta linha o crepusculo do dia 5 pedia a massa do dia
	# 1 — e as dez noites davam a mesma tabela, que foi o que deram.
	SimLoop.state.day = dia
	ClockService.seek(dia, _vespera())


## Corre `quantos` dias inteiros desde o primeiro, e devolve os segundos de
## relogio de parede que isso custou. E a medida do §66 — "dez dias em menos de
## dez segundos" — e o unico numero deste ficheiro que nao e sobre o jogo.
func days(quantos: int) -> float:
	both_flanks = true  # um sorteio de lado por noite (§51): os dois flancos
	arm(1)
	ClockService.seek(1, 0.0)
	var passos := int(_relogio().day_seconds * quantos / PASSO)
	var t0 := Time.get_ticks_usec()
	for _i in passos:
		SimLoop.step(PASSO)
	return float(Time.get_ticks_usec() - t0) / UM_MILHAO


## Larga o cenario. O autosave volta a ficar como estava: um teste que o deixasse
## desligado escondia o F1-14 do teste seguinte.
func stop() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## Quantos dias cabem num dia de relogio. So para quem imprime o custo.
func day_seconds() -> float:
	return _relogio().day_seconds


## Ha muro de pe entre a mancha e o nucleo? E a pergunta que faz do cenario um
## cenario: sem ela, uma noite medida com o muro no flanco errado dava um numero
## com todo o ar de ser bom. Le-se do mundo, com a funcao que o proprio combate
## usa, e nao do sorteio que escolheu onde por o muro.
func _ha_muro_no_caminho() -> bool:
	var mancha := SimLoop.night.rot.position_x()
	return SimLoop.builds.barrier(mancha, SimLoop.core_x, Band.Kind.SURFACE) != null


## De que lado vem a mancha esta noite, sem gastar o sorteio. O RngService
## entrega o gerador a quem testa de proposito — "so para testes e para o ecra
## de depuracao" — e repor o `state` depois de o ler deixa a sequencia onde
## estava: a noite que se mede e a que a semente produz, e nao uma vizinha.
##
## E uma copia da regra do NightWatch, e uma copia pode envelhecer. Nao apodrece
## em silencio: o `GUARDADO` de cada noite pergunta ao mundo se o muro ficou
## mesmo no caminho, e uma copia velha da-o a falso na primeira corrida.
func _flanco() -> int:
	var r := RngService.stream(&"rot")
	var estado := r.state
	var lado := 1 if r.randi_range(0, 1) == 1 else -1
	r.state = estado
	return lado


## Uma mancha com uma so criatura na tabela. E o que faz do §07 um microteste: a
## regra de escolha do §51 — "a mais cara que cabe" — continua intacta, e o que
## muda e o que ha para escolher. A massa do dia nao se toca, e por isso as vagas
## crescem com o dia, como o §07 pede.
func _so_rastejantes() -> void:
	var perfil := Registry.entry(&"rot", &"default") as RotProfile
	var rastejante := Registry.entry(&"creatures", &"crawler") as CreatureData
	SimLoop.night.rot = RotSystem.new(perfil, [rastejante] as Array[CreatureData])


## As torres que esta defesa tem, pela ordem em que o §10 as escreve. Duas
## bandeiras e nao uma lista porque sao duas DECISOES diferentes do jogador, e o
## §66 mede-se a ligar e a desligar cada uma por si.
func _torres() -> Array[StringName]:
	var quais: Array[StringName] = []
	if tower:
		quais.append(Region.TORRE)
	if high_tower:
		quais.append(Region.TORRE_ALTA)
	return quais


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


## Um passo antes do crepusculo. Comecar ai e o que faz disto uma NOITE e nao um
## dia: o que vem antes — trabalho, producao, recrutamento — nao entra no §07.
func _vespera() -> float:
	var duracoes := _relogio().phase_durations
	var t := 0.0
	for i in int(GameClock.Phase.DUSK):
		t += duracoes[i]
	return t - PASSO


## Corre ate a fase pedida. O tecto e dois dias: uma fase que nao chega e um
## defeito no relogio, e esperar por ela para sempre escondia-o.
##
## As criaturas contam-se ANTES de cada passo, e por isso `_vivas` fica com o que
## havia no ultimo passo antes do amanhecer — que e o passo em que elas se
## dissolvem. E o unico sitio de onde esse numero se pode tirar.
func _ate(fase: GameClock.Phase) -> bool:
	for _i in int(_relogio().day_seconds / PASSO) * 2:
		_vivas = SimLoop.creatures.count()
		SimLoop.step(PASSO)
		if ClockService.clock.current_phase() == fase:
			return true
	return false


## Os sinais da §46, uma vez so. Ligar a cada arm() contava cada invocacao tantas
## vezes quantas as noites ja corridas.
func _ouvir() -> void:
	if not EventBus.night_survived.is_connected(_sobreviveu):
		EventBus.night_survived.connect(_sobreviveu)
	if not EventBus.rot_summoned.is_connected(_invocou):
		EventBus.rot_summoned.connect(_invocou)
	if not EventBus.contact_slot_taken.is_connected(_encostou):
		EventBus.contact_slot_taken.connect(_encostou)


func _sobreviveu(_dia: int, mortes: int, muros: int) -> void:
	_mortes = mortes
	_muros = muros


func _invocou(_creature_id: StringName, _x: float, _massa: float) -> void:
	_invocadas += 1


## Quantas chegaram a encostar ao muro. E a pressao que o §07 mede: uma noite em
## que nenhuma la chega foi ganha longe da muralha, e isso le-se aqui e em mais
## lado nenhum — nem as mortes nem os abates o dizem.
func _encostou(_wall_id: int, _slot: int, _creature_id: int) -> void:
	_contacto += 1
