# src/sim/systems/requires.gd — a gramatica da coluna `requires` (§75).
#
# Doze condicoes ad hoc dao doze interpretacoes; esta aceita tres formas e mais
# nenhuma: <chave><op><numero>, <chave>=<id>, e o vazio. Virgulas sao AND. Sem
# parenteses, sem "ou", sem negacao — se uma oferta precisar de mais, sao duas.
class_name Requires
extends RefCounted


## A gramatica da §75: <chave><op><numero> ou <chave>=<id>, virgulas em AND. Uma
## chave que o estado nao tem vale zero — e por isso nenhuma condicao sobre um
## sistema que ainda nao existe e verdadeira por acaso.
static func meets(requires: String, ctx: Dictionary) -> bool:
	if requires.strip_edges().is_empty():
		return true
	var forma := RegEx.create_from_string(
		"^(?<chave>[a-z_]+)(?<op>>=|<=|=)(?<valor>[A-Za-z0-9_]+)$"
	)
	for termo in requires.split(","):
		var m := forma.search(termo.strip_edges())
		if m == null:
			return false
		var tem: Variant = ctx.get(StringName(m.get_string("chave")), 0)
		var quer := m.get_string("valor")
		if not quer.is_valid_int():
			if str(tem) != quer:
				return false
			continue
		var n := int(tem)
		match m.get_string("op"):
			">=":
				if n < int(quer):
					return false
			"<=":
				if n > int(quer):
					return false
			_:
				if n != int(quer):
					return false
	return true
