# tests/band_light_test.gd — a luz de cada faixa (F1-13, §80, ADR 0011).
#
# O que se prova aqui nao e que a cor seja bonita: e que as seis fases sao
# DISTINGUIVEIS — que e o criterio do ticket — e que a noite e castanha e nao
# azul, que e a decisao que a ADR 0011 fechou depois de a §05 dizer o contrario.
extends GdUnitTestSuite

## §80: "pixeis de matiz 200°-290° com saturacao > 0,35" sao a Podridao e a luz,
## e nunca o ambiente. E o teste das "duas frias" da tabela do §80.
const FRIO_DE := 200.0
const FRIO_ATE := 290.0
const FRIO_SAT := 0.35
const VOLTA := 360.0
## A cor de uma fase e a cor do MEIO dela (ver BandLight.ambient).
const MEIO := 0.5


func _dados() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func test_a_noite_e_castanha_e_nao_azul() -> void:
	var cor := BandLight.ambient(_dados(), GameClock.Phase.NIGHT, MEIO)
	var matiz := cor.h * VOLTA

	var porque := "a noite saiu em %d° com saturacao %.2f" % [int(matiz), cor.s]
	var frio := matiz >= FRIO_DE and matiz <= FRIO_ATE and cor.s > FRIO_SAT
	assert_bool(frio).override_failure_message(porque).is_false()
	assert_float(matiz).is_equal_approx(_dados().phase_tint_hue[GameClock.Phase.NIGHT], 0.5)


func test_as_seis_fases_sao_distinguiveis() -> void:
	# O criterio do F1-13. Duas fases seguidas com a mesma cor seriam uma fase
	# que o jogador nao ve mudar — e o §24 nao lhe da HUD nenhum para o dizer.
	var vistas: Array[Color] = []
	for fase in _dados().phase_durations.size():
		var cor := BandLight.ambient(_dados(), fase, MEIO)
		for antes in vistas:
			var perto := absf(antes.v - cor.v) < 0.02 and absf(antes.s - cor.s) < 0.02
			assert_bool(perto).override_failure_message("duas fases com a mesma cor").is_false()
		vistas.append(cor)
	assert_int(vistas.size()).is_equal(6)


func test_o_chao_da_noite_desce_abaixo_do_ambiente() -> void:
	# §80: "o chao da noite desce abaixo do ambiente: 0,11". O numero esta no
	# clock.tres e o teste le-o de la — nao o repete.
	var dados := _dados()
	var ambiente := BandLight.ambient(dados, GameClock.Phase.NIGHT, MEIO)
	var chao := BandLight.of(dados, Band.Kind.SURFACE, GameClock.Phase.NIGHT, MEIO)

	assert_float(chao.v).is_equal_approx(dados.night_value_floor, 0.005)
	assert_float(chao.v).is_less(ambiente.v)


func test_o_plano_de_jogo_fica_inalterado() -> void:
	# §80, a linha "Plano de jogo · y 517-720 · toda a paleta · inalterado". O
	# tecto de valores e para o CENARIO; as tropas e as moedas nao o levam, e por
	# isso o plane() e a unica coisa que desce e o modulate leva so o ambiente.
	var dados := _dados()
	assert_float(BandLight.plane(dados, Band.Kind.AERIAL)).is_equal(1.0)
	assert_float(BandLight.plane(dados, Band.Kind.SURFACE)).is_less(1.0)
	assert_float(BandLight.plane(dados, Band.Kind.UNDERGROUND)).is_less(
		BandLight.plane(dados, Band.Kind.SURFACE)
	)


func test_o_aereo_e_o_ambiente_e_o_subsolo_e_o_mais_escuro() -> void:
	var dados := _dados()
	var fase := int(GameClock.Phase.NOON)
	var aereo := BandLight.of(dados, Band.Kind.AERIAL, fase, MEIO)
	var superficie := BandLight.of(dados, Band.Kind.SURFACE, fase, MEIO)
	var subsolo := BandLight.of(dados, Band.Kind.UNDERGROUND, fase, MEIO)

	assert_float(aereo.v).is_equal_approx(BandLight.ambient(dados, fase, MEIO).v, 0.001)
	assert_float(superficie.v).is_less(aereo.v)
	assert_float(subsolo.v).is_less(superficie.v)


func test_a_cor_de_uma_fase_e_a_cor_do_meio_dela() -> void:
	# O principio do crepusculo ainda tem tarde nele, e o fim ja tem noite. O que
	# e crepusculo puro e o meio — que e o unico ponto que a tabela do §80 fixa.
	var dados := _dados()
	var tarde := dados.phase_tint_val[GameClock.Phase.AFTERNOON]
	var crepusculo := dados.phase_tint_val[GameClock.Phase.DUSK]
	var noite := dados.phase_tint_val[GameClock.Phase.NIGHT]

	assert_float(BandLight.ambient(dados, GameClock.Phase.DUSK, MEIO).v).is_equal_approx(
		crepusculo, 0.001
	)
	assert_float(BandLight.ambient(dados, GameClock.Phase.DUSK, 0.0).v).is_equal_approx(
		(tarde + crepusculo) * MEIO, 0.001
	)
	assert_float(BandLight.ambient(dados, GameClock.Phase.DUSK, 1.0).v).is_equal_approx(
		(crepusculo + noite) * MEIO, 0.001
	)


func test_a_noite_so_clareia_no_fim() -> void:
	# O defeito que isto apanha: com a interpolacao a atravessar a fase inteira,
	# aos 62% da noite o ecra ja estava a 62% do caminho para a alvorada, e a
	# noite nunca chegava a ser noite.
	var dados := _dados()
	var noite := dados.phase_tint_val[GameClock.Phase.NIGHT]
	var meio_da_noite := BandLight.ambient(dados, GameClock.Phase.NIGHT, 0.62)

	assert_float(meio_da_noite.v).is_less(noite * 2.0)


func test_a_ultima_fase_da_a_volta_a_primeira() -> void:
	# A noite acaba na alvorada, e a alvorada comeca na noite: nem uma nem outra
	# caem num indice fora do array.
	var dados := _dados()
	var noite := dados.phase_tint_val[GameClock.Phase.NIGHT]
	var alvorada := dados.phase_tint_val[GameClock.Phase.DAWN]

	assert_float(BandLight.ambient(dados, GameClock.Phase.NIGHT, 1.0).v).is_equal_approx(
		(noite + alvorada) * MEIO, 0.001
	)
	assert_float(BandLight.ambient(dados, GameClock.Phase.DAWN, 0.0).v).is_equal_approx(
		(noite + alvorada) * MEIO, 0.001
	)


func test_a_razao_do_chao_sai_dos_dois_numeros_do_80() -> void:
	var dados := _dados()
	var esperado := dados.night_value_floor / dados.phase_tint_val[GameClock.Phase.NIGHT]

	assert_float(BandLight.ground_ratio(dados)).is_equal_approx(esperado, 0.0001)
