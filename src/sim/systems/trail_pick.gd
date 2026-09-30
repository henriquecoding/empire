# src/sim/systems/trail_pick.gd — que segmento vem a seguir num trilho (o pedido do
# dono de 30/09/2026; §21; ADR 0038). Tirado do WildSegments, que passava das 250.
#
# Os pesos sao os da tabela do §21 (segments.csv): vazio 30, bosque 25, ruina 12,
# acampamento de mercenarios 8 — e o acampamento de mendigos que a Q-173 acrescenta.
# As regras de cada linha dizem o que nao pode vir: `gap=N` (a N segmentos do ultimo
# igual, no minimo), `not_near_base` (o primeiro depois da regiao), `not_adjacent=K`.
# O clima do sitio empurra o bosque contra o vazio: e o que faz estiradas de bosque e
# de clareira, em vez de um sorteio a cada segmento (o multi-noise do Minecraft).
#
# Puro e estatico: recebe o kit, os tipos que ja sairam desse lado e os sorteios.
class_name TrailPick
extends RefCounted

## O que nunca se sorteia num trilho: o que e autorado e o que o plano poe no sitio.
const FORA := [
	&"start_base", &"opening", &"threshold", &"settlement", &"fortress", &"edge", &"chaotic"
]
const BOSQUE := &"forest"
const VAZIO := &"empty"
const ENCONTRO := &"encounter"
const PERTO_DA_BASE := &"not_near_base"
const INTERVALO := "gap="
const VIZINHO := "not_adjacent="
## O clima vai de 0 a 1; o empurrao vai de -1 a 1.
const DOBRO := 2.0


## A linha do segmento seguinte. `antes` sao os tipos que ja sairam deste lado, de dentro
## para fora; `vizinho` e o id do ultimo, para a variante nao se repetir lado a lado.
## Com `so_encontros`, so contam as linhas que sao encontro (se alguma couber).
static func choose(
	kit: Array[SegmentData],
	antes: Array,
	vizinho: StringName,
	clima: float,
	cluster: float,
	u_tipo: float,
	u_variante: float,
	so_encontros := false
) -> SegmentData:
	var pesos := {}
	for linha in kit:
		if linha.weight <= 0 or FORA.has(linha.kind) or pesos.has(linha.kind):
			continue
		if (so_encontros and not linha.rules.has(ENCONTRO)) or not _cabe(linha, antes):
			continue
		pesos[linha.kind] = maxf(0.0, float(linha.weight) * _clima(linha.kind, clima, cluster))
	if pesos.is_empty():
		if so_encontros:
			return choose(kit, antes, vizinho, clima, cluster, u_tipo, u_variante)
		return null
	return variant(of_kind(kit, _sortear(pesos, u_tipo)), u_variante, vizinho)


## Se as linhas deste tipo contam como encontro de trilho.
static func encounter(kit: Array[SegmentData], tipo: StringName) -> bool:
	for linha in of_kind(kit, tipo):
		return linha.rules.has(ENCONTRO)
	return false


## A borda com este assunto, ou a primeira que houver.
static func edge(kit: Array[SegmentData], assunto: StringName, u: float) -> SegmentData:
	var bordas := of_kind(kit, &"edge")
	var certas := bordas.filter(func(s: SegmentData) -> bool: return s.subject == assunto)
	return variant(certas if not certas.is_empty() else bordas, u, &"")


static func of_kind(kit: Array[SegmentData], tipo: StringName) -> Array:
	return kit.filter(func(s: SegmentData) -> bool: return s.kind == tipo)


## Uma das linhas, pelo sorteio `u`, que nao e a do vizinho quando ha outra.
static func variant(linhas: Array, u: float, vizinho: StringName) -> SegmentData:
	var outras := linhas.filter(func(s: SegmentData) -> bool: return s.id != vizinho)
	var escolha := outras if not outras.is_empty() else linhas
	if escolha.is_empty():
		return null
	return escolha[mini(floori(u * float(escolha.size())), escolha.size() - 1)]


static func _cabe(linha: SegmentData, antes: Array) -> bool:
	for regra in linha.rules:
		var r := String(regra)
		if regra == PERTO_DA_BASE and antes.is_empty():
			return false
		if r.begins_with(VIZINHO) and not antes.is_empty():
			if String(antes[-1]) == r.substr(VIZINHO.length()):
				return false
		if r.begins_with(INTERVALO):
			for d in range(1, mini(int(r.substr(INTERVALO.length())), antes.size() + 1)):
				if antes[antes.size() - d] == linha.kind:
					return false
	return true


static func _clima(tipo: StringName, clima: float, cluster: float) -> float:
	var puxa := cluster * (clima * DOBRO - 1.0)
	if tipo == BOSQUE:
		return 1.0 + puxa
	return 1.0 - puxa if tipo == VAZIO else 1.0


static func _sortear(pesos: Dictionary, u: float) -> StringName:
	var tipos := pesos.keys()
	tipos.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var total := 0.0
	for t in tipos:
		total += float(pesos[t])
	var soma := 0.0
	for t in tipos:
		soma += float(pesos[t])
		if u * total < soma:
			return t
	return tipos[-1]
