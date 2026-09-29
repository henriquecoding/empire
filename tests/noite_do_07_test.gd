# tests/noite_do_07_test.gd — o microteste do §07, corrido pelo instrumento.
#
# O §07 fecha com uma instrucao, e e a unica do dossie escrita como tarefa:
# "monta um cenario fechado ... ajusta ate a noite ser ganha com 1-2 mortes no
# dia 5 e perdida sem torre no dia 8. Este microteste e a fundacao de todo o
# balanceamento posterior."
#
# Este ficheiro tem as duas metades disso, e elas nao se confundem:
#
#   · o que o INSTRUMENTO tem de fazer — montar, correr em headless ao passo
#     fixo, dar o mesmo resultado a mesma semente. E o F1-15, e passa.
#   · o que os NUMEROS tem de dar — as duas linhas do §07. A Q-073 fechou-as
#     pela receita: um posto e um lugar, e para caberem mais arqueiros evolui-se
#     o lugar, por isso a torre entra na receita e o "sem torre no dia 8" passa
#     a variante. Fica saltada so a metade das mortes (Q-151): com a torre e as
#     primeiras noites em rampa, a noite 5 ganha-se sem ninguem morrer.
#
# Mexer em data/ para os calar era o que o AGENTS.md proibe em tantas palavras.
extends GdUnitTestSuite

const Harness := preload("res://tests/sim_harness.gd")

## §07: "a noite ser ganha com 1-2 mortes no dia 5".
const DIA_DO_ALVO := 5
const MORTES_MIN := 1
const MORTES_MAX := 2
## §07: "e perdida sem torre no dia 8".
const DIA_DA_PERDA := 8
## §66: "dez dias em menos de dez segundos".
const DIAS := 10
const ORCAMENTO_S := 10.0

var _h: Harness


func before_test() -> void:
	_h = Harness.new()


func after_test() -> void:
	_h.stop()


# ── O instrumento (F1-15) ────────────────────────────────────────────────────


func test_o_cenario_fecha_se_a_volta_do_que_o_07_nomeia() -> void:
	_h.arm(DIA_DO_ALVO)

	# Um muro, seis arqueiros, e o nucleo que elas vem procurar. Mais nada: o
	# greybox poe dezoito obras e e por isso que ele nao serve para medir.
	assert_int(SimLoop.builds.count()).is_equal(2)
	assert_int(SimLoop.units.count()).is_equal(_h.archers + 1)  # +1: o monarca
	assert_bool(SimLoop.builds.fallen(BuildSlot.NUCLEO)).is_false()


func test_a_mancha_vem_pelo_flanco_onde_esta_o_muro() -> void:
	# O cenario seria uma medicao sem sentido se o muro ficasse do outro lado.
	# E a copia da regra de sorteio do NightWatch que isto protege: envelhecida,
	# da aqui falso na primeira corrida em vez de dar numeros bonitos e falsos.
	var r := _h.night(DIA_DO_ALVO)
	assert_bool(r[Harness.GUARDADO]).is_true()


func test_as_vagas_crescem_com_o_dia() -> void:
	# §07: "vagas de Rastejantes CRESCENTES". Nao e o cenario que as faz crescer
	# — e a massa do §74, que sobe 18 por dia. O cenario so tem de nao estragar.
	var cedo: int = _h.night(1)[Harness.INVOCADAS]
	var tarde: int = _h.night(DIA_DA_PERDA)[Harness.INVOCADAS]
	(
		assert_int(tarde)
		. override_failure_message(
			"noite 1 invocou %d e a noite %d invocou %d" % [cedo, DIA_DA_PERDA, tarde]
		)
		. is_greater(cedo)
	)


func test_a_torre_nao_da_dano_da_certeza() -> void:
	# A frase do §07, medida em vez de citada: a torre nao muda o dano do
	# arqueiro — muda a precisao, de 0,34 para 1,0 — e o que isso vale le-se na
	# mesma noite, com as mesmas vagas e a mesma semente.
	_h.tower = false
	var sem: Dictionary = _h.night(DIA_DO_ALVO)
	_h.tower = true
	var com: Dictionary = _h.night(DIA_DO_ALVO)

	var msg := (
		"noite %d: sem torre %d abates de %d; com torre %d de %d"
		% [
			DIA_DO_ALVO,
			sem[Harness.ABATES],
			sem[Harness.INVOCADAS],
			com[Harness.ABATES],
			com[Harness.INVOCADAS],
		]
	)
	assert_int(com[Harness.INVOCADAS]).is_equal(sem[Harness.INVOCADAS])
	assert_int(com[Harness.ABATES]).override_failure_message(msg).is_greater(sem[Harness.ABATES])


func test_a_mesma_semente_da_a_mesma_noite() -> void:
	# §42: "uma semente reproduz tudo". Sem isto o instrumento nao serve para
	# afinar — duas corridas do mesmo numero davam duas respostas, e nenhuma
	# mudanca em data/ se podia atribuir a mudanca.
	var primeira := _h.night(DIA_DO_ALVO)
	var segunda := _h.night(DIA_DO_ALVO)
	assert_dict(segunda).is_equal(primeira)


func test_dez_dias_correm_em_headless_ao_passo_fixo() -> void:
	# O "Feito" do F1-15. Nao mede o tempo — mede que dez dias inteiros correm
	# sem cena, sem input e sem _physics_process, e que o relogio la chega.
	var segundos := _h.days(DIAS)
	assert_int(ClockService.clock.day).is_equal(DIAS + 1)
	print(
		(
			"§66: %d dias (%d s de jogo) em %.2f s de relogio — orcamento %.0f s"
			% [DIAS, int(_h.day_seconds() * DIAS), segundos, ORCAMENTO_S]
		)
	)


# ── Os numeros (F1-16) ───────────────────────────────────────────────────────
# gdUnit4 le do_skip/skip_reason pela assinatura; o linter nao sabe disso.
# gdlint: disable=unused-argument


func test_a_noite_5_ganha_se_com_a_torre() -> void:
	# Q-073, decidida pelo dono: "se so ha um lugar so deve haver um; para caber
	# mais, evolui-se o lugar". A receita do §07 passa a ter a torre — e com ela
	# os seis arqueiros tem onde estar, e a noite 5 ganha-se: o muro fica de pe.
	_h.tower = true
	var r := _h.night(DIA_DO_ALVO)
	assert_int(r[Harness.MUROS]).is_equal(0)
	assert_bool(r[Harness.DE_PE]).is_true()
	assert_int(r[Harness.MORTES]).is_less_equal(MORTES_MAX)


func test_a_noite_5_custa_1_a_2_mortes(
	do_skip := true,
	skip_reason := (
		"Q-151: com a torre na receita (Q-073) a noite 5 ganha-se sem mortes, e as "
		+ "primeiras noites em rampa (Q-017) tornam-na mais leve. Falta a afinacao"
	)
) -> void:
	_h.tower = true
	assert_int(_h.night(DIA_DO_ALVO)[Harness.MORTES]).is_between(MORTES_MIN, MORTES_MAX)


func test_sem_torre_a_noite_8_perde_o_muro() -> void:
	# A variante do §07 (Q-073): sem a torre, o unico posto da estacaria nao chega
	# para a noite 8, e o muro cai. Uma noite sozinha nao chega ao nucleo; dez
	# seguidas chegam, e e isso que o tests/dez_dias_test.gd mede.
	_h.tower = false
	assert_int(_h.night(DIA_DA_PERDA)[Harness.MUROS]).is_greater(0)


func test_dez_dias_em_menos_de_dez_segundos(
	do_skip := true,
	skip_reason := (
		"Q-074 (decidida: medir antes de otimizar, e primeiro num export de release): "
		+ "o binario de editor da 9 a 11 s e o §66 pede 10. Falta o export de medicao"
	)
) -> void:
	assert_float(_h.days(DIAS)).is_less(ORCAMENTO_S)

# gdlint: enable=unused-argument
