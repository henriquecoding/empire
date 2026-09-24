# tests/dawn_sweep_test.gd — o amanhecer varre o mundo (§24; GB-17).
#
# A lista de juice do §24, "que nao e opcional": "Amanhecer — sino + varrimento
# de luz da esquerda para a direita a 900 px/s + as tropas a sairem dos postos
# em cascata". O sino e som e nao ha som (audio/ nao e deste ticket); a cascata e
# simulacao e esta na Q-089. O varrimento e isto.
extends GdUnitTestSuite

const REGIAO := 3840.0


func _varrimento() -> DawnSweep:
	var v: DawnSweep = auto_free(DawnSweep.new())
	add_child(v)
	return v


## O numero e o do dossie, e e o unico que o §24 da a esta linha.
func test_anda_aos_900_px_s_do_24() -> void:
	assert_float(DawnSweep.VELOCIDADE_PX_S).is_equal(900.0)


func test_vai_da_esquerda_para_a_direita() -> void:
	var v := _varrimento()
	v.start(REGIAO)
	var antes := v.front()
	v.advance(0.5)
	assert_float(v.front()).is_equal_approx(antes + DawnSweep.VELOCIDADE_PX_S * 0.5, 0.01)
	assert_float(antes).is_equal(0.0)


## Atravessa a regiao inteira e acaba: nao fica uma faixa de luz presa na borda
## direita ate a alvorada seguinte.
func test_atravessa_a_regiao_e_acaba() -> void:
	var v := _varrimento()
	v.start(REGIAO)
	var passos := 0
	while v.active() and passos < 1000:
		v.advance(1.0 / 60.0)
		passos += 1
	assert_bool(v.active()).is_false()
	var segundos := passos / 60.0
	var esperado := (REGIAO + DawnSweep.LARGURA) / DawnSweep.VELOCIDADE_PX_S
	assert_float(segundos).is_equal_approx(esperado, 0.05)


func test_sem_alvorada_nao_ha_varrimento() -> void:
	var v := _varrimento()
	assert_bool(v.active()).is_false()
	v.advance(1.0)
	assert_float(v.front()).is_equal(0.0)


## A cor e a da alvorada do clock.csv (§80), e nao uma cor nova: o varrimento e
## a luz da fase a chegar, e nao outra luz.
func test_a_cor_e_a_da_alvorada() -> void:
	var v := _varrimento()
	v.start(REGIAO)
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var alvorada := BandLight.ambient(relogio, GameClock.Phase.DAWN, DawnSweep.MEIA)
	assert_float(v.color().h).is_equal_approx(alvorada.h, 0.001)
