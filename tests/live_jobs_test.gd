extends GdUnitTestSuite


func test_paid_site_sends_a_worker_without_waiting_for_the_next_phase() -> void:
	var state := GameState.new()
	var units := UnitSystem.new()
	var data := Registry.entry(&"units", &"vagrant") as UnitData
	var worker := units.spawn(state, data, 1, 0.0)
	var builds := BuildSystem.new()
	var site := builds.post(WallSite.slot(300.0))
	site.state = BuildSlot.State.SCAFFOLD
	var jobs := SimFactory.job_board()
	jobs.publish(builds)
	jobs.assign(units, GameClock.Phase.MORNING)
	assert_int(units.job_ids[units.index_of(worker)]).is_not_equal(UnitSystem.NENHUM)
	assert_float(units.target_xs[units.index_of(worker)]).is_equal(site.x)


func test_upgrading_an_existing_wall_refreshes_its_posts() -> void:
	var builds := BuildSystem.new()
	var site := builds.post(WallSite.slot(300.0))
	site.level = 1
	site.state = BuildSlot.State.DONE
	site.path = BuildSlot.Path.GUARNICAO
	var jobs := SimFactory.job_board()
	jobs.publish(builds)
	site.level = 2
	jobs.publish(builds)
	assert_int(jobs.slots.size()).is_equal(site.posts())


func test_clear_allows_republishing_the_same_buildings() -> void:
	var builds := BuildSystem.new()
	var site := builds.post(WallSite.slot(300.0))
	site.level = 1
	site.state = BuildSlot.State.DONE
	var jobs := SimFactory.job_board()
	jobs.publish(builds)
	jobs.clear()
	jobs.publish(builds)
	assert_int(jobs.slots.size()).is_equal(site.posts())
