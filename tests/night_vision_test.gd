# tests/night_vision_test.gd — a noite que se ve (ADR 0048).
#
# O dono (02/10/2026): "adoro o clima dificil de ver, mas nao quero que seja
# impossivel". A noite continua castanha (ADR 0011) e continua escura; o que se
# prova aqui e que o olho a alcanca — e que o dia nao mudou por isso.
extends GdUnitTestSuite

const MEIO := 0.5


func _dados() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func test_a_noite_vista_continua_castanha() -> void:
	var dados := _dados()
	var tinta := BandLight.ambient(dados, GameClock.Phase.NIGHT, MEIO)
	var vista := BandLight.seen(dados, GameClock.Phase.NIGHT, MEIO)
	assert_float(vista.h).is_equal_approx(tinta.h, 0.001)
	assert_float(vista.s).is_equal_approx(tinta.s, 0.001)


func test_o_olho_nao_desce_abaixo_do_piso() -> void:
	var dados := _dados()
	assert_float(dados.night_vision).is_greater(dados.phase_tint_val[GameClock.Phase.NIGHT])
	for fase in dados.phase_durations.size():
		for passo in 11:
			var vista := BandLight.seen(dados, fase, float(passo) / 10.0)
			assert_float(vista.v).is_greater_equal(dados.night_vision - 0.0001)


func test_de_dia_o_olho_ve_o_que_ja_via() -> void:
	var dados := _dados()
	for fase in [GameClock.Phase.MORNING, GameClock.Phase.NOON, GameClock.Phase.AFTERNOON]:
		var tinta := BandLight.ambient(dados, fase, MEIO)
		var vista := BandLight.seen(dados, fase, MEIO)
		assert_bool(vista.is_equal_approx(tinta)).is_true()


func test_a_noite_vista_e_ainda_a_fase_mais_escura() -> void:
	# Levantar o piso nao pode apagar a noite: continua a ser a fase de menos luz,
	# e e por isso que as tuas luzes ainda se leem nela.
	var dados := _dados()
	var noite := BandLight.seen(dados, GameClock.Phase.NIGHT, MEIO).v
	for fase in dados.phase_durations.size() - 1:
		assert_float(BandLight.seen(dados, fase, MEIO).v).is_greater(noite)


func test_o_chao_continua_abaixo_do_ceu() -> void:
	# §80: o chao da noite desce abaixo do ambiente — a mesma razao, depois do olho.
	var dados := _dados()
	var ceu := BandLight.seen_of(dados, Band.Kind.AERIAL, GameClock.Phase.NIGHT, MEIO)
	var chao := BandLight.seen_of(dados, Band.Kind.SURFACE, GameClock.Phase.NIGHT, MEIO)
	var fundo := BandLight.seen_of(dados, Band.Kind.UNDERGROUND, GameClock.Phase.NIGHT, MEIO)
	assert_float(chao.v).is_less(ceu.v)
	assert_float(fundo.v).is_less(chao.v)
	assert_float(chao.a).is_equal_approx(1.0, 0.0001)
