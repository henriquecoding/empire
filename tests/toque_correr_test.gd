# tests/toque_correr_test.gd — o botao CORRER do toque (ADR 0047, adenda de 02/10).
#
# O dono, a 02/10/2026: "No mobile deve ter um botao para correr tambem". Arrastar a
# alavanca ate ao fim continua a correr; o CORRER e um interruptor do lado dos botoes,
# para o polegar que nao anda: tocado uma vez, quem anda corre ate se tocar outra vez.
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


func test_tocar_liga_e_tocar_outra_vez_desliga() -> void:
	var p := _pad()
	var correr := p.layout.centre(R.RUN)
	assert_bool(p.running).is_false()
	_tocar(p, 3, correr)
	assert_bool(p.running).is_true()
	_tocar(p, 3, correr)
	assert_bool(p.running).is_false()


## Ligado, andar um pouco ja corre: o polegar da alavanca nao precisa de ir ao fim.
func test_ligado_andar_corre() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	p.press(0, casa)
	p.drag(0, casa + Vector2(30.0, 0.0), Vector2(30.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_true()
	assert_bool(p.wanted()[&"king_run"]).is_false()
	_tocar(p, 1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_true()
	assert_bool(p.runs()).is_true()


## Parado nao se corre: o interruptor diz como se anda, e nao que se anda.
func test_parado_nao_corre() -> void:
	var p := _pad()
	_tocar(p, 1, p.layout.centre(R.RUN))
	assert_bool(p.wanted()[&"king_run"]).is_false()
	assert_bool(p.wanted()[&"move_left"]).is_false()
	assert_bool(p.wanted()[&"move_right"]).is_false()


## Arrastar ate ao fim continua a correr, sem o botao (o "drag all the way" do Kingdom).
func test_sem_o_botao_ate_ao_fim_continua_a_correr() -> void:
	var p := _pad()
	var casa := p.layout.stick_home()
	p.press(0, casa)
	p.drag(0, casa + Vector2(200.0, 0.0), Vector2(200.0, 0.0))
	assert_bool(p.running).is_false()
	assert_bool(p.wanted()[&"king_run"]).is_true()


## Um dedo que escorrega para fora antes de levantar nao troca nada, como no FIXAR.
func test_escorregar_para_fora_nao_troca() -> void:
	var p := _pad()
	var correr := p.layout.centre(R.RUN)
	p.press(2, correr)
	p.drag(2, correr - Vector2(0.0, 200.0), Vector2(0.0, -200.0))
	p.lift(2, correr - Vector2(0.0, 200.0))
	assert_bool(p.running).is_false()


## A pausa, um menu ou outra mao largam tudo: o interruptor tambem.
func test_reset_desliga() -> void:
	var p := _pad()
	_tocar(p, 1, p.layout.centre(R.RUN))
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
