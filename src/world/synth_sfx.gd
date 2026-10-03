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
## O fim de cada som desce a zero neste tempo: um corte seco estala.
const FECHO_S := 0.01

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
static var _a_fazer: Sintese


## Uma receita a meio: sintetiza-se aos bocados, e depois passa-se a 16 bits.
class Sintese:
	var receita: Dictionary
	var n := 0
	var i := 0
	var j := 0
	var fases := PackedFloat32Array()
	var saida := PackedFloat32Array()
	var dados := PackedByteArray()
	var filtrado := 0.0
	var pico := 0.0

	func _init(r: Dictionary) -> void:
		receita = r
		n = int(float(r.dur) * TAXA)
		fases.resize((r.parts as Array).size())
		saida.resize(n)
		dados.resize(n * 2)

	## Avanca `quantas` amostras; devolve se acabou (sintese e conversao).
	func advance(quantas: int) -> bool:
		var ate := mini(n, i + quantas)
		while i < ate:
			saida[i] = SynthSfx.sample(receita, i, fases, self)
			pico = maxf(pico, absf(saida[i]))
			i += 1
		if i < n:
			return false
		var escala := PICO / pico if pico > 0.0 else 0.0
		ate = mini(n, j + quantas)
		while j < ate:
			saida[j] *= escala
			dados.encode_s16(j * 2, int(clampf(saida[j], -1.0, 1.0) * 32767.0))
			j += 1
		return j >= n


## O som da pista, feito por inteiro se o aquecimento ainda la nao chegou.
static func stream(cue: StringName) -> AudioStreamWAV:
	if not _feitos.has(cue):
		var s := Sintese.new(RECEITAS[cue])
		s.advance(s.n)
		_feitos[cue] = _wav(s.dados)
	return _feitos[cue]


static func has(cue: StringName) -> bool:
	return RECEITAS.has(cue)


## Se o som da pista ja esta feito.
static func ready(cue: StringName) -> bool:
	return _feitos.has(cue)


## Um bocado do aquecimento: POR_FRAME amostras da proxima pista por fazer, pela
## ordem das RECEITAS (as moedas primeiro). Devolve se ja esta tudo feito.
static func warm(quantas: int = POR_FRAME) -> bool:
	if _a_fazer == null:
		for cue: StringName in RECEITAS:
			if not _feitos.has(cue):
				_a_fazer = Sintese.new(RECEITAS[cue])
				_a_fazer.set_meta(&"cue", cue)
				break
		if _a_fazer == null:
			return true
	if _a_fazer.advance(quantas):
		_feitos[_a_fazer.get_meta(&"cue")] = _wav(_a_fazer.dados)
		_a_fazer = null
	return false


## As amostras de uma receita, de -PICO a PICO.
static func samples(receita: Dictionary) -> PackedFloat32Array:
	var s := Sintese.new(receita)
	s.advance(s.n)
	return s.saida


## A amostra `i` de uma receita, por normalizar. `fases` e `s` levam o estado.
static func sample(receita: Dictionary, i: int, fases: PackedFloat32Array, s: Sintese) -> float:
	var parts: Array = receita.parts
	var ruido: Array = receita.get("noise", [0.0, 1.0, 1.0])
	var ataque: float = maxf(receita.get("attack", 0.003), 1.0 / TAXA)
	var vibrato: Array = receita.get("vibrato", [0.0, 0.0])
	var t := float(i) / TAXA
	var tom := lerpf(1.0, receita.get("glide", 1.0), t / float(receita.dur))
	tom *= 1.0 + float(vibrato[1]) * sin(TAU * float(vibrato[0]) * t)
	var v := 0.0
	for k in parts.size():
		var p: Array = parts[k]
		var atraso: float = p[3] if p.size() > 3 else 0.0
		fases[k] += TAU * float(p[0]) * tom / TAXA
		if t >= atraso:
			v += float(p[1]) * sin(fases[k]) * _envolvente(t - atraso, ataque, p[2])
	s.filtrado = lerpf(s.filtrado, _ruido(i), float(ruido[2]))
	v += float(ruido[0]) * s.filtrado * exp(-t / float(ruido[1]))
	return v * clampf((float(receita.dur) - t) / FECHO_S, 0.0, 1.0)


static func _envolvente(t: float, ataque: float, decai: float) -> float:
	return minf(1.0, t / ataque) * exp(-t / decai)


## Ruido branco sem sorteio: um hash do indice da amostra, sempre o mesmo som.
static func _ruido(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0


static func _wav(dados: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA
	wav.stereo = false
	wav.data = dados
	return wav
