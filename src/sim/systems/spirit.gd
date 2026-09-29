# src/sim/systems/spirit.gd — o animo do reino (§07, §74, §76; Q-102, o dono a
# 29/09/2026: "gosto desse sistema de moral, faca uma densa pesquisa e elabore algo
# concreto que faca sentido ao meu jogo").
#
# O §07 tem moral por tropa (fugir, e o raio do rei); o §74 e o §76 falam de um
# moral do IMPERIO ("serra-lo tira 1 ponto de moral ao imperio durante 2 dias")
# que nao existia. A pesquisa (docs/recovery/PESQUISA-MORAL-2026-09-29.md) deu tres
# regras que servem este jogo:
#   · cada acontecimento deixa uma MEMORIA com peso e prazo (RimWorld): o animo e a
#     base mais as memorias vivas, e por isso explica-se sozinho — sabe-se sempre
#     porque esta onde esta, e volta a base quando elas passam;
#   · o animo mexe em tres coisas que ja existem, por limiares e nao por formula
#     continua (Stronghold, Frostpunk): quem foge, quanto se produz, e quanta gente
#     vem aos acampamentos;
#   · o que o mexe e o que o jogador ja decide — a noite ganha, os mortos, o soldo
#     por pagar, a arvore com nome serrada, o povo conquistado ou perdido. Nada de
#     recurso novo para gerir; e um espelho do que ja se fez (Mount & Blade).
#
# Puro: as memorias entram de fora (SpiritWatch), os numeros sao da curva.
class_name Spirit
extends RefCounted

## O animo vai de 0 a 100: e uma percentagem, e nao balanceamento.
const TETO := 100.0
const CHAVE := 0
const PESO := 1
const ATE := 2

## [chave, peso, ultimo dia em que conta], por ordem de chegada.
var memories: Array = []

var _base := 0.0
var _baixo := 0.0
var _alto := 0.0


## Os tres numeros sao da curva (spirit_levels): a base, e os limiares de abatido e
## de animado.
func _init(base: float, baixo: float, alto: float) -> void:
	_base = base
	_baixo = baixo
	_alto = alto


## Uma memoria: `peso` pontos de animo durante `dias` dias a contar de `dia`.
func note(chave: StringName, peso: float, dia: int, dias: int) -> void:
	if is_zero_approx(peso) or dias <= 0:
		return
	memories.append([String(chave), peso, dia + dias - 1])


## O animo agora, de 0 a 100.
func value(dia: int) -> float:
	var total := _base
	for m in memories:
		if int(m[ATE]) >= dia:
			total += float(m[PESO])
	return clampf(total, 0.0, TETO)


## -1 abatido, 0 sereno, +1 animado.
func level(dia: int) -> int:
	var v := value(dia)
	if v < _baixo:
		return -1
	if v > _alto:
		return 1
	return 0


## A alvorada esquece o que ja passou.
func dawn(dia: int) -> void:
	memories = memories.filter(func(m: Array) -> bool: return int(m[ATE]) >= dia)


func to_dict() -> Dictionary:
	return {&"memories": memories.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	memories = d.get(&"memories", []).duplicate(true)
