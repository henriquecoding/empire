# src/core/registry.gd — os .tres carregados por StringName (§41, §44).
#
# O indice DERIVA da arvore: varre res://data/ e uma tabela nova entra por
# existir, nao por alguem se lembrar dela. A alternativa era repetir aqui a
# lista de data/source/_tables.csv — e uma lista repetida a mao diverge, em
# silencio, porque uma lista desatualizada nao da erro.
#
# A tabela e o caminho da pasta dentro de data/: "units", "crown/impulses",
# "lore/titles". E o que a coluna `out` do _tables.csv ja diz, e resolve o unico
# problema real do indice — os ids NAO sao unicos entre tabelas: boar e uma
# montaria (data/mounts/boar.tres) e um animal (data/wildlife/boar.tres).
#
# O _tables.csv nao serve de fonte aqui: data/source/ tem um .gdignore e por
# isso nao existe no jogo exportado. O teste e que o confere contra este indice,
# a correr do codigo-fonte, onde os dois estao visiveis.
extends Node

const RAIZ := "res://data"

## data/source/ e a fonte dos numeros e nao entra no jogo; data/i18n/ e texto
## importado, nao sao recursos de dados.
const FORA: Array[String] = ["source", "i18n"]

var _tabelas: Dictionary = {}  # String -> Dictionary[String, Resource]
var _total: int = 0


func _ready() -> void:
	load_all()


## Varre e indexa. Idempotente: chamar duas vezes nao duplica nada.
func load_all() -> void:
	_tabelas.clear()
	_total = 0
	_varrer(RAIZ, "")


## O recurso, ou null. Um id desconhecido e sempre erro: grita no editor pelo
## assert e no jogo exportado pelo push_error, em vez de devolver null calado e
## rebentar tres sistemas a frente.
func entry(tabela: StringName, id: StringName) -> Resource:
	var chave := String(tabela)
	if _tabelas.has(chave) and _tabelas[chave].has(String(id)):
		return _tabelas[chave][String(id)]
	assert(false, "Registry: %s/%s nao existe" % [tabela, id])
	push_error("Registry: %s/%s nao existe" % [tabela, id])
	return null


func has_entry(tabela: StringName, id: StringName) -> bool:
	var chave := String(tabela)
	return _tabelas.has(chave) and _tabelas[chave].has(String(id))


## Os ids de uma tabela, ORDENADOS. A §42 proibe iterar um Dictionary quando o
## resultado afeta a simulacao: a ordem de um dicionario nao e garantida entre
## execucoes, e uma regiao gerada pela mesma semente deixava de ser a mesma.
func ids(tabela: StringName) -> PackedStringArray:
	var chave := String(tabela)
	if not _tabelas.has(chave):
		return PackedStringArray()
	var saida := PackedStringArray(_tabelas[chave].keys())
	saida.sort()
	return saida


## Os recursos de uma tabela, pela mesma ordem de ids().
func entries(tabela: StringName) -> Array[Resource]:
	var saida: Array[Resource] = []
	for id in ids(tabela):
		saida.append(_tabelas[String(tabela)][id])
	return saida


## As tabelas encontradas, ordenadas.
func tables() -> PackedStringArray:
	var saida := PackedStringArray(_tabelas.keys())
	saida.sort()
	return saida


## Quantos recursos ao todo. O painel de estado e os testes contam por aqui em
## vez de afirmar um numero.
func total() -> int:
	return _total


func _varrer(caminho: String, tabela: String) -> void:
	var dir := DirAccess.open(caminho)
	if dir == null:
		push_error("Registry: nao abre %s" % caminho)
		return

	for ficheiro in dir.get_files():
		var nome := _sem_remap(ficheiro)
		if nome.ends_with(".tres"):
			_indexar(tabela, nome.get_basename(), caminho.path_join(nome))

	for sub in dir.get_directories():
		if sub in FORA or sub.begins_with("."):
			continue
		_varrer(caminho.path_join(sub), tabela.path_join(sub) if tabela else sub)


## Num jogo exportado os .tres vem convertidos e listados como .tres.remap; do
## codigo-fonte vem como estao. Sem isto o indice esta cheio no editor e vazio
## no executavel — e so se descobre depois de exportar.
func _sem_remap(ficheiro: String) -> String:
	return ficheiro.trim_suffix(".remap") if ficheiro.ends_with(".remap") else ficheiro


func _indexar(tabela: String, id: String, caminho: String) -> void:
	if not _tabelas.has(tabela):
		_tabelas[tabela] = {}
	# ResourceLoader aqui e correto: sao dados do jogo, versionados connosco.
	# A ADR 0007 proibe-o em ficheiros de SAVE, que sao outra coisa — um .tres
	# vindo de fora pode trazer script embutido.
	_tabelas[tabela][id] = ResourceLoader.load(caminho)
	_total += 1
