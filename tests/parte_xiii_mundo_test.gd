# tests/parte_xiii_mundo_test.gd — D-07 a D-14 da §84: os nomes, os dez
# capitulos, os tres epilogos e o save (§76, §77, §79, §84).
#
# Regra da ADR 0019: o que se mede so com os dados corre ja, contra
# data/source/ e data/**/*.tres. O que precisa de um sistema que ainda nao
# existe fica saltado com a razao escrita e o nome do sistema que falta —
# nunca comentado, nunca apagado.
extends GdUnitTestSuite

const Dados := preload("res://tests/support/dados.gd")


func _rot() -> RotProfile:
	return load("res://data/rot/default.tres")


# ----------------------------------------------------------------- §76


func test_d07_nunca_ha_mais_de_nove_nomeados_vivos() -> void:
	var kv := Dados.kv("res://data/source/economy.csv")
	assert_int(int(kv.get("named_cap", 0))).is_equal(9)
	# Nove titulos, nove feitos: o teto e o tamanho da tabela e nao um numero solto.
	var titles := Dados.all_in("res://data/lore/titles")
	assert_int(titles.size()).is_equal(9)
	var ids := {}
	var feats := {}
	for t: TitleData in titles:
		assert_bool(t.unique_while_alive).is_true()
		ids[t.id] = true
		feats[t.condition_kind] = true
	assert_int(ids.size()).is_equal(9)
	assert_int(feats.size()).is_equal(9)


func test_d08_um_titulo_volta_com_ordinal_depois_de_tres_dias_de_luto() -> void:
	var kv := Dados.kv("res://data/source/economy.csv")
	assert_int(int(kv.get("title_mourning_days", 0))).is_equal(3)


# ----------------------------------------------------------------- §77


# gdlint: disable=unused-argument
func test_d09_todos_os_capitulos_colocados_tem_caminho_alternativo(
	do_skip := true,
	skip_reason := "Falta o WorldGen (§54): o caminho alternativo e uma propriedade da rota gerada."
) -> void:
	for c: ChapterData in Dados.all_in("res://data/world/chapters"):
		assert_float(c.detour_seconds).is_greater(0.0)


func test_d12_os_doze_diarios_sao_alcancaveis_em_mil_sementes(
	do_skip := true,
	skip_reason := "Falta o WorldGen (§54) e a atribuicao de diarios (§79). E o unico caro da §84."
) -> void:
	assert_int(Dados.all_in("res://data/lore/journals").size()).is_equal(12)


# gdlint: enable=unused-argument


func test_d09_dados_todo_o_capitulo_tem_preco_de_desvio() -> void:
	# A metade que os dados provam: nenhum capitulo entra sem preco escrito.
	for c: ChapterData in Dados.all_in("res://data/world/chapters"):
		var msg := "%s: desvio de %.0f s" % [c.id, c.detour_seconds]
		assert_float(c.detour_seconds).override_failure_message(msg).is_greater(0.0)


func test_d10_exatamente_um_capitulo_tem_law_enters_walls() -> void:
	# Aparece o segundo, e a excecao do Forno Aceso deixa de ser especial (Q-039).
	var n := 0
	var quem := ""
	for c: ChapterData in Dados.all_in("res://data/world/chapters"):
		if c.law_enters_walls:
			n += 1
			quem = str(c.id)
	assert_int(n).override_failure_message("leis dentro de casa: %d (%s)" % [n, quem]).is_equal(1)
	assert_str(quem).is_equal("lit_oven")


func test_d11_dez_capitulos_e_o_cerco_e_sempre_um_deles() -> void:
	var chapters := Dados.all_in("res://data/world/chapters")
	assert_int(chapters.size()).is_equal(10)
	var garantidos: Array[String] = []
	var com_diario := 0
	for c: ChapterData in chapters:
		if c.guaranteed:
			garantidos.append(str(c.id))
		if c.reward_kind == &"journal":
			com_diario += 1
		# Regra 4 da §77: um diario, ou uma Semente Ancia. Nunca nenhum dos dois.
		assert_array([&"journal", &"ancient_seed"]).contains([c.reward_kind])
	assert_array(garantidos).is_equal(["endless_siege"])
	# Cinco dos doze diarios vao para capitulos, mais o 12 no Cerco: seis.
	assert_int(com_diario).is_equal(6)


func test_o_cerco_carrega_o_diario_12() -> void:
	var cerco: ChapterData = load("res://data/world/chapters/endless_siege.tres")
	assert_str(str(cerco.reward_id)).is_equal("journal_12")
	assert_bool(cerco.guaranteed).is_true()


func test_so_o_capitulo_sem_cancao_e_o_das_alminhas() -> void:
	# §77: "e o unico capitulo sem cancao: o silencio e a lei a funcionar."
	var sem: Array[String] = []
	for c: ChapterData in Dados.all_in("res://data/world/chapters"):
		if c.song_key.is_empty():
			sem.append(str(c.id))
	assert_array(sem).is_equal(["crossroad_souls"])


# ----------------------------------------------------------------- §79


func test_d13_o_epilogo_e_determinista_e_segue_a_precedencia() -> void:
	# A tabela da §79, avaliada de cima para baixo, contra os quatro limiares
	# do rot.csv. Nao precisa de sistema nenhum: e uma funcao pura.
	var casos := [
		[20, 6, 6, "dominio"],  # divida manda, mesmo com os seis soltos
		[12, 0, 6, "dominio"],
		[11, 4, 0, "dominio"],
		[3, 0, 4, "uniao"],
		[0, 0, 6, "uniao"],
		[4, 0, 6, "turno"],  # divida de 4: nem uma coisa nem outra
		[0, 0, 3, "turno"],
		[11, 3, 3, "turno"],
	]
	for caso in casos:
		var msg := "divida %d, ficados %d, soltos %d" % [caso[0], caso[1], caso[2]]
		assert_str(_epilogue(caso[0], caso[1], caso[2])).override_failure_message(msg).is_equal(
			caso[3]
		)


## A precedencia da §79, uma vez, para nao a haver escrita em dois sitios.
func _epilogue(debt: int, kept: int, released: int) -> String:
	var r := _rot()
	if debt >= r.dominion_debt_min:
		return "dominio"
	if kept >= r.dominion_peoples_kept:
		return "dominio"
	if debt <= r.union_debt_max and released >= r.union_peoples_released:
		return "uniao"
	return "turno"


# ----------------------------------------------------------------- §84


func test_d14_o_save_dos_sistemas_novos_so_contem_tipos_base() -> void:
	# A ADR 0007 fechou o save em FileAccess.store_var/get_var(false). A lista
	# de campos esta na §84; aqui guarda-se a regra que a torna verificavel.
	var permitidos := [
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_STRING,
		TYPE_DICTIONARY,
		TYPE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
	]
	var save := {
		"debt_lantern": 0,
		"refusals_by_day": PackedInt32Array(),
		"amargueiro_x": PackedFloat32Array(),
		"amargueiro_band": PackedInt32Array(),
		"amargueiro_tier": PackedInt32Array(),
		"amargueiro_day": PackedInt32Array(),
		"amargueiro_title": PackedStringArray(),
		"titles_holder": {},
		"titles_ordinal": {},
		"titles_mourning": {},
		"colheita_people": "",
		"colheita_days": 0,
		"colheita_queue": PackedStringArray(),
		"peoples_released": PackedStringArray(),
		"peoples_kept": PackedStringArray(),
		"chapters_placed": PackedStringArray(),
		"chapter_visits": {},
		"journals_found": PackedStringArray(),
	}
	for campo in save:
		var msg := "%s e do tipo %d" % [campo, typeof(save[campo])]
		assert_array(permitidos).override_failure_message(msg).contains([typeof(save[campo])])
	# E a prova de que passa mesmo pelo canal da ADR 0007, ida e volta.
	var caminho := "user://test_d14.save"
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_var(save, false)
	f.close()
	f = FileAccess.open(caminho, FileAccess.READ)
	var lido: Variant = f.get_var(false)
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	assert_int(typeof(lido)).is_equal(TYPE_DICTIONARY)
	assert_int((lido as Dictionary).size()).is_equal(save.size())
