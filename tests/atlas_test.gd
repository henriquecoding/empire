# tests/atlas_test.gd — o Atlas do Imperio le-se (UI-01, ADR 0078).
#
# Nao se congela uma cor: prova-se que os pares que a interface usa se leem — o texto a
# 4,5:1 e um sinal a 3:1 (WCAG 2.2, XAG 102) —, tambem com o fundo meio transparente
# por cima do ceu mais claro, e que cada familia de comandos do toque se distingue das
# outras.
extends GdUnitTestSuite

const TEXTO := 4.5
const SINAL := 3.0


func test_the_contrast_formula_matches_the_reference_pairs() -> void:
	assert_float(Atlas.contrast(Color.WHITE, Color.BLACK)).is_equal_approx(21.0, 0.01)
	assert_float(Atlas.contrast(Color.BLACK, Color.WHITE)).is_equal_approx(21.0, 0.01)
	assert_float(Atlas.contrast(Color.GRAY, Color.GRAY)).is_equal_approx(1.0, 0.001)


func test_text_reads_on_the_field_and_on_the_folio() -> void:
	for tinta: Color in [Atlas.TEXT, Atlas.SECONDARY, Atlas.COIN, Atlas.DANGER]:
		assert_float(Atlas.contrast(tinta, Atlas.FIELD)).is_greater_equal(TEXTO)
		assert_float(Atlas.contrast(tinta, Atlas.RAISED)).is_greater_equal(TEXTO)
	for sinal: Color in [Atlas.VALID, Atlas.INFO]:
		assert_float(Atlas.contrast(sinal, Atlas.FIELD)).is_greater_equal(SINAL)
	assert_float(Atlas.contrast(Atlas.INK, Atlas.FOLIO)).is_greater_equal(TEXTO)
	assert_float(Atlas.contrast(Atlas.INK_SOFT, Atlas.FOLIO)).is_greater_equal(TEXTO)


func test_the_translucent_hud_card_still_reads_over_the_brightest_sky() -> void:
	var fundo := Color.WHITE.blend(HudStyle.BACKGROUND)
	assert_float(Atlas.contrast(HudStyle.TEXT, fundo)).is_greater_equal(TEXTO)
	assert_float(Atlas.contrast(HudStyle.MUTED, fundo)).is_greater_equal(TEXTO)
	assert_float(Atlas.contrast(HudStyle.GOLD, fundo)).is_greater_equal(TEXTO)


func test_the_hud_and_the_pause_share_the_same_tokens() -> void:
	assert_that(HudStyle.TEXT).is_equal(Atlas.TEXT)
	assert_that(PauseTheme.INK).is_equal(Atlas.TEXT)
	assert_that(HudStyle.GOLD).is_equal(Atlas.COIN)
	assert_that(PauseTheme.GOLD).is_equal(Atlas.COIN)
	assert_that(GameHud.GOLD).is_equal(Atlas.COIN)


func test_a_card_has_one_cut_corner_and_keeps_its_content_margin() -> void:
	var cartao := Atlas.card()
	var cortados := 0
	for canto in 4:
		if cartao.get_corner_radius(canto) > 0:
			cortados += 1
	assert_int(cortados).is_equal(1)
	assert_int(cartao.corner_detail).is_equal(1)  # um corte recto, e nao um arco
	assert_float(cartao.get_content_margin(SIDE_LEFT)).is_greater(0.0)


func test_each_command_family_has_its_own_colour_and_combat_its_own_shape() -> void:
	var cores := {}
	for papel: TouchLayout.Role in [
		TouchLayout.Role.DROP, TouchLayout.Role.ASSUME, TouchLayout.Role.ATTACK
	]:
		cores[TouchView.family(papel)] = true
		assert_float(Atlas.contrast(TouchView.family(papel), Atlas.FIELD)).is_greater_equal(SINAL)
	assert_int(cores.size()).is_equal(3)
	assert_bool(TouchView.combat(TouchLayout.Role.ATTACK)).is_true()
	assert_bool(TouchView.combat(TouchLayout.Role.SKILL)).is_true()
	assert_bool(TouchView.combat(TouchLayout.Role.DROP)).is_false()
	assert_bool(TouchView.combat(TouchLayout.Role.ASSUME)).is_false()
	assert_that(TouchView.family(TouchLayout.Role.DROP)).is_equal(Atlas.COIN)
	assert_that(TouchView.family(TouchLayout.Role.ASSUME)).is_equal(Atlas.INFO)
