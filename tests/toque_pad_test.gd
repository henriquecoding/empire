# tests/toque_pad_test.gd — os dedos, um a um e varios ao mesmo tempo (ADR 0047, UX-02).
#
# O TouchPad e o que sabe quem e cada dedo: a alavanca, um botao ou o mundo. O que
# devolve sao as accoes do InputMap que o polegar quer premidas — as mesmas que o
# teclado e o comando premem —, e o que o mundo pediu (espreitar, apontar).
# Os dedos constroem-se aqui e nao se injectam (ADR 0009).
extends GdUnitTestSuite

const R := TouchLayout.Role


func _pad(canhoto: bool = false) -> TouchPad:
	var p := TouchPad.new()
	p.layout.screen = Vector2(1280.0, 720.0)
	p.layout.left_handed = canhoto
	return p


func _no(p: TouchPad, papel: int) -> Vector2:
	return p.layout.centre(papel)


func test_sem_dedos_nada_esta_premido() -> void:
	var quer := _pad().wanted()
	for accao: StringName in quer:
		assert_bool(quer[accao]).override_failure_message(String(accao)).is_false()
	for accao: StringName in TouchPad.ACCOES.values() + TouchPad.ANDAR:
		assert_bool(quer.has(accao)).override_failure_message(String(accao)).is_true()


func test_a_alavanca_anda_e_corre() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	assert_int(p.press(0, casa)).is_equal(R.STICK)
	p.drag(0, casa + Vector2(40.0, 0.0), Vector2(40.0, 0.0))
	var quer := p.wanted()
	assert_bool(quer[&"move_right"]).is_true()
	assert_bool(quer[&"move_left"]).is_false()
	assert_bool(quer[&"king_run"]).is_false()
	p.drag(0, casa + Vector2(200.0, 0.0), Vector2(160.0, 0.0))
	assert_bool(p.wanted()[&"king_run"]).is_false()
	p.press(1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_true()
	p.lift(0, casa + Vector2(200.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_false()
	assert_bool(p.wanted()[&"king_run"]).is_false()


func test_manter_a_moeda_e_largar_em_continuo() -> void:
	var p := _pad()
	assert_int(p.press(1, _no(p, R.DROP))).is_equal(R.DROP)
	p.take()
	assert_bool(p.wanted()[&"verb_drop"]).is_true()
	p.lift(1, _no(p, R.DROP))
	assert_bool(p.wanted()[&"verb_drop"]).is_false()


## Um toque mais rapido do que um frame nao se perde: o InputRouter le o verb_drop no
## _process, e um premir-e-largar no mesmo frame nunca la chegava.
func test_um_toque_rapido_fica_premido_um_frame() -> void:
	var p := _pad()
	p.press(1, _no(p, R.DROP))
	p.lift(1, _no(p, R.DROP))
	assert_bool(p.wanted()[&"verb_drop"]).is_true()
	p.take()
	assert_bool(p.wanted()[&"verb_drop"]).is_false()


## O dedo fica com o botao onde pousou ate se levantar: um polegar que escorrega uns
## pixeis no meio de um continuo nao o interrompe.
func test_o_dedo_que_escorrega_continua_no_botao() -> void:
	var p := _pad()
	var moeda := _no(p, R.DROP)
	p.press(1, moeda)
	p.drag(1, moeda + Vector2(-120.0, -80.0), Vector2(-120.0, -80.0))
	p.take()
	assert_bool(p.wanted()[&"verb_drop"]).is_true()


func test_dois_polegares_ao_mesmo_tempo() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	p.press(0, casa)
	p.drag(0, casa - Vector2(50.0, 0.0), Vector2(-50.0, 0.0))
	p.press(1, _no(p, R.ATTACK))
	p.take()
	var quer := p.wanted()
	assert_bool(quer[&"move_left"]).is_true()
	assert_bool(quer[&"attack"]).is_true()
	p.lift(0, casa)
	assert_bool(p.wanted()[&"move_left"]).is_false()
	assert_bool(p.wanted()[&"attack"]).is_true()


func test_cada_botao_preme_a_sua_accao() -> void:
	for papel: int in TouchPad.ACCOES:
		var p := _pad()
		assert_int(p.press(3, _no(p, papel))).is_equal(papel)
		var quer := p.wanted()
		for accao: StringName in TouchPad.ACCOES.values():
			var deve: bool = accao == TouchPad.ACCOES[papel]
			assert_bool(quer[accao]).override_failure_message(String(accao)).is_equal(deve)


## A roda do §24 ao toque: manter, arrastar para o segmento, largar. O vector e o do
## stick — o InputRouter.wheel_segment le-o igual.
func test_a_roda_aponta_com_o_dedo() -> void:
	var p := _pad()
	var roda := _no(p, R.WHEEL)
	p.press(2, roda)
	assert_float(p.aim.length()).is_equal(0.0)
	p.drag(2, roda + Vector2(0.0, -120.0), Vector2(0.0, -120.0))
	assert_int(InputRouter.wheel_segment(p.aim, 6)).is_equal(0)
	p.drag(2, roda + Vector2(120.0, 0.0), Vector2(120.0, -120.0))
	assert_int(InputRouter.wheel_segment(p.aim, 4)).is_equal(1)
	# Perto do centro nao aponta nada: largar ai cancela, como largar o Y.
	p.drag(2, roda + Vector2(8.0, 4.0), Vector2(-112.0, 4.0))
	assert_int(InputRouter.wheel_segment(p.aim, 4)).is_equal(-1)


## Largar a roda nao apaga a mira: o InputRouter usa o segmento apontado no frame em
## que o king_wheel deixa de estar premido, e esse frame vem depois do dedo sair.
func test_a_mira_fica_ate_a_roda_voltar_a_abrir() -> void:
	var p := _pad()
	var roda := _no(p, R.WHEEL)
	p.press(2, roda)
	p.drag(2, roda + Vector2(0.0, -120.0), Vector2(0.0, -120.0))
	p.lift(2, roda + Vector2(0.0, -120.0))
	p.take()
	assert_bool(p.wanted()[&"king_wheel"]).is_false()
	assert_int(InputRouter.wheel_segment(p.aim, 6)).is_equal(0)
	p.press(2, roda)
	assert_float(p.aim.length()).is_equal(0.0)


func test_a_pausa_e_um_toque_e_nao_um_arrastar() -> void:
	var p := _pad()
	var pausa := _no(p, R.PAUSE)
	assert_int(p.press(4, pausa)).is_equal(R.PAUSE)
	p.lift(4, pausa)
	assert_bool(p.pause_tapped).is_true()
	p.take()
	assert_bool(p.pause_tapped).is_false()
	p.press(4, pausa)
	p.drag(4, Vector2(640.0, 400.0), Vector2(-500.0, 200.0))
	p.lift(4, Vector2(640.0, 400.0))
	assert_bool(p.pause_tapped).is_false()


## O mundo nao e reclamado pelo _input: so chega ao TouchPad o que nenhum menu levou
## (o painel de combate e um Control com botoes).
func test_o_mundo_e_o_que_sobra() -> void:
	var p := _pad()
	assert_int(p.press(5, Vector2(640.0, 300.0))).is_equal(R.WORLD)
	assert_bool(p.tracks(5)).is_false()
	p.press_world(5, Vector2(640.0, 300.0))
	assert_bool(p.tracks(5)).is_true()


func test_arrastar_no_mundo_espreita_e_largar_devolve_a_camara() -> void:
	var p := _pad()
	p.layout.fixed = true  # so com a alavanca fixa e que o mundo se arrasta (UX-03)
	p.press_world(5, Vector2(640.0, 300.0))
	p.drag(5, Vector2(600.0, 300.0), Vector2(-40.0, 0.0))
	p.drag(5, Vector2(560.0, 310.0), Vector2(-40.0, 10.0))
	# Agarrar o mundo: o dedo vai para a esquerda, a camara para a direita.
	assert_float(p.pan).is_equal(80.0)
	p.lift(5, Vector2(560.0, 310.0))
	assert_bool(p.let_go).is_true()
	assert_int(p.taps.size()).is_equal(0)
	p.take()
	assert_float(p.pan).is_equal(0.0)
	assert_bool(p.let_go).is_false()


func test_tocar_no_mundo_aponta() -> void:
	var p := _pad()
	p.press_world(5, Vector2(700.0, 450.0))
	p.drag(5, Vector2(705.0, 452.0), Vector2(5.0, 2.0))
	p.lift(5, Vector2(705.0, 452.0))
	assert_int(p.taps.size()).is_equal(1)
	assert_vector(p.taps[0]).is_equal(Vector2(705.0, 452.0))
	assert_bool(p.wanted()[&"mark_target"]).is_false()


## A pausa, a escolha de classe e a viagem largam tudo: nenhum botao fica premido do
## outro lado de um menu.
func test_reset_larga_tudo() -> void:
	var p := _pad()
	p.press(0, p.layout.stick_home())
	p.drag(0, p.layout.stick_home() + Vector2(90.0, 0.0), Vector2(90.0, 0.0))
	p.press(1, _no(p, R.DROP))
	p.reset()
	var quer := p.wanted()
	for accao: StringName in quer:
		assert_bool(quer[accao]).override_failure_message(String(accao)).is_false()
	assert_bool(p.tracks(0)).is_false()


## Um dedo que o motor diz premido duas vezes (perdeu o largar) nao fica preso.
func test_um_dedo_sem_largar_nao_fica_preso() -> void:
	var p := _pad()
	p.press(1, _no(p, R.DROP))
	p.press(1, _no(p, R.ASSUME))
	p.take()
	var quer := p.wanted()
	assert_bool(quer[&"verb_drop"]).is_false()
	assert_bool(quer[&"verb_assume"]).is_true()


func test_o_canhoto_anda_com_a_mao_direita() -> void:
	var p := _pad(true)
	assert_int(p.press(0, Vector2(1100.0, 600.0))).is_equal(R.STICK)
	p.drag(0, Vector2(1050.0, 600.0), Vector2(-50.0, 0.0))
	assert_bool(p.wanted()[&"move_left"]).is_true()
