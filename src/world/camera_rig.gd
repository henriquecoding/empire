# src/world/camera_rig.gd — a camara unica (§11, §19, §24, §59).
#
# Uma camara so. O mundo e uma linha e o enquadramento vertical e fixo — ceu,
# distancia, plano medio, plano de jogo e primeiro plano estao todos no mesmo
# ecra de 720 px (§11) — por isso nada aqui mexe em Y. O que existe e como ela
# segue em X.
#
# A regra que manda no ficheiro inteiro: a camara move-se em PIXEIS INTEIROS de
# mundo (§22). A conta faz-se em float e so o resultado e arredondado, sempre
# para baixo, como as camadas de parallax do §59 — uma so regra de arredondamento
# no projeto todo. Sem isto, movimento subpixel faz a camara tremer, e uma camara
# que treme estraga a leitura de toda a arte que vier depois.
#
# Nenhum numero de afinacao esta aqui: vem todo de data/camera/default.tres.
class_name CameraRig
extends Camera2D

## Abaixo disto o alvo esta parado e a antecipacao nao muda de lado. Nao e
## afinacao: e o limiar numerico que impede a direcao de oscilar quando o alvo
## treme um milesimo de pixel.
const PARADO := 0.01
## Os dois lados da margem do rato, na mesma unidade do `pan()`.
const ESQUERDA := -1.0
const DIREITA := 1.0

## Largura do enquadramento, em px de mundo. Sai do viewport no _ready(); um
## teste poe-a a mao para nao precisar de janela.
var view_width: float = 0.0

var _dados: CameraData
var _alvo: Node2D
var _x: float = 0.0
var _antecipacao: float = 0.0
var _livre: float = 0.0
var _recuo_px_s: float = 0.0
var _alvo_x_anterior: float = 0.0
var _direcao: float = 0.0
var _limite_esq: float = 0.0
var _limite_dir: float = 0.0
var _tem_limites: bool = false
## Se o rato esta dentro da janela, e a janela tem o foco. Sem isto um rato que
## saiu pela borda deixava a ultima posicao la encostada, e a camara ia-se embora
## sozinha enquanto se lia outra coisa noutra janela.
var _rato_dentro: bool = false


func _ready() -> void:
	_dados = Registry.entry(&"camera", &"default") as CameraData
	view_width = get_viewport_rect().size.x


## Quem seguir. Passar null deixa a camara onde esta.
func follow(alvo: Node2D) -> void:
	_alvo = alvo
	if alvo != null:
		_alvo_x_anterior = alvo.global_position.x
		_x = alvo.global_position.x
		_aplicar()


## Os limites da regiao, em x de mundo (§21: a regiao tem principio e fim). Se a
## regiao for mais estreita do que o ecra, a camara fica no meio dela.
func set_region(esquerda: float, direita: float) -> void:
	_limite_esq = esquerda
	_limite_dir = direita
	_tem_limites = true
	_aplicar()


func clear_region() -> void:
	_tem_limites = false


## Camara livre (§24: stick direito, Q e Z, ou o rato na margem). direcao e -1,
## 0 ou 1.
func pan(direcao: float, delta: float) -> void:
	if is_zero_approx(direcao):
		return
	_livre += direcao * _dados.free_speed_px_s * delta
	# Recomeca a contagem do regresso a cada comando: a velocidade de recuo sai
	# de onde a camara ficou, para que os 2 s do §24 sejam mesmo 2 s.
	_recuo_px_s = absf(_livre) / _dados.free_return_seconds


## Um passo. Publico para que um teste possa correr mil passos sem esperar por
## frames — e para que a camara nao dependa de estar numa arvore para ser testada.
func advance(delta: float) -> void:
	if _alvo != null:
		_atualizar_direcao()
		_x = _suavizar(_x, _alvo.global_position.x, _dados.follow_seconds, delta)
	_antecipacao = _suavizar(
		_antecipacao, _direcao * _dados.lookahead_px, _dados.lookahead_seconds, delta
	)
	_livre = move_toward(_livre, 0.0, _recuo_px_s * delta)
	_aplicar()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var direcao := Input.get_axis(&"camera_left", &"camera_right")
	if is_zero_approx(direcao) and _rato_dentro:
		direcao = edge(get_viewport().get_mouse_position().x, view_width, _dados.edge_pan_px)
	pan(direcao, delta)
	advance(delta)


## §24: "Q · Z ou rato na margem". -1 na margem esquerda, 1 na direita, 0 no
## resto do ecra — que e onde se clica. Em px de ecra, como a mao os ve (GB-12).
static func edge(rato_x: float, largura: float, margem: float) -> float:
	if margem <= 0.0:
		return 0.0
	if rato_x < margem:
		return ESQUERDA
	if rato_x >= largura - margem:
		return DIREITA
	return 0.0


func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_rato_dentro = true


func _notification(o_que: int) -> void:
	var saiu := [
		NOTIFICATION_WM_MOUSE_EXIT,
		NOTIFICATION_WM_WINDOW_FOCUS_OUT,
		NOTIFICATION_APPLICATION_FOCUS_OUT,
	]
	if o_que in saiu:
		_rato_dentro = false


func _atualizar_direcao() -> void:
	var andou := _alvo.global_position.x - _alvo_x_anterior
	_alvo_x_anterior = _alvo.global_position.x
	if absf(andou) > PARADO:
		_direcao = signf(andou)


## Suavizacao exponencial: independente da taxa de frames, e sem o salto que um
## lerp com factor fixo da quando o delta varia. tau a zero e resposta imediata.
func _suavizar(atual: float, alvo: float, tau: float, delta: float) -> float:
	if tau <= 0.0:
		return alvo
	return alvo + (atual - alvo) * exp(-delta / tau)


## O unico sitio onde a posicao sai do float e vai para o ecra.
func _aplicar() -> void:
	position.x = floorf(_prender(_x + _antecipacao + _livre))


func _prender(x: float) -> float:
	if not _tem_limites:
		return x
	var meia := view_width / 2
	if _limite_dir - _limite_esq <= view_width:
		# Regiao mais estreita do que o ecra: fica no meio dela, sem oscilar
		# entre os dois limites em cada frame.
		return (_limite_esq + _limite_dir) / 2
	return clampf(x, _limite_esq + meia, _limite_dir - meia)
