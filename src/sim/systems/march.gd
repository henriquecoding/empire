# src/sim/systems/march.gd — a marcha: quem sai do imperio para conquistar (§13;
# Q-146, Q-154, o dono a 29/09/2026).
#
# O §13: "Designas tropas para avancar. Elas saem do imperio, que fica desguarnecido
# nessa noite. Esta e a decisao." E o dono: "o rei nunca sai para longe do reino;
# quem vai para longe sao as classes jogaveis" (Q-146) — e "a comitiva tem um teto
# tambem" (Q-154), como o barco do Kingdom: New Lands (3 construtores, 4 arqueiros,
# 3 cavaleiros).
#
# Vai quem e teu, esta perto do rei e na faixa dele, ate ao teto de cada papel (a
# tag do units.csv: builder, ranged, melee). Saem das colunas; na alvorada em que a
# marcha acaba voltam, e o que trazem depende de quantos foram.
#
# Puro: recebe as tropas, os perfis e os numeros.
class_name March
extends RefCounted

const NENHUM := -1

## Os perfis de quem foi (data ids), por ordem de id.
var party: PackedStringArray = PackedStringArray()
## A regiao (indice no plano) que a marcha foi conquistar.
var target: int = NENHUM
## O dia em cuja alvorada a marcha volta.
var returns: int = 0


func marching() -> bool:
	return target != NENHUM


## Quem iria agora: teus, vivos, na faixa do rei e a `alcance` dele, ate ao teto
## de cada papel (`tetos`: tag -> quantos). Por id crescente (§42).
static func who(
	unidades: UnitSystem, perfis: Dictionary, rei: int, alcance: float, tetos: Dictionary
) -> PackedInt32Array:
	var r := unidades.index_of(rei)
	var vao := PackedInt32Array()
	if r == NENHUM:
		return vao
	var contados := {}
	var ids := unidades.ids.duplicate()
	ids.sort()
	for unit_id in ids:
		var i := unidades.index_of(unit_id)
		if i == r or not unidades.alive(i) or unidades.owners[i] != unidades.owners[r]:
			continue
		if (
			unidades.bands[i] != unidades.bands[r]
			or absf(unidades.xs[i] - unidades.xs[r]) > alcance
		):
			continue
		var perfil: UnitData = perfis.get(unidades.data_ids[i])
		var papel := _papel(perfil, tetos)
		if papel == &"" or int(contados.get(papel, 0)) >= int(tetos[papel]):
			continue
		contados[papel] = int(contados.get(papel, 0)) + 1
		vao.append(unit_id)
	return vao


## Parte: quem vai sai das colunas. `noites` e quantas fica fora.
func start(
	unidades: UnitSystem, quem: PackedInt32Array, regiao: int, dia: int, noites: int
) -> void:
	party = PackedStringArray()
	for unit_id in quem:
		party.append(String(unidades.data_ids[unidades.index_of(unit_id)]))
		unidades.remove(unit_id)
	target = regiao
	returns = dia + noites


## Se e a alvorada da volta.
func due(dia: int) -> bool:
	return marching() and dia >= returns


## Acaba: devolve quem volta, e esquece a marcha.
func finish() -> PackedStringArray:
	var voltam := party
	party = PackedStringArray()
	target = NENHUM
	return voltam


static func _papel(perfil: UnitData, tetos: Dictionary) -> StringName:
	if perfil == null:
		return &""
	for tag in perfil.tags:
		if tetos.has(tag):
			return tag
	return &""


func to_dict() -> Dictionary:
	return {&"party": party, &"target": target, &"returns": returns}


func from_dict(d: Dictionary) -> void:
	party = PackedStringArray(d.get(&"party", PackedStringArray()))
	target = int(d.get(&"target", NENHUM))
	returns = int(d.get(&"returns", 0))
