# tests/smoothing_test.gd — o render interpola; a simulacao nao (§40, I5; GB-10).
#
# A simulacao anda a 30 Hz e o ecra a 60 ou mais. Sem isto cada posicao ficava
# dois frames parada e saltava de uma vez: o rei a 80 px/s avancava 2,7 px aos
# solavancos, e a camara, que o segue, levava os solavancos com ela.
extends GdUnitTestSuite

const U := Smoothing.Group.UNITS
const C := Smoothing.Group.COINS


func before_test() -> void:
	Smoothing.reset()


func _gravar(grupo: int, ids: Array, xs: Array, alturas: Array = []) -> void:
	(
		Smoothing
		. record(
			grupo,
			PackedInt32Array(ids),
			PackedFloat32Array(xs),
			PackedFloat32Array(alturas),
		)
	)


## Um corpo que nasceu neste tick nao tem de onde vir: desenha-se onde esta.
func test_quem_nunca_foi_gravado_fica_onde_esta() -> void:
	assert_vector(Smoothing.blend(U, 7, Vector2(100.0, 0.0), 0.5)).is_equal(Vector2(100.0, 0.0))


func test_entre_dois_ticks_o_corpo_esta_entre_duas_posicoes() -> void:
	_gravar(U, [7], [100.0])
	_gravar(U, [7], [102.0])
	var agora := Vector2(102.0, 0.0)
	assert_float(Smoothing.blend(U, 7, agora, 0.0).x).is_equal_approx(100.0, 0.001)
	assert_float(Smoothing.blend(U, 7, agora, 0.5).x).is_equal_approx(101.0, 0.001)
	assert_float(Smoothing.blend(U, 7, agora, 1.0).x).is_equal_approx(102.0, 0.001)


## A altura da moeda interpola com o x: o arco e a animacao mais importante do
## jogo (§24), e a 30 Hz era um arco de doze pontos.
func test_a_moeda_interpola_a_altura_tambem() -> void:
	_gravar(C, [3], [50.0], [10.0])
	_gravar(C, [3], [51.0], [14.0])
	var meio := Smoothing.blend(C, 3, Vector2(51.0, 14.0), 0.5)
	assert_float(meio.y).is_equal_approx(12.0, 0.001)


## Um corpo posto noutro sitio — um save, a captura com --rei — nao andou: um
## rasto de meio ecra durante um tick era um corpo que nunca existiu.
func test_um_salto_nao_se_interpola() -> void:
	_gravar(U, [7], [100.0])
	_gravar(U, [7], [100.0 + Smoothing.SALTO_PX * 2])
	var agora := Vector2(100.0 + Smoothing.SALTO_PX * 2, 0.0)
	assert_vector(Smoothing.blend(U, 7, agora, 0.25)).is_equal(agora)


## Os tres grupos nao se misturam: uma moeda e uma tropa podem ter ids que um
## dia se cruzam, e o ImpactView ja aprendeu isso com as obras.
func test_os_grupos_nao_se_misturam() -> void:
	_gravar(U, [5], [10.0])
	_gravar(U, [5], [12.0])
	assert_vector(Smoothing.blend(C, 5, Vector2(90.0, 0.0), 0.5)).is_equal(Vector2(90.0, 0.0))


## Quem morreu e foi retirado deixa de ter passado: um id que volta (nao volta,
## o §45 nao os reutiliza, mas a regra e barata) comeca do sitio onde esta.
func test_quem_saiu_da_gravacao_esquece_o_passado() -> void:
	_gravar(U, [7], [100.0])
	_gravar(U, [], [])
	_gravar(U, [7], [140.0])
	assert_vector(Smoothing.blend(U, 7, Vector2(140.0, 0.0), 0.5)).is_equal(Vector2(140.0, 0.0))


## Com o jogo em pausa o SimLoop nao anda e a gravacao continua: o que era agora
## passa a antes, e o corpo fica quieto em vez de oscilar entre dois ticks velhos.
func test_em_pausa_o_corpo_fica_quieto() -> void:
	_gravar(U, [7], [100.0])
	_gravar(U, [7], [102.0])
	_gravar(U, [7], [102.0])
	assert_vector(Smoothing.blend(U, 7, Vector2(102.0, 0.0), 0.3)).is_equal(Vector2(102.0, 0.0))


func test_o_salto_e_maior_do_que_o_passo_mais_rapido_de_um_tick() -> void:
	var rapido := 0.0
	for dados in SimFactory.by_id(&"units").values():
		rapido = maxf(rapido, (dados as UnitData).move_speed)
	for dados in SimFactory.by_id(&"creatures").values():
		rapido = maxf(rapido, (dados as CreatureData).move_speed)
	var por_tick := rapido / Engine.physics_ticks_per_second
	var msg := "o mais rapido anda %.1f px por tick" % por_tick
	assert_float(Smoothing.SALTO_PX).override_failure_message(msg).is_greater(por_tick)
