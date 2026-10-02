class_name CombatView
extends Node2D

const CIRCLE_POINTS := 16
const SWING_FRACTION := 0.35
const SWING_POINTS := 9
const AIM_OFFSET := 5.0
const AIM_CAP := 4
const TARGET_POINTS := 12

const DURATION := 0.20
const GOLD := Color("f0c679")
const GREEN := Color("97d1ab")
const WIDTH := 2.0
const HEIGHT := 30.0
const ARROWHEAD := 6.0
static var attacks: Dictionary = {}


func _ready() -> void:
	attacks.clear()
	EventBus.attack_launched.connect(_launched)
	EventBus.target_marked.connect(_skill)
	EventBus.game_paused.connect(_pause)


func _pause(_value: bool) -> void:
	attacks.clear()


func _process(delta: float) -> void:
	if SimLoop.running():
		for who: int in attacks.keys():
			attacks[who][&"remaining"] = float(attacks[who][&"remaining"]) - delta
			if float(attacks[who][&"remaining"]) <= 0.0:
				attacks.erase(who)
	queue_redraw()


func _launched(who: int, target: int, hit: bool) -> void:
	var units := SimLoop.units
	var i := units.index_of(who)
	if i < 0:
		return
	var body := Registry.entry(&"units", units.data_ids[i]) as UnitData
	var manual := SimLoop.combat.manual.last
	var direction := CombatInput.facing
	var reach := float(body.range_px)
	var end_x := units.xs[i] + direction * reach
	var c := SimLoop.creatures.index_of(target)
	if c >= 0:
		end_x = SimLoop.creatures.xs[c]
		direction = ImpactView.aim(units.xs[i], end_x)
	elif int(manual.get(&"who", -1)) == who:
		direction = manual[&"direction"]
		reach = manual[&"range"]
		end_x = float(manual[&"target_x"])
	attacks[who] = {
		&"remaining": DURATION,
		&"x": units.xs[i],
		&"end": end_x,
		&"band": units.bands[i],
		&"direction": direction,
		&"ranged": body.tags.has(&"ranged"),
		&"skill": false,
		&"hit": hit
	}


func _skill(_target: int, who: int) -> void:
	if HeroWatch.current() != &"bard" or who != Assume.driven():
		return
	var i := SimLoop.units.index_of(who)
	if i < 0:
		return
	attacks[who] = {
		&"remaining": DURATION,
		&"x": SimLoop.units.xs[i],
		&"band": SimLoop.units.bands[i],
		&"direction": CombatInput.aim_direction(),
		&"ranged": false,
		&"skill": true
	}


func _draw() -> void:
	if SimLoop.field == null or ClassSelection.active:
		return
	_aim()
	for who: int in attacks:
		var attack: Dictionary = attacks[who]
		if SoilCover.covers(int(attack[&"band"]), float(attack[&"x"])):
			continue
		var alpha := float(attack[&"remaining"]) / DURATION
		var color := GREEN if bool(attack[&"skill"]) else GOLD
		color.a = alpha
		var ground := WorldPalette.ground_of(int(attack[&"band"]))
		var start := Vector2(float(attack[&"x"]), ground - HEIGHT)
		var direction := float(attack[&"direction"])
		if bool(attack[&"skill"]):
			draw_arc(start, HEIGHT * (1.0 + 1.0 - alpha), 0.0, TAU, CIRCLE_POINTS, color, WIDTH)
		elif bool(attack[&"ranged"]):
			var end := Vector2(float(attack[&"end"]), start.y)
			draw_line(start, end, color, WIDTH)
			draw_line(end, end + Vector2(-direction * ARROWHEAD, -WIDTH), color, WIDTH)
			draw_line(end, end + Vector2(-direction * ARROWHEAD, WIDTH), color, WIDTH)
		else:
			var angle := 0.0 if direction > 0.0 else PI
			draw_arc(
				start,
				HEIGHT,
				angle - PI * SWING_FRACTION,
				angle + PI * SWING_FRACTION,
				SWING_POINTS,
				color,
				WIDTH
			)


func _aim() -> void:
	if CombatInput.blocked():
		return
	var units := SimLoop.units
	var who := Assume.driven()
	var i := units.index_of(who)
	if i < 0 or not units.alive(i):
		return
	var manual := SimLoop.combat.manual
	var stats := manual.profile(units, who)
	if stats.is_empty() or int(stats[&"damage"]) <= 0:
		return
	var direction := CombatInput.aim_direction()
	var start := Vector2(units.xs[i], WorldPalette.ground_of(int(units.bands[i])) + AIM_OFFSET)
	var end := start + Vector2(direction * float(stats[&"range"]), 0.0)
	var color := GOLD
	color.a = SWING_FRACTION
	draw_dashed_line(start, end, color, 1.0, AIM_OFFSET)
	draw_line(end + Vector2(0, -AIM_CAP), end + Vector2(0, AIM_CAP), color, 1.0)
	var target := manual.target(units, SimLoop.creatures, who, direction)
	var c := SimLoop.creatures.index_of(target)
	if c >= 0 and not SoilCover.covers(int(SimLoop.creatures.bands[c]), SimLoop.creatures.xs[c]):
		var foot := Vector2(
			SimLoop.creatures.xs[c], WorldPalette.ground_of(int(SimLoop.creatures.bands[c]))
		)
		draw_arc(foot - Vector2(0, HEIGHT), HEIGHT, 0.0, TAU, TARGET_POINTS, GOLD, 1.0)
