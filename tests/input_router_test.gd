# tests/input_router_test.gd — largar em continuo (§24, GB-06).
#
# O router nao se testa com teclas: a suite corre em headless e nao injecta
# InputEvents (ADR 0009). O que se testa e a conta que ele faz — quantas moedas
# cabem no tempo que a tecla ja esta premida — e o caso que a pode partir: um
# intervalo de zero, que num ciclo `while` era o jogo a bloquear para sempre.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


func _intervalo() -> float:
	return (Registry.entry(&"economy", &"curve") as EconomyCurve).coin_drop_repeat_s


func test_antes_do_intervalo_nao_sai_moeda_nenhuma() -> void:
	assert_int(InputRouter.repeats(_intervalo() * 0.99, _intervalo())).is_equal(0)


func test_ao_intervalo_sai_uma() -> void:
	assert_int(InputRouter.repeats(_intervalo(), _intervalo())).is_equal(1)


## Uma travagem de frame nao perde moedas: o tempo acumulado desconta-se, nao se
## deita fora. Tres intervalos num passo so dao tres.
func test_um_passo_longo_nao_perde_as_moedas_que_la_cabem() -> void:
	assert_int(InputRouter.repeats(_intervalo() * 3.0, _intervalo())).is_equal(3)


## Intervalo a zero e "sem continuo". Sem esta guarda, um `while` a dividir por
## zero era o jogo parado, e um `for` era um ciclo de mil milhoes de moedas.
func test_sem_intervalo_nao_ha_continuo() -> void:
	assert_int(InputRouter.repeats(10.0, 0.0)).is_equal(0)
	assert_int(InputRouter.repeats(10.0, -1.0)).is_equal(0)


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


## E o passo de fisica tem de caber no intervalo: com um intervalo menor do que
## um tick, o ritmo passava a ser o dos frames e nao o do CSV.
func test_o_intervalo_e_maior_do_que_um_tick() -> void:
	assert_float(_intervalo()).is_greater(PASSO)
