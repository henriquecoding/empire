# src/sim/systems/offer_rules.gd — a gramatica da coluna requires, e quem e
# elegivel esta noite (§75).
#
# "Doze condicoes ad hoc dao doze interpretacoes." Tres formas e mais nenhuma:
# <chave><op><numero> com op em { >= , <= , = }, ou <chave>=<id>; virgulas em
# AND; nada de parenteses, de "ou", de negacao. O que nao cabe nisto nunca e
# elegivel — uma condicao mal escrita fecha a oferta em vez de a abrir.
#
# Avaliada contra `factos`: o estado autoritativo (§45) reduzido as oito chaves
# da §75. Quem os junta e quem chama; aqui so se le.
class_name OfferRules
extends RefCounted

const CHAVES: Array[StringName] = [
	&"gate", &"treasury", &"named", &"marker", &"peoples", &"successor", &"debt", &"biome"
]
const FORMA := "^([a-z_]+)(>=|<=|=)([A-Za-z0-9_]+)$"
const SEPARADOR := ","
## Os tres grupos da FORMA: chave, operador, alvo.
const G_CHAVE := 1
const G_OP := 2
const G_ALVO := 3

static var _forma: RegEx


static func holds(requires: String, factos: Dictionary) -> bool:
	if requires.strip_edges().is_empty():
		return true
	for termo in requires.split(SEPARADOR):
		if not _termo(termo.strip_edges(), factos):
			return false
	return true


## Elegivel esta noite: o dia minimo passou, a condicao cumpre-se, e nao e uma
## das que so se aceitam uma vez por campanha e ja foi aceite (Q-040).
static func eligible(
	oferta: OfferData, factos: Dictionary, dia: int, usadas: PackedStringArray
) -> bool:
	if dia < oferta.min_day:
		return false
	if oferta.once_per_campaign and usadas.has(String(oferta.id)):
		return false
	return holds(oferta.requires, factos)


static func _termo(termo: String, factos: Dictionary) -> bool:
	if _forma == null:
		_forma = RegEx.create_from_string(FORMA)
	var m := _forma.search(termo)
	if m == null:
		return false
	var chave := StringName(m.get_string(G_CHAVE))
	if not CHAVES.has(chave) or not factos.has(chave):
		return false
	var valor: Variant = factos[chave]
	var op := m.get_string(G_OP)
	var alvo := m.get_string(G_ALVO)
	if typeof(valor) != TYPE_INT:
		return op == "=" and String(valor) == alvo
	if not alvo.is_valid_int():
		return false
	match op:
		">=":
			return valor >= alvo.to_int()
		"<=":
			return valor <= alvo.to_int()
	return valor == alvo.to_int()
