# tests/volley_test.gd — as flechas que se veem voar (§07, §50).
#
# A flecha e so do ecra: o acerto chega ja decidido (§50) e o voo nao o muda. O
# que se prova e que uma flecha que acertou entrega o golpe quando CHEGA, e nao
# quando sai; que uma falha fica cravada e depois sai; e que o voo tem duracao
# e forma de arco, com os dois pontos nas pontas.
extends GdUnitTestSuite

const DE := Vector2(0.0, 500.0)
const ALVO := Vector2(200.0, 490.0)


func _parado(_id: int) -> Vector2:
	return ALVO


func test_quem_acertou_so_bate_quando_a_flecha_chega() -> void:
	var v := Volley.new()
	v.launch(DE, 42, ALVO, true, 0.0, 0.0)
	var dur := clampf(ALVO.x / Volley.VELOCIDADE, Volley.VOO.x, Volley.VOO.y)
	assert_array(v.step(dur * 0.5, _parado)).is_empty()
	var chegadas := v.step(dur, _parado)
	assert_int(chegadas.size()).is_equal(1)
	assert_int(chegadas[0][Volley.ALVO]).is_equal(42)
	assert_float(chegadas[0][Volley.SENTIDO]).is_equal(1.0)
	assert_int(v.flying()).is_equal(0)
	assert_int(v.stuck()).is_equal(0)


## O acerto ja esta decidido: a flecha segue o alvo ate ele, mesmo que ande.
func test_a_flecha_que_acertou_segue_o_alvo() -> void:
	var v := Volley.new()
	v.launch(DE, 42, ALVO, true, 0.0, 0.0)
	var fugiu := func(_id: int) -> Vector2: return Vector2(-300.0, 490.0)
	var chegadas := v.step(Volley.VOO.y, fugiu)
	assert_float(chegadas[0][Volley.SENTIDO]).is_equal(-1.0)


## O §07 da ao arqueiro em campo 0,34: duas em tres caem no chao, e ficam la um
## bocado — e a falha a ler-se — antes de sair.
func test_a_falha_crava_se_no_chao_e_depois_sai() -> void:
	var v := Volley.new()
	v.launch(DE, 42, Vector2(ALVO.x, DE.y), false, 0.0, 20.0)
	assert_array(v.step(Volley.VOO.y, _parado)).is_empty()
	assert_int(v.stuck()).is_equal(1)
	v.step(Volley.VOO.y + Volley.CRAVADA_S, _parado)
	assert_int(v.stuck()).is_equal(0)


func test_o_chao_nao_guarda_flechas_sem_fim() -> void:
	var v := Volley.new()
	for k in Volley.CRAVADAS_MAX + 10:
		v.launch(DE, k, Vector2(ALVO.x, DE.y), false, 0.0, 20.0)
	v.step(Volley.VOO.y, _parado)
	assert_int(v.stuck()).is_equal(Volley.CRAVADAS_MAX)


## Longe ou perto, o voo cabe entre VOO.x e VOO.y: uma flecha instantanea nao se
## ve, e uma lenta parece outra coisa.
func test_o_voo_tem_duracao_com_chao_e_tecto() -> void:
	var v := Volley.new()
	v.launch(DE, 1, Vector2(5000.0, 500.0), true, 0.0, 0.0)
	v.launch(DE, 2, Vector2(2.0, 500.0), true, 0.0, 0.0)
	assert_int(v.step(Volley.VOO.x * 0.9, _parado).size()).is_equal(0)
	assert_int(v.step(Volley.VOO.y, _parado).size()).is_equal(2)


func test_o_voo_e_um_arco_com_os_pontos_nas_pontas() -> void:
	assert_vector(Volley.point(DE, ALVO, 0.0)).is_equal(DE)
	assert_vector(Volley.point(DE, ALVO, 1.0)).is_equal(ALVO)
	var meio := Volley.point(DE, ALVO, 0.5)
	assert_float(meio.y).is_less(DE.lerp(ALVO, 0.5).y)
	assert_float(Volley.heading(DE, ALVO, 0.0).y).is_less(0.0)
	assert_float(Volley.heading(DE, ALVO, 1.0).y).is_greater(0.0)
