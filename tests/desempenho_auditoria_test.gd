# tests/desempenho_auditoria_test.gd — a auditoria de desempenho de 08/10/2026.
#
# Medido com o perfilador do motor numa partida pilotada: o tick perguntava a escada e a
# muralha a todas as obras antes de ver se havia moeda em cima, o desenho das obras fazia
# a mesma conta para as que estavam fora do ecra, e os 801 bichos de cenario eram
# percorridos duas vezes por frame para mexer em 150 e desenhar 25. Aqui prova-se, como
# no desempenho_test.gd, que cada atalho da a mesma resposta que o caminho comprido.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


## Os trocos da FaunaGrid dao os mesmos bichos, pela mesma ordem, que percorrer a regiao
## inteira — com os bichos a fugir do rei, a andar e a mudar de troco pelo caminho.
func test_os_trocos_dos_bichos_dao_os_mesmos_que_a_regiao_inteira() -> void:
	RngService.configure(20260916)
	var tipos := [Wilds.Animal.SONGBIRD, Wilds.Animal.CROW, Wilds.Animal.BUTTERFLY]
	var lista := PackedFloat32Array()
	for i in 240:
		lista.append_array([tipos[i % 3], float(i) * 37.0 - 2000.0, float(i % 7) / 7.0])
	for i in 12:
		lista.append_array([Wilds.Animal.BIRD, 300.0 + float(i) * 9.0, 0.5])
	var f := Fauna.new()
	f.populate(lista, 3840.0, Vector2(-2000.0, 7000.0))
	for passo in 600:
		var de := -1500.0 + float(passo) * 9.0
		f.vista = Rect2(de, 0.0, 2560.0, 720.0)
		f.tick(PASSO, de + 1280.0, true)
		if passo % 50 != 0:
			continue
		for janela: Vector2 in [Vector2(de, de + 2560.0), Vector2(de + 640.0, de + 1920.0)]:
			assert_array(f.grade.seen(f.bichos, janela.x, janela.y)).is_equal(
				_a_eito(f, janela.x, janela.y, true)
			)
			assert_array(f.grade.between(f.bichos, janela.x, janela.y)).is_equal(
				_a_eito(f, janela.x, janela.y, false)
			)
	var tudo := PresentationBounds.TUDO
	assert_array(f.grade.seen(f.bichos, tudo.position.x, tudo.end.x)).is_equal(
		_a_eito(f, tudo.position.x, tudo.end.x, true)
	)
	RngService.configure(20260916)


## O caminho comprido: todos os bichos, um a um.
static func _a_eito(f: Fauna, de: float, ate: float, bando: bool) -> PackedInt32Array:
	var saida := PackedInt32Array()
	for i in f.bichos.size():
		var b := f.bichos[i]
		if (bando or b.flock_index < 0) and b.x >= de and b.x <= ate:
			saida.append(i)
	return saida


## Os controlos de toque so se redesenham quando o plano muda: parado e o mesmo plano, e
## premir um botao, mudar a escala ou abrir a roda muda-o.
func test_o_plano_do_toque_e_o_mesmo_parado_e_muda_ao_premir() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20260930)
	Greybox.build()
	var pad := TouchPad.new()
	pad.layout.screen = Vector2(1280.0, 720.0)
	var antes := TouchView.plan(pad, false, 1.0)
	assert_bool(TouchView.plan(pad, false, 1.0) == antes).is_true()
	assert_bool(TouchView.plan(pad, false, 2.0) == antes).is_false()
	assert_bool(TouchView.plan(pad, true, 1.0) == antes).is_false()
	pad.press(0, pad.layout.centre(TouchLayout.Role.DROP))
	var premido := TouchView.plan(pad, false, 1.0)
	assert_bool(premido == antes).is_false()
	pad.lift(0, pad.layout.centre(TouchLayout.Role.DROP))
	assert_bool(TouchView.plan(pad, false, 1.0) == antes).is_true()
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## O corpo de letra lembrado e o que a conta daria: o mesmo texto no mesmo raio cabe igual.
func test_o_rotulo_lembrado_tem_o_corpo_que_a_conta_daria() -> void:
	for texto: String in ["Run", "Interact", "Impulses", "Vigil"]:
		for raio: float in [30.0, 44.0, 60.0]:
			for pedido: int in [13, 26, 260]:
				var corpo := TouchArt.fit(texto, raio, pedido)
				assert_int(corpo).is_equal(_a_medir(texto, raio, pedido))
				assert_int(TouchArt.fit(texto, raio, pedido)).is_equal(corpo)


## O caminho comprido do rotulo: medir do corpo pedido para baixo ate caber.
static func _a_medir(texto: String, raio: float, corpo: int) -> int:
	var minimo := mini(corpo, maxi(TouchArt.LETRA.min, roundi(raio * TouchArt.LETRA.min_raio)))
	var letra := HudStyle.font()
	while (
		corpo > minimo
		and letra.get_string_size(texto, 0, -1, corpo).x > raio * TouchArt.MEDIDA.texto
	):
		corpo -= 1
	return corpo
