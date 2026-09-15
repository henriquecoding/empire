# tests/support/campaign.gd — dez dias seguidos no cenario do §07 (F1-16).
#
# O §66 da a Fase 1 um criterio de saida de uma linha: "sobreviver 10 dias e
# possivel e nao e trivial". Uma noite nao responde a isso — o F1-15 mede noites
# e e outra pergunta. Esta mede a PARTIDA: monta a defesa uma vez, corre dez
# noites sem parar, e diz se o castelo-arvore ficou de pe.
#
# Nao ha jogador. O que esta de pe ao primeiro crepusculo e o que la esta ao
# decimo amanhecer, e e de proposito: o que se quer medir e se uma defesa DADA
# aguenta a curva do §74, e nao se alguem a sabe conduzir. Por isso a defesa e
# um argumento — e e comparando duas que se responde as duas metades do §66:
# uma que aguenta da o "possivel", uma que nao aguenta da o "nao trivial".
#
# E um objeto e nao funcoes estaticas por uma razao do GDScript: as lambdas
# capturam os locais POR VALOR, e um contador dentro de uma lambda nao chegava
# ca fora. Os totais sao campos, e os ouvintes sao metodos.
extends RefCounted

const Harness := preload("res://tests/sim_harness.gd")

const PASSO := 1.0 / 30.0
const PRIMEIRO_DIA := 1

## As chaves do que uma partida devolve.
const DIAS := &"days"
const CAIU := &"fell_on_day"
const AGUENTOU := &"survived"
const MORTES := &"deaths"
const MUROS := &"walls_lost"
const NOITES := &"nights"
const VIDA := &"core_ratio"
const SEGUNDOS := &"seconds"

var _mortes: int = 0
var _muros: int = 0
var _noites: int = 0
var _caiu: int = 0


## Corre `dias` dias inteiros com a defesa que o `h` descreve. Devolve o dia em
## que o nucleo caiu — zero se aguentou — e o que custou pelo caminho.
func run(h: Harness, dias: int) -> Dictionary:
	h.both_flanks = true  # cada noite sorteia o seu lado (§51): muro nos dois
	h.arm(PRIMEIRO_DIA)
	ClockService.seek(PRIMEIRO_DIA, 0.0)
	SimLoop.state.day = PRIMEIRO_DIA
	_mortes = 0
	_muros = 0
	_noites = 0
	_caiu = 0
	_ouvir()

	var passos := int(h.day_seconds() * dias / PASSO)
	var t0 := Time.get_ticks_usec()
	for _i in passos:
		SimLoop.step(PASSO)
		# §10: "se o castelo-arvore cair, cai a partida". O `game.gd` para aqui e
		# isto para tambem — continuar a simular depois da derrota media dias que
		# ninguem chegou a jogar, e punha a medicao a demorar o dobro.
		if _caiu > 0:
			break
	var segundos := float(Time.get_ticks_usec() - t0) / 1000000.0
	EventBus.flush()  # o night_survived da ultima alvorada (F1-15)
	_calar()

	return {
		DIAS: dias,
		CAIU: _caiu,
		AGUENTOU: _caiu == 0,
		MORTES: _mortes,
		MUROS: _muros,
		NOITES: _noites,
		VIDA: _vida_do_nucleo(),
		SEGUNDOS: segundos,
	}


## Quanto resta do castelo-arvore, de 0 a 1. E a margem: aguentar com 0,9 e
## aguentar com 0,05 sao a mesma resposta a "sobreviveu?" e duas respostas
## diferentes a "e trivial?".
func _vida_do_nucleo() -> float:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return float(vaga.health) / maxf(1.0, float(vaga.max_health()))
	return 0.0


func _ouvir() -> void:
	EventBus.unit_died.connect(_morreu)
	EventBus.wall_breached.connect(_rompeu)
	EventBus.building_destroyed.connect(_caiu_obra)
	EventBus.night_survived.connect(_sobreviveu)


func _calar() -> void:
	EventBus.unit_died.disconnect(_morreu)
	EventBus.wall_breached.disconnect(_rompeu)
	EventBus.building_destroyed.disconnect(_caiu_obra)
	EventBus.night_survived.disconnect(_sobreviveu)


func _morreu(_unit_id: int, _x: float, _band: int, _drops: PackedStringArray) -> void:
	_mortes += 1


func _rompeu(_wall_id: int) -> void:
	_muros += 1


## §10: "se o castelo-arvore cair, cai a partida". Guarda-se o PRIMEIRO dia em
## que isso acontece — depois de cair ele nao volta a cair, e o dia interessa
## mais do que o facto.
func _caiu_obra(building_id: int, _x: float) -> void:
	if _caiu > 0:
		return
	var i := SimLoop.builds.index_of(building_id)
	if i != BuildSlot.NENHUM and SimLoop.builds.slots[i].kind == BuildSlot.NUCLEO:
		_caiu = SimLoop.state.day


func _sobreviveu(_dia: int, _mortes_da_noite: int, _muros_da_noite: int) -> void:
	_noites += 1
