# src/world/synth_sfx.gd — os sons provisorios, feitos de senos e de ruido (ADR 0054).
#
# O jogo nao tinha som nenhum: audio/ espera pelas gravacoes, e o AGENTS.md nao deixa
# tocar-lhe. A pesquisa de 03/10 poe o som entre as tres coisas que mais pesam no que
# um golpe ou uma moeda "sentem" — e o Kingdom vive do tilintar de cada moeda. Isto e
# o que o PaintedArt e para a arte: cada pista da folha sintetizada em codigo, no
# arranque, para que o jogo se ouca ja. Quando a gravacao chegar, toma o lugar dela.
#
# Uma receita: a duracao, os parciais [Hz, amplitude, decaimento em s, atraso em s], o
# ruido [amplitude, decaimento, filtro 0-1], o deslize do tom ate ao fim, o ataque e o
# vibrato [Hz, profundidade]. Sao timbre, e nao balanceamento: ninguem os afina a jogar.
class_name SynthSfx
extends RefCounted

const TAXA := 22050
const PICO := 0.8

const RECEITAS := {
	&"sfx_coin_drop":
	{
		"dur": .18,
		"parts": [[2637, .6, .09], [3951, .35, .06], [5274, .2, .04]],
		"noise": [.15, .01, .9]
	},
	&"sfx_coin_collect": {"dur": .14, "parts": [[1568, .6, .12], [2349, .3, .1]], "glide": 1.5},
	&"sfx_coin_spend": {"dur": .22, "parts": [[2093, .6, .15], [3136, .4, .12], [4186, .2, .08]]},
	&"sfx_attack_bow":
	{"dur": .15, "parts": [[330, .5, .12]], "glide": .9, "noise": [.25, .02, .8]},
	&"sfx_attack_sword": {"dur": .12, "parts": [], "noise": [.5, .08, .5]},
	&"sfx_hit_flesh": {"dur": .14, "parts": [[110, .8, .07], [70, .5, .1]], "noise": [.6, .04, .3]},
	&"sfx_king_hit":
	{"dur": .25, "parts": [[150, .9, .12], [95, .6, .18]], "noise": [.5, .06, .4], "glide": .7},
	&"sfx_death_unit":
	{"dur": .7, "parts": [[330, .6, .5], [247, .4, .6]], "glide": .6, "attack": .01},
	&"sfx_death_creature":
	{"dur": .2, "parts": [[220, .5, .08]], "noise": [.7, .08, .5], "glide": .4},
	&"sfx_build_hammer":
	{"dur": .1, "parts": [[196, .6, .04], [392, .3, .03]], "noise": [.5, .03, .6]},
	&"sfx_build_complete":
	{"dur": .8, "parts": [[1047, .5, .6], [1319, .4, .5, .06], [1568, .35, .45, .12]]},
	&"sfx_building_destroyed": {"dur": .9, "parts": [[60, .8, .4]], "noise": [1, .35, .35]},
	&"sfx_wall_upgrade":
	{"dur": .6, "parts": [[523, .5, .4], [784, .5, .4, .08]], "noise": [.3, .03, .6]},
	&"sfx_wall_breached": {"dur": 1.4, "parts": [[45, 1, .7]], "noise": [1, .6, .3]},
	&"sfx_cavity_reveal": {"dur": 1.2, "parts": [[41, .9, .9]], "noise": [.5, .6, .08]},
	&"sfx_recruit": {"dur": .35, "parts": [[784, .5, .15], [1175, .5, .2, .07]]},
	&"sfx_impulse":
	{
		"dur": 1.0,
		"parts": [[880, .4, .6], [1109, .35, .6, .05], [1319, .35, .6, .1], [1760, .25, .5, .15]],
	},
	&"stg_dawn_bell":
	{
		"dur": 2.6,
		"parts":
		[
			[220, .35, 2.4],
			[440, 1, 1.8],
			[523, .45, 1.2],
			[660, .35, 1],
			[880, .4, .8],
			[1205, .25, .5]
		],
		"noise": [.25, .02, .9],
	},
	&"stg_dusk_warning":
	{
		"dur": 1.7,
		"parts": [[175, 1, 3], [350, .5, 3], [525, .3, 3], [700, .18, 3], [875, .1, 3]],
		"glide": .94,
		"attack": .12,
		"vibrato": [5.5, .006],
	},
	&"stg_night": {"dur": 1.2, "parts": [[55, 1, .9], [82, .5, .6]], "noise": [.3, .05, .2]},
	&"stg_conquest":
	{
		"dur": 1.5,
		"parts": [[523, .5, .5], [659, .5, .5, .15], [784, .5, .8, .3], [1047, .4, .9, .45]],
	},
	&"stg_succession":
	{"dur": 2.0, "parts": [[392, .5, 1.2], [494, .4, 1.2, .25], [587, .4, 1.4, .5]]},
}

## Quantas amostras se fazem por frame no aquecimento: o som nao trava o jogo (web).
const POR_FRAME := 800

static var _feitos := {}
static var _a_fazer: SynthTake
## As pistas que alguem pediu antes de estarem feitas: passam a frente das outras.
static var _pressa: Array[StringName] = []


## O som da pista, feito por inteiro se o aquecimento ainda la nao chegou.
static func stream(cue: StringName) -> AudioStreamWAV:
	if not _feitos.has(cue):
		var s := SynthTake.new(RECEITAS[cue])
		s.advance(s.n)
		_feitos[cue] = _wav(s.dados)
	return _feitos[cue]


static func has(cue: StringName) -> bool:
	return RECEITAS.has(cue)


## Se o som da pista ja esta feito.
static func ready(cue: StringName) -> bool:
	return _feitos.has(cue)


## Quanto dura o som da pista, em segundos.
static func duration(cue: StringName) -> float:
	return float(RECEITAS[cue].dur)


## Poe a pista a frente no aquecimento: alguem ja a quis ouvir (o sino da primeira
## alvorada sai no primeiro tick, antes de o aquecimento la chegar pela ordem).
static func hurry(cue: StringName) -> void:
	if RECEITAS.has(cue) and not _feitos.has(cue) and not _pressa.has(cue):
		_pressa.append(cue)


## Esquece os sons feitos: o aquecimento recomeca do zero (os testes).
static func forget() -> void:
	_feitos.clear()
	_pressa.clear()
	_a_fazer = null


## Um bocado do aquecimento: POR_FRAME amostras da proxima pista por fazer — as que
## tem pressa primeiro, depois pela ordem das RECEITAS (as moedas primeiro). Devolve
## se ja esta tudo feito.
static func warm(quantas: int = POR_FRAME) -> bool:
	if _a_fazer == null:
		var cue := _proxima()
		if cue == &"":
			return true
		_a_fazer = SynthTake.new(RECEITAS[cue])
		_a_fazer.set_meta(&"cue", cue)
	if _a_fazer.advance(quantas):
		_feitos[_a_fazer.get_meta(&"cue")] = _wav(_a_fazer.dados)
		_a_fazer = null
	return false


static func _proxima() -> StringName:
	while not _pressa.is_empty():
		var cue: StringName = _pressa.pop_front()
		if not _feitos.has(cue):
			return cue
	for cue: StringName in RECEITAS:
		if not _feitos.has(cue):
			return cue
	return &""


## As amostras de uma receita, de -PICO a PICO.
static func samples(receita: Dictionary) -> PackedFloat32Array:
	var s := SynthTake.new(receita)
	s.advance(s.n)
	return s.saida


static func _wav(dados: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA
	wav.stereo = false
	wav.data = dados
	return wav
