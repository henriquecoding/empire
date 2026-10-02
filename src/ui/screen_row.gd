# src/ui/screen_row.gd — o ecra inteiro na pausa: entrar, sair, ou como no iPhone (UX-03).
#
# O dono, a 02/10/2026: "no menu e possivel tirar da tela cheia". Uma linha so para isto,
# ao pe das opcoes: o botao troca de nome com o estado, e escreve-se outra vez quando a
# janela muda de tamanho — que e o que o ecra inteiro faz ao entrar e ao sair.
class_name ScreenRow
extends VBoxContainer

var _botao: Button
var _nota: Label


func _ready() -> void:
	_botao = PauseTheme.button(self, &"UI_FULLSCREEN_ENTER", WebScreen.toggle)
	_nota = PauseTheme.label(self, &"UI_FULLSCREEN_IPHONE")
	_nota.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)
	_nota.add_theme_color_override("font_color", PauseTheme.MUTED)
	get_tree().root.size_changed.connect(refresh)
	EventBus.game_paused.connect(func(_pausa: bool) -> void: refresh())
	refresh()


func refresh() -> void:
	_botao.visible = WebScreen.available()
	_nota.visible = not _botao.visible and WebScreen.iphone()
	visible = _botao.visible or _nota.visible
	_botao.text = tr(&"UI_FULLSCREEN_EXIT" if WebScreen.active() else &"UI_FULLSCREEN_ENTER")
	_nota.text = tr(&"UI_FULLSCREEN_IPHONE")
