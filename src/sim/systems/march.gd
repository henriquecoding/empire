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
# tag do units.csv: builder, ranged, melee). Saem das colunas como estavam (a linha
# inteira, Columns.row) e na alvorada em que a marcha acaba voltam iguais: com a
# vida, as moedas e o id que o nome deles conhece.
#
# O cerco (Q-166; relatorio Kingdom, K6): cada povo do plano tem uma fortaleza, mais
# firme quanto mais adiante. Cada marcha tira-lhe firmeza pelos que foram, e essa
# firmeza nao volta — o portal do Kingdom nao regenera vida. Cai quando a conta chega
# a zero. Nem todos voltam: quem tira no sorteio (fluxo combat, no Realm) menos do
# que a chance de baixa fica no campo.
#
# Puro: recebe as tropas, os perfis, os numeros e os sorteios.
class_name March
extends RefCounted

const NENHUM := -1

## Quem foi, linha a linha como estava nas colunas, por ordem de id.
var party: Array[Dictionary] = []
## Os ids de quem esta fora: nao morreram, e o TitleSystem nao os chora.
var away: Dictionary = {}
## A regiao (indice no plano) que a marcha foi conquistar.
var target: int = NENHUM
## O dia em cuja alvorada a marcha volta.
var returns: int = 0
## A firmeza ja tirada a cada fortaleza: regiao (indice no plano) -> quanto.
var sieges: Dictionary = {}


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
	party = []
	away.clear()
	for unit_id in quem:
		party.append(Columns.row(unidades, unidades.index_of(unit_id)))
		away[unit_id] = true
		unidades.remove(unit_id)
	target = regiao
	returns = dia + noites


## Se e a alvorada da volta.
func due(dia: int) -> bool:
	return marching() and dia >= returns


## Acaba: devolve quem volta (as linhas), e esquece a marcha.
func finish() -> Array[Dictionary]:
	var voltam := party
	party = []
	away.clear()
	target = NENHUM
	return voltam


## A firmeza inteira da fortaleza da regiao `regiao` (a 1 e o primeiro povo).
static func fortress(regiao: int, base: int, por_regiao: int) -> int:
	return base + por_regiao * maxi(0, regiao - 1)


## A firmeza que ainda sobra a fortaleza da regiao, nunca abaixo de zero.
func firmness(regiao: int, base: int, por_regiao: int) -> int:
	return maxi(0, fortress(regiao, base, por_regiao) - int(sieges.get(regiao, 0)))


## Uma marcha acabou de bater na fortaleza: o dano fica para a seguinte.
func siege(regiao: int, dano: int) -> void:
	sieges[regiao] = int(sieges.get(regiao, 0)) + maxi(0, dano)


## Quem volta: os que tiraram no sorteio (um por linha, pela ordem de `foram`) pelo
## menos a chance de baixa.
static func survivors(
	foram: Array[Dictionary], sorteios: PackedFloat32Array, chance: float
) -> Array[Dictionary]:
	var voltam: Array[Dictionary] = []
	for k in foram.size():
		if k >= sorteios.size() or sorteios[k] >= chance:
			voltam.append(foram[k])
	return voltam


static func _papel(perfil: UnitData, tetos: Dictionary) -> StringName:
	if perfil == null:
		return &""
	for tag in perfil.tags:
		if tetos.has(tag):
			return tag
	return &""


func to_dict() -> Dictionary:
	return {&"party": party, &"target": target, &"returns": returns, &"sieges": sieges.duplicate()}


func from_dict(d: Dictionary) -> void:
	party = []
	away.clear()
	for linha: Variant in d.get(&"party", []):
		if linha is Dictionary:
			party.append(linha)
			away[int(linha.get(&"ids", NENHUM))] = true
	target = int(d.get(&"target", NENHUM))
	returns = int(d.get(&"returns", 0))
	sieges = {}
	var cercos: Variant = d.get(&"sieges", {})  # um save de antes do cerco nao o tem
	if cercos is Dictionary:
		for regiao: Variant in cercos:
			sieges[int(regiao)] = int(cercos[regiao])
