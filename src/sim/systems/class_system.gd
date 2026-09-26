# src/sim/systems/class_system.gd — a classe do rei (§08), a comecar pelo Monarca.
#
# "Tanque. +10% defesa as tropas num raio. [...] O boost passa a +25% e aplica-se
# ao imperio inteiro." A classe e um arquetipo com duas fases: a primeira e a
# aura a volta do rei, a segunda estende-a ao imperio. "Evolucao custa Semente
# Real (1 para a Fase 2) e uma condicao de feito. [...] Nunca e so dinheiro."
#
# Tres leituras que o dossie nao faz, reversiveis e escritas na Q-114:
#   - "defesa" e menos dano recebido, com a fraccao poupada guardada de golpe para
#     golpe — a mesma leitura do construtor e das muralhas (Q-109);
#   - uma noite "defendida em pessoa" e uma em que, pelo menos num tick, uma tropa
#     tua combateu dentro do raio do rei, na faixa dele;
#   - o gesto de evoluir e o Verbo 1 no nucleo, como consagrar uma arvore (§74).
#
# Puro: as tropas, o rei e a noite entram de fora; os numeros saem do ClassData.
class_name ClassSystem
extends RefCounted

const NENHUM := -1
const PRIMEIRA := 1
## A chave dos parametros de cada fase (classes.csv, `phase*_params`).
const DEFESA := &"defense"
const RAIO := &"radius"

var phase: int = PRIMEIRA
var nights_defended: int = 0

var _dados: ClassData
var _rei: int = NENHUM
var _defendida := false
## A fraccao de dano que a aura ja poupou a cada tropa e ainda nao fez um ponto.
var _poupado: Dictionary = {}


func _init(dados: ClassData) -> void:
	_dados = dados


## A defesa que `i` recebe da classe agora: a da fase em curso se a tropa e tua e
## esta dentro da aura (fase 1) ou em qualquer sitio (fase 2). Nunca o proprio rei.
func defense_of(unidades: UnitSystem, i: int) -> float:
	var r := unidades.index_of(_rei)
	if r == NENHUM or i == r or not unidades.alive(r) or not unidades.alive(i):
		return 0.0
	if unidades.owners[i] != unidades.owners[r]:
		return 0.0
	var params := _params()
	if phase == PRIMEIRA and not _na_aura(unidades, i, r, float(params.get(RAIO, 0.0))):
		return 0.0
	return float(params.get(DEFESA, 0.0))


## O dano que passa de `quanto` num golpe em `unit_id`, depois da defesa.
func soak(unidades: UnitSystem, unit_id: int, quanto: int) -> int:
	var defesa := defense_of(unidades, unidades.index_of(unit_id))
	if defesa <= 0.0:
		return quanto
	var guardado := float(_poupado.get(unit_id, 0.0)) + quanto * defesa
	var poupado := mini(quanto, int(guardado))
	_poupado[unit_id] = guardado - poupado
	return quanto - poupado


## Um tick: quem e o rei, e se esta noite ja houve combate teu dentro da aura.
func watch(unidades: UnitSystem, rei: int, noite: bool) -> void:
	_rei = rei
	if not noite or _defendida:
		return
	var r := unidades.index_of(rei)
	if r == NENHUM or not unidades.alive(r):
		return
	var raio := float(_dados.phase1_params.get(RAIO, 0.0))
	for i in unidades.count():
		if i == r or unidades.owners[i] != unidades.owners[r]:
			continue
		if unidades.states[i] == UnitFsm.State.FIGHT and _na_aura(unidades, i, r, raio):
			_defendida = true
			return


## A alvorada fecha a noite: se foi defendida em pessoa, conta.
func dawn() -> void:
	if _defendida:
		nights_defended += 1
	_defendida = false


## Se ha fase seguinte, a condicao de feito esta cumprida e `sementes` chegam.
func can_evolve(sementes: int) -> bool:
	if phase >= _dados.phase_count or sementes < _dados.evolve_seed_cost:
		return false
	return nights_defended >= _dados.evolve_condition_value


## Evolui, gastando a Semente Real do `estado`. Devolve verdadeiro se evoluiu.
func evolve(estado: GameState) -> bool:
	if not can_evolve(estado.royal_seeds):
		return false
	estado.royal_seeds -= _dados.evolve_seed_cost
	phase += 1
	return true


## Tudo o que muda o proximo golpe vai no save — a fraccao guardada e o rei
## incluidos: sem eles, um jogo carregado divergia do mesmo jogo jogado de seguida.
func to_dict() -> Dictionary:
	return {
		&"phase": phase,
		&"nights": nights_defended,
		&"defended": _defendida,
		&"king": _rei,
		&"soaked": _poupado.duplicate(),
	}


func from_dict(guardado: Dictionary) -> void:
	phase = guardado.get(&"phase", PRIMEIRA)
	nights_defended = guardado.get(&"nights", 0)
	_defendida = guardado.get(&"defended", false)
	_rei = guardado.get(&"king", NENHUM)
	_poupado = guardado.get(&"soaked", {}).duplicate()


func _params() -> Dictionary:
	return _dados.phase1_params if phase == PRIMEIRA else _dados.phase2_params


func _na_aura(unidades: UnitSystem, i: int, r: int, raio: float) -> bool:
	return unidades.bands[i] == unidades.bands[r] and absf(unidades.xs[i] - unidades.xs[r]) <= raio
