# src/sim/systems/woodland.gd — as arvores do mundo, uma a uma (ADR 0070).
#
# A floresta deixou de ser so cenario: cada arvore tem um id estavel, uma especie, um
# sitio e um estado. De pe, marcada para abater (alguem pagou), abatida por um
# construtor (fica o cepo) ou limpa (a fundacao ou uma obra levou-a, sem moeda).
#
# O que se corta nao volta: nem com a primavera nem ao carregar. A estacao muda a
# aparencia (a copa de uma caducifolia), e isso e apresentacao; a existencia e isto.
# O save leva as arvores inteiras — posicao incluida —, e nao so a semente: uma semente
# sozinha da outro mapa quando o gerador muda (§8.7 do relatorio de vegetacao).
#
# Puro: as especies, o trabalho e os raios entram como argumentos.
class_name Woodland
extends RefCounted

enum State { STANDING, MARKED, FELLED, CLEARED }

const NONE := -1

var ids := PackedInt32Array()
var xs := PackedFloat32Array()
var species := PackedStringArray()
var states := PackedByteArray()
var progress := PackedFloat32Array()
## A floresta de casa ja foi plantada; e a versao do gerador que a plantou.
var generated := false
var version := 0
## Um save de antes da floresta: plantou-se ja com o reino de pe.
var legacy := false
## As zonas do mundo continuo ja plantadas (lado:indice), para nao plantar duas vezes.
var zones: Dictionary = {}
## Sobe a cada mudanca: e a chave de quem desenha. Nao conta como estado do mundo.
var revision := 0
## Do momento, sem save: as obras cujo chao ja se limpou, e a chave do abrigo das tocas.
var cleared_slots: Dictionary = {}
var shelter_key := Vector2i(-1, -1)
var _por_id: Dictionary = {}


## Uma arvore de pe em `x`. Um id que ja existe nao se planta outra vez.
func plant(id: int, x: float, kind: StringName) -> bool:
	if _por_id.has(id):
		return false
	_por_id[id] = ids.size()
	ids.append(id)
	xs.append(x)
	species.append(String(kind))
	states.append(State.STANDING)
	progress.append(0.0)
	revision += 1
	return true


func count() -> int:
	return ids.size()


func index_of(id: int) -> int:
	return int(_por_id.get(id, NONE))


## De pe, marcada ou nao: ainda faz sombra, abriga e alimenta.
func standing(i: int) -> bool:
	return i >= 0 and i < states.size() and states[i] <= State.MARKED


## A arvore de pe mais perto de `x`, ate `reach`; NONE se nao ha.
func nearest(x: float, reach: float) -> int:
	var melhor := NONE
	var perto := reach
	for i in ids.size():
		var d := absf(xs[i] - x)
		if standing(i) and d <= perto:
			perto = d
			melhor = i
	return melhor


## Alguem pagou para a abater. So uma arvore de pe e por marcar.
func mark(i: int) -> bool:
	if i < 0 or i >= states.size() or states[i] != State.STANDING:
		return false
	states[i] = State.MARKED
	revision += 1
	return true


## Os indices das arvores marcadas, a espera de um construtor.
func marked() -> PackedInt32Array:
	var saida := PackedInt32Array()
	for i in states.size():
		if states[i] == State.MARKED:
			saida.append(i)
	return saida


## `delta` segundos de trabalho na arvore `i`. Verdadeiro quando cai, agora.
func chop(i: int, delta: float, work: float) -> bool:
	if i < 0 or i >= states.size() or states[i] != State.MARKED:
		return false
	progress[i] += maxf(0.0, delta)
	if progress[i] < work:
		return false
	states[i] = State.FELLED
	revision += 1
	return true


## As arvores de pe entre `from` e `to` saem sem moeda: a fundacao, uma obra. Devolve
## os ids que sairam — e o manifesto da limpeza.
func clear(from: float, to: float) -> PackedInt32Array:
	var saida := PackedInt32Array()
	for i in ids.size():
		if standing(i) and xs[i] >= from and xs[i] <= to:
			states[i] = State.CLEARED
			saida.append(ids[i])
	if not saida.is_empty():
		revision += 1
	return saida


## Quantas arvores de pe, das especies `kinds` (id -> true), ha a `radius` de `x`. E a
## origem de uma regra de influencia: quem conta e o que conta.
func count_near(x: float, radius: float, kinds: Dictionary) -> int:
	var n := 0
	for i in ids.size():
		if standing(i) and absf(xs[i] - x) <= radius and kinds.has(StringName(species[i])):
			n += 1
	return n


## O chao das arvores que ja nao estao, com `margin` para cada lado: a flora comum
## a volta de um tronco abatido sai com ele, e a clareira le-se.
func gone_spans(margin: float) -> Array[Vector2]:
	var saida: Array[Vector2] = []
	for i in ids.size():
		if not standing(i):
			saida.append(Vector2(xs[i] - margin, xs[i] + margin))
	return saida


func to_dict() -> Dictionary:
	return {
		&"ids": ids,
		&"xs": xs,
		&"species": species,
		&"states": states,
		&"progress": progress,
		&"generated": generated,
		&"version": version,
		&"legacy": legacy,
		&"zones": zones.duplicate(),
	}


## Um save sem floresta chega sem chaves: por plantar, e marcado como de antes dela.
func from_dict(d: Dictionary) -> void:
	ids = PackedInt32Array(d.get(&"ids", PackedInt32Array()))
	xs = PackedFloat32Array(d.get(&"xs", PackedFloat32Array()))
	species = PackedStringArray(d.get(&"species", PackedStringArray()))
	states = PackedByteArray(d.get(&"states", PackedByteArray()))
	progress = PackedFloat32Array(d.get(&"progress", PackedFloat32Array()))
	var n := ids.size()
	xs.resize(n)
	species.resize(n)
	states.resize(n)
	progress.resize(n)
	generated = d.get(&"generated", false) == true
	version = int(d.get(&"version", 0))
	legacy = d.get(&"legacy", not d.has(&"generated")) == true
	zones = (d.get(&"zones", {}) as Dictionary).duplicate()
	_por_id = {}
	for i in n:
		_por_id[ids[i]] = i
	revision += 1
