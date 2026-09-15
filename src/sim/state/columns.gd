# src/sim/state/columns.gd — gravar e repor um sistema de colunas (§45, §62).
#
# Tres sistemas guardam o estado em colunas paralelas — tropas, criaturas e
# moedas — e os tres tinham o mesmo to_dict() escrito a mao, com uma linha por
# coluna. Uma lista escrita duas vezes diverge: acrescentava-se uma coluna, e
# ela ficava de fora do save sem que nada chumbasse.
#
# Aqui nao ha lista nenhuma: as colunas SAO as variaveis de array do proprio
# sistema, e e ele que as declara. Uma coluna nova entra no save por ser
# declarada, e nao por alguem se lembrar de a acrescentar a uma segunda lista.
#
# Puro e sem estado. Le o get_property_list() do sistema e filtra por tipo:
# tudo o que e um array e nao comeca por underscore e uma coluna.
class_name Columns
extends RefCounted

## Os tipos que contam como coluna: os PackedArrays das colunas quentes e o
## Array tipado dos data_ids.
const ARRAYS: Array[int] = [
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
]


## Os nomes das colunas deste sistema, pela ordem em que estao declaradas. Um
## array publico e uma coluna; um que comece por underscore e um indice interno.
static func names(sistema: Object) -> PackedStringArray:
	var saida := PackedStringArray()
	for p in sistema.get_property_list():
		var nome: String = p[&"name"]
		if nome.begins_with("_") or not _e_coluna(p):
			continue
		saida.append(nome)
	return saida


## As colunas em tipos base, para o save (§62). Sem Object nenhum.
static func to_dict(sistema: Object) -> Dictionary:
	var saida := {}
	for nome in names(sistema):
		saida[StringName(nome)] = _base(sistema.get(nome))
	return saida


## Repoe. Uma coluna em falta fica como estava — um save de outra versao degrada
## em vez de recusar (§62), e e a mesma regra do GameState.from_dict().
static func from_dict(sistema: Object, d: Dictionary) -> void:
	for nome in names(sistema):
		var chave := StringName(nome)
		if not d.has(chave):
			continue
		sistema.set(nome, _como(sistema.get(nome), d[chave]))


## So variaveis de script, e so as que sao arrays. O `script` e os grupos que o
## get_property_list() tambem devolve nao sao colunas de nada.
static func _e_coluna(p: Dictionary) -> bool:
	if int(p[&"usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
		return false
	return int(p[&"type"]) in ARRAYS


## Um Array[StringName] nao passa pelo canal da ADR 0007; vai como texto.
static func _base(valor: Variant) -> Variant:
	if typeof(valor) != TYPE_ARRAY:
		return valor
	var nomes := PackedStringArray()
	for x in valor:
		nomes.append(String(x))
	return nomes


## E volta a ser o que era: o set() de uma propriedade tipada recusa o tipo
## errado, e por isso a conversao tem de acontecer antes dele.
static func _como(atual: Variant, guardado: Variant) -> Variant:
	if typeof(atual) != TYPE_ARRAY:
		return guardado
	var nomes: Array[StringName] = []
	for x in guardado:
		nomes.append(StringName(x))
	return nomes
