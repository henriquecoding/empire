# src/world/screen_shake.gd — o tremor de ecra, por trauma (§24, §26).
#
# O §24 limita-o a duas coisas — o muro a cair e o Ariete a acertar — e a 4 px.
# O que muda aqui e a forma: em vez de um tremor que comeca cheio e desce a
# direito, um "trauma" de 0 a 1 que os acontecimentos somam e o tempo gasta, e
# um tremor que e o QUADRADO dele (Squirrel Eiserloh, "Juicing Your Cameras With
# Math", GDC 2016). Duas dentadas seguidas do Ariete tremem mais do que uma, e um
# trauma pequeno quase nao se sente — que e o que o §24 pede a um golpe normal.
#
# Ruido suave em vez de um sorteio por frame: uma soma de senos com fases
# sorteadas uma vez. Um sorteio por frame vibra; isto abana.
#
# Puro: as fases entram de fora (o fluxo visual, §42) e o tempo tambem.
class_name ScreenShake
extends RefCounted

## §24: "Amplitude max. 4 px".
const MAX_PX := 4.0
## Quanto trauma se gasta por segundo: um muro inteiro (1,0) acalma em 0,7 s.
const DECAI := 1.4
## As velocidades do ruido (rad/s). Na vertical abana a metade.
const RITMO := Vector2(29.0, 37.0)
const VERTICAL := 0.5

var trauma := 0.0
var _t := 0.0
var _fases := Vector4.ZERO


func _init(fases: Vector4 = Vector4.ZERO) -> void:
	_fases = fases


func add(quanto: float) -> void:
	trauma = clampf(trauma + quanto, 0.0, 1.0)


## Um passo do tempo do ecra; devolve o deslocamento deste frame.
func step(delta: float) -> Vector2:
	_t += delta
	trauma = maxf(0.0, trauma - DECAI * delta)
	if trauma <= 0.0:
		return Vector2.ZERO
	var forca := MAX_PX * trauma * trauma
	var x := 0.6 * sin(_t * RITMO.x + _fases.x) + 0.4 * sin(_t * RITMO.x * 2.3 + _fases.y)
	var y := 0.6 * sin(_t * RITMO.y + _fases.z) + 0.4 * sin(_t * RITMO.y * 1.7 + _fases.w)
	return Vector2(x, y * VERTICAL) * forca
