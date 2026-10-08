class_name WallGuide
extends RefCounted


static func building(site: BuildSlot, values: Dictionary) -> String:
	var key := &"CONTEXT_WALL_BUILDING" if _crew(site) else &"CONTEXT_WALL_WAITING"
	return GuideHints.translate(key).format(values)


static func offer(site: BuildSlot, values: Dictionary) -> String:
	if not _crew(site):
		return GuideHints.translate(&"CONTEXT_WALL_BUILDER").format(values)
	if not SimLoop.builds.can_climb(site, SimLoop.state, SimLoop.night.amargueiros):
		return GuideHints.translate(&"CONTEXT_LOCKED").format(values)
	var levels := SimFactory.walls_by_level()
	values["level"] = site.level + 1
	values["name"] = GuideHints.translate(levels[site.level].display_key)
	values["path"] = GuideHints.translate(
		&"PATH_GARRISON" if site.path == BuildSlot.Path.GUARNICAO else &"PATH_FORTIFY"
	)
	var key := &"CONTEXT_WALL" if KingVerbs.wall_choice_open(site) else &"CONTEXT_WALL_UPGRADE"
	return GuideHints.translate(key).format(values)


static func _crew(site: BuildSlot) -> bool:
	var owner := SimLoop.recruits.owner_of(SimLoop.units, SimLoop.king_id)
	return WallCrew.available(SimLoop.units, site.band, owner)
