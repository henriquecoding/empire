# src/sim/systems/under_reserve.gd — o chao de cada sitio do subsolo: reservado antes
# de a entrada se publicar, nunca disputado por dois, e reparado uma vez nos saves de
# antes do contrato de area util (o relatorio de 05/10/2026, §6.3, §6.4 e §15; ADR 0072).
#
# Tirado do UndergroundSites, que passava das 250. Puro e estatico: le e escreve o
# registo que recebe, e nada mais.
class_name UnderReserve
extends RefCounted


## A reserva, em duas passagens: cada sitio por gerar guarda o envelope minimo que lhe
## cabe (por ordem de chegada, sem tocar nos gerados nem nos de antes); depois cada um
## fica com o que sobra dos outros. Nenhum cresce para o chao prometido a outro, e um
## sitio opcional sem chao fica sem entrada (SUB-05, SUB-06).
static func reserve(u: UndergroundSites) -> void:
	for i in u.sites.size():
		var s := u.sites[i]
		s[UndergroundSites.PLAN] = UnderFit.NONE
		if u.generated(i):
			continue
		var antes: Array = []
		for j in u.sites.size():
			if u.generated(j) or j < i:
				antes.append(u.span(j) if u.generated(j) else u.sites[j][UndergroundSites.PLAN])
		var lim := UnderFit.clip(s[UndergroundSites.CAP], s[UndergroundSites.MOUTH], antes)
		var tapa := UnderLayout.blocked(s[UndergroundSites.SPEC])
		var plano := UnderFit.plan(
			s[UndergroundSites.MOUTH], s[UndergroundSites.NEED], lim, tapa, rules_of(u, i)
		)
		var porque := UnderFit.OK if not is_nan(plano.x) else UnderFit.NO_ROOM
		s[UndergroundSites.WHY] = s[UndergroundSites.SPEC].get(UndergroundSites.DENY, porque)
		s[UndergroundSites.PLAN] = (
			plano if s[UndergroundSites.WHY] == UnderFit.OK else UnderFit.NONE
		)
	for i in u.sites.size():
		u.sites[i][UndergroundSites.LIMIT] = limit_of(u, i, u.sites[i][UndergroundSites.CAP])


## Ate onde o sitio `i` pode ir, a partir de `cap`, sem tocar no chao de outro.
static func limit_of(u: UndergroundSites, i: int, cap: Vector2) -> Vector2:
	var outros: Array = []
	for j in u.sites.size():
		if j != i:
			outros.append(
				(
					u.span(j)
					if u.generated(j)
					else u.sites[j].get(UndergroundSites.PLAN, UnderFit.NONE)
				)
			)
	return UnderFit.clip(cap, u.mouth_of(i), outros)


## O que se mede num sitio gerado: porque nao serve (ou OK) e, numa reserva, o bau.
static func stamp(u: UndergroundSites, i: int) -> void:
	var tapa := UnderLayout.blocked(u.sites[i][UndergroundSites.SPEC])
	var dados: Dictionary = u.meta.get(u.key_of(i), {UndergroundSites.VERSION: 1})
	u.meta[u.key_of(i)] = dados  # um sitio de antes ainda nao tinha medida nenhuma
	dados[UndergroundSites.WHY] = UnderFit.check(u.span(i), u.mouth_of(i), tapa, rules_of(u, i))
	if u.kind_of(i) == UndergroundSites.HATCH and not dados.has(UndergroundSites.CHEST):
		dados[UndergroundSites.CHEST] = UnderFit.chest(
			u.span(i), u.mouth_of(i), tapa, rules_of(u, i)
		)


## Os sitios gerados com um gerador anterior: o tipo das salas volta, e o chao que falta
## estende-se dentro do que e dele — sem mexer na boca nem no que la esta (§15.2).
## Idempotente: a marca de versao fica, e a segunda vez nao faz nada. Quantos reparou.
static func mend(u: UndergroundSites) -> int:
	var reparados := 0
	for i in u.sites.size():
		var dados: Dictionary = u.meta.get(u.key_of(i), {})
		var versao := rules_of(u, i).generator_version
		if not u.generated(i) or int(dados.get(UndergroundSites.VERSION, 1)) >= versao:
			continue
		var spec: Dictionary = u.sites[i][UndergroundSites.SPEC]
		var mudou := UnderLayout.mend_kinds(u.rooms(i), u.mouth_of(i), spec)
		var tapa := UnderLayout.blocked(spec)
		if UnderFit.check(u.span(i), u.mouth_of(i), tapa, rules_of(u, i)) != UnderFit.OK:
			var lim := limit_of(u, i, _wider(u.sites[i][UndergroundSites.CAP], u.span(i)))
			var salas: Array[Dictionary] = []
			salas.assign(u.rooms(i))
			if UnderLayout.fit(salas, u.mouth_of(i), lim, PackedFloat32Array(), spec):
				u.layouts[u.key_of(i)] = salas
				mudou = true
		u.meta[u.key_of(i)] = {UndergroundSites.VERSION: versao, UndergroundSites.MENDED: mudou}
		stamp(u, i)
		reparados += 1
	if reparados > 0:
		u.revision += 1
		reserve(u)
	return reparados


## Onde fica o bau de uma reserva: na baia, longe da subida. NAN se nao tem.
static func chest_x(u: UndergroundSites, i: int) -> float:
	return float((u.meta.get(u.key_of(i), {}) as Dictionary).get(UndergroundSites.CHEST, NAN))


## Onde fica o objetivo de um sitio gerado: o meio da baia (SUB-11).
static func goal_x(u: UndergroundSites, i: int) -> float:
	var tapa := UnderLayout.blocked(u.sites[i][UndergroundSites.SPEC])
	return UnderFit.goal(u.span(i), u.mouth_of(i), tapa, rules_of(u, i))


static func rules_of(u: UndergroundSites, i: int) -> UnderRules:
	return UnderLayout.rules(u.sites[i][UndergroundSites.SPEC])


static func _wider(cap: Vector2, lim: Vector2) -> Vector2:
	if is_nan(lim.x):
		return cap
	return Vector2(minf(cap.x, lim.x), maxf(cap.y, lim.y))
