# tests/silhouette_test.gd — o que cada coisa E, em forma (§10, §22, §55).
#
# O greybox desenhava tudo com o mesmo rectangulo e mudava-lhe a cor pelo
# ESTADO. A cor diz o que se passa e nao diz o que a coisa e — e por isso um
# canteiro, uma torre e o castelo-arvore eram o mesmo cinzento em larguras
# diferentes. O §22 escreve onde e que a identidade vive: "a paleta muda com a
# hora do dia e com o LUT; a silhueta do telhado nao muda nunca".
#
# Este ficheiro mede a CLASSIFICACAO — que cada categoria de `buildings.csv`,
# cada tag de `creatures.csv` e cada arma de `units.csv` chega ao ecra com forma
# propria. A geometria e o `outline_test.gd`.
#
# Nao ha aqui nenhum numero do dossie escrito a mao: as categorias, as tags, as
# armas e os niveis do muro saem de data/.
extends GdUnitTestSuite

## O que o `of_slot` devolve quando nao soube dizer o que ali esta. Um teste que
## aceitasse isto como resposta certa nao media nada.
const SEM_RESPOSTA := Silhouette.Form.CAIXA

## As quatro tropas que existem no segmento zero (Greybox). Se estas nao se
## separam, nada do resto interessa — sao as unicas que alguem ve hoje.
const NO_GREYBOX: Array[StringName] = [&"vagrant", &"archer", &"spearman", &"monarch"]


func _edificios() -> Dictionary:
	return SimFactory.by_id(&"buildings")


func test_cada_categoria_de_buildings_tem_forma_propria() -> void:
	# A regra do §22 medida: a forma e a identidade, e duas categorias com a
	# mesma forma sao duas coisas que o jogador nao separa de relance.
	var por_forma := {}
	for dados: BuildingData in Registry.entries(&"buildings"):
		var forma := Silhouette.of_building(dados)
		var sem := "%s (categoria %s) nao tem forma" % [dados.id, dados.category]
		assert_int(forma).override_failure_message(sem).is_not_equal(SEM_RESPOSTA)
		var chave := "%s|%s" % [dados.category, dados.tags.has(Silhouette.ANTIAEREA)]
		if not por_forma.has(forma):
			por_forma[forma] = chave
		var porque := "a forma %d serve %s e %s" % [forma, por_forma[forma], chave]
		assert_str(por_forma[forma]).override_failure_message(porque).is_equal(chave)


func test_a_torre_alta_nao_se_confunde_com_a_torre_de_arqueiros() -> void:
	# §10: "a alta e a que atinge a camada aerea". Duas obras da MESMA categoria
	# com funcoes diferentes — e a unica vez em que a categoria nao chega.
	var edificios := _edificios()
	var torre := Silhouette.of_building(edificios.get(&"archer_tower") as BuildingData)
	var alta := Silhouette.of_building(edificios.get(&"high_tower") as BuildingData)
	assert_int(alta).is_not_equal(torre)
	# E ve-se qual e qual sem ler o nome: a que chega ao Alado e a mais alta.
	assert_float(Silhouette.height(alta, 1)).is_greater(Silhouette.height(torre, 1))


func test_o_muro_e_a_unica_obra_com_ameias() -> void:
	# O muro nao esta em buildings.csv — esta em walls.csv, e o que o distingue
	# no mundo e ter os dois caminhos do §10. E por ai que o `of_slot` o apanha,
	# e nao pelo id: perguntar pelo id era escolher um nivel e esquecer quatro.
	var muro := BuildSlot.new()
	muro.kind = &"stakes"
	muro.healths_a = PackedInt32Array([40])
	assert_bool(muro.two_paths()).is_true()
	assert_int(Silhouette.of_slot(muro, _edificios())).is_equal(Silhouette.Form.AMEIA)

	for dados: BuildingData in Registry.entries(&"buildings"):
		var porque := "%s desenha ameias e nao e um muro" % dados.id
		var forma := Silhouette.of_building(dados)
		assert_int(forma).override_failure_message(porque).is_not_equal(Silhouette.Form.AMEIA)


func test_uma_obra_que_o_registry_nao_conhece_nao_inventa_forma() -> void:
	var estranha := BuildSlot.new()
	estranha.kind = &"nao_existe"
	assert_int(Silhouette.of_slot(estranha, _edificios())).is_equal(SEM_RESPOSTA)


func test_as_criaturas_veem_se_todas_diferentes() -> void:
	# A noite e a altura em que saber o que vem a chegar vale mais: um
	# Rastejante e um Ariete de lodo chegam pela mesma borda e pedem respostas
	# opostas. Sao sete linhas em creatures.csv e teem de ser sete silhuetas.
	var vistas := {}
	for dados: CreatureData in Registry.entries(&"creatures"):
		var forma := Silhouette.of_creature(dados)
		var porque := "%s desenha-se como %s" % [dados.id, vistas.get(forma, "")]
		assert_bool(vistas.has(forma)).override_failure_message(porque).is_false()
		vistas[forma] = str(dados.id)
	assert_int(vistas.size()).is_equal(Registry.entries(&"creatures").size())


func test_toda_a_arma_de_units_csv_tem_marca() -> void:
	# A marca e o que separa um arqueiro de um lanceiro a dez passos. Uma arma
	# sem marca e uma tropa que se confunde com outra.
	var armas := {}
	var escritas := {}
	for dados: UnitData in Registry.entries(&"units"):
		var marca := Silhouette.of_unit(dados)
		if dados.weapon_kind.is_empty():
			var voa: bool = dados.tags.has(Silhouette.VOADORA)
			var sem := "%s nao leva arma e desenha a marca %d" % [dados.id, marca]
			var vazia := marca == Silhouette.Mark.NENHUMA
			assert_bool(vazia or voa).override_failure_message(sem).is_true()
			continue
		escritas[dados.weapon_kind] = true
		var porque := "a arma %s de %s nao tem marca" % [dados.weapon_kind, dados.id]
		assert_int(marca).override_failure_message(porque).is_not_equal(Silhouette.Mark.NENHUMA)
		armas[dados.weapon_kind] = marca
	# Nenhuma arma fica pelo caminho: as de units.csv chegam todas ao ecra.
	assert_int(armas.size()).is_equal(escritas.size())


func test_a_tropa_do_greybox_ve_se_toda_diferente() -> void:
	var tropas := SimFactory.by_id(&"units")
	var vistas := {}
	for id in NO_GREYBOX:
		var marca := Silhouette.of_unit(tropas.get(id) as UnitData)
		var porque := "%s desenha-se como %s" % [id, vistas.get(marca, "")]
		assert_bool(vistas.has(marca)).override_failure_message(porque).is_false()
		vistas[marca] = str(id)


func test_o_porte_separa_o_que_o_contorno_sozinho_nao_separava() -> void:
	# A segunda metade da leitura: um Rastejante e largo e rente ao chao, um
	# Zelador e fino e alto. Com o mesmo porte, duas formas parecidas de longe
	# passavam a mesma mancha — e de longe e onde isto tem de funcionar.
	var alto := WorldPalette.DEGRAU * 2.0
	var chao := int(Band.Kind.SURFACE)
	var rastejo := Silhouette.body_box(Silhouette.Form.RASTEJO, 0.0, chao, alto)
	var zelador := Silhouette.body_box(Silhouette.Form.ZELADOR, 0.0, chao, alto)
	assert_float(rastejo.size.x).is_greater(rastejo.size.y)
	assert_float(zelador.size.y).is_greater(zelador.size.x)
	assert_float(rastejo.size.x).is_greater(zelador.size.x)


func test_todo_o_corpo_assenta_na_linha_de_chao_da_sua_faixa() -> void:
	# §11: e a linha do chao que diz em que faixa uma coisa esta. Um corpo que
	# nao assente nela flutua, e um corpo que flutua nao se sabe onde esta.
	var alto := WorldPalette.DEGRAU * 2.0
	for faixa in [Band.Kind.AERIAL, Band.Kind.SURFACE, Band.Kind.UNDERGROUND]:
		for forma in Silhouette.Form.values():
			var caixa := Silhouette.body_box(forma, 120.0, int(faixa), alto)
			var chao := WorldPalette.ground_of(int(faixa))
			var porque := "a forma %d da faixa %d acaba em %.1f" % [forma, faixa, caixa.end.y]
			assert_float(caixa.end.y).override_failure_message(porque).is_equal_approx(chao, 0.001)
			assert_float(caixa.get_center().x).is_equal_approx(120.0, 0.001)
