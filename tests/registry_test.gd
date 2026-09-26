# tests/registry_test.gd — o indice contra a arvore, e contra o _tables.csv.
#
# Este teste corre do codigo-fonte, onde data/source/ ainda e visivel, e e por
# isso que pode fazer a conferencia que o Registry nao pode fazer no jogo
# exportado: que toda a tabela declarada no _tables.csv foi mesmo encontrada.
extends GdUnitTestSuite

const TABELAS_CSV := "res://data/source/_tables.csv"


## As pastas que o _tables.csv declara, tiradas da coluna `out`.
func _pastas_declaradas() -> PackedStringArray:
	var pastas := PackedStringArray()
	var linhas := FileAccess.get_file_as_string(TABELAS_CSV).split("\n")
	for i in range(1, linhas.size()):
		var linha := linhas[i]
		if linha.strip_edges().is_empty():
			continue
		var saida := linha.split(",")[2]
		var pasta := saida.trim_prefix("res://data/").get_base_dir()
		if pasta not in pastas:
			pastas.append(pasta)
	return pastas


func test_todas_as_tabelas_do_tables_csv_estao_indexadas() -> void:
	var em_falta: Array[String] = []
	for pasta in _pastas_declaradas():
		if pasta not in Registry.tables():
			em_falta.append(pasta)
	var porque := "pastas do _tables.csv que o Registry nao indexou: %s" % ", ".join(em_falta)
	assert_array(em_falta).override_failure_message(porque).is_empty()


func test_indexa_os_202_recursos_e_nenhum_e_nulo() -> void:
	var nulos: Array[String] = []
	var contados := 0
	for tabela in Registry.tables():
		for id in Registry.ids(tabela):
			contados += 1
			if Registry.entry(tabela, id) == null:
				nulos.append("%s/%s" % [tabela, id])

	var porque := "recursos que nao carregaram: %s" % [nulos]
	assert_array(nulos).override_failure_message(porque).is_empty()
	assert_int(contados).is_equal(Registry.total())
	# O numero nao esta escrito aqui: conta-se a arvore e compara-se com o indice.
	var na_arvore := _contar_tres("res://data")
	assert_int(Registry.total()).is_equal(na_arvore)


func test_o_id_e_a_chave_e_resolve_por_stringname() -> void:
	var arqueiro := Registry.entry(&"units", &"archer")
	assert_object(arqueiro).is_not_null()
	assert_str(arqueiro.id).is_equal("archer")


func test_ids_iguais_em_tabelas_diferentes_nao_se_atropelam() -> void:
	# boar e montaria e e animal. Se o indice fosse global, um comia o outro.
	assert_bool(Registry.has_entry(&"mounts", &"boar")).is_true()
	assert_bool(Registry.has_entry(&"wildlife", &"boar")).is_true()

	var montaria := Registry.entry(&"mounts", &"boar")
	var animal := Registry.entry(&"wildlife", &"boar")
	assert_str(montaria.get_script().get_global_name()).is_equal("MountData")
	assert_str(animal.get_script().get_global_name()).is_equal("WildlifeData")


func test_as_subpastas_sao_tabelas_proprias() -> void:
	# data/rot/default.tres convive com data/rot/offers/ e data/rot/amargueiros/.
	assert_bool(Registry.has_entry(&"rot", &"default")).is_true()
	assert_bool(Registry.has_entry(&"rot/offers", &"an_heir")).is_true()
	assert_bool(Registry.has_entry(&"rot/amargueiros", &"fell")).is_true()
	assert_bool(Registry.has_entry(&"crown/impulses", &"call_to_arms")).is_true()
	assert_bool(Registry.has_entry(&"lore/titles", &"the_one_who_stayed")).is_true()
	assert_bool(Registry.has_entry(&"world/chapters", &"endless_siege")).is_true()


func test_ids_vem_ordenados_e_nao_pela_ordem_do_dicionario() -> void:
	# §42: uma regiao gerada pela mesma semente deixa de ser a mesma se a ordem
	# de iteracao mudar entre execucoes.
	var lista := Registry.ids(&"units")
	var copia := lista.duplicate()
	copia.sort()
	assert_array(lista).is_equal(copia)
	assert_int(Registry.entries(&"units").size()).is_equal(lista.size())


func test_a_fonte_dos_numeros_nao_entra_no_indice() -> void:
	# data/source/ tem .gdignore e nao existe no jogo exportado; indexa-la aqui
	# fazia o indice do editor diferir do indice do executavel.
	assert_bool(&"source" in Registry.tables()).is_false()
	assert_bool(&"i18n" in Registry.tables()).is_false()


func test_uma_tabela_desconhecida_devolve_vazio_em_vez_de_rebentar() -> void:
	assert_int(Registry.ids(&"nao_existe").size()).is_equal(0)
	assert_int(Registry.entries(&"nao_existe").size()).is_equal(0)
	assert_bool(Registry.has_entry(&"nao_existe", &"seja_o_que_for")).is_false()


func test_recarregar_nao_duplica() -> void:
	var antes := Registry.total()
	Registry.load_all()
	assert_int(Registry.total()).is_equal(antes)


func _contar_tres(caminho: String) -> int:
	var dir := DirAccess.open(caminho)
	if dir == null:
		return 0
	var n := 0
	for f in dir.get_files():
		if f.ends_with(".tres"):
			n += 1
	for sub in dir.get_directories():
		if sub in Registry.FORA or sub.begins_with("."):
			continue
		n += _contar_tres(caminho.path_join(sub))
	return n
