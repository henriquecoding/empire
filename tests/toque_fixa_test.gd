# tests/toque_fixa_test.gd — andar ou espreitar: a alavanca solta e a fixa (UX-03, ADR 0047).
#
# O dono, a 02/10/2026, depois de jogar no telemovel: "a camera esta andando demais so por
# eu mover o personagem, o arrastar a tela esta entrando em conflito com o andar, o
# arrastar a tela no mobile so funciona se a pessoa clicar num botao para fixar o
# analogico de andar". Por omissao a alavanca e solta e arrastar nunca mexe a camara;
# com ela fixa no sitio, o resto do ecra arrasta-se para espreitar.
# Os dedos constroem-se e nao se injectam (ADR 0009).
extends GdUnitTestSuite

const R := TouchLayout.Role
const BASE := Vector2(1280.0, 720.0)
const ESCALAS := [0.8, 1.0, 1.4]
const BOTOES := [R.DROP, R.ATTACK, R.ASSUME, R.SKILL, R.WHEEL, R.PAUSE]


func _pad(fixa: bool = false, canhoto: bool = false) -> TouchPad:
	var p := TouchPad.new()
	p.layout.screen = BASE
	p.layout.fixed = fixa
	p.layout.left_handed = canhoto
	return p


## O polegar que andava e passava para o mundo espreitava em vez de andar: solta, a
## alavanca ocupa a metade dela inteira, e arrastar no mundo nao mexe a camara.
func test_solta_arrastar_nunca_espreita() -> void:
	var p := _pad()
	assert_int(p.press(0, Vector2(560.0, 250.0))).is_equal(R.STICK)
	p.drag(0, Vector2(620.0, 250.0), Vector2(60.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_true()
	assert_float(p.pan).is_equal(0.0)
	p.press_world(1, Vector2(900.0, 300.0))
	p.drag(1, Vector2(700.0, 300.0), Vector2(-200.0, 0.0))
	assert_float(p.pan).is_equal(0.0)
	p.lift(1, Vector2(700.0, 300.0))
	assert_bool(p.let_go).is_false()


## Fixa, a alavanca e o circulo dela e mais nada; o resto do ecra e mundo, e arrasta-se.
func test_fixa_o_resto_do_ecra_espreita() -> void:
	var p := _pad(true)
	var casa := p.layout.stick_home()
	assert_int(p.press(0, casa)).is_equal(R.STICK)
	assert_int(p.press(1, Vector2(560.0, 250.0))).is_equal(R.WORLD)
	p.press_world(1, Vector2(560.0, 250.0))
	p.drag(1, Vector2(500.0, 250.0), Vector2(-60.0, 0.0))
	assert_float(p.pan).is_equal(60.0)
	p.lift(1, Vector2(500.0, 250.0))
	assert_bool(p.let_go).is_true()


## Fixa, o centro e o da base, e nao onde o dedo pousou: pousar ao lado ja anda.
func test_fixa_o_centro_e_o_da_base() -> void:
	var p := _pad(true)
	var casa := p.layout.stick_home()
	p.press(0, casa + Vector2(70.0, 0.0))
	assert_bool(p.wanted()[&"move_right"]).is_true()
	assert_vector(p.stick.base).is_equal(casa)
	p.drag(0, casa + Vector2(400.0, 0.0), Vector2(330.0, 0.0))
	assert_bool(p.wanted()[&"king_run"]).is_true()
	assert_vector(p.stick.base).is_equal(casa)
	p.drag(0, casa - Vector2(40.0, 0.0), Vector2(-440.0, 0.0))
	assert_bool(p.wanted()[&"move_left"]).is_true()


func test_o_botao_fixar_e_um_toque() -> void:
	var p := _pad()
	var fixar := p.layout.centre(R.FIX)
	assert_int(p.press(2, fixar)).is_equal(R.FIX)
	p.lift(2, fixar)
	assert_bool(p.fix_tapped).is_true()
	p.take()
	assert_bool(p.fix_tapped).is_false()
	p.press(2, fixar)
	p.drag(2, fixar + Vector2(200.0, 0.0), Vector2(200.0, 0.0))
	p.lift(2, fixar + Vector2(200.0, 0.0))
	assert_bool(p.fix_tapped).is_false()


## O FIXAR fica por cima da alavanca, do lado dela: nao toca nela, nos botoes nem no HUD.
func test_o_fixar_cabe_e_nao_tapa_nada() -> void:
	for escala: float in ESCALAS:
		for canhoto: bool in [false, true]:
			var l := _pad(false, canhoto).layout
			l.scale = escala
			var c := l.centre(R.FIX)
			var r := l.radius(R.FIX)
			var msg := "FIXAR a %.1f, canhoto %s" % [escala, canhoto]
			assert_float(c.y - r).override_failure_message(msg).is_greater(GameHud.FAIXA_TOPO)
			var ate_alavanca := c.distance_to(l.stick_home()) - r - l.stick_radius()
			assert_float(ate_alavanca).override_failure_message(msg).is_greater(0.0)
			for b: int in BOTOES:
				var folga := c.distance_to(l.centre(b)) - r - l.radius(b)
				assert_float(folga).override_failure_message(msg).is_greater(0.0)
			assert_bool((c.x < BASE.x / 2) != canhoto).override_failure_message(msg).is_true()
			assert_float(l.reach(R.FIX)).is_greater_equal(40.0)


func test_a_preferencia_comeca_solta() -> void:
	assert_bool(Preferences.POR_OMISSAO[Preferences.TOUCH_FIXED]).is_false()


## Fora da Web nao ha ecra inteiro do browser: o botao da pausa nem aparece.
func test_fora_da_web_nao_ha_ecra_inteiro_do_browser() -> void:
	assert_bool(WebScreen.available()).is_false()
	assert_bool(WebScreen.active()).is_false()
	assert_bool(WebScreen.iphone()).is_false()
