# tests/bestiary_test.gd — o bestiario da Podridao: forma, porte e cor (ADR 0049).
#
# O dono (02/10/2026): "a variedade, formato e tamanho dos inimigos deve ser mesmo
# bem feita". O que se mede aqui e o que se le de longe: que cada criatura tem o
# seu tamanho e nenhum e o de outra, que o tamanho conta a historia certa contra
# uma tropa e contra o rei, e que a noite continua a ser dela so pelos olhos.
extends GdUnitTestSuite

const F := Silhouette.Form
## §80: frio e saturado, a noite, so a mancha. As cores do corpo ficam abaixo.
const FRIO_DE := 200.0
const FRIO_ATE := 290.0
const FRIO_SAT := 0.35
## As tropas e os monarcas sao sprites de 64x64 (Q-219).
const SPRITE_PX := 64.0


func _caixa(forma: Silhouette.Form) -> Rect2:
	return Bestiary.box(forma, 0.0, int(Band.Kind.SURFACE))


func _rei() -> Rect2:
	return OriginalArt.new().box(&"monarch", Vector2.ZERO)


func test_toda_a_criatura_do_csv_tem_desenho() -> void:
	for dados: CreatureData in Registry.entries(&"creatures"):
		var forma := Silhouette.of_creature(dados)
		var porque := "%s (forma %d) nao esta no bestiario" % [dados.id, forma]
		assert_bool(Bestiary.handles(forma)).override_failure_message(porque).is_true()


func test_nenhuma_tem_o_tamanho_de_outra() -> void:
	var vistos := {}
	for forma: Silhouette.Form in Bestiary.TAMANHO:
		var tamanho := _caixa(forma).size
		assert_bool(vistos.has(tamanho)).override_failure_message("%d repete" % forma).is_false()
		vistos[tamanho] = forma


func test_o_rastejante_e_o_mais_pequeno_e_o_devorador_o_maior() -> void:
	var area := func(f: Silhouette.Form) -> float: return _caixa(f).get_area()
	for forma: Silhouette.Form in Bestiary.TAMANHO:
		if forma != F.RASTEJO:
			assert_float(area.call(forma)).is_greater(area.call(F.RASTEJO))
		if forma != F.COLOSSO:
			assert_float(area.call(forma)).is_less(area.call(F.COLOSSO))


## Q-219 (o dono, 03/10/2026: «o menor tem que ter um tamanho aceitavel para que o
## combate faca sentido em base 64x64»): o Rastejante, o mais pequeno, enche a largura de
## um sprite de 64 e tem a altura de uma tropa; o Bruto passa o rei; o Devorador sobe-se.
func test_o_porte_conta_contra_a_tropa_e_o_rei() -> void:
	var rei := _rei().size.y
	var tropa: float = OriginalArt.new().box(&"vagrant", Vector2.ZERO).size.y
	var rastejante := _caixa(F.RASTEJO).size
	assert_float(rastejante.x).is_greater_equal(SPRITE_PX)
	assert_float(rastejante.y).is_greater_equal(tropa)
	assert_float(rastejante.y).is_less(tropa * 1.5)  # e o enxame: nao passa de uma tropa e meia
	assert_float(_caixa(F.BRUTO).size.y).is_greater(rei)
	assert_float(_caixa(F.BRUTO).size.y).is_less(_caixa(F.COLOSSO).size.y)
	assert_float(_caixa(F.COLOSSO).size.y).is_greater(rei * 1.5)  # sobe-se a ele (§74)


## O pixel de cada criatura e inteiro e par ou impar mas nunca meio: o pixel fica pixel,
## e nenhuma desce do pixel de descanso (BeastPen.PIXEL).
func test_cada_criatura_tem_um_pixel_inteiro() -> void:
	for forma: Silhouette.Form in Bestiary.TAMANHO:
		var pixel := Bestiary.pixel_of(forma)
		assert_float(pixel).is_equal(roundf(pixel))
		assert_float(pixel).is_greater_equal(BeastPen.PIXEL)


func test_o_ariete_e_comprido_e_o_zelador_e_fino() -> void:
	var ariete := _caixa(F.ARIETE).size
	var zelador := _caixa(F.ZELADOR).size
	assert_float(ariete.x).is_greater(ariete.y * 2.0)
	assert_float(zelador.y).is_greater(zelador.x * 2.5)


func test_todas_assentam_no_chao_da_faixa() -> void:
	for forma: Silhouette.Form in Bestiary.TAMANHO:
		for faixa in [Band.Kind.AERIAL, Band.Kind.SURFACE, Band.Kind.UNDERGROUND]:
			var caixa := Bestiary.box(forma, 300.0, int(faixa))
			assert_float(caixa.end.y).is_equal_approx(WorldPalette.ground_of(int(faixa)), 0.001)
			assert_float(caixa.get_center().x).is_equal_approx(300.0, 0.001)


func test_nenhum_corpo_e_frio_e_saturado() -> void:
	# O roxo saturado e dos olhos e da mancha; o corpo e carne pisada (§80, ADR 0034).
	for forma: Silhouette.Form in Bestiary.CORES:
		for hexa: String in Bestiary.CORES[forma]:
			var cor := Color(hexa)
			var frio := cor.h * 360.0 >= FRIO_DE and cor.h * 360.0 <= FRIO_ATE
			var porque := "%s da forma %d e frio e saturado" % [hexa, forma]
			assert_bool(frio and cor.s > FRIO_SAT).override_failure_message(porque).is_false()


func test_as_cores_passam_pela_luz_de_quem_desenha() -> void:
	var tons := Bestiary.tones(F.BRUTO, func(c: Color) -> Color: return c.darkened(0.5))
	assert_int(tons.size()).is_equal(BeastPen.Tone.size())
	var corpo := Color(Bestiary.CORES[F.BRUTO][BeastPen.Tone.BODY])
	assert_bool((tons[BeastPen.Tone.BODY] as Color).is_equal_approx(corpo.darkened(0.5))).is_true()


func test_o_pincel_espelha_para_o_outro_lado() -> void:
	var direita := BeastPen.new(null, Vector2(100.0, 500.0), Vector2(2.0, 2.0), 1.0)
	var esquerda := BeastPen.new(null, Vector2(100.0, 500.0), Vector2(2.0, 2.0), -1.0)
	assert_vector(direita.at(5.0, 3.0)).is_equal(Vector2(110.0, 494.0))
	assert_vector(esquerda.at(5.0, 3.0)).is_equal(Vector2(90.0, 494.0))
