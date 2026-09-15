# tests/dez_dias_test.gd — o criterio de saida da Fase 1 (§66, F1-16).
#
# O §66 escreve-o numa linha: "sobreviver 10 dias e possivel e nao e trivial".
# Sao duas metades, e este ficheiro mede as duas com a mesma defesa de cada lado
# da fronteira:
#
#   · POSSIVEL — a defesa do decimo dia — um Bastiao, a muralha de ferro no
#     outro flanco, as duas torres e doze arqueiros — corre dez noites inteiras
#     e o castelo-arvore fica de pe, inteiro.
#   · NAO TRIVIAL — a receita do §07 — estacaria, seis arqueiros, sem torre —
#     cai ao terceiro dia. E entre uma e outra ha degraus, e todos caem: a
#     tabela inteira esta em `tools/dez_dias.gd`.
#
# Nenhum numero do dossie foi mexido por este ficheiro. O unico que a Fase 1
# escreveu de novo e o `contact_slots` do nucleo — a coluna que o `walls.csv`
# sempre teve e o `buildings.csv` nao tinha (Q-075) —, e a varredura mostra que
# o criterio do §66 se le igual com ela entre 2 e 7: nao e ela que decide.
extends GdUnitTestSuite

const Harness := preload("res://tests/sim_harness.gd")
const Campaign := preload("res://tests/support/campaign.gd")

const DIAS := 10
## A defesa do decimo dia. Um Bastiao e nao dois: o §10 escreve-o "unico por
## imperio", e o outro flanco leva a muralha de ferro. As duas torres, que o §10
## vende em separado, e doze arqueiros — os postos dos dois flancos sao treze.
const BASTIAO_E_FERRO := [5, 4]
const ARQUEIROS := 12
## A receita do §07, tal e qual: "um muro, seis arqueiros". Sem torre nenhuma.
const ESTACARIA := [1, 1]
const RECEITA_DO_07 := 6
## Duas noites chegam para a pergunta "chega-lhe alguma coisa?": com a estacaria
## do §10 o muro cai na primeira, e a partir dai o nucleo esta a descoberto.
const DUAS_NOITES := 2

var _h: Harness


func before_test() -> void:
	_h = Harness.new()
	# A tabela inteira, e nao so Rastejantes: o crawlers_only e o microteste de
	# combate do §07, e o §66 mede o jogo.
	_h.crawlers_only = false


func after_test() -> void:
	_h.stop()


func test_e_possivel_sobreviver_dez_dias() -> void:
	_h.wall_levels = PackedInt32Array(BASTIAO_E_FERRO)
	_h.tower = true
	_h.high_tower = true
	_h.archers = ARQUEIROS

	var r := Campaign.new().run(_h, DIAS)

	assert_bool(r[Campaign.AGUENTOU]).override_failure_message(_conta(r)).is_true()
	assert_int(r[Campaign.NOITES]).is_equal(DIAS)
	# De pe E inteiro. Aguentar a 5% e aguentar, mas e a resposta de quem nao
	# tem decimo primeiro dia — e o §66 nao acaba a Fase 1 no fio da navalha.
	assert_float(r[Campaign.VIDA]).is_equal_approx(1.0, 0.01)


func test_nao_e_trivial_sobreviver_dez_dias() -> void:
	_h.wall_levels = PackedInt32Array(ESTACARIA)
	_h.tower = false
	_h.high_tower = false
	_h.archers = RECEITA_DO_07

	var r := Campaign.new().run(_h, DIAS)

	assert_bool(r[Campaign.AGUENTOU]).override_failure_message(_conta(r)).is_false()
	assert_int(r[Campaign.CAIU]).is_between(1, DIAS)


## §07, em maiusculas: "a torre nao da dano — da certeza". O F1-07 mediu-o numa
## noite; aqui mede-se na partida, com a MESMA muralha dos dois lados: tirar as
## torres a defesa que aguenta dez dias e o que a faz cair.
func test_sem_torres_a_mesma_muralha_cai() -> void:
	_h.wall_levels = PackedInt32Array(BASTIAO_E_FERRO)
	_h.tower = false
	_h.high_tower = false
	_h.archers = ARQUEIROS

	var r := Campaign.new().run(_h, DIAS)

	assert_bool(r[Campaign.AGUENTOU]).override_failure_message(_conta(r)).is_false()


## Q-075, o defeito que bloqueava este ticket: so o muro tinha slots de contacto,
## e uma obra com zero slots nao recebe atacante nenhum. Sem esta linha o jogo
## nao se podia perder, e nao ha numero em data/ que torne dificil um jogo que
## nao se pode perder.
func test_o_nucleo_pode_ser_atacado() -> void:
	_h.wall_levels = PackedInt32Array(ESTACARIA)
	_h.tower = false
	_h.high_tower = false
	_h.archers = RECEITA_DO_07

	var r := Campaign.new().run(_h, DUAS_NOITES)

	assert_float(r[Campaign.VIDA]).override_failure_message(_conta(r)).is_less(1.0)


func _conta(r: Dictionary) -> String:
	return (
		"muros %s, torres %s/%s, %d arqueiros: %s, %d mortes, nucleo a %.2f"
		% [
			_h.wall_levels,
			_h.tower,
			_h.high_tower,
			_h.archers,
			"aguentou" if r[Campaign.AGUENTOU] else "caiu no dia %d" % r[Campaign.CAIU],
			r[Campaign.MORTES],
			r[Campaign.VIDA],
		]
	)
