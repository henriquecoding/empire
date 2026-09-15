# tests/outline_test.gd — a geometria das silhuetas do greybox (§22, §55, §80).
#
# O `silhouette_test.gd` mede a classificacao — que cada coisa tem forma
# propria. Este mede o DESENHO: que duas formas nunca dao o mesmo contorno, que
# nenhuma sai da caixa que lhe deram, que a arma troca de lado com o sentido, e
# que o muro leva na silhueta o numero que o §55 diz que ele muda ao subir.
#
# O portao que interessa e o primeiro. A leitura a 1 bit do §80 — "limiar de
# luminancia a 0,42 sobre o ecra composto; falha se nao se identifica a cena" —
# nao se automatiza, mas a metade que se automatiza e esta: duas coisas com o
# mesmo contorno sao uma so, e nenhum limiar as separa depois.
extends GdUnitTestSuite

## Uma caixa qualquer, longe da origem e com os lados diferentes: uma forma que
## so funcione num quadrado centrado em zero chumba aqui e nao no ecra.
const CAIXA := Rect2(Vector2(140.0, 380.0), Vector2(64.0, 96.0))


func _niveis_do_muro() -> int:
	return SimFactory.walls_by_level().size()


func _dentro(caixa: Rect2, p: Vector2) -> bool:
	# O has_point do Rect2 exclui a borda de baixo e a da direita, e uma
	# silhueta assenta na borda de baixo: aqui a borda conta como dentro.
	var x := p.x >= caixa.position.x and p.x <= caixa.end.x
	return x and p.y >= caixa.position.y and p.y <= caixa.end.y


func _dentes(pontos: PackedVector2Array, topo: float) -> int:
	# Cada ameia poe dois pontos no topo da caixa: o que sobe e o que desce.
	var n := 0
	for p: Vector2 in pontos:
		if is_equal_approx(p.y, topo):
			n += 1
	return n


# ------------------------------------------------------- o contorno


func test_nenhuma_forma_desenha_a_mesma_coisa_que_outra() -> void:
	# O portao do ficheiro inteiro: com a MESMA caixa, duas formas teem de dar
	# dois desenhos. Sem isto, a classificacao do outro ficheiro era so um enum.
	var desenhos := {}
	for forma in Silhouette.Form.values():
		var pontos := Outline.shape(forma, CAIXA, Outline.DENTES_MIN)
		var chave := str(pontos)
		var porque := "a forma %d desenha o mesmo que a %s" % [forma, desenhos.get(chave, "")]
		assert_bool(desenhos.has(chave)).override_failure_message(porque).is_false()
		desenhos[chave] = str(forma)
		var solta := "a forma %d nao e um poligono" % forma
		assert_int(pontos.size()).override_failure_message(solta).is_greater_equal(3)


func test_toda_a_forma_cabe_na_caixa_que_lhe_deram() -> void:
	# A caixa e o contrato entre quem escolhe a altura e quem desenha. Uma forma
	# que saia dela tapa a tropa que esta a frente — e o greybox existe para se
	# ver o que se passa, nao para o esconder.
	for forma in Silhouette.Form.values():
		for p: Vector2 in Outline.shape(forma, CAIXA, Outline.DENTES_MIN):
			var porque := "a forma %d sai da caixa em %s" % [forma, p]
			assert_bool(_dentro(CAIXA, p)).override_failure_message(porque).is_true()


func test_o_muro_leva_um_dente_por_slot_de_contacto() -> void:
	# §55: "cada subida emite wall_upgraded, que muda material, silhueta e numero
	# de slots de contacto — os tres ao mesmo tempo, porque e a mesma decisao de
	# design". O greybox nao tem material, e por isso a silhueta leva os outros
	# dois: um dente por atacante que engaja, lido de walls.csv.
	for nivel: WallData in SimFactory.walls_by_level():
		var pontos := Outline.shape(Silhouette.Form.AMEIA, CAIXA, nivel.contact_slots)
		var dentes := _dentes(pontos, CAIXA.position.y)
		var porque := "%s tem %d slots e %d/2 dentes" % [nivel.id, nivel.contact_slots, dentes]
		assert_int(dentes).override_failure_message(porque).is_equal(nivel.contact_slots * 2)


func test_um_muro_sem_slots_ainda_e_um_muro() -> void:
	# Um sitio por construir tem nivel 0 e nenhum slot de contacto. Desenhar zero
	# dentes deixava um rectangulo — que e exactamente o que ninguem distingue.
	var pontos := Outline.shape(Silhouette.Form.AMEIA, CAIXA, 0)
	assert_int(_dentes(pontos, CAIXA.position.y)).is_equal(Outline.DENTES_MIN * 2)


# ------------------------------------------------------- as marcas


func test_nenhuma_marca_desenha_a_mesma_coisa_que_outra() -> void:
	var desenhos := {}
	for marca in Silhouette.Mark.values():
		var pontos := Outline.mark(marca, CAIXA, 1.0)
		if marca == Silhouette.Mark.NENHUMA:
			assert_array(pontos).is_empty()
			continue
		var chave := str(pontos)
		var porque := "a marca %d desenha o mesmo que a %s" % [marca, desenhos.get(chave, "")]
		assert_bool(desenhos.has(chave)).override_failure_message(porque).is_false()
		desenhos[chave] = str(marca)
		assert_int(pontos.size()).is_greater_equal(2)


func test_a_marca_troca_de_lado_com_o_sentido() -> void:
	# Quem vai para a esquerda leva a arma a esquerda. Sem isto nao se percebe
	# para onde uma tropa esta virada, e "para onde vai" e metade do que ha para
	# ler numa noite.
	for marca in Silhouette.Mark.values():
		if marca == Silhouette.Mark.NENHUMA:
			continue
		var direita := str(Outline.mark(marca, CAIXA, 1.0))
		var esquerda := str(Outline.mark(marca, CAIXA, -1.0))
		var porque := "a marca %d fica igual nos dois sentidos" % marca
		assert_bool(direita != esquerda).override_failure_message(porque).is_true()


func test_a_marca_sai_do_corpo_mas_nao_se_perde_no_ecra() -> void:
	# A marca sai da caixa de proposito — e uma arma —, mas nao mais do que o
	# corpo mede. Uma lanca de tres corpos era um risco no ecra, nao uma tropa.
	var folga := CAIXA.grow(maxf(CAIXA.size.x, CAIXA.size.y))
	for marca in Silhouette.Mark.values():
		for p: Vector2 in Outline.mark(marca, CAIXA, 1.0):
			var porque := "a marca %d chega a %s, longe da caixa %s" % [marca, p, CAIXA]
			assert_bool(_dentro(folga, p)).override_failure_message(porque).is_true()


# ------------------------------------------------------- a altura


func test_a_copa_do_castelo_arvore_entra_na_faixa_aerea() -> void:
	# §11: "nada de silhueta contornada entra na faixa aerea, excepto as
	# voadoras e a copa da arvore colossal do castelo, e e justamente por isso
	# que ela vai ler-se como monumental".
	var alto := Silhouette.height(Silhouette.Form.COPA, 1)
	var topo := WorldPalette.ground_of(int(Band.Kind.SURFACE)) - alto
	assert_float(topo).is_less(float(Band.AERIAL_BOTTOM))
	# E nao se cola ao topo do ecra: o §11 quer "espaco entre os dois".
	assert_float(topo).is_greater(float(Band.SKY_TOP))


func test_o_castelo_arvore_e_a_obra_mais_alta_do_mapa() -> void:
	var copa := Silhouette.height(Silhouette.Form.COPA, 1)
	for forma in Silhouette.OBRAS:
		if forma == Silhouette.Form.COPA:
			continue
		var alto := Silhouette.height(forma, _niveis_do_muro())
		var porque := "a forma %d chega a %.1f px e o nucleo a %.1f" % [forma, alto, copa]
		assert_float(alto).override_failure_message(porque).is_less(copa)


func test_o_muro_cresce_com_o_nivel_e_tudo_o_resto_nao() -> void:
	# §10: cinco niveis, e o §25 quer que a subida se veja. So o muro sobe: um
	# canteiro de nivel 1 e o unico canteiro que existe.
	var topo := _niveis_do_muro()
	for nivel in range(1, topo):
		var baixo := Silhouette.height(Silhouette.Form.AMEIA, nivel)
		assert_float(Silhouette.height(Silhouette.Form.AMEIA, nivel + 1)).is_greater(baixo)
	var parada := Silhouette.height(Silhouette.Form.TELHADO, 1)
	assert_float(Silhouette.height(Silhouette.Form.TELHADO, topo)).is_equal_approx(parada, 0.001)


func test_nenhuma_obra_e_mais_baixa_do_que_uma_moeda() -> void:
	# O chao do greybox: uma obra que se ve menos do que a moeda que a paga nao
	# se ve. Um sitio por construir tem nivel 0 e tambem tem de ter altura — e o
	# §25 diz porque: "a silhueta e o convite. Nao ha botao construir."
	for forma in Silhouette.OBRAS:
		for nivel in [0, 1]:
			var alto := Silhouette.height(forma, nivel)
			var porque := "a forma %d de nivel %d tem %.1f px" % [forma, nivel, alto]
			var minimo := WorldPalette.MOEDA_R * 2.0
			assert_float(alto).override_failure_message(porque).is_greater(minimo)
