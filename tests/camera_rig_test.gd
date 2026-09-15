# tests/camera_rig_test.gd — o contrato do F0-08: nao treme, arredonda, respeita.
#
# "Uma camara que treme com movimento subpixel estraga a leitura de toda a arte
# que vier depois" — e por isso o teste do tremor e o mais importante aqui.
extends GdUnitTestSuite

const PASSO := 1.0 / 60.0
const VISTA := 1280.0


func _rig() -> CameraRig:
	var rig: CameraRig = auto_free(CameraRig.new())
	add_child(rig)
	rig.view_width = VISTA
	return rig


func _alvo(x: float) -> Node2D:
	var n: Node2D = auto_free(Node2D.new())
	add_child(n)
	n.global_position = Vector2(x, 0.0)
	return n


## Corre ate a camara assentar, para se medir o estado final e nao o transitorio.
func _assentar(rig: CameraRig, segundos: float = 5.0) -> void:
	for _i in int(segundos / PASSO):
		rig.advance(PASSO)


func test_a_posicao_e_sempre_um_pixel_inteiro() -> void:
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.follow(alvo)

	for i in 400:
		alvo.global_position.x += 0.3  # movimento subpixel, de proposito
		rig.advance(PASSO)
		var x := rig.position.x
		assert_float(x).override_failure_message("frame %d: x = %f" % [i, x]).is_equal(floorf(x))


func test_nao_treme_com_movimento_subpixel() -> void:
	# O defeito que este teste existe para apanhar: a camara a saltar +1/-1
	# entre frames enquanto o alvo anda sempre para a frente. Com o alvo a
	# avancar, a posicao so pode subir ou ficar — nunca recuar.
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.follow(alvo)

	var anterior := rig.position.x
	var recuos := 0
	for _i in 600:
		alvo.global_position.x += 0.3
		rig.advance(PASSO)
		if rig.position.x < anterior:
			recuos += 1
		anterior = rig.position.x

	assert_int(recuos).override_failure_message("a camara recuou %d vezes" % recuos).is_equal(0)


func test_antecipa_na_direcao_do_movimento() -> void:
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.follow(alvo)
	var dados: CameraData = Registry.entry(&"camera", &"default")

	for _i in int(3.0 / PASSO):
		alvo.global_position.x += 2.0
		rig.advance(PASSO)
	var direita := rig.position.x - alvo.global_position.x

	# A camara vai a frente do alvo, e por quase toda a antecipacao pedida.
	var porque := "antecipou so %f px de %f" % [direita, dados.lookahead_px]
	assert_bool(direita > dados.lookahead_px * 0.8).override_failure_message(porque).is_true()


func test_a_antecipacao_troca_de_lado_quando_o_alvo_volta_para_tras() -> void:
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.follow(alvo)

	for _i in int(3.0 / PASSO):
		alvo.global_position.x += 2.0
		rig.advance(PASSO)
	assert_bool(rig.position.x > alvo.global_position.x).is_true()

	for _i in int(3.0 / PASSO):
		alvo.global_position.x -= 2.0
		rig.advance(PASSO)
	assert_bool(rig.position.x < alvo.global_position.x).is_true()


func test_um_alvo_parado_nao_faz_a_camara_oscilar() -> void:
	var rig := _rig()
	var alvo := _alvo(500.0)
	rig.follow(alvo)
	_assentar(rig)

	var pousada := rig.position.x
	for _i in 300:
		rig.advance(PASSO)
		assert_float(rig.position.x).is_equal(pousada)


func test_respeita_os_limites_da_regiao() -> void:
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.set_region(0.0, 4000.0)
	rig.follow(alvo)

	# Contra a borda esquerda: a camara nao mostra nada antes do inicio.
	alvo.global_position.x = -500.0
	_assentar(rig)
	assert_float(rig.position.x).is_equal(floorf(VISTA / 2))

	# E contra a direita.
	alvo.global_position.x = 9000.0
	_assentar(rig)
	assert_float(rig.position.x).is_equal(floorf(4000.0 - VISTA / 2))


func test_uma_regiao_mais_estreita_do_que_o_ecra_fica_centrada() -> void:
	var rig := _rig()
	var alvo := _alvo(0.0)
	rig.set_region(0.0, 600.0)  # menos do que os 1280 da vista
	rig.follow(alvo)

	for x in [-300.0, 0.0, 300.0, 900.0]:
		alvo.global_position.x = x
		_assentar(rig, 1.0)
		# Sem esta regra a camara oscilava entre os dois limites em cada frame.
		assert_float(rig.position.x).is_equal(floorf(600.0 / 2))


func test_a_camara_livre_volta_sozinha_nos_dois_segundos_do_dossie() -> void:
	var rig := _rig()
	var alvo := _alvo(1000.0)
	rig.follow(alvo)
	_assentar(rig)
	var pousada := rig.position.x
	var dados: CameraData = Registry.entry(&"camera", &"default")

	for _i in int(1.0 / PASSO):  # um segundo a empurrar para a direita
		rig.pan(1.0, PASSO)
		rig.advance(PASSO)
	var porque := "a camara livre nao se mexeu"
	assert_bool(rig.position.x > pousada).override_failure_message(porque).is_true()

	# §24: "Reconhecimento; volta sozinha em 2 s".
	for _i in int(dados.free_return_seconds / PASSO) + 1:
		rig.advance(PASSO)
	assert_float(rig.position.x).is_equal(pousada)


func test_nenhum_numero_de_afinacao_esta_no_script() -> void:
	# O G4 ja o verifica em geral; aqui prova-se o caminho: os valores que a
	# camara usa sao os do .tres, e mudar o CSV muda a camara.
	var dados: CameraData = Registry.entry(&"camera", &"default")
	assert_object(dados).is_not_null()
	assert_bool(dados.lookahead_px > 0.0).is_true()
	assert_bool(dados.follow_seconds > 0.0).is_true()
	assert_float(dados.free_return_seconds).is_equal(2.0)
