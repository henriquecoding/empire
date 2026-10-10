extends GdUnitTestSuite


func test_ponto_guardado_identifica_dia_e_ignora_outra_partida() -> void:
	var saves: Array[Dictionary] = [
		{&"exists": false},
		{&"exists": true, &"seed": 42, &"day": 3},
		{&"exists": true, &"seed": 42, &"day": 5},
		{&"exists": true, &"seed": 99, &"day": 50},
	]
	assert_int(PauseSession.checkpoint_day(saves, 42)).is_equal(5)
	assert_int(PauseSession.checkpoint_day(saves, 0)).is_zero()


func test_escala_de_texto_e_paineis_persiste() -> void:
	var path := "user://audit_text_scale.dat"
	var prefs := Preferences.new(path)
	assert_bool(prefs.set_number(Preferences.TEXT_SCALE, 1.5)).is_true()
	var copy := Preferences.new(path)
	assert_float(copy.number(Preferences.TEXT_SCALE)).is_equal(1.5)
	DirAccess.remove_absolute(path)
