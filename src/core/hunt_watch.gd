# src/core/hunt_watch.gd — onde ficam as tocas, e a que ritmo dao (§06, §25, Q-106).
#
# O HuntingSystem e puro; isto le os dados, o relogio e o sorteio. As tocas ficam
# em sitios autorados do segmento, e cada uma da um bicho de cada vez, com o
# periodo que faz a media do dia ser a do hunt_yield (economy.csv) — a caca deixa
# de ser um stock que se esgota em meio minuto e passa a render o dia inteiro.
class_name HuntWatch
extends RefCounted

## Os sitios das tocas, em torno do nucleo (§21). A primeira e o coelho do §25.
const BUSHES := [-160.0, 770.0, -880.0, 1040.0, -1450.0, 1440.0, -1040.0, 910.0]
const INTRO_SECONDS := 70.0  # §25, minuto 1:10; encenacao, nao afinacao de combate.
const BICHO := &"rabbit"
const METADE := 0.5
const LUZ := [
	GameClock.Phase.DAWN, GameClock.Phase.MORNING, GameClock.Phase.NOON, GameClock.Phase.AFTERNOON
]

## O periodo por duracao do dia: pedido a cada tick, lido dos dados uma vez.
static var _periodo := {}


## O segundo do dia em que cai o coelho do 1:10, no dia que o jogador escolheu
## (§26, 240–540 s). O 1:10 e o de um dia do clock.csv; num dia mais longo ou mais
## curto cai no mesmo PONTO do dia, e nao ao mesmo segundo (auditoria, D10).
static func intro_at(dia_s: float) -> float:
	var base := (Registry.entry(&"economy", &"clock") as ClockData).day_seconds
	return INTRO_SECONDS * dia_s / base


## Poe as tocas na primeira vez, e abre o dia.
static func prepare(
	hunt: HuntingSystem, day: int, core_x: float, width: float, _fase: int = 0
) -> void:
	if width <= 0.0:
		return
	if not hunt.burrows.placed():
		place(hunt, core_x, width)
	if day > hunt.day and SimLoop.night != null:
		wither(hunt, SimLoop.night.amargueiros)
	hunt.open_day(day)


## As tocas da regiao, e o tempo ate ao primeiro bicho de cada uma — espalhado
## pelo periodo, para nao darem todas ao mesmo tempo (Q-120). A primeira da ja:
## e o coelho do 1:10.
static func place(hunt: HuntingSystem, core_x: float, width: float) -> void:
	var dados := Registry.entry(&"wildlife", BICHO) as WildlifeData
	var periodo := period(ClockService.clock.day_seconds() if ClockService.clock else 0.0)
	var onde: Array[float] = []
	var esperas: Array[float] = []
	for k in mini(dados.burrows_per_region, BUSHES.size()):
		onde.append(clampf(core_x + BUSHES[k], 0.0, width))
		esperas.append(0.0 if k == 0 else RngService.float_range(&"economy", 0.0, periodo))
	hunt.burrows.place(onde, esperas)


## Segundos de luz entre dois bichos da mesma toca: a luz do dia vezes as tocas,
## a dividir pela caca media do dia (hunt_yield). `dia_s` e a duracao escolhida.
static func period(dia_s: float) -> float:
	if _periodo.has(dia_s):
		return _periodo[dia_s]
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var dados := Registry.entry(&"wildlife", BICHO) as WildlifeData
	var media := (SimFactory.curve().hunt_yield.x + SimFactory.curve().hunt_yield.y) * METADE
	if media <= 0.0 or dados.burrows_per_region <= 0:
		return 0.0
	var luz := 0.0
	for fase in LUZ:
		luz += relogio.phase_durations[fase]
	var escala := dia_s / relogio.day_seconds if dia_s > 0.0 else 1.0
	_periodo[dia_s] = luz * escala * dados.burrows_per_region / media
	return _periodo[dia_s]


## Um Amargueiro de pe perto de uma toca mata-a (Q-106): e o "fazer algo errado".
static func wither(hunt: HuntingSystem, arvores: AmargueiroSystem) -> Array[float]:
	var dados := Registry.entry(&"wildlife", BICHO) as WildlifeData
	if arvores == null or dados.burrow_wither_px <= 0.0:
		return []
	var perigos := PackedFloat32Array()
	for k in arvores.xs.size():
		var de_pe := arvores.fates[k] == AmargueiroSystem.Fate.STANDING
		if de_pe and arvores.bands[k] == int(Band.Kind.SURFACE):
			perigos.append(arvores.xs[k])
	return hunt.wither(perigos, dados.burrow_wither_px)
