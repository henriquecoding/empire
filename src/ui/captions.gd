# src/ui/captions.gd — as legendas de som (§26; GB-22).
#
# O §26: "Legendas para pistas sonoras — baixo, 8 pistas (sino, crepusculo, muro
# a cair...). Fazer. Substitui o audio para surdos." As chaves CAPTION_* estavam
# no strings.csv desde o dia zero; o que falta e quem as mostre.
#
# Que evento dispara cada uma nao se decide aqui: e a coluna `caption_key` da
# docs/audio/AUDIO_CUE_SHEET.csv, e o teste confere as duas. Das oito, cinco tem
# sinal que ja se emite; o prazo da divida e o segredo por perto esperam pelos
# sistemas deles (§14, §17).
#
# Liga-se na pausa (OPT_CAPTIONS) e vem desligada: e uma opcao para quem precisa.
class_name Captions
extends Label

## Sinal da §46 -> chave. As outras duas pistas com sinal (o rei atingido e a
## mancha a chegar) precisam de uma condicao, e tem funcao propria.
const PISTAS := {
	&"dawn_broke": &"CAPTION_DAWN_BELL",
	&"dusk_fell": &"CAPTION_DUSK_WARNING",
	&"night_started": &"CAPTION_NIGHT",
	&"wall_breached": &"CAPTION_WALL_BREACHED",
}

## Quanto tempo uma legenda fica, e quantas cabem de uma vez. Nao vem do dossie:
## e o tempo de ler uma linha curta, e tres e o que nao tapa o jogo.
const DURA_S := 3.0
const LINHAS := 3
## No ceu, por baixo do aviso do HUD: e o unico sitio do ecra onde nunca anda
## ninguem — em baixo ficava por cima do subsolo (§11). §26: nada abaixo de 12 px.
const CAIXA := {"topo": 152.0, "alto": 84.0, "letra": 18, "contorno": 4}
const COR := Color(0.96, 0.92, 0.81)
const TINTA := Color(0.08, 0.07, 0.06)
const MEIA := 0.5

var enabled: bool = false
## [chave, segundos que faltam], pela ordem em que chegaram.
var _linhas: Array[Array] = []
var _mancha_vista := false


func _ready() -> void:
	# Antes do primeiro frame: o sino da alvorada do dia 1 chega no primeiro tick.
	enabled = Preferences.on(Preferences.CAPTIONS)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_font_size_override("font_size", CAIXA.letra)
	add_theme_color_override("font_color", COR)
	add_theme_color_override("font_outline_color", TINTA)
	add_theme_constant_override("outline_size", CAIXA.contorno)
	for sinal: StringName in PISTAS:
		EventBus.connect(sinal, _na_pista.bind(PISTAS[sinal]).unbind(1))
	EventBus.unit_damaged.connect(_no_dano)
	EventBus.rot_spawned.connect(_na_mancha_nova)
	EventBus.rot_moved.connect(_na_mancha)
	# AUD-03: o sacrificio (Q-127) e quem se vai embora por falta de soldo (Q-124).
	EventBus.rot_fed.connect(_no_sacrificio)
	EventBus.unit_fled.connect(_na_fuga)


## Mostra uma legenda. A mesma pista outra vez refaz o tempo em vez de somar uma
## linha — e o max_instances 1 da folha de pistas.
func say(chave: StringName) -> void:
	if not enabled:
		return
	for linha in _linhas:
		if linha[0] == chave:
			linha[1] = DURA_S
			_escrever()
			return
	_linhas.append([chave, DURA_S])
	while _linhas.size() > LINHAS:
		_linhas.pop_front()
	_escrever()


func advance(delta: float) -> void:
	if _linhas.is_empty():
		return
	var ficam: Array[Array] = []
	for linha in _linhas:
		linha[1] -= delta
		if linha[1] > 0.0:
			ficam.append(linha)
	_linhas = ficam
	_escrever()


## Se a mancha, centrada em `x` e com `largura`, toca a faixa do ecra
## (esquerda, direita) em x de mundo.
static func in_view(x: float, largura: float, ecra: Vector2) -> bool:
	return x + largura * MEIA >= ecra.x and x - largura * MEIA <= ecra.y


func _process(delta: float) -> void:
	enabled = Preferences.on(Preferences.CAPTIONS)
	var ecra := get_viewport_rect().size
	position = Vector2(0.0, CAIXA.topo)
	size = Vector2(ecra.x, CAIXA.alto)
	advance(delta)


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSLATION_CHANGED:
		_escrever()


func _escrever() -> void:
	var partes := PackedStringArray()
	for linha in _linhas:
		partes.append(tr(linha[0]))
	text = "\n".join(partes)


func _no_sacrificio(_massa: float, _oferta: StringName) -> void:
	say(&"CAPTION_ROT_FED")


func _na_fuga(_unit_id: int, porque: StringName) -> void:
	if porque == &"upkeep":
		_na_pista(&"CAPTION_UNIT_LEFT")


func _na_pista(chave: StringName) -> void:
	say(chave)


## §07: "o rei em campo pode morrer" — so o monarca tem pista.
func _no_dano(unit_id: int, _quanto: int, _de: int) -> void:
	if unit_id == SimLoop.king_id:
		say(&"CAPTION_KING_HIT")


func _na_mancha_nova(_x: float, _largura: float, _massa: float, _lado: int) -> void:
	_mancha_vista = false


## Uma vez por noite, quando a mancha entra na largura visivel (folha de pistas).
func _na_mancha(x: float, largura: float) -> void:
	if _mancha_vista:
		return
	var camara := get_viewport().get_camera_2d()
	if camara == null:
		return
	var meio := camara.get_screen_center_position().x
	var metade := get_viewport_rect().size.x * MEIA
	if in_view(x, largura, Vector2(meio - metade, meio + metade)):
		_mancha_vista = true
		say(&"CAPTION_ROT_NEAR")
