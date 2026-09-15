# tests/architecture_test.gd — os portoes G1, G3 e G4 (§64), e a tabela canonica da §70.
extends GdUnitTestSuite

const Rules := preload("res://tools/lint_rules.gd")


func test_sim_nao_toca_em_nos() -> void:
	var problems := Rules.check_g1()
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_aleatoriedade_so_pelo_rng_service() -> void:
	var problems := Rules.check_g2()
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_sem_literais_de_balanceamento() -> void:
	var problems := Rules.check_g4()
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_band_vive_na_simulacao() -> void:
	# §70: um tipo que a simulacao le vive na simulacao.
	assert_bool(FileAccess.file_exists("res://src/sim/band.gd")).is_true()
	assert_bool(FileAccess.file_exists("res://src/core/band.gd")).is_false()
	assert_bool(FileAccess.file_exists("res://src/world/band.gd")).is_false()
	assert_int(Band.Kind.AERIAL).is_equal(0)
	assert_int(Band.Kind.SURFACE).is_equal(1)
	assert_int(Band.Kind.UNDERGROUND).is_equal(2)
	assert_int(Band.SOIL_CUT).is_equal(Band.SCREEN_BOTTOM - Band.GROUND_LINE)


func test_nenhum_script_passa_das_250_linhas() -> void:
	# §28 — o gdlint tambem o verifica; aqui cobre tools/, que o gdlint do CI nao le.
	for root in ["res://src", "res://tests", "res://tools"]:
		for f in Rules.gd_files(root):
			var n := FileAccess.get_file_as_string(f).split("\n").size()
			assert_int(n).override_failure_message("%s tem %d linhas" % [f, n]).is_less_equal(251)


# gdlint: disable=unused-argument
func test_eventos_no_catalogo(
	do_skip := true, skip_reason := "G3 entra com o EventBus dos 61 sinais (F0-07)"
) -> void:
	assert_bool(FileAccess.file_exists("res://src/core/event_bus.gd")).is_true()
# gdlint: enable=unused-argument
