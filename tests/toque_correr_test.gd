# tests/toque_correr_test.gd — o botao CORRER do toque (ADR 0047, UX-04, Q-193).
#
# O dono, a 02/10/2026: "No mobile deve ter um botao para correr tambem". E a 03/10/2026,
# no painel (Q-193): "so corre ao manter o botao apertado". O CORRER e o Shift do toque:
# premido, quem anda corre; levantado o dedo, anda. A alavanca ate ao fim ja nao corre.
# Os dedos constroem-se e nao se injectam (ADR 0009).
extends GdUnitTestSuite

const R := TouchLayout.Role
const BASE := Vector2(1280.0, 720.0)
const ESCALAS := [0.8, 1.0, 1.4]
const OUTROS := [R.DROP, R.ATTACK, R.ASSUME, R.SKILL, R.WHEEL, R.PAUSE, R.FIX]
const ENTRE := 12.0


func _pad(canhoto: bool = false) -> TouchPad:
	var p := TouchPad.new()
	p.layout.screen = BASE
	p.layout.left_handed = canhoto
	return p


func _tocar(p: TouchPad, i: int, onde: Vector2) -> void:
	p.press(i, onde)
	p.lift(i, onde)


func test_o_correr_e_um_botao_do_lado_dos_botoes() -> void:
	for canhoto: bool in [false, true]:
		var l := _pad(canhoto).layout
		var c := l.centre(R.RUN)
		assert_int(l.role_at(c)).is_equal(R.RUN)
		assert_bool((c.x > BASE.x / 2) != canhoto).is_true()


func test_corre_so_enquanto_se_prime() -> void:
	var p := _pad()
	var correr := p.layout.centre(R.RUN)
	assert_bool(p.running).is_false()
	p.press(3, correr)
	assert_bool(p.running).is_true()
	p.lift(3, correr)
	assert_bool(p.running).is_false()


## Um toque nao liga nada: nao ha interruptor.
func test_um_toque_nao_fica_ligado() -> void:
	var p := _pad()
	_tocar(p, 3, p.layout.centre(R.RUN))
	assert_bool(p.running).is_false()


## Premido, andar um pouco ja corre: o polegar da alavanca nao precisa de ir ao fim.
func test_premido_andar_corre() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	p.press(0, casa)
	p.drag(0, casa + Vector2(30.0, 0.0), Vector2(30.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_true()
	assert_bool(p.wanted()[&"king_run"]).is_false()
	p.press(1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_true()
	assert_bool(p.runs()).is_true()
	p.lift(1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_false()


## Parado nao se corre: o botao diz como se anda, e nao que se anda.
func test_parado_nao_corre() -> void:
	var p := _pad()
	p.press(1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_false()
	assert_bool(p.wanted()[&"move_left"]).is_false()
	assert_bool(p.wanted()[&"move_right"]).is_false()


## Sem o botao, a alavanca ate ao fim anda e nao corre: o correr e um gesto so (Q-193).
func test_sem_o_botao_ate_ao_fim_nao_corre() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	p.press(0, casa)
	p.drag(0, casa + Vector2(200.0, 0.0), Vector2(200.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_true()
	assert_bool(p.wanted()[&"king_run"]).is_false()


## O dedo que escorrega para fora continua a segurar: largar e levantar.
func test_escorregar_para_fora_continua_a_correr() -> void:
	var p := _pad()
	var correr := p.layout.centre(R.RUN)
	p.press(2, correr)
	p.drag(2, correr - Vector2(0.0, 200.0), Vector2(0.0, -200.0))
	assert_bool(p.running).is_true()
	p.lift(2, correr - Vector2(0.0, 200.0))
	assert_bool(p.running).is_false()


## A pausa, um menu ou outra mao largam tudo: o correr tambem.
func test_reset_larga() -> void:
	var p := _pad()
	p.press(1, p.layout.centre(R.RUN))
	p.reset()
	assert_bool(p.running).is_false()


## O CORRER nao tapa nada: cabe no ecra, por baixo do HUD, longe dos outros botoes e
## fora da alavanca em repouso — em todos os tamanhos e nas duas maos.
func test_o_correr_cabe_e_nao_tapa_nada() -> void:
	var painel := CombatBar.place(BASE, 1.0)
	for escala: float in ESCALAS:
		for canhoto: bool in [false, true]:
			var l := _pad(canhoto).layout
			l.scale = escala
			var c := l.centre(R.RUN)
			var r := l.radius(R.RUN)
			var msg := "CORRER a %.1f, canhoto %s" % [escala, canhoto]
			var caixa := Rect2(c, Vector2.ZERO).grow(r)
			(
				assert_bool(Rect2(Vector2.ZERO, BASE).encloses(caixa))
				. override_failure_message(msg)
				. is_true()
			)
			assert_bool(caixa.intersects(painel)).override_failure_message(msg).is_false()
			assert_float(caixa.position.y).override_failure_message(msg).is_greater(
				GameHud.FAIXA_TOPO
			)
			var ate_alavanca := c.distance_to(l.stick_home()) - r - l.stick_radius()
			assert_float(ate_alavanca).override_failure_message(msg).is_greater(0.0)
			for b: int in OUTROS:
				var folga := c.distance_to(l.centre(b)) - r - l.radius(b)
				assert_float(folga).override_failure_message(msg).is_greater_equal(ENTRE)
			assert_float(l.reach(R.RUN)).is_greater_equal(40.0)
