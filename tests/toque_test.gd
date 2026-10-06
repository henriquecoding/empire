# tests/toque_test.gd — a disposicao dos controlos por toque e a alavanca (ADR 0047, UX-02).
#
# Os eventos constroem-se e nao se injectam (ADR 0009): o que se mede e a geometria
# e a leitura que a camada de toque faz de um dedo, sem arvore nem ecra.
extends GdUnitTestSuite

const BASE := Vector2(1280.0, 720.0)
const ESCALAS := [0.8, 1.0, 1.4]
## Os botoes de jogo do arco do polegar direito.
const BOTOES := [
	TouchLayout.Role.DROP,
	TouchLayout.Role.ATTACK,
	TouchLayout.Role.ASSUME,
	TouchLayout.Role.SKILL,
	TouchLayout.Role.WHEEL,
]
## Folga minima entre dois botoes desenhados: um polegar nao carrega em dois.
const ENTRE := 12.0
## O raio de toque minimo a 1280x720 com o tamanho por omissao (UX-02).
const ALVO_MIN := 40.0


func _layout(escala: float = 1.0, canhoto: bool = false) -> TouchLayout:
	var l := TouchLayout.new()
	l.scale = escala
	l.left_handed = canhoto
	l.screen = BASE
	return l


func test_cada_accao_do_mapa_do_24_tem_um_gesto() -> void:
	for accao: StringName in [&"move_left", &"move_right", &"king_run", &"pause"]:
		assert_bool(InputMap.has_action(accao)).is_true()
	var tocadas := TouchPad.ACCOES.values()
	for accao: StringName in [
		&"verb_drop", &"verb_assume", &"attack", &"mark_target", &"king_wheel"
	]:
		assert_bool(tocadas.has(accao)).override_failure_message(String(accao)).is_true()
		assert_bool(InputMap.has_action(accao)).override_failure_message(String(accao)).is_true()


func test_os_botoes_cabem_no_ecra_e_nao_se_tocam() -> void:
	for escala: float in ESCALAS:
		for canhoto: bool in [false, true]:
			var l := _layout(escala, canhoto)
			for a: int in BOTOES:
				var c := l.centre(a)
				var r := l.radius(a)
				var msg := "botao %d a %.1f" % [a, escala]
				(
					assert_bool(Rect2(Vector2.ZERO, BASE).grow(-r).has_point(c))
					. override_failure_message(msg)
					. is_true()
				)
				for b: int in BOTOES:
					if b <= a:
						continue
					var folga := c.distance_to(l.centre(b)) - r - l.radius(b)
					msg = "botoes %d e %d a %.1f: %.1f px" % [a, b, escala, folga]
					assert_float(folga).override_failure_message(msg).is_greater_equal(ENTRE)


func test_nenhum_alvo_e_pequeno_demais_para_um_dedo() -> void:
	var l := _layout()
	for a: int in BOTOES + [TouchLayout.Role.PAUSE]:
		assert_float(l.reach(a)).override_failure_message(str(a)).is_greater_equal(ALVO_MIN)
	assert_float(l.stick_radius()).is_greater_equal(ALVO_MIN * 2)


## O HUD de cima e o painel de combate (Q-186) sao o ceu do ecra; a pausa fica por baixo
## dos dois, e nenhum botao do polegar sobe ate eles.
func test_nada_fica_por_baixo_do_hud_nem_do_painel_de_combate() -> void:
	var painel := CombatBar.place(BASE, 1.0)
	for escala: float in ESCALAS:
		var l := _layout(escala)
		for a: int in BOTOES:
			var caixa := Rect2(l.centre(a), Vector2.ZERO).grow(l.radius(a))
			assert_bool(caixa.intersects(painel)).override_failure_message(str(a)).is_false()
			assert_float(caixa.position.y).override_failure_message(str(a)).is_greater(
				GameHud.FAIXA_TOPO
			)


func test_o_canhoto_e_o_espelho() -> void:
	var destro := _layout()
	var canhoto := _layout(1.0, true)
	for a: int in BOTOES:
		var d := destro.centre(a)
		var c := canhoto.centre(a)
		assert_float(c.x).is_equal_approx(BASE.x - d.x, 0.01)
		assert_float(c.y).is_equal_approx(d.y, 0.01)
	assert_float(canhoto.stick_home().x).is_equal_approx(BASE.x - destro.stick_home().x, 0.01)
	# A pausa nao muda de lado: a esquerda de cima e o titulo, e a casca web poe la o voltar.
	assert_vector(canhoto.centre(TouchLayout.Role.PAUSE)).is_equal(
		destro.centre(TouchLayout.Role.PAUSE)
	)


func test_cada_sitio_do_ecra_tem_um_papel() -> void:
	var l := _layout()
	for a: int in BOTOES + [TouchLayout.Role.PAUSE]:
		assert_int(l.role_at(l.centre(a))).override_failure_message(str(a)).is_equal(a)
	# Um pouco fora do desenho ainda e o botao: a folga do dedo.
	var moeda := l.centre(TouchLayout.Role.DROP)
	var r := l.radius(TouchLayout.Role.DROP)
	assert_int(l.role_at(moeda + Vector2(r + 4.0, 0.0))).is_equal(TouchLayout.Role.DROP)
	assert_int(l.role_at(l.stick_home())).is_equal(TouchLayout.Role.STICK)
	# O polegar pousado na barra preta da esquerda de um telemovel continua a ser a alavanca.
	assert_int(l.role_at(Vector2(-40.0, 600.0))).is_equal(TouchLayout.Role.STICK)
	# Solta (por omissao), a alavanca e a metade do polegar inteira, por baixo do HUD: o
	# polegar que pousa um pouco mais acima ou mais ao centro anda, e nao espreita.
	assert_int(l.role_at(Vector2(120.0, 160.0))).is_equal(TouchLayout.Role.STICK)
	assert_int(l.role_at(Vector2(600.0, 300.0))).is_equal(TouchLayout.Role.STICK)
	assert_int(l.role_at(Vector2(700.0, 300.0))).is_equal(TouchLayout.Role.WORLD)
	assert_int(l.role_at(Vector2(120.0, 40.0))).is_equal(TouchLayout.Role.WORLD)


func test_o_canhoto_troca_os_lados_da_alavanca() -> void:
	var l := _layout(1.0, true)
	assert_int(l.role_at(Vector2(1180.0, 600.0))).is_equal(TouchLayout.Role.STICK)
	assert_int(l.role_at(l.centre(TouchLayout.Role.DROP))).is_equal(TouchLayout.Role.DROP)
	assert_float(l.centre(TouchLayout.Role.DROP).x).is_less(BASE.x / 2)


func test_o_tamanho_fica_entre_os_limites() -> void:
	var l := _layout(3.0)
	assert_float(l.scale).is_equal(TouchLayout.MAXIMO)
	l.scale = 0.1
	assert_float(l.scale).is_equal(TouchLayout.ESCALA.min)


func test_a_base_da_alavanca_nunca_sai_do_ecra() -> void:
	var l := _layout()
	var r := l.stick_radius()
	for p: Vector2 in [Vector2(-60.0, 700.0), Vector2(5.0, 400.0), Vector2(300.0, 719.0)]:
		var base := l.stick_base(p)
		(
			assert_bool(Rect2(Vector2.ZERO, BASE).grow(-r).has_point(base))
			. override_failure_message(str(p))
			. is_true()
		)


# ─── A alavanca ──────────────────────────────────────────────────────────────


func _alavanca(onde: Vector2 = Vector2(200.0, 600.0)) -> TouchStick:
	var s := TouchStick.new()
	s.begin(onde, onde, 96.0, 1.0)
	return s


func test_o_polegar_pousado_nao_anda() -> void:
	var s := _alavanca()
	assert_float(s.axis()).is_equal(0.0)
	s.move(Vector2(200.0 + TouchStick.MORTA - 1.0, 640.0))
	assert_float(s.axis()).is_equal(0.0)


## O centro e onde o dedo pousou, mesmo quando a base desenhada nao pode estar la: um
## polegar na barra preta da esquerda nao comeca a correr para a esquerda.
func test_o_centro_e_onde_o_dedo_pousou() -> void:
	var s := TouchStick.new()
	s.begin(Vector2(-40.0, 600.0), Vector2(110.0, 600.0), 96.0, 1.0)
	assert_float(s.axis()).is_equal(0.0)
	assert_bool(s.runs()).is_false()
	s.move(Vector2(-10.0, 600.0))
	assert_float(s.axis()).is_equal(1.0)


func test_arrastar_anda_e_ate_ao_fim_corre() -> void:
	var s := _alavanca()
	s.move(Vector2(240.0, 600.0))
	assert_float(s.axis()).is_equal(1.0)
	assert_bool(s.runs()).is_false()
	s.move(Vector2(200.0 + 96.0, 600.0))
	assert_bool(s.runs()).is_true()
	s.move(Vector2(150.0, 600.0))
	assert_float(s.axis()).is_equal(-1.0)


## So o horizontal conta: o mundo e uma linha (§11).
func test_arrastar_na_vertical_nao_anda() -> void:
	var s := _alavanca()
	s.move(Vector2(200.0, 400.0))
	assert_float(s.axis()).is_equal(0.0)


## A base vai atras do dedo: voltar para o outro lado custa so o caminho de volta.
func test_a_base_vai_atras_do_dedo() -> void:
	var s := _alavanca()
	s.move(Vector2(600.0, 600.0))
	assert_bool(s.runs()).is_true()
	s.move(Vector2(600.0 - 96.0 - TouchStick.MORTA - 2.0, 600.0))
	assert_float(s.axis()).is_equal(-1.0)


func test_largar_para() -> void:
	var s := _alavanca()
	s.move(Vector2(300.0, 600.0))
	s.end()
	assert_float(s.axis()).is_equal(0.0)
	assert_bool(s.runs()).is_false()


## UX-06: no telemovel a densidade cresce os botoes ate ao TETO, e o tamanho escolhido
## nas opcoes continua a multiplicar isso — antes ficava tudo preso no maximo.
func test_o_tamanho_das_opcoes_conta_no_telemovel() -> void:
	var raios: Array[float] = []
	for escolhido: float in [TouchLayout.ESCALA.min, 1.0, TouchLayout.ESCALA.max]:
		var l := _layout()
		l.scale = escolhido * minf(2.12, TouchLayout.TETO)
		raios.append(l.radius(TouchLayout.Role.DROP))
	assert_float(raios[0]).is_less(raios[1])
	assert_float(raios[1]).is_less(raios[2])


## UX-06: o x livre entre os controlos nao toca em nenhum botao, no destro e no canhoto.
func test_o_meio_livre_nao_toca_em_nenhum_controlo() -> void:
	for canhoto: bool in [false, true]:
		var l := _layout(1.4, canhoto)
		l.screen = Vector2(1558.0, 720.0)
		var livre := TouchLayout.free_between(l.circles_now(), l.screen.x, l.screen.y)
		assert_float(livre.y).is_greater(livre.x)
		for papel: TouchLayout.Role in [TouchLayout.Role.FIX] + TouchLayout.BOTOES.keys():
			var c := l.centre(papel)
			var r := l.reach(papel)
			# O Vector2 guarda em 32 bits: um centesimo de px de folga na comparacao.
			assert_bool(c.x + r <= livre.x + 0.01 or c.x - r >= livre.y - 0.01).is_true()
