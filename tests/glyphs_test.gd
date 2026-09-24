# tests/glyphs_test.gd — o rodape diz os botoes da mao que esta a jogar (§26; GB-15).
#
# O §26 poe na lista do Steam Deck Verified: "os glifos no ecra correspondem ao
# dispositivo ativo". O rodape dizia "ESPACO largar · E passagem · TAB estado" a
# quem tinha um comando na mao, e o Steam Deck nao tem Espaco nem Tab.
#
# Os eventos constroem-se e nao se injectam (ADR 0009).
extends GdUnitTestSuite

const K := Glyphs.Device.KEYBOARD
const XBOX := Glyphs.Device.XBOX
const PS := Glyphs.Device.PLAYSTATION


func _eixo(valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = valor
	return e


func test_uma_tecla_ou_um_clique_e_teclado() -> void:
	var tecla := InputEventKey.new()
	tecla.pressed = true
	var clique := InputEventMouseButton.new()
	clique.pressed = true
	assert_int(Glyphs.device_of(tecla, XBOX, "")).is_equal(K)
	assert_int(Glyphs.device_of(clique, PS, "")).is_equal(K)


func test_um_botao_do_comando_e_o_comando_que_o_nome_diz() -> void:
	var botao := InputEventJoypadButton.new()
	botao.pressed = true
	assert_int(Glyphs.device_of(botao, K, "PS5 Controller")).is_equal(PS)
	assert_int(Glyphs.device_of(botao, K, "Xbox Series Controller")).is_equal(XBOX)


## Um stick que deriva uns centesimos nao e alguem a pegar no comando: se fosse,
## o rodape trocava sozinho debaixo das maos de quem esta no teclado.
func test_um_stick_a_derivar_nao_troca_nada() -> void:
	assert_int(Glyphs.device_of(_eixo(0.1), K, "Xbox")).is_equal(K)
	assert_int(Glyphs.device_of(_eixo(0.9), K, "Xbox")).is_equal(XBOX)


## Mexer no rato nao e mudar de mao: quem joga no comando tambem lhe toca.
func test_mexer_o_rato_nao_troca_nada() -> void:
	assert_int(Glyphs.device_of(InputEventMouseMotion.new(), XBOX, "")).is_equal(XBOX)


## O Steam Deck e o resto sao A/B/X/Y como o §24 escreve primeiro; so o que se
## diz PlayStation leva cruz, quadrado e triangulo.
func test_o_nome_do_comando_decide_os_botoes() -> void:
	for nome in ["PS4 Controller", "DualSense Wireless Controller", "Sony DualShock 3"]:
		assert_int(Glyphs.pad_of(nome)).override_failure_message(nome).is_equal(PS)
	for nome in ["Steam Deck", "Steam Virtual Gamepad", "Xbox One Controller", ""]:
		assert_int(Glyphs.pad_of(nome)).override_failure_message(nome).is_equal(XBOX)


## Os botoes do mapa do §24, pelo dispositivo: A/✕ larga, X/▢ entra na passagem,
## Y/△ abre a roda, o gatilho direito marca.
func test_o_rodape_diz_os_botoes_do_mapa_do_24() -> void:
	var teclado := Glyphs.hint(K)
	var xbox := Glyphs.hint(XBOX)
	var ps := Glyphs.hint(PS)
	assert_str(teclado).contains(tr(&"KEY_SPACE")).contains("TAB").contains("ESC")
	assert_str(xbox).contains("RT").contains("START").not_contains(tr(&"KEY_SPACE"))
	assert_str(ps).contains(tr(&"PAD_CROSS")).contains(tr(&"PAD_TRIANGLE")).contains("R2")
	for dica in [teclado, xbox, ps]:
		for chave in Glyphs.ACCOES:
			assert_str(dica).contains(tr(chave))


func test_cada_dispositivo_tem_um_botao_por_accao() -> void:
	for dispositivo in [K, XBOX, PS]:
		assert_int(Glyphs.BOTOES[dispositivo].size()).is_equal(Glyphs.ACCOES.size())
