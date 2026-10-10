extends GdUnitTestSuite


func test_fechar_e_reabrir_a_mina_preserva_a_obra_e_trava_producao() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261007)
	Greybox.build()
	var mines: Array[BuildSlot] = []
	for slot in SimLoop.builds.slots:
		if slot.kind == &"ore_pit":
			slot.raise_to(1)
			mines.append(slot)
		if slot.kind == Passages.ESCORA:
			slot.raise_to(1)
	TerritoryWatch.apply()
	for mine in mines:
		assert_str(String(mine.terrain_bar)).is_equal("TERRAIN_ACCESS_BLOCKED")
		assert_int(mine.level).is_equal(1)
	var events := SimLoop.economy.on_phase(SimLoop.builds, GameClock.Phase.MORNING, [])
	for event in events:
		assert_bool(mines.has(event.get(EconomySystem.VAGA))).is_false()
	for slot in SimLoop.builds.slots:
		if slot.kind == Passages.ESCORA:
			slot.level = 0
			slot.state = BuildSlot.State.EMPTY
	TerritoryWatch.apply()
	for mine in mines:
		assert_str(String(mine.terrain_bar)).is_empty()
	SimLoop.stop()
	SimLoop.autosave_enabled = true
