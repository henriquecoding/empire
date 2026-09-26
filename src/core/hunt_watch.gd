class_name HuntWatch
extends RefCounted

## Clareiras autoradas do segmento (§21). A primeira e o coelho do §25.
const CLEARINGS := [-160.0, -760.0, 770.0, -880.0, 910.0, -1040.0, 1040.0, -1450.0, 1440.0]
const INTRO_SECONDS := 70.0  # §25, minuto 1:10; encenacao, nao afinacao de combate.
## As fases de luz em que abre cada vaga de coelhos (Q-106, opcao b). Uma so vaga
## volta ao stock do dia inteiro ao amanhecer.
const WAVE_PHASES := [GameClock.Phase.DAWN, GameClock.Phase.NOON, GameClock.Phase.AFTERNOON]


static func prepare(
	hunt: HuntingSystem, day: int, core_x: float, width: float, fase: int = 0
) -> void:
	if hunt.day >= day or width <= 0.0:
		release_due(hunt, fase)
		return
	var curve := SimFactory.curve()
	var count := RngService.int_range(&"economy", curve.hunt_yield.x, curve.hunt_yield.y)
	var places: Array[float] = []
	for i in mini(count, CLEARINGS.size()):
		places.append(clampf(core_x + CLEARINGS[i], 0.0, width))
	hunt.open_day(day, places, WAVE_PHASES.size())
	release_due(hunt, fase)


## Abre as vagas cuja fase ja chegou. A noite nao abre nada: a caca e de dia.
static func release_due(hunt: HuntingSystem, fase: int) -> void:
	var abertas := WAVE_PHASES.size() - hunt.pending.size()
	while not hunt.pending.is_empty() and fase >= int(WAVE_PHASES[abertas]):
		hunt.release()
		abertas += 1
