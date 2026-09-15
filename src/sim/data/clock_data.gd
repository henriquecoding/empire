# src/sim/data/clock_data.gd
# O Resource que o construtor do GameClock recebe (§30) e que a v5 nao criava.
class_name ClockData
extends Resource

## Alvorada, manha, meio-dia, tarde, crepusculo, noite — em segundos reais.
@export
var phase_durations: PackedFloat32Array = PackedFloat32Array([15.0, 85.0, 40.0, 85.0, 30.0, 105.0])

## Redundante de proposito: o teste compara com a soma e chumba se divergirem.
@export var day_seconds: float = 360.0

@export var tick_hz: int = 30

## v5.2 — limites do slider de duracao do dia (§26: 240-540 s). Acessibilidade
## e dificuldade honesta; o GameClock escala as seis fases na mesma proporcao.
@export var day_seconds_min: float = 240.0
@export var day_seconds_max: float = 540.0

@export_group("v6 · a cor de cada fase (§80, ADR 0011)")
## Matiz, saturacao e valor do tint por fase, na ordem das phase_durations.
## A noite e castanha (32 / 0,22 / 0,16), nao azul — Q-037, fechada.
@export var phase_tint_hue: PackedFloat32Array = PackedFloat32Array()
@export var phase_tint_sat: PackedFloat32Array = PackedFloat32Array()
@export var phase_tint_val: PackedFloat32Array = PackedFloat32Array()
## O chao da noite desce abaixo do ambiente: 0,11 (§80).
@export var night_value_floor: float = 0.0
