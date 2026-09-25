# tests/accessibility_filter_test.gd — contraste e daltonismo (§26; GB-25, GB-26).
#
# A matriz de QA escreve os dois testes: A3, "OPT_CONTRAST no minimo e no
# maximo — a mancha e as tropas distinguem-se do fundo nos dois extremos"; A4 e
# A15, "a Podridao distingue-se do terreno em protanopia, deuteranopia e
# tritanopia". Medem-se aqui com a mesma conta que o shader faz.
extends GdUnitTestSuite

const M := AccessibilityFilter.Mode
## Quanto da separacao que um olho sem deficiencia ve entre a mancha e o chao
## tem de sobrar a quem a tem, com o modo ligado. Nao e do dossie: e o que diz
## "distingue-se" com um numero, e o modo tritanopia fica a 95%.
const SOBRA := 0.9


func _distancia(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


## Desligado, o filtro nao toca em nada — e a camada esconde-se.
func test_desligado_nao_muda_nenhuma_cor() -> void:
	var cor := Color(0.35, 0.22, 0.42)
	assert_bool(AccessibilityFilter.identity(1.0, M.OFF)).is_true()
	var saida := AccessibilityFilter.apply(cor, 1.0, M.OFF)
	assert_float(_distancia(saida, cor)).is_less(0.0001)


## A3: mais contraste afasta do cinzento do meio; menos, aproxima.
func test_o_contraste_afasta_e_aproxima_do_meio() -> void:
	var escura := Color(0.2, 0.2, 0.2)
	var meio := Color(0.5, 0.5, 0.5)
	var mais := AccessibilityFilter.apply(escura, AccessibilityFilter.CONTRASTE.max, M.OFF)
	var menos := AccessibilityFilter.apply(escura, AccessibilityFilter.CONTRASTE.min, M.OFF)
	assert_float(_distancia(mais, meio)).is_greater(_distancia(escura, meio))
	assert_float(_distancia(menos, meio)).is_less(_distancia(escura, meio))


## A3 nos extremos: a mancha e o chao continuam separados no contraste minimo.
func test_no_contraste_minimo_a_mancha_ainda_se_separa_do_chao() -> void:
	var minimo := AccessibilityFilter.CONTRASTE.min
	var mancha := AccessibilityFilter.apply(WorldPalette.MANCHA, minimo, M.OFF)
	var chao := AccessibilityFilter.apply(TerrainArt.SOIL, minimo, M.OFF)
	var normal := _distancia(WorldPalette.MANCHA, TerrainArt.SOIL)
	assert_float(_distancia(mancha, chao)).is_greater_equal(normal * minimo - 0.0001)


## A4 e A15: com o modo ligado, quem tem a deficiencia ve a mancha separada do
## chao quase tanto quanto quem nao a tem.
func test_com_o_modo_a_mancha_distingue_se_do_chao_nos_tres() -> void:
	var normal := _distancia(WorldPalette.MANCHA, TerrainArt.SOIL)
	for modo in [M.PROTANOPIA, M.DEUTERANOPIA, M.TRITANOPIA]:
		var mancha := AccessibilityFilter.simulate(
			AccessibilityFilter.apply(WorldPalette.MANCHA, 1.0, modo), modo
		)
		var chao := AccessibilityFilter.simulate(
			AccessibilityFilter.apply(TerrainArt.SOIL, 1.0, modo), modo
		)
		var msg := "modo %d: %.3f contra %.3f" % [modo, _distancia(mancha, chao), normal]
		assert_float(_distancia(mancha, chao)).override_failure_message(msg).is_greater(
			normal * SOBRA
		)


## E e o modo que faz a diferenca: sem ele, em tritanopia, a mancha perde mais
## de metade da separacao — que e a razao de o modo existir.
func test_sem_o_modo_a_tritanopia_perde_a_mancha() -> void:
	var t := M.TRITANOPIA
	var mancha := AccessibilityFilter.simulate(WorldPalette.MANCHA, t)
	var chao := AccessibilityFilter.simulate(TerrainArt.SOIL, t)
	var normal := _distancia(WorldPalette.MANCHA, TerrainArt.SOIL)
	assert_float(_distancia(mancha, chao)).is_less(normal * 0.5)


## O shader e o GDScript fazem a mesma conta: as matrizes que ele recebe sao as
## daqui, e nao numeros dele.
func test_o_shader_nao_tem_numeros_proprios() -> void:
	var fonte := FileAccess.get_file_as_string("res://shaders/accessibility.gdshader")
	assert_str(fonte).not_contains("0.152286").not_contains("0.7,")
	assert_str(fonte).contains("uniform mat3 simulacao").contains("uniform mat3 correcao")
