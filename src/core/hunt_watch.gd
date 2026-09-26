class_name HuntWatch
extends RefCounted

## Clareiras autoradas do segmento (§21). A primeira e o coelho do §25.
const CLEARINGS := [-160.0, -760.0, 770.0, -880.0, 910.0, -1040.0, 1040.0, -1450.0, 1440.0]
const INTRO_SECONDS := 70.0  # §25, minuto 1:10; encenacao, nao afinacao de combate.


static func prepare(hunt: HuntingSystem, day: int, core_x: float, width: float) -> void:
	if hunt.day >= day or width <= 0.0:
		return
	var curve := SimFactory.curve()
	var count := RngService.int_range(&"economy", curve.hunt_yield.x, curve.hunt_yield.y)
	var places: Array[float] = []
	for i in mini(count, CLEARINGS.size()):
		places.append(clampf(core_x + CLEARINGS[i], 0.0, width))
	hunt.open_day(day, places)
