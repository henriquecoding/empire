# src/sim/systems/chapter_plan.gd — onde caem os capitulos de uma campanha, e
# que diario carrega cada um (§77, §79; XIII-07).
#
# §77: "O gerador coloca seis por campanha, no maximo um por regiao, com o fluxo
# de aleatoriedade da §42 sob a semente do mundo. Um deles e sempre O Cerco Que
# Nao Acaba; os outros cinco saem dos nove restantes." Um capitulo com bioma so
# cai numa regiao desse bioma — e por isso duas fichas do mesmo bioma nao cabem
# na mesma campanha de uma regiao por povo (Q-105).
#
# Os diarios: "o 12 esta sempre no Cerco, e os outros cinco vao para o capitulo
# que preferem, ou, se esse nao saiu, para o seguinte que tenha saido, por ordem
# de ato." O que fica sem diario carrega uma Semente Ancia (regra 4).
#
# Puro. Nao sorteia: recebe `sorteio(de, ate) -> int`, que e o fluxo `world` do
# RngService (G2). Os campos do save tem os nomes da §84: chapters_placed.
class_name ChapterPlan
extends RefCounted

const NENHUM := -1
const DIARIO := &"journal"
const RUINA := &"ruin"
const FORTALEZA := &"fortress"
const CAPITULO := &"chapter"

## O bioma de cada regiao da campanha, pela ordem delas.
var regions: PackedStringArray = PackedStringArray()
## O capitulo de cada regiao; vazio = nenhum.
var placed: PackedStringArray = PackedStringArray()
## O diario que o capitulo dessa regiao carrega; vazio = uma Semente Ancia.
var journals: PackedStringArray = PackedStringArray()
## O preco do desvio do capitulo dessa regiao, em segundos (regra 5, D-09).
var detours: PackedFloat32Array = PackedFloat32Array()


## Sorteia o plano. `quantos` sai da curva (chapters_per_campaign).
static func draw(
	regioes: PackedStringArray, capitulos: Array[ChapterData], quantos: int, sorteio: Callable
) -> ChapterPlan:
	var ordem := _por_ordem(capitulos)
	var escolhidos: Array[ChapterData] = []
	var baralho: Array[ChapterData] = []
	for c in ordem:
		if c.guaranteed:
			escolhidos.append(c)
		else:
			baralho.append(c)
	var sitios := _baralhar(_sitios(regioes), sorteio)
	for c: ChapterData in _baralhar(baralho, sorteio):
		if escolhidos.size() >= quantos:
			break
		var mais := escolhidos.duplicate()
		mais.append(c)
		if not _cabem(mais, sitios).is_empty():
			escolhidos.append(c)
	var p := ChapterPlan.new()
	p._colocar(_cabem(escolhidos, sitios), regioes)
	p._dar_diarios(ordem)
	return p


## Quantas campanhas diferentes cabem: os conjuntos de `k` fichas, das que nao
## sao garantidas, que se conseguem por nas regioes com as garantidas.
static func worlds(capitulos: Array[ChapterData], regioes: PackedStringArray, k: int) -> int:
	var fixos: Array[ChapterData] = []
	var livres: Array[ChapterData] = []
	for c in _por_ordem(capitulos):
		(fixos if c.guaranteed else livres).append(c)
	return _contar(fixos, livres, 0, k, _sitios(regioes))


func count() -> int:
	return Array(placed).filter(func(s: String) -> bool: return not s.is_empty()).size()


func has(capitulo: StringName) -> bool:
	return placed.has(String(capitulo))


## Se o diario se acha nesta campanha: o da ruina esta dentro das tuas muralhas
## desde o dia 1; o de fortaleza, se o povo dela esta numa regiao (`povos`, pela
## ordem de `regions`); o de capitulo, se algum capitulo o carrega.
func reachable(diario: JournalData, povos: PackedStringArray) -> bool:
	match diario.where_kind:
		RUINA:
			return true
		FORTALEZA:
			return povos.has(String(diario.where_id))
	return journals.has(String(diario.id))


func to_dict() -> Dictionary:
	return {
		&"chapter_regions": regions,
		&"chapters_placed": placed,
		&"chapter_journals": journals,
		&"chapter_detours": detours,
	}


func from_dict(d: Dictionary) -> void:
	regions = d.get(&"chapter_regions", regions)
	placed = d.get(&"chapters_placed", placed)
	journals = d.get(&"chapter_journals", journals)
	detours = d.get(&"chapter_detours", detours)


# ─── Por dentro ──────────────────────────────────────────────────────────────


func _colocar(onde: Dictionary, regioes: PackedStringArray) -> void:
	regions = regioes
	placed.resize(regioes.size())
	journals.resize(regioes.size())
	detours.resize(regioes.size())
	for c: ChapterData in onde:
		var i: int = onde[c]
		placed[i] = String(c.id)
		detours[i] = c.detour_seconds


## O seu diario a cada um que saiu; depois, os que ficaram sem capitulo, por
## ordem, para o seguinte que saiu e ainda nao carrega nada — dando a volta.
func _dar_diarios(ordem: Array[ChapterData]) -> void:
	var sem_casa: Array[ChapterData] = []
	for c in ordem:
		if c.reward_kind != DIARIO:
			continue
		var i := placed.find(String(c.id))
		if i == NENHUM:
			sem_casa.append(c)
		else:
			journals[i] = String(c.reward_id)
	for c in sem_casa:
		var k := ordem.find(c)
		for passo in range(1, ordem.size()):
			var i := placed.find(String(ordem[(k + passo) % ordem.size()].id))
			if i != NENHUM and journals[i].is_empty():
				journals[i] = String(c.reward_id)
				break


## Capitulo -> indice da regiao, ou vazio se nao cabem. Os de bioma primeiro,
## que sao os que tem menos sitio; `sitios` sao os indices ja baralhados.
static func _cabem(lista: Array, sitios: Array) -> Dictionary:
	var fila := lista.filter(func(c: ChapterData) -> bool: return c.biome != &"")
	fila.append_array(lista.filter(func(c: ChapterData) -> bool: return c.biome == &""))
	var onde := {}
	return onde if _por(fila, 0, sitios, onde) else {}


static func _por(fila: Array, k: int, sitios: Array, onde: Dictionary) -> bool:
	if k == fila.size():
		return true
	var c: ChapterData = fila[k]
	for s in sitios:
		var i: int = s[0]
		if onde.values().has(i) or (c.biome != &"" and s[1] != String(c.biome)):
			continue
		onde[c] = i
		if _por(fila, k + 1, sitios, onde):
			return true
		onde.erase(c)
	return false


static func _contar(fixos: Array, livres: Array, desde: int, k: int, sitios: Array) -> int:
	if k == 0:
		return 1 if not _cabem(fixos, sitios).is_empty() else 0
	var n := 0
	for i in range(desde, livres.size()):
		var mais := fixos.duplicate()
		mais.append(livres[i])
		if _cabem(mais, sitios).is_empty():
			continue
		n += _contar(mais, livres, i + 1, k - 1, sitios)
	return n


static func _por_ordem(capitulos: Array[ChapterData]) -> Array[ChapterData]:
	var ordem := capitulos.duplicate()
	ordem.sort_custom(func(a: ChapterData, b: ChapterData) -> bool: return a.order < b.order)
	return ordem


## As regioes como [indice, bioma], que e o que se baralha e se preenche.
static func _sitios(regioes: PackedStringArray) -> Array:
	var saida := []
	for i in regioes.size():
		saida.append([i, regioes[i]])
	return saida


## Tira ao acaso, sem repor: com um sorteio que da sempre o primeiro, a ordem
## fica como estava.
static func _baralhar(lista: Array, sorteio: Callable) -> Array:
	var resto := lista.duplicate()
	var saida := []
	while not resto.is_empty():
		saida.append(resto.pop_at(sorteio.call(0, resto.size() - 1)))
	return saida
