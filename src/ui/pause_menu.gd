# src/ui/pause_menu.gd — "Pausa / opcoes", e o fim da partida (§24, §26, §16).
#
# O mapa de comando do §24 da ao Start e ao Esc a linha "Pausa / opcoes —
# Sempre". A pausa ja existia; as opcoes nao, e o §26 tem duas que marca como
# obrigatorias: desligar o tremor de ecra e os claroes (GB-13). Vivem aqui
# porque e aqui que o §24 as pos, e gravam-se nas Preferences (§45).
#
# A derrota passa pelo mesmo ecra (GB-16). Antes, com o castelo-arvore caido, o
# veu dizia "JOGO EM PAUSA — ESC para continuar", e o Esc nao fazia nada: era a
# unica frase do jogo que mentia. O §16 diz o que e perder — "decay em vez de
# reset", e nao um save que se recarrega — e por isso o que se oferece e um jogo
# NOVO, e nao a ultima alvorada.
#
# Navega-se com o comando sem codigo nenhum para isso: sao Controls do motor, e
# as accoes ui_up, ui_down e ui_accept ja trazem o D-pad e o botao A (§26: "a
# configuracao por omissao da acesso a todo o conteudo").
#
# O texto e todo por chave de data/i18n/strings.csv (AGENTS.md), e as opcoes
# vivem no OptionsPanel desde que isto chegou as 250 linhas do §28.
class_name PauseMenu
extends Control

## Quem recomeca a partida e a cena de jogo, e ela esta noutra camada (§70): o
## pedido vai pelo grupo e nao por um import.
const GRUPO_JOGO := &"jogo"
const RECOMECAR := &"new_game"

const FUNDO := Color(0.02, 0.02, 0.03, 0.62)
const PAPEL := Color(0.20, 0.16, 0.13, 0.96)
const OURO := Color(0.95, 0.67, 0.27)
## §26: "nenhum caracter abaixo de 9 px... recomendado 12 px". Isto e titulo e
## menu, lidos a um metro de um Steam Deck.
const LETRA := {"titulo": 30, "item": 20}
const MOLDURA := {"borda": 3, "canto": 4, "margem": 28, "entre": 14}
const LARGURA := 380.0

var _titulo: Label
var _opcoes: OptionsPanel
var _retomar: Button
var _novo: Button
var _perdido := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.color = FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size.x = LARGURA
	caixa.add_theme_constant_override("separation", MOLDURA.entre)
	centro.add_child(_painel(caixa))
	_titulo = _rotulo(caixa)
	_opcoes = OptionsPanel.new()
	_opcoes.add_theme_constant_override("separation", MOLDURA.entre)
	caixa.add_child(_opcoes)
	_retomar = _botao(caixa, _ao_retomar)
	_novo = _botao(caixa, _ao_recomecar)
	_escrever()
	hide()
	EventBus.game_paused.connect(_na_pausa)


## O ecra abre com a pausa e fecha com ela. A derrota tambem pausa (game.gd), e e
## entao que ele muda de titulo e de botao.
func _na_pausa(pausado: bool) -> void:
	if pausado:
		open(defeated())
	else:
		_fechar()


## Abre o ecra, de pausa ou de derrota. Publico para se poder medir sem montar
## uma partida e deixa-la cair.
func open(perdido: bool) -> void:
	_perdido = perdido
	_retomar.visible = not perdido
	_novo.visible = perdido
	_opcoes.refresh()
	_escrever()
	show()
	(_novo if perdido else _retomar).grab_focus()


## §10: "se cair, cai a partida" — o nucleo, ou o rei sem herdeiro (Defeat). E a
## unica pausa de onde nao se volta.
static func defeated() -> bool:
	return Defeat.happened()


## O texto do menu. Volta a escrever-se quando o idioma muda (§27, GB-28).
func _escrever() -> void:
	_titulo.text = tr(&"UI_CROWN_FALLEN") if _perdido else tr(&"UI_PAUSED")
	_retomar.text = tr(&"UI_RESUME")
	_novo.text = tr(&"UI_NEW_GAME")


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSLATION_CHANGED and _titulo != null:
		_escrever()


## Quem fecha solta o foco: um botao escondido com foco continuava a ouvir o
## Espaco, e o Espaco e o Verbo 1.
func _fechar() -> void:
	var com_foco := get_viewport().gui_get_focus_owner()
	if com_foco != null and is_ancestor_of(com_foco):
		com_foco.release_focus()
	hide()


func _ao_retomar() -> void:
	if not defeated():
		SimLoop.set_paused(false)


func _ao_recomecar() -> void:
	_fechar()
	get_tree().call_group(GRUPO_JOGO, RECOMECAR)


func _painel(conteudo: Control) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = PAPEL
	estilo.border_color = OURO
	estilo.set_border_width_all(MOLDURA.borda)
	estilo.set_corner_radius_all(MOLDURA.canto)
	estilo.set_content_margin_all(MOLDURA.margem)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo)
	painel.add_child(conteudo)
	return painel


func _rotulo(caixa: VBoxContainer) -> Label:
	var rotulo := Label.new()
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", LETRA.titulo)
	rotulo.add_theme_color_override("font_color", OURO)
	caixa.add_child(rotulo)
	return rotulo


func _botao(caixa: VBoxContainer, ao_premir: Callable) -> Button:
	var botao := Button.new()
	botao.add_theme_font_size_override("font_size", LETRA.item)
	botao.pressed.connect(ao_premir)
	caixa.add_child(botao)
	return botao
