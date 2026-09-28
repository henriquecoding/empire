# tests/pace_test.gd — a roda do rei abranda o tempo (§24, Q-034).
#
# Abranda-se saltando passos, e nao encolhendo o delta: o passo fixo do §19 e a
# semente do §42 ficam intactos, e metade dos frames de fisica corre um passo.
extends GdUnitTestSuite


func after_test() -> void:
	Pace.reset()


func _passos(frames: int) -> int:
	var n := 0
	for _i in frames:
		if Pace.due():
			n += 1
	return n


func test_em_tempo_real_cada_frame_e_um_passo() -> void:
	Pace.reset()
	assert_int(_passos(30)).is_equal(30)


func test_com_a_roda_aberta_corre_metade_dos_passos() -> void:
	Pace.reset()
	Pace.scale = (Registry.entry(&"economy", &"clock") as ClockData).wheel_time_scale
	assert_float(Pace.scale).is_equal(0.5)
	assert_int(_passos(30)).is_equal(15)


func test_largar_a_roda_volta_ao_tempo_real() -> void:
	Pace.reset()
	Pace.scale = 0.5
	_passos(7)
	Pace.scale = 1.0
	assert_int(_passos(10)).is_equal(10)


func test_abrandar_vem_ligado_e_desliga_se_nas_opcoes() -> void:
	# "A roda abranda o tempo a 50%, desligavel" (Q-034).
	var caminho := "user://pace_test_settings.cfg"
	var prefs := Preferences.new(caminho)
	assert_bool(prefs.enabled(Preferences.WHEEL_SLOWDOWN)).is_true()
	assert_bool(prefs.set_enabled(Preferences.WHEEL_SLOWDOWN, false)).is_true()
	assert_bool(Preferences.new(caminho).enabled(Preferences.WHEEL_SLOWDOWN)).is_false()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
