# src/ui/fresh_start_panel.gd — o "Recomecar do zero" da pausa, e a pergunta (Q-164).
#
# Um botao que abre uma pergunta com duas respostas, no mesmo painel e sem janela
# nova. O foco comeca no "Cancelar": o Espaco e o Verbo 1 e o A do comando e o
# ui_accept (§26) — um toque a mais nao pode apagar uma campanha. Nao ha "manter
# premido" nem temporizador, pela mesma razao de acessibilidade: a protecao e a
# segunda confirmacao com o foco do lado seguro.
#
# A pergunta diz o que se perde, com numeros, e o que fica (as opcoes). Quem apaga e
# o FreshStart, tudo ou nada; quem recomeca e a cena de jogo, pelo grupo `jogo`, como
# o botao da derrota — a interface nao importa de src/world/ (§70).
class_name FreshStartPanel
extends VBoxContainer

const GRUPO_JOGO := &"jogo"
const RECOMECAR := &"new_game"
## §26: "recomendado 12 px". Lido a um metro de um Steam Deck, como o OptionsPanel.
const LETRA := 20
const TINTA := Color(0.96, 0.92, 0.81)
const CHAVES := [
	&"UI_FRESH_START",
	&"UI_FRESH_START_ASK",
	&"UI_FRESH_START_CONFIRM",
	&"UI_CANCEL",
	&"UI_FRESH_START_FAILED",
]

var _abrir: Button
var _pergunta: Label
var _cancelar: Button
var _apagar: Button
var _ao_sair: Callable


## `ao_sair` fecha a pausa antes de a cena recarregar (PauseMenu._fechar).
func _init(ao_sair: Callable) -> void:
	_ao_sair = ao_sair


func _ready() -> void:
	_abrir = _botao(_perguntar)
	_pergunta = Label.new()
	_pergunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pergunta.add_theme_font_size_override("font_size", LETRA)
	_pergunta.add_theme_color_override("font_color", TINTA)
	add_child(_pergunta)
	_cancelar = _botao(_desistir)
	_apagar = _botao(_confirmar)
	close()


## Volta ao botao, sem pergunta. A pausa chama-o de cada vez que abre. Solta o foco
## de um controlo que vai esconder: um botao escondido com foco continuava a ouvir o
## Espaco, que e o Verbo 1 (a mesma regra do PauseMenu._fechar).
func close() -> void:
	var com_foco := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if com_foco != null and com_foco != _abrir and is_ancestor_of(com_foco):
		com_foco.release_focus()
	_mostrar(false)


func _perguntar() -> void:
	_mostrar(true)
	_cancelar.grab_focus()


## Cancelar devolve o foco ao botao de onde se veio.
func _desistir() -> void:
	close()
	_abrir.grab_focus()


func _confirmar() -> void:
	_cancelar.disabled = true
	_apagar.disabled = true
	_depois(FreshStart.wipe())


## Separado do wipe para se poder medir a falha sem estragar o disco de quem testa.
func _depois(apagou: bool) -> void:
	if not apagou:
		_pergunta.text = tr(&"UI_FRESH_START_FAILED")
		_cancelar.disabled = false
		_cancelar.grab_focus()
		return
	InputRouter.pointed = -1  # um segmento da roda apontado na pausa nao dispara no jogo novo
	_ao_sair.call()
	get_tree().call_group(GRUPO_JOGO, RECOMECAR)


## O que se perde, pelos numeros de agora (a partida, o legado a espera, o dia).
static func lost() -> Dictionary:
	var estado := SimLoop.state
	var acabou := Defeat.happened() or estado.crossed
	var dia := ClockService.clock.day if ClockService.clock != null else 1
	return counts(estado, dia, acabou, LegacyStore.pending(), LegacyStore.failed)


## Durante a partida, a partida viva. Depois do fim, com o legado gravado, o legado a
## espera — os numeros da linha da derrota (Q-134). Se o legado falhou (CONT-01), os
## saves que ficaram guardam a partida viva, e sao esses que se vao apagar.
static func counts(
	estado: GameState, dia: int, acabou: bool, legado: Dictionary, falhou: bool
) -> Dictionary:
	var perde := {"day": dia, "seeds": estado.royal_seeds, "found": estado.found.size()}
	if acabou and not falhou and not legado.is_empty():
		perde["seeds"] = int(legado.get(Legacy.SEMENTES, 0))
		perde["found"] = PackedStringArray(legado.get(Legacy.ACHADOS, [])).size()
	return perde


func _mostrar(perguntar: bool) -> void:
	_abrir.visible = not perguntar
	for controlo: Control in [_pergunta, _cancelar, _apagar]:
		controlo.visible = perguntar
	_cancelar.disabled = false
	_apagar.disabled = false
	_escrever()


## Todo o texto do painel, por chave (§27). Volta a escrever-se quando o idioma muda.
func _escrever() -> void:
	_abrir.text = tr(&"UI_FRESH_START")
	_pergunta.text = tr(&"UI_FRESH_START_ASK").format(lost())
	_cancelar.text = tr(&"UI_CANCEL")
	_apagar.text = tr(&"UI_FRESH_START_CONFIRM")


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSLATION_CHANGED and _abrir != null:
		_escrever()


func _botao(ao_premir: Callable) -> Button:
	var botao := Button.new()
	botao.add_theme_font_size_override("font_size", LETRA)
	botao.pressed.connect(ao_premir)
	add_child(botao)
	return botao
