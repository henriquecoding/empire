# tests/support/dados.gd — leitura de dados para os testes de design (ADR 0019).
# Os testes da Parte XIII correm sobre os .tres gerados e sobre data/source/,
# sem depender de sistema nenhum. Estes dois ajudantes sao tudo o que precisam.
extends RefCounted


## Todos os recursos .tres de uma pasta, por ordem de nome.
static func all_in(path: String) -> Array:
	var out: Array = []
	var names := ResourceLoader.list_directory(path)
	names.sort()
	for name in names:
		if name.ends_with(".tres"):
			out.append(load(path.path_join(name)))
	return out


## Uma tabela kv de data/source/ como Dicionario chave -> valor, em texto.
static func kv(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var header := f.get_csv_line()
	var col := header.find("key")
	var val := header.find("value")
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() <= maxi(col, val) or line[col].is_empty():
			continue
		out[line[col]] = line[val]
	f.close()
	return out
