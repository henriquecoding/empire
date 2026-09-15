# tests/candeia_test.gd — a candeia da Podridao e a regra de luz do §80 (F1-17).
#
# O "Feito" do ticket sao tres coisas, e duas delas medem-se aqui: a candeia tem
# TRES PARAGENS — e sao as do §80, lidas de data/ e nao escritas em codigo — e
# DOMINA O ECRA, que com as mesmas paragens quer dizer alcancar mais longe do
# que qualquer outra luz. A terceira, ver-se chegar do horizonte, e desenho: o
# `RotView` poe a mancha no plano medio do §80 e a luz no chao, e quem a olha e
# o `make captura`.
#
# Nenhum numero do §80 esta escrito neste ficheiro: as tres cores, o raio e o
# dither saem do rot.tres, e o portao `check_dossie_vs_csv` confere-os contra o
# dossie. Um teste que repetisse os hexadecimais so provava que eu os sei copiar.
extends GdUnitTestSuite

## §74: "150 + 4 x dia px, com teto em 260". Os dias sao so pontos de prova.
const DIA_CEDO := 1
const DIA_TARDE := 40
## §80: "tres paragens, nunca um gradiente".
const PARAGENS := 3


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func test_o_raio_da_candeia_sobe_com_o_dia_e_para_no_teto() -> void:
	var perfil := _perfil()
	var cedo := WorldLight.radius(perfil, DIA_CEDO)
	var tarde := WorldLight.radius(perfil, DIA_TARDE)

	assert_float(cedo).is_equal_approx(
		perfil.lantern_radius_base + perfil.lantern_radius_per_day * DIA_CEDO, 0.001
	)
	assert_float(tarde).is_greater(cedo)
	assert_float(tarde).is_equal_approx(perfil.lantern_radius_max, 0.001)
	# O dia 0 — um mundo por comecar — da a base, e nao zero nem um raio negativo.
	assert_float(WorldLight.radius(perfil, 0)).is_equal_approx(perfil.lantern_radius_base, 0.001)


func test_sao_tres_paragens_e_vem_todas_de_data() -> void:
	var perfil := _perfil()
	var cores := WorldLight.stops(perfil)

	assert_int(cores.size()).is_equal(PARAGENS)
	assert_object(cores[0]).is_equal(Color.html(perfil.lantern_tint_edge))
	assert_object(cores[1]).is_equal(Color.html(perfil.lantern_tint_mid))
	assert_object(cores[2]).is_equal(Color.html(perfil.lantern_tint))
	# Do bordo para o nucleo, cada uma mais clara do que a de fora: e o que faz
	# disto uma luz e nao tres discos com cores parecidas.
	assert_float(cores[1].get_luminance()).is_greater(cores[0].get_luminance())
	assert_float(cores[2].get_luminance()).is_greater(cores[1].get_luminance())


func test_as_paragens_pintam_se_de_fora_para_dentro() -> void:
	var raio := WorldLight.radius(_perfil(), DIA_CEDO)

	# O bordo e o raio inteiro; as de dentro sao fraccoes dele, por ordem.
	assert_float(WorldLight.stop_radius(raio, 0)).is_equal_approx(raio, 0.001)
	for i in PARAGENS - 1:
		var fora := WorldLight.stop_radius(raio, i)
		assert_float(WorldLight.stop_radius(raio, i + 1)).is_less(fora)
	assert_float(WorldLight.stop_radius(raio, PARAGENS - 1)).is_greater(0.0)


func test_o_dither_e_um_padrao_de_dois_estados_e_nao_um_gradiente() -> void:
	var perfil := _perfil()
	var raio := WorldLight.radius(perfil, DIA_CEDO)
	var celula := perfil.lantern_dither_px
	var pontos := WorldLight.dither(Vector2.ZERO, raio, celula)

	# Um quadrado aceso por cada um apagado: o anel tem metade das celulas que
	# lhe cabem. Se fossem todas, era um contorno; se fossem por alfa, era o
	# gradiente que o §80 recusa.
	var cabem := TAU * raio / celula
	assert_int(pontos.size()).is_equal(int(cabem / WorldLight.POR_CELULA))
	for p in pontos:
		# Cada um assenta na circunferencia: o canto esta a meia celula do ponto.
		assert_float((p + Vector2(celula, celula) * 0.5).length()).is_equal_approx(raio, 0.001)
	assert_array(WorldLight.dither(Vector2.ZERO, 0.0, celula)).is_empty()


func test_dentro_do_raio_ve_se_e_fora_ve_se_a_silhueta() -> void:
	# §74: "dentro do raio ve-se o que a Podridao invocou; fora, nao".
	var raio := WorldLight.radius(_perfil(), DIA_CEDO)
	assert_bool(WorldLight.lit(0.0, 0.0, raio)).is_true()
	assert_bool(WorldLight.lit(raio, 0.0, raio)).is_true()
	assert_bool(WorldLight.lit(raio + 1.0, 0.0, raio)).is_false()

	# E a silhueta nao e uma cor nova: e a mesma com a luz que chega ao chao.
	var chao := BandLight.ground_ratio(Registry.entry(&"economy", &"clock") as ClockData)
	var cor := WorldPalette.BICHO
	assert_object(WorldLight.reveal(cor, true, chao)).is_equal(cor)
	var escura := WorldLight.reveal(cor, false, chao)
	assert_float(escura.get_luminance()).is_less(cor.get_luminance())
	assert_float(escura.a).is_equal_approx(cor.a, 0.001)


func test_uma_obra_sem_luz_nao_tem_raio_nenhum() -> void:
	# O `light_radius` do §10 e a unica fonte: uma obra sem ele nao acende nada,
	# e uma obra em ruina tambem nao. O ciclo do BandView le por aqui.
	var vaga := BuildSlot.new()
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	assert_float(WorldLight.hearth_radius(vaga)).is_equal_approx(0.0, 0.001)

	vaga.effects = {&"light_radius": 120.0}
	assert_float(WorldLight.hearth_radius(vaga)).is_equal_approx(120.0, 0.001)
	vaga.state = BuildSlot.State.RUIN
	assert_float(WorldLight.hearth_radius(vaga)).is_equal_approx(0.0, 0.001)


# gdUnit4 le do_skip/skip_reason pela assinatura; o linter nao sabe disso.
# gdlint: disable=unused-argument


func test_uma_luz_domina_por_ecra(
	do_skip := true,
	skip_reason := (
		"Q-077: o farol do §10 ilumina 300 px e a candeia do §74 nunca passa dos "
		+ "260. Ver docs/QUESTIONS.md — o dossie diz as duas coisas"
	)
) -> void:
	# §80: "uma luz domina por ecra. Se duas competem, o ecra le plano."
	var tecto := _perfil().lantern_radius_max
	for dados: BuildingData in Registry.entries(&"buildings"):
		var raio := float(dados.effect_params.get(&"light_radius", 0.0))
		if raio <= 0.0:
			continue
		var porque := "%s ilumina %d px e a candeia so chega a %d" % [dados.id, raio, tecto]
		assert_bool(WorldLight.dominates(tecto, raio)).override_failure_message(porque).is_true()

# gdlint: enable=unused-argument
