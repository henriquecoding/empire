# src/world/day_tint.gd — a luz de cada fase, animada pelo relogio (F1-13, §23).
#
# Um CanvasModulate, e mais nada. As seis cores estao em data/economy/clock.tres
# — matiz, saturacao e valor por fase — e nenhuma esta escrita aqui: mudar a cor
# da tarde e mudar uma celula de clock.csv.
#
# A cor interpola ENTRE fases, com o phase_progress() do relogio. Sem isso o
# ecra dava um salto de cor de 15 em 15 segundos, e o §23 pede o contrario: a
# luz e o relogio do jogador, e um relogio nao anda aos saltos.
#
# A noite e castanha e nao azul: 32° · 0,22 · 0,16 (ADR 0011, §80, Q-037).
class_name DayTint
extends CanvasModulate

const TABELA := &"economy"
const RELOGIO := &"clock"
## O matiz vem em graus no CSV e a Color quer a volta inteira em 1,0.
const VOLTA := 360.0

var _dados: ClockData


func _ready() -> void:
	_dados = Registry.entry(TABELA, RELOGIO) as ClockData
	_aplicar()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _dados == null:
		return
	_aplicar()


## A cor no ponto do dia em que o relogio esta. Publica para que a ferramenta de
## captura possa pedir uma fase sem esperar 360 segundos por ela.
func tint_at(fase: int, progresso: float) -> Color:
	var seguinte := (fase + 1) % _dados.phase_durations.size()
	return _cor(fase).lerp(_cor(seguinte), clampf(progresso, 0.0, 1.0))


func _aplicar() -> void:
	var relogio := ClockService.clock
	color = tint_at(int(relogio.current_phase()), relogio.phase_progress())


func _cor(fase: int) -> Color:
	return Color.from_hsv(
		_dados.phase_tint_hue[fase] / VOLTA,
		_dados.phase_tint_sat[fase],
		_dados.phase_tint_val[fase]
	)
