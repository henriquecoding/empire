# src/world/dawn_sweep.gd — o amanhecer que se ve chegar (§24; GB-17).
#
# A linha do §24, na lista de juice "que nao e opcional": "Amanhecer — sino +
# varrimento de luz da esquerda para a direita a 900 px/s + as tropas a sairem
# dos postos em cascata, nao todas ao mesmo tempo."
#
# Uma das tres. O sino e som, e audio/ nao se toca (AGENTS.md, regra 9). A
# cascata mexe em QUANDO cada tropa recebe o alvo do dia, e isso e o passo 3 do
# §43, simulacao — esta na Q-089. O varrimento e apresentacao pura: uma frente
# de luz que parte da borda esquerda da regiao no dawn_broke e a atravessa a
# 900 px/s. A mancha recua ao amanhecer (§51) e e isto que o diz a quem esta a
# olhar para o outro lado.
#
# A cor e a da alvorada do clock.csv (§80) e nao uma cor nova: e a luz da fase a
# chegar. Soma-se ao que esta por baixo, como a luz faz, e nunca apaga nada.
class_name DawnSweep
extends Node2D

## §24: "a 900 px/s". O unico numero da linha.
const VELOCIDADE_PX_S := 900.0
## A cauda da frente: a luz que ja passou esbate-se ao longo disto. Geometria de
## greybox, como as alturas do Silhouette.
const LARGURA := 240.0
## O bordo da frente: uma luz a chegar nao tem aresta. Medido na primeira
## captura, uma frente seca lia-se como um corte no ecra e nao como luz.
const BORDO := 56.0
## Quanto a frente acende. Baixo de proposito: e uma alvorada, nao um clarao.
const INTENSIDADE := 0.26
const MEIA := 0.5

var _frente := 0.0
var _fim := 0.0
var _ativo := false
var _cor := Color.WHITE


func _ready() -> void:
	var soma := CanvasItemMaterial.new()
	soma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = soma
	EventBus.dawn_broke.connect(_na_alvorada)


func _na_alvorada(_dia: int) -> void:
	start(SimLoop.world_width)


## Uma alvorada: a frente volta a borda esquerda e atravessa `largura` px.
func start(largura: float) -> void:
	_frente = 0.0
	_fim = largura + LARGURA
	_ativo = true
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	_cor = BandLight.ambient(relogio, GameClock.Phase.DAWN, MEIA)
	queue_redraw()


## Um passo. Publico pela razao do `advance()` da camara: mede-se sem frames.
func advance(delta: float) -> void:
	if not _ativo:
		return
	_frente += VELOCIDADE_PX_S * delta
	_ativo = _frente < _fim
	queue_redraw()


func active() -> bool:
	return _ativo


func front() -> float:
	return _frente


func color() -> Color:
	return _cor


## Com o jogo em pausa a alvorada tambem espera.
func _process(delta: float) -> void:
	if SimLoop.running():
		advance(delta)


func _draw() -> void:
	if not _ativo:
		return
	var pico := _frente - BORDO
	var aceso := Color(_cor, INTENSIDADE)
	var nada := Color(_cor, 0.0)
	_faixa(_frente - LARGURA, pico, nada, aceso)
	_faixa(pico, _frente, aceso, nada)


## Uma faixa vertical do topo ao fundo do ecra, com a cor a passar de `de` a `ate`.
func _faixa(esquerda: float, direita: float, de: Color, ate: Color) -> void:
	var pontos := PackedVector2Array(
		[
			Vector2(esquerda, Band.SKY_TOP),
			Vector2(direita, Band.SKY_TOP),
			Vector2(direita, Band.SCREEN_BOTTOM),
			Vector2(esquerda, Band.SCREEN_BOTTOM),
		]
	)
	draw_polygon(pontos, PackedColorArray([de, ate, ate, de]))
