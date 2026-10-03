# src/world/sfx_cues.gd — as pistas que o jogo ja toca, e como (§23, ADR 0054).
#
# A folha de pistas (docs/audio/AUDIO_CUE_SHEET.csv) diz que evento da §46 dispara cada
# pista, a que volume, com quanta variacao de tom, quantas de cada vez e ate que
# distancia da camara se ouvem. Isto e a mesma folha, so nas pistas que o SynthSfx sabe
# fazer enquanto as gravacoes de audio/ nao chegam; o tests/som_test.gd confere as duas.
#
# Uma distancia de 0 e "ouve-se em todo o lado": os sinais do relogio, da coroa e do muro.
class_name SfxCues
extends RefCounted

const EVENTO := &"event"
const VOLUME := &"volume_db"
const TOM := &"pitch_variation"
const MAXIMO := &"max_instances"
const DISTANCIA := &"distance_px"

const CUES := {
	&"stg_dawn_bell": {EVENTO: &"dawn_broke", VOLUME: 0.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"stg_dusk_warning": {EVENTO: &"dusk_fell", VOLUME: 0.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"stg_night": {EVENTO: &"night_started", VOLUME: -2.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"sfx_coin_drop":
	{EVENTO: &"coin_dropped", VOLUME: -6.0, TOM: 0.08, MAXIMO: 8, DISTANCIA: 640.0},
	&"sfx_coin_collect":
	{EVENTO: &"coin_collected", VOLUME: -8.0, TOM: 0.08, MAXIMO: 6, DISTANCIA: 640.0},
	&"sfx_coin_spend":
	{EVENTO: &"coin_spent", VOLUME: -6.0, TOM: 0.08, MAXIMO: 4, DISTANCIA: 640.0},
	&"sfx_attack_bow":
	{EVENTO: &"attack_launched", VOLUME: -9.0, TOM: 0.08, MAXIMO: 8, DISTANCIA: 1280.0},
	&"sfx_attack_sword":
	{EVENTO: &"attack_launched", VOLUME: -9.0, TOM: 0.08, MAXIMO: 6, DISTANCIA: 1280.0},
	&"sfx_hit_flesh":
	{EVENTO: &"unit_damaged", VOLUME: -9.0, TOM: 0.08, MAXIMO: 6, DISTANCIA: 1280.0},
	&"sfx_king_hit": {EVENTO: &"unit_damaged", VOLUME: -3.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"sfx_death_unit":
	{EVENTO: &"unit_died", VOLUME: -6.0, TOM: 0.05, MAXIMO: 3, DISTANCIA: 1600.0},
	&"sfx_death_creature":
	{EVENTO: &"creature_died", VOLUME: -9.0, TOM: 0.08, MAXIMO: 4, DISTANCIA: 1280.0},
	&"sfx_build_hammer":
	{EVENTO: &"build_progressed", VOLUME: -12.0, TOM: 0.08, MAXIMO: 4, DISTANCIA: 1280.0},
	&"sfx_build_complete":
	{EVENTO: &"build_completed", VOLUME: -6.0, TOM: 0.0, MAXIMO: 2, DISTANCIA: 1600.0},
	&"sfx_building_destroyed":
	{EVENTO: &"building_destroyed", VOLUME: -4.0, TOM: 0.0, MAXIMO: 2, DISTANCIA: 1600.0},
	&"sfx_wall_upgrade":
	{EVENTO: &"wall_upgraded", VOLUME: -6.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 1600.0},
	&"sfx_wall_breached":
	{EVENTO: &"wall_breached", VOLUME: 0.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"sfx_cavity_reveal":
	{EVENTO: &"cavity_revealed", VOLUME: -4.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"sfx_recruit":
	{EVENTO: &"unit_promoted", VOLUME: -8.0, TOM: 0.05, MAXIMO: 2, DISTANCIA: 640.0},
	&"sfx_impulse":
	{EVENTO: &"royal_impulse_used", VOLUME: -4.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"stg_conquest":
	{EVENTO: &"fortress_conquered", VOLUME: 0.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
	&"stg_succession":
	{EVENTO: &"succession_started", VOLUME: 0.0, TOM: 0.0, MAXIMO: 1, DISTANCIA: 0.0},
}


static func of(cue: StringName) -> Dictionary:
	return CUES[cue]
