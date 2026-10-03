# tests/folego_test.gd — o folego de quem corre (Q-193).
#
# O dono, a 03/10/2026: "assim como Kingdom tem um limite, depois de certo periodo fica
# cansado e tem que andar normalmente ate se recuperar, o imperador evoluido tem a
# resistencia maior tambem".
extends GdUnitTestSuite

const DT := 1.0 / 30.0


func _correr(f: Stamina, segundos: float, cap: float, refill: float, quer := true) -> int:
	var corridos := 0
	for _k in int(round(segundos / DT)):
		if f.step(quer, DT, cap, refill):
			corridos += 1
	return corridos


func test_os_numeros_estao_nos_dados() -> void:
	var c := SimFactory.curve()
	assert_float(c.king_run_stamina_s).is_greater(0.0)
	assert_float(c.king_run_refill_s).is_greater(0.0)
	assert_float(c.king_run_evolved_mult).is_greater(1.0)


func test_corre_ate_ao_limite_e_cansa() -> void:
	var f := Stamina.new()
	var corridos := _correr(f, 10.0, 6.0, 8.0)
	assert_int(corridos).is_between(int(round(6.0 / DT)) - 1, int(round(6.0 / DT)) + 1)
	assert_bool(f.tired).is_true()
	assert_bool(f.step(true, DT, 6.0, 8.0)).is_false()


func test_cansado_anda_ate_recuperar_tudo() -> void:
	var f := Stamina.new()
	_correr(f, 7.0, 6.0, 8.0)
	assert_bool(f.tired).is_true()
	_correr(f, 4.0, 6.0, 8.0, false)
	assert_bool(f.tired).is_true()
	assert_bool(f.step(true, DT, 6.0, 8.0)).is_false()
	_correr(f, 4.1, 6.0, 8.0, false)
	assert_bool(f.tired).is_false()
	assert_bool(f.step(true, DT, 6.0, 8.0)).is_true()


## Parar a meio recupera, e o folego que sobra continua a contar.
func test_parar_a_meio_recupera() -> void:
	var f := Stamina.new()
	_correr(f, 3.0, 6.0, 6.0)
	assert_float(f.ratio(6.0)).is_equal_approx(0.5, 0.02)
	_correr(f, 1.5, 6.0, 6.0, false)
	assert_float(f.ratio(6.0)).is_equal_approx(0.75, 0.02)
	assert_bool(f.tired).is_false()


## Quem evoluiu corre mais tempo: o limite multiplica-se.
func test_evoluido_tem_mais_folego() -> void:
	var c := SimFactory.curve()
	var normal := _correr(Stamina.new(), 60.0, c.king_run_stamina_s, c.king_run_refill_s)
	var forte := c.king_run_stamina_s * c.king_run_evolved_mult
	var evoluido := _correr(Stamina.new(), 60.0, forte, c.king_run_refill_s)
	assert_int(evoluido).is_greater(normal)


## Sem limite nos dados, corre-se como antes.
func test_sem_limite_corre_sempre() -> void:
	var f := Stamina.new()
	assert_int(_correr(f, 30.0, 0.0, 0.0)).is_equal(int(round(30.0 / DT)))
