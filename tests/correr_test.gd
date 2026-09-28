# tests/correr_test.gd — o rei corre com o Shift esquerdo (Q-149).
#
# O passo de quem e conduzido multiplica-se pelo king_run_mult do economy.csv
# enquanto a tecla esta premida. So o rei: quem o segue anda ao passo de sempre.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260928
const PASSOS := 30
const LONGE := 3000.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.units.piloted_pace = 1.0
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _andou(pace: float) -> float:
	var u := SimLoop.units
	var i := u.index_of(SimLoop.king_id)
	var de := u.xs[i]
	u.piloted_pace = pace
	u.set_target_x(SimLoop.king_id, de + LONGE)
	for _k in PASSOS:
		u.tick_movement(STEP, SimLoop.king_id)
	return u.xs[i] - de


func test_a_correr_o_rei_anda_king_run_mult_vezes_mais() -> void:
	var mult := SimFactory.curve().king_run_mult
	assert_float(mult).is_greater(1.0)
	var a_andar := _andou(1.0)
	var a_correr := _andou(mult)
	assert_float(a_correr).is_equal_approx(a_andar * mult, 0.01)


func test_so_o_rei_corre() -> void:
	var u := SimLoop.units
	var vagabundo := Registry.entry(&"units", &"vagrant") as UnitData
	var outro := u.spawn(SimLoop.state, vagabundo, 1, SimLoop.core_x)
	var j := u.index_of(outro)
	var de := u.xs[j]
	u.set_target_x(outro, de + LONGE)
	u.piloted_pace = SimFactory.curve().king_run_mult
	for _k in PASSOS:
		u.tick_movement(STEP, SimLoop.king_id)
	assert_float(u.xs[j] - de).is_equal_approx(u.speeds[j] * STEP * PASSOS, 0.01)


func test_ha_uma_tecla_para_correr() -> void:
	assert_bool(InputMap.has_action(&"king_run")).is_true()
	var tem_shift := false
	for e in InputMap.action_get_events(&"king_run"):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_SHIFT:
			tem_shift = (e as InputEventKey).location == KEY_LOCATION_LEFT
	assert_bool(tem_shift).is_true()
