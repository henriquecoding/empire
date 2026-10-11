# src/sim/systems/placement_rules.gd — onde se levanta uma obra que precisa de uma fonte
# (o relatorio de 06/10/2026, §7 e §16.4; ADR 0077).
#
# O bioma diz o que PODE haver; a fonte diz o que HA, e onde. Uma obra com
# `requires_biome_feature` precisa de uma fonte desse tipo, na mesma faixa, com o meio a
# `alcance` px da borda dela no maximo — ver agua ao longe nao chega, e rocha a
# superficie nao serve a quem esta la em baixo sem passagem. A resposta diz se cabe, com
# que fontes, a que distancia ficou a mais perto e, se nao cabe, a chave da razao.
#
# Puro: as fontes chegam de fora (TerritoryWatch). A previsao da fundacao, o convite da
# obra e o pagamento perguntam todos aqui; nao ha outra resposta.
class_name PlacementRules
extends RefCounted

## As chaves de uma fonte.
const ID := &"id"
const NEED := &"need"
const BAND := &"band"
const SPAN := &"span"
const ACCESS := &"access"
## As chaves da resposta (o PlacementResult do §16.4).
const ALLOWED := &"allowed"
const REASONS := &"reasons"
const SOURCES := &"sources"
const GAP := &"gap"
## A razao de cada necessidade sem fonte, como chave de texto (data/i18n/strings.csv).
const MISSING := {
	&"water": &"TERRAIN_NO_WATER",
	&"forest": &"TERRAIN_NO_FOREST",
	&"rock": &"TERRAIN_NO_ROCK",
}
const UNKNOWN := &"TERRAIN_NO_SOURCE"


## Uma fonte concreta: o que e, em que faixa, e o intervalo do mundo que ocupa.
static func source(id: String, need: StringName, band: int, span: Vector2) -> Dictionary:
	return {ID: id, NEED: need, BAND: band, SPAN: span}


## Se uma obra que precisa de `need` cabe em `x`, na faixa `band`. `minimum` fontes ao
## alcance, pelo menos (a floresta conta arvores; a agua e a rocha bastam uma).
static func evaluate(
	need: StringName, x: float, band: int, sources: Array, reach: float, minimum := 1
) -> Dictionary:
	var usadas: Array[String] = []
	var razoes: Array[StringName] = []
	if need.is_empty():
		return {ALLOWED: true, REASONS: razoes, SOURCES: usadas, GAP: 0.0}
	var perto := INF
	var blocked := false
	for fonte: Dictionary in sources:
		if fonte[NEED] != need or int(fonte[BAND]) != band:
			continue
		var d := gap(x, fonte[SPAN])
		perto = minf(perto, d)
		if d <= reach:
			if bool(fonte.get(ACCESS, true)):
				usadas.append(String(fonte[ID]))
			else:
				blocked = true
	var cabe := usadas.size() >= maxi(1, minimum)
	if not cabe:
		razoes.append(&"TERRAIN_ACCESS_BLOCKED" if blocked else MISSING.get(need, UNKNOWN))
	return {ALLOWED: cabe, REASONS: razoes, SOURCES: usadas, GAP: perto}


## A distancia de `x` ao intervalo `span`: zero dentro dele.
static func gap(x: float, span: Vector2) -> float:
	return maxf(0.0, maxf(span.x - x, x - span.y))
