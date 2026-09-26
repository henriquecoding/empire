# src/sim/systems/crown_system.gd — os impulsos reais (§15, §57).
#
# "Um impulso por dia. Cada um tem vantagem e desvantagem — nunca so vantagem. E
# a mecanica que transforma gerir em apostar." Paga-se do saco do rei, como
# tudo (§02), e o efeito e dado: o benefit e o drawback de impulses.csv sao
# chaves que este sistema sabe ler, e nao seis casos escritos a mao (§57).
#
# Das seis chaves de beneficio, tres tem hoje onde pegar — a producao, os
# vagabundos e a fuga. As outras esperam pelo comercio, pela ganancia e pela
# divida, e sao recusadas sem cobrar (Q-110), como as ofertas da Q-099.
#
# Puro: recebe os impulsos, as tropas e os tipos de plantacao ja carregados.
class_name CrownSystem
extends RefCounted

const NENHUM := -1
const TODAS := &"*"

## O que ja sabe ler. Uma chave fora daqui e um impulso por ligar.
const BENEFICIOS := [&"production_mult_today", &"vagrants_become_spearmen", &"no_flee_tonight"]
const TROPA_DA_CHAMADA := &"spearman"
const E_CHAVE := 0
const E_VALOR := 1
const E_DE := 2
const E_ATE := 3

## O ultimo dia em que se usou um impulso.
var used_day := 0
## Efeitos activos: [chave, valor, primeiro dia, ultimo dia] — os indices abaixo.
var effects: Array = []

var _impulsos: Dictionary
var _tropas: Dictionary
var _plantacoes: PackedStringArray


func _init(impulsos: Dictionary, tropas: Dictionary, plantacoes: PackedStringArray) -> void:
	_impulsos = impulsos
	_tropas = tropas
	_plantacoes = plantacoes


func available(id: StringName) -> bool:
	var impulso: ImpulseData = _impulsos.get(id)
	return impulso != null and impulso.benefit in BENEFICIOS


## Os impulsos por id — e a ordem das teclas 1 a 6 da roda (§24, Q-110).
func ids() -> Array[StringName]:
	var saida: Array[StringName] = []
	for id in _impulsos:
		saida.append(id)
	saida.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return saida


## Usa um impulso hoje, se ainda nao se usou nenhum, se ele tem onde pegar e se o
## saco do rei chega. Devolve verdadeiro se usou.
func use(id: StringName, dia: int, unidades: UnitSystem, rei: int) -> bool:
	var i := unidades.index_of(rei)
	if used_day == dia or not available(id) or i == NENHUM or not unidades.alive(i):
		return false
	var impulso: ImpulseData = _impulsos[id]
	if unidades.carried_coins[i] < impulso.coin_cost:
		return false
	unidades.carried_coins[i] -= impulso.coin_cost
	used_day = dia
	effects.append([impulso.benefit, impulso.benefit_value, dia, dia])
	var de := dia if impulso.drawback_days == 0 else dia + 1
	effects.append([impulso.drawback, impulso.drawback_value, de, dia + impulso.drawback_days])
	if impulso.benefit == &"vagrants_become_spearmen":
		_chamar_as_armas(unidades, unidades.owners[i])
	return true


## Quanto rende uma obra deste tipo hoje, por cima do que ja rendia.
func yield_mult(dia: int, kind: StringName) -> float:
	var fator := 1.0
	for e in _de(dia):
		match e[E_CHAVE]:
			&"production_mult_today":
				fator *= e[E_VALOR]
			&"production_zero_today":
				fator = 0.0
			&"farms_idle_tomorrow":
				if kind in _plantacoes:
					fator = 0.0
	return fator


## Vigilia: esta noite ninguem foge (§07 pede a fuga; o impulso tira-a).
func steadfast(dia: int) -> bool:
	for e in _de(dia):
		if e[E_CHAVE] == &"no_flee_tonight":
			return true
	return false


## Ao amanhecer do dia: o custo da vigilia — a vida de cada tropa tua cai ao que
## o impulso diz, uma vez. Esquece os efeitos que ja passaram.
func dawn(dia: int, unidades: UnitSystem) -> void:
	for e in _de(dia):
		if e[E_CHAVE] != &"troop_health_mult_tomorrow" or e[E_DE] != dia:
			continue
		for i in unidades.count():
			if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
				continue
			var teto := ceili(unidades.max_healths[i] * float(e[E_VALOR]))
			unidades.healths[i] = mini(unidades.healths[i], teto)
		e[E_DE] = dia + 1  # aplicado: nao volta a cortar no mesmo dia
	effects = effects.filter(func(e: Array) -> bool: return e[E_ATE] >= dia)


func to_dict() -> Dictionary:
	return {&"used_day": used_day, &"effects": effects.duplicate(true)}


func from_dict(guardado: Dictionary) -> void:
	used_day = guardado.get(&"used_day", 0)
	effects = guardado.get(&"effects", []).duplicate(true)


func _de(dia: int) -> Array:
	return effects.filter(func(e: Array) -> bool: return e[E_DE] <= dia and dia <= e[E_ATE])


## "Todos os vagabundos viram lanceiros gratis": os que ainda nao sao de ninguem
## passam a ser teus, e a lanca e a do lanceiro (Q-110).
func _chamar_as_armas(unidades: UnitSystem, dono: int) -> void:
	var lanceiro: UnitData = _tropas.get(TROPA_DA_CHAMADA)
	if lanceiro == null:
		return
	for i in unidades.count():
		if unidades.owners[i] != RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		if unidades.data_ids[i] != &"vagrant":
			continue
		TrainingSystem.retrain(unidades, i, lanceiro)
		unidades.owners[i] = dono
