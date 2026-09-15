# tests/dez_dias_test.gd — o criterio de saida da Fase 1 (§66, F1-16).
#
# O §66 escreve-o numa linha: "sobreviver 10 dias e possivel e nao e trivial".
# Sao duas metades, e so uma delas se pode medir hoje:
#
#   · POSSIVEL — mede-se, e passa. Uma defesa corre dez noites inteiras, ao
#     passo fixo, com a tabela de invocacao do §07 a subir por dia, e o
#     castelo-arvore fica de pe.
#   · NAO TRIVIAL — nao se mede, e nao e por falta de afinacao: NADA no jogo
#     consegue derrubar o nucleo. Ver a Q-075. Os dois testes disso ficam
#     saltados com essa razao (ADR 0019), e voltam sozinhos no dia em que a
#     pergunta fechar — sem que ninguem se lembre de os ir buscar.
#
# Nenhum numero de data/ foi mexido por este ficheiro. Nao ha numero que torne
# nao-trivial um jogo que nao se pode perder.
extends GdUnitTestSuite

const Harness := preload("res://tests/sim_harness.gd")
const Campaign := preload("res://tests/support/campaign.gd")

const DIAS := 10
## A defesa do decimo dia: a muralha no terceiro degrau do §10, as duas torres
## — a de arqueiros e a alta, que o §07 diz que o Alado obriga — e dez tropas.
const NIVEL_DO_MURO := 3
const ARQUEIROS := 10
## §08: o dia em que o Bruto entra, e a noite de superficie mais pesada que ha
## antes do Cavador.
const DIA_DOS_BRUTOS := 8

var _h: Harness


func before_test() -> void:
	_h = Harness.new()
	# A tabela inteira, e nao so Rastejantes: o crawlers_only e o microteste de
	# combate do §07, e o §66 mede o jogo.
	_h.crawlers_only = false


func after_test() -> void:
	_h.stop()


func test_e_possivel_sobreviver_dez_dias() -> void:
	_h.wall_level = NIVEL_DO_MURO
	_h.tower = true
	_h.high_tower = true
	_h.archers = ARQUEIROS

	var r := Campaign.new().run(_h, DIAS)

	var msg := (
		"dez dias com muro %d, duas torres e %d arqueiros: %s, %d mortes, nucleo a %.2f"
		% [
			NIVEL_DO_MURO,
			ARQUEIROS,
			"aguentou" if r[Campaign.AGUENTOU] else "caiu no dia %d" % r[Campaign.CAIU],
			r[Campaign.MORTES],
			r[Campaign.VIDA],
		]
	)
	assert_bool(r[Campaign.AGUENTOU]).override_failure_message(msg).is_true()
	assert_int(r[Campaign.NOITES]).is_equal(DIAS)


# gdUnit4 le do_skip/skip_reason pela assinatura; o linter nao sabe disso.
# gdlint: disable=unused-argument


func test_o_nucleo_pode_ser_atacado(
	do_skip := true,
	skip_reason := (
		"Q-075: o nucleo nao tem slots de contacto — so o WallData os tem — e "
		+ "uma obra com zero slots nao recebe atacante nenhum. Ver docs/QUESTIONS.md"
	)
) -> void:
	# Sem muro nenhum, uma noite de Brutos tem de conseguir morder o castelo.
	# Medido: chegam a 270 px e o nucleo perde 0%.
	_h.wall_level = 1
	var r := Campaign.new().run(_h, DIA_DOS_BRUTOS)
	assert_float(r[Campaign.VIDA]).is_less(1.0)


func test_nao_e_trivial_sobreviver_dez_dias(
	do_skip := true,
	skip_reason := (
		"Q-075: nenhuma defesa perde, nem seis arqueiros sem torre nem sem muro. "
		+ "Nao ha numero que torne dificil um jogo que nao se pode perder. F1-16"
	)
) -> void:
	# A metade que falta do §66: uma defesa insuficiente tem de cair.
	_h.wall_level = 1
	_h.tower = false
	_h.high_tower = false
	_h.archers = 6
	assert_bool(Campaign.new().run(_h, DIAS)[Campaign.AGUENTOU]).is_false()

# gdlint: enable=unused-argument
