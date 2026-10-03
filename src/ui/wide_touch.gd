# src/ui/wide_touch.gd — no telemovel, o mundo enche o ecra ate 1,25x o 16:9 (Q-188).
#
# O dono aprovou a 03/10/2026 a proposta da Q-188: no toque, o canvas alarga-se ate ao
# limite da ADR 0001 em vez das barras pretas dos lados, onde os polegares pousam. Um
# 20:9 e exactamente 1,25x o 16:9 e enche-se todo; um ecra mais largo leva barras so no
# que passa disso. Com teclado ou comando, o 16:9 de sempre.
class_name WideTouch
extends RefCounted

## O ecra de base (§67) e o limite da ADR 0001.
const BASE := Vector2i(1280, 720)
const LIMITE := 1.25


## A largura do canvas para uma janela, em px de base: a altura fica nos 720.
static func width_for(janela: Vector2, toque: bool) -> int:
	if not toque or janela.y <= 0.0:
		return BASE.x
	var largo := float(BASE.y) * janela.x / janela.y
	return int(clampf(largo, float(BASE.x), float(BASE.x) * LIMITE))


static func apply(raiz: Window, toque: bool) -> void:
	var janela := Vector2(DisplayServer.window_get_size())
	var canvas := Vector2i(width_for(janela, toque), BASE.y)
	# So quando muda: mudar o canvas emite o size_changed que chamou isto.
	if raiz.content_scale_size != canvas:
		raiz.content_scale_size = canvas
