# src/core/save_migrations_v5.gd — o passo da versao 4 para a 5: as respostas do painel
# de 30/09/2026 (ADR 0041). Tirado do SaveMigrations para o passo caber inteiro.
#
# Tudo com o valor que reproduz o jogo antigo: conduz-se o rei, nenhuma classe chegou,
# as tocas sao arbustos com coelhos (Q-150) e a coroa esta na cabeca do rei (Q-167).
class_name SaveMigrationsV5
extends RefCounted

const NINGUEM := -1


static func apply(d: Dictionary) -> void:
	var mundo := _dict(d, &"world")
	if mundo.is_empty():
		return
	if not mundo.has(&"pilot"):
		mundo[&"pilot"] = NINGUEM  # conduz-se o rei (§08, Q-162)
	if not mundo.has(&"roster"):
		mundo[&"roster"] = {}
	if not mundo.has(&"crown_drop"):
		mundo[&"crown_drop"] = {}  # a coroa na cabeca do rei (Q-167)
	var caca := _dict(mundo, &"hunting")
	var tocas := _dict(caca, &"burrows")
	if not tocas.is_empty() and not tocas.has(&"kinds"):
		var n := _tamanho(tocas.get(&"xs", []))
		tocas[&"kinds"] = _repetir(Burrows.ARBUSTO, n)
		tocas[&"game"] = _repetir(Burrows.COELHO, n)
		caca[&"burrows"] = tocas
	if not caca.is_empty() and not caca.has(&"wounds"):
		caca[&"wounds"] = {}
	if not caca.is_empty():
		mundo[&"hunting"] = caca
	d[&"world"] = mundo


static func _repetir(o_que: StringName, n: int) -> PackedStringArray:
	var saida := PackedStringArray()
	for _k in n:
		saida.append(String(o_que))
	return saida


static func _tamanho(v: Variant) -> int:
	return v.size() if v is Array or v is PackedFloat32Array else 0


static func _dict(d: Dictionary, chave: StringName) -> Dictionary:
	var valor: Variant = d.get(chave, {})
	return valor if valor is Dictionary else {}
