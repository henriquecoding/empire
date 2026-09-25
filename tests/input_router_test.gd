# tests/input_router_test.gd — largar em continuo (§24, GB-06).
#
# O router nao se testa com teclas: a suite corre em headless e nao injecta
# InputEvents (ADR 0009). O que se testa e o NUMERO que manda no gesto — o ritmo
# do continuo —, e a unica coisa que interessa provar sobre ele: que vem de
# `data/` e nao de um literal no script (AGENTS.md, regra 3), e que esta numa
# gama em que o gesto e um gesto e nao uma torneira.
extends GdUnitTestSuite

## O passo de fisica do §19. A 30 Hz, um intervalo mais curto do que isto punha o
## ritmo do continuo a ser o dos frames e nao o do CSV.
const PASSO := 1.0 / 30.0


func _intervalo() -> float:
	return (Registry.entry(&"economy", &"curve") as EconomyCurve).coin_drop_repeat_s


## A regra 3 do AGENTS.md por escrito: o ritmo esta na `economy.csv` e o script
## nao tem numero nenhum. Zero seria "sem continuo" e chumba aqui.
func test_o_ritmo_do_continuo_vem_de_data() -> void:
	assert_float(_intervalo()).is_greater(0.0)


func test_o_intervalo_e_maior_do_que_um_tick() -> void:
	assert_float(_intervalo()).is_greater(PASSO)


## A tecla premida tem de pagar um Bastiao (§10, o degrau mais caro) sem que o
## jogador ache que o jogo encravou. O numero nao esta escrito aqui: sai do
## walls.csv e do coin_drop_repeat_s.
func test_a_tecla_premida_paga_o_degrau_mais_caro_em_tempo_de_jogo() -> void:
	var caro := 0
	for w in SimFactory.walls_by_level():
		caro = maxi(caro, w.cost)
	var segundos := caro * _intervalo()
	var msg := "o degrau de %d moedas leva %.1f s de tecla premida" % [caro, segundos]
	assert_float(segundos).override_failure_message(msg).is_less(20.0)


## E nao tao depressa que o saco se esvazie antes de a primeira moeda chegar ao
## chao: o arco dura `2v/g` e ver uma moeda a cair e metade do §24.
func test_o_continuo_nao_e_mais_rapido_do_que_o_arco_de_uma_moeda() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var voo := 2.0 * curva.coin_drop_speed_px_s / curva.coin_gravity_px_s2
	var msg := "voo de %.2f s contra um intervalo de %.2f s" % [voo, _intervalo()]
	assert_float(_intervalo()).override_failure_message(msg).is_greater(voo * 0.1)


# ─── O gatilho direito no comando (GB-11) ────────────────────────────────────
#
# Os eventos constroem-se aqui e nao se injectam: nenhum passa pelo Input nem
# pela arvore (ADR 0009). O que se testa e a leitura que o router faz deles.


func _gatilho(valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_TRIGGER_RIGHT
	e.axis_value = valor
	return e


## Um gatilho e analogico: carregar nele emite um evento por cada posicao do
## caminho, e cada um le como "premido". Medido antes disto: um puxao marcava
## seis vezes. Um puxao e UM gesto, e marca uma vez.
func test_um_puxao_do_gatilho_marca_uma_vez() -> void:
	var premido := false
	var marcas := 0
	for valor in [0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 0.8, 0.0, 0.6, 1.0, 0.0]:
		var e := _gatilho(valor)
		if InputRouter.rising(e, premido):
			marcas += 1
		premido = InputRouter.held(e, premido)
	assert_int(marcas).is_equal(2)


## O rato aponta; o comando nao tem cursor. Com o gatilho, o alvo mede-se a
## partir do rei — antes media-se do sitio onde o rato tivesse ficado.
func test_so_o_rato_aponta_com_o_cursor() -> void:
	assert_bool(InputRouter.aims_with_cursor(_clique(true))).is_true()
	assert_bool(InputRouter.aims_with_cursor(_gatilho(1.0))).is_false()


func _clique(premido: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_RIGHT
	e.pressed = premido
	return e


## O clique marca ao premir e nao ao soltar — o soltar tambem e um evento da
## mesma accao, e sem isto cada clique contava duas vezes para o "premido".
func test_o_clique_marca_ao_premir_e_nao_ao_soltar() -> void:
	assert_bool(InputRouter.rising(_clique(true), false)).is_true()
	assert_bool(InputRouter.rising(_clique(false), true)).is_false()
	assert_bool(InputRouter.held(_clique(false), true)).is_false()
