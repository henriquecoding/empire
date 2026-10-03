# src/world/synth_take.gd — um som do SynthSfx a fazer-se, amostra a amostra (ADR 0054).
#
# Saiu do SynthSfx a 03/10/2026, com o desempenho: o aquecimento custava 2 ms por frame
# durante dezasseis segundos, e o que mais pesava era ler a receita — um dicionario, com
# os parciais em listas — outra vez em cada amostra. Aqui le-se uma vez, para colunas, e
# as contas sao as mesmas, pela mesma ordem: o som sai igual.
class_name SynthTake
extends RefCounted

## O fim de cada som desce a zero neste tempo: um corte seco estala.
const FECHO_S := 0.01
## O ataque de uma receita que nao diz o seu: um clique, sem estalo.
const ATAQUE_S := 0.003
## O indice do atraso num parcial [Hz, amplitude, decaimento, atraso].
const ATRASO := 3
## O maior valor de uma amostra de 16 bits, e o intervalo de uma amostra.
const S16 := 32767.0
const UM := 1.0
## O hash do ruido: as constantes classicas do "random" dos shaders, sem sorteio.
const HASH := Vector2(12.9898, 43758.5453)
const SEM_RUIDO := [0.0, 1.0, 1.0]
const SEM_VIBRATO := [0.0, 0.0]

var receita: Dictionary
var n := 0
var i := 0
var j := 0
var fases := PackedFloat32Array()
var saida := PackedFloat32Array()
var dados := PackedByteArray()
var filtrado := 0.0
var pico := 0.0
## Os parciais, em colunas.
var hz := PackedFloat64Array()
var amp := PackedFloat64Array()
var decai := PackedFloat64Array()
var atraso := PackedFloat64Array()
## O resto da receita, lido uma vez.
var ataque := ATAQUE_S
var glide := 1.0
var dur := 0.0
var vibrato_hz := 0.0
var vibrato_fundo := 0.0
var ruido_amp := 0.0
var ruido_decai := 1.0
var ruido_filtro := 1.0


func _init(r: Dictionary) -> void:
	receita = r
	dur = float(r.dur)
	n = int(dur * SynthSfx.TAXA)
	fases.resize((r.parts as Array).size())
	saida.resize(n)
	dados.resize(n * 2)
	for p: Array in r.parts:
		hz.append(float(p[0]))
		amp.append(float(p[1]))
		decai.append(float(p[2]))
		atraso.append(float(p[ATRASO]) if p.size() > ATRASO else 0.0)
	ataque = maxf(r.get("attack", ATAQUE_S), 1.0 / SynthSfx.TAXA)
	glide = r.get("glide", 1.0)
	var vibrato: Array = r.get("vibrato", SEM_VIBRATO)
	vibrato_hz = vibrato[0]
	vibrato_fundo = vibrato[1]
	var ruido: Array = r.get("noise", SEM_RUIDO)
	ruido_amp = ruido[0]
	ruido_decai = ruido[1]
	ruido_filtro = ruido[2]


## Avanca `quantas` amostras; devolve se acabou (sintese e conversao a 16 bits).
func advance(quantas: int) -> bool:
	var ate := mini(n, i + quantas)
	while i < ate:
		saida[i] = sample(i)
		pico = maxf(pico, absf(saida[i]))
		i += 1
	if i < n:
		return false
	var escala := SynthSfx.PICO / pico if pico > 0.0 else 0.0
	ate = mini(n, j + quantas)
	while j < ate:
		saida[j] *= escala
		dados.encode_s16(j * 2, int(clampf(saida[j], -UM, UM) * S16))
		j += 1
	return j >= n


## A amostra `k` da receita, por normalizar. Avanca as fases e o filtro do ruido.
func sample(k: int) -> float:
	var t := float(k) / SynthSfx.TAXA
	var tom := lerpf(1.0, glide, t / dur)
	tom *= 1.0 + vibrato_fundo * sin(TAU * vibrato_hz * t)
	var v := 0.0
	for p in hz.size():
		fases[p] += TAU * hz[p] * tom / SynthSfx.TAXA
		if t >= atraso[p]:
			var dt := t - atraso[p]
			v += amp[p] * sin(fases[p]) * (minf(1.0, dt / ataque) * exp(-dt / decai[p]))
	var branco := lerpf(-UM, UM, fposmod(sin(float(k) * HASH.x) * HASH.y, UM))
	filtrado = lerpf(filtrado, branco, ruido_filtro)
	v += ruido_amp * filtrado * exp(-t / ruido_decai)
	return v * clampf((dur - t) / FECHO_S, 0.0, 1.0)
