# src/sim/systems/amargueiro_system.gd — o que a noite deixa no campo (§74).
#
# Uma tropa que morre fora das muralhas cria raiz na alvorada, com a cara na
# casca, e alimenta a noite seguinte: +22 de massa, ou +45 se tinha nome. Os tres
# destinos sao o Verbo 1 (§05): cortar e moeda na base — um slot de destino no
# BuildSystem (§55); consagrar e uma Semente Real, e vira Marco; deixar e nada.
#
# Colunas, como a §84 as escreve. Puro: devolve o que houve. Onde se cria raiz e
# do AmargueiroRoots. Fora daqui: a Semente Real como coisa que se larga (Q-087),
# o Amargueiro subterraneo a bloquear a passagem (§79), as regioes adjacentes.
class_name AmargueiroSystem
extends RefCounted

## OLD e o Amargueiro velho do segmento de abertura (§83): de pe desde antes de
## ti, com cara, sem serra, e fora da tua massa (Q-096).
enum Fate { STANDING, MARKER, OLD }

const NENHUM := -1

## O kind do slot de destino: a arvore vista pelo BuildSystem, e nao uma obra.
const CORTE := &"amargueiro"

const CORTAR := &"fell"
const CONSAGRAR := &"consecrate"

const EV_RAIZ := 0
const EV_PERDA := 1
const EV_SERRA := 2
const EV_CORTADO := 3

const CHAVE := &"kind"
const ONDE := &"x"
const FAIXA := &"band"
const ESCALA := &"tier"
const TITULO := &"title"
const LENHO := &"bitter_wood"
const MORAL := &"morale"
const DIAS := &"morale_days"
const VAGA := &"slot"

var xs: PackedFloat32Array = PackedFloat32Array()
var bands: PackedInt32Array = PackedInt32Array()
var tiers: PackedInt32Array = PackedInt32Array()
var days: PackedInt32Array = PackedInt32Array()
var titles: PackedStringArray = PackedStringArray()
var nights: PackedInt32Array = PackedInt32Array()
var fates: PackedInt32Array = PackedInt32Array()
## O slot do corte no BuildSystem, ou NENHUM enquanto a serra nao pega.
var slot_ids: PackedInt32Array = PackedInt32Array()

## O Lenho Amargo (§74, regra 1): nao e moeda, nao se vende, so se constroi com
## ele. Por isso e um contador aqui e nunca uma moeda no chao.
var bitter_wood: int = 0

var _perfil: RotProfile
var _cortar: AmargueiroData
var _consagrar: AmargueiroData
var _tropas: Dictionary


## `destinos` e a tabela de amargueiros.csv por id; `tropas` a de units.csv, para
## a escala de quem morreu.
func _init(perfil: RotProfile, destinos: Dictionary, tropas: Dictionary) -> void:
	assert(perfil != null, "o AmargueiroSystem precisa do RotProfile")
	_perfil = perfil
	_cortar = destinos.get(CORTAR)
	_consagrar = destinos.get(CONSAGRAR)
	_tropas = tropas


func count() -> int:
	return xs.size()


## As arvores de pe sem nome e com nome: os dois termos da massa da §74. Um Marco
## ja nao conta — consagrar tira os +22 (amargueiros.csv, mass_delta).
func anonymous() -> int:
	return _de_pe(false)


func named() -> int:
	return _de_pe(true)


## A alvorada (§48, §05: a fase em que se contam as perdas). Primeiro envelhece
## quem ja estava — uma noite de pe e o que deixa a serra pegar (regra 2) — e so
## depois levanta os mortos da noite, que ainda nao aguentaram nenhuma.
##
## Os corpos saem das colunas das tropas: fora das muralhas levantam-se arvore,
## dentro desaparecem e contam como perda normal. `titulos` e unit_id -> chave
## do titulo (§76); quem nao esta la morreu anonimo.
func at_dawn(
	dia: int,
	unidades: UnitSystem,
	obras: BuildSystem,
	nucleo: float,
	largura: float,
	titulos: Dictionary = {}
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for i in count():
		if fates[i] != Fate.STANDING:
			continue
		nights[i] += 1
		if slot_ids[i] == NENHUM and nights[i] >= _perfil.amargueiro_nights_standing:
			var vaga := obras.post(_serra(xs[i], bands[i]))
			slot_ids[i] = vaga.id
			eventos.append({CHAVE: EV_SERRA, VAGA: vaga.id, ONDE: xs[i]})
	var regras := AmargueiroRoots.new(_perfil, _tropas, _cortar.yield_by_tier.size())
	for unit_id in regras.dead(unidades):
		var u := unidades.index_of(unit_id)
		var x := unidades.xs[u]
		var faixa := AmargueiroRoots.body_band(unidades.bands[u])
		var escala := regras.tier(unidades.data_ids[u])
		var titulo: String = titulos.get(unit_id, "")
		unidades.remove(unit_id)
		if not regras.roots(x, faixa, obras, Vector2(nucleo, largura), consecrated()):
			eventos.append({CHAVE: EV_PERDA, ONDE: x, FAIXA: faixa})
			continue
		_plantar(x, faixa, escala, dia, titulo)
		eventos.append({CHAVE: EV_RAIZ, ONDE: x, FAIXA: faixa, ESCALA: escala, TITULO: titulo})
	return eventos


## Todos os ticks: as serras que acabaram. O BuildSystem fez a parte do §55 —
## moeda, presenca, progresso —, aqui so se colhe o que ficou de pe no fim.
func harvest(obras: BuildSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for i in range(count() - 1, -1, -1):
		if slot_ids[i] == NENHUM or fates[i] != Fate.STANDING:
			continue
		var s := obras.index_of(slot_ids[i])
		if s == NENHUM or obras.slots[s].level < 1:
			continue
		_toco(obras.slots[s])
		var nomeado := not titles[i].is_empty()
		var lenho := _cortar.yield_named if nomeado else _cortar.yield_by_tier[tiers[i] - 1]
		bitter_wood += lenho
		var e := {CHAVE: EV_CORTADO, ONDE: xs[i], LENHO: lenho, TITULO: titles[i]}
		e[MORAL] = _cortar.morale_cost if nomeado else 0
		e[DIAS] = _cortar.morale_days if nomeado else 0
		eventos.append(e)
		_arrancar(i)
	return eventos


## Uma Semente Real na base: vira Marco de pedra (§74). Pode ser logo na primeira
## alvorada. Recusa um Marco e recusa uma arvore com a serra ja dentro — as
## moedas pagas do corte nao voltam, e nao se paga duas vezes o mesmo destino.
func consecrate(i: int, obras: BuildSystem) -> bool:
	if i < 0 or i >= count() or fates[i] != Fate.STANDING:
		return false
	if slot_ids[i] != NENHUM:
		var s := obras.index_of(slot_ids[i])
		if s != NENHUM and obras.slots[s].state != BuildSlot.State.EMPTY:
			return false
		if s != NENHUM:
			_toco(obras.slots[s])
	fates[i] = Fate.MARKER
	slot_ids[i] = NENHUM
	return true


## O terreno consagrado dos Marcos, em intervalos de x. E a lista que o
## RotSystem.tick recebe: sobre ela a Podridao abranda (§05, §51).
func consecrated() -> Array[Vector2]:
	var saida: Array[Vector2] = []
	var raio := float(_consagrar.protect_radius_px)
	for i in count():
		if fates[i] == Fate.MARKER:
			saida.append(Vector2(xs[i] - raio, xs[i] + raio))
	return saida


## Os campos da §84, e o que nao se deriva: o destino, as noites, e a serra a meio.
func to_dict(obras: BuildSystem) -> Dictionary:
	return AmargueiroSave.write(self, obras)


## Repoe DEPOIS de o BuildSystem ter reposto as obras autoradas: as serras
## voltam a ser postas aqui, com ids novos, e so assim nao colidem com os velhos.
func from_dict(d: Dictionary, obras: BuildSystem) -> void:
	AmargueiroSave.read(self, d, obras)


func plant(x: float, faixa: int, escala: int, dia: int, titulo: String) -> int:
	_plantar(x, faixa, escala, dia, titulo)
	return count() - 1


func plant_old(x: float, faixa: int, escala: int) -> int:
	var i := plant(x, faixa, escala, 0, "")
	fates[i] = Fate.OLD
	return i


## Uma serra nova para a arvore i. Publica para o save a poder repor.
func saw(i: int) -> BuildSlot:
	return _serra(xs[i], bands[i])


func _de_pe(com_nome: bool) -> int:
	var n := 0
	for i in count():
		if fates[i] == Fate.STANDING and titles[i].is_empty() != com_nome:
			n += 1
	return n


func _plantar(x: float, faixa: int, escala: int, dia: int, titulo: String) -> void:
	xs.append(x)
	bands.append(faixa)
	tiers.append(escala)
	days.append(dia)
	titles.append(titulo)
	nights.append(0)
	fates.append(Fate.STANDING)
	slot_ids.append(NENHUM)


func _serra(x: float, faixa: int) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.kind = CORTE
	vaga.x = x
	vaga.band = faixa as Band.Kind
	vaga.width = _perfil.amargueiro_base_px
	vaga.costs = PackedInt32Array([_cortar.cost_coins])
	vaga.works = PackedFloat32Array([_cortar.work_seconds])
	return vaga


## O que fica quando a serra acaba, ou quando a arvore vira pedra: um slot que ja
## nao aceita moeda e nao esta de pe. Os ids do BuildSystem sao indices, e por
## isso ele nao se tira da lista — deixa de ser uma obra.
func _toco(vaga: BuildSlot) -> void:
	vaga.costs = PackedInt32Array()
	vaga.works = PackedFloat32Array()
	vaga.state = BuildSlot.State.RUIN


func _arrancar(i: int) -> void:
	xs.remove_at(i)
	bands.remove_at(i)
	tiers.remove_at(i)
	days.remove_at(i)
	titles.remove_at(i)
	nights.remove_at(i)
	fates.remove_at(i)
	slot_ids.remove_at(i)
