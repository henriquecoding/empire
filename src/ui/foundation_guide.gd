# src/ui/foundation_guide.gd — o que a fundacao aqui leva e o que deixa (ADR 0066, 0070).
#
# Parado num sitio livre, o painel pergunta se se funda ali. Por baixo, as consequencias
# daquele sitio, contadas e nao inventadas: as arvores que a clareira tira (sem madeira),
# se isso tira o apoio do bosque a coleta ou o abrigo da toca do veado, e o que fica dentro
# da clareira porque nunca se limpa — a estatua, as raizes da Podridao, a passagem.
class_name FoundationGuide
extends RefCounted


## As linhas de consequencia de fundar em `x`; "" se nao ha nenhuma.
static func reading(x: float, values: Dictionary) -> String:
	if SimLoop.field == null:
		return ""
	var raio := LastCartWatch.rules().foundation_clear_radius
	var w := SimLoop.field.woodland
	var linhas := ""
	var arvores := 0
	for i in w.count():
		if w.standing(i) and absf(w.xs[i] - x) <= raio:
			arvores += 1
	if arvores > 0:
		values["trees"] = arvores
		linhas += "\n" + _tr(&"FOUNDATION_CLEARS_TREES").format(values)
	if _loses(x, raio, SimLoop.arrival.cache_x, Influence.FORAGE):
		linhas += "\n" + _tr(&"FOUNDATION_GROVE_LOST")
	var tocas := SimLoop.field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] == String(ForestWatch.ARVORE):
			if _loses(x, raio, tocas.xs[k], Influence.SHELTER):
				linhas += "\n" + _tr(&"FOUNDATION_SHELTER_LOST")
				break
	var ficam := _kept(x, raio)
	if not ficam.is_empty():
		values["kept"] = ", ".join(ficam)
		linhas += "\n" + _tr(&"FOUNDATION_KEEPS").format(values)
	return linhas


## Se limpar `raio` a volta de `x` deixa o destino em `alvo` abaixo do minimo da regra `tag`.
static func _loses(x: float, raio: float, alvo: float, tag: StringName) -> bool:
	var regras := ForestWatch.rules()
	var forage := tag == Influence.FORAGE
	var alcance := regras.grove_feeds_radius if forage else regras.shelter_radius
	var minimo := regras.grove_feeds_min if forage else regras.shelter_min
	var kinds := Influence.kinds(ForestWatch.flora(), tag)
	var w := SimLoop.field.woodland
	var antes := w.count_near(alvo, alcance, kinds)
	var depois := 0
	for i in w.count():
		var conta := w.standing(i) and kinds.has(StringName(w.species[i]))
		if conta and absf(w.xs[i] - alvo) <= alcance and absf(w.xs[i] - x) > raio:
			depois += 1
	return antes >= minimo and depois < minimo


## O que fica dentro da clareira porque nunca se limpa.
static func _kept(x: float, raio: float) -> Array[String]:
	var ficam: Array[String] = []
	for at in SimLoop.secrets.xs:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_STATUE"))
			break
	for at in SimLoop.night.amargueiros.xs:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_ROOTS"))
			break
	for at in SimLoop.passages:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_PASSAGE"))
			break
	return ficam


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)
