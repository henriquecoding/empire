# tests/captura_semente_test.gd — a semente de um jogo novo pode ser pedida.
#
# O planejamento de 26/09 (§8) exige que cada captura diga a semente com que foi
# tirada e que a mesma semente a reproduza. Sem `--semente`, um jogo novo nasce
# da hora do relogio e nenhuma fotografia se repete.
extends GdUnitTestSuite

const OMISSAO := 1234


func test_sem_pedido_fica_a_omissao() -> void:
	assert_int(Game.seed_from(PackedStringArray(["--novo"]), OMISSAO)).is_equal(OMISSAO)


func test_a_semente_pedida_manda() -> void:
	var args := PackedStringArray(["--novo", Game.SEMENTE, "20260926"])
	assert_int(Game.seed_from(args, OMISSAO)).is_equal(20260926)


func test_uma_semente_ilegivel_nao_passa_por_zero() -> void:
	var args := PackedStringArray([Game.SEMENTE, "amanha"])
	assert_int(Game.seed_from(args, OMISSAO)).is_equal(OMISSAO)
	assert_int(Game.seed_from(PackedStringArray([Game.SEMENTE]), OMISSAO)).is_equal(OMISSAO)
