# src/ui/web_screen.gd — o ecra inteiro do browser, pedido pela pausa (UX-03, ADR 0047).
#
# O ecra inteiro e da casca (tools/web/shell.html): ela poe a pagina toda nele, para o
# aviso de rodar o telemovel continuar a ver-se. O do motor so conhece o canvas, e nao
# sabia sair do da casca — por isso a pausa pergunta a ela, pelo objecto que publica.
# No iPhone nao ha ecra inteiro para uma pagina (o WebKit so o da a videos): a casca
# di-lo, e a pausa ensina o "Adicionar ao ecra principal". Fora da Web, nada disto existe.
class_name WebScreen
extends RefCounted

const CASCA := "empireEcra"


## Se o browser deixa pôr o jogo em ecra inteiro.
static func available() -> bool:
	var casca: Variant = _casca()
	return casca != null and bool(casca.pode())


static func active() -> bool:
	var casca: Variant = _casca()
	return casca != null and bool(casca.ativo())


## Um iPhone fora do ecra principal: o unico sitio onde o ecra inteiro nao se pode pedir.
static func iphone() -> bool:
	var casca: Variant = _casca()
	return casca != null and bool(casca.iphone())


## Entra ou sai. Chamado de um toque ou de um clique: o browser so da o ecra inteiro a
## um gesto de quem joga, e o frame em que o botao da pausa responde ainda o e.
static func toggle() -> void:
	var casca: Variant = _casca()
	if casca != null:
		casca.alternar()


static func _casca() -> Variant:
	if not OS.has_feature("web"):
		return null
	return JavaScriptBridge.get_interface(CASCA)
