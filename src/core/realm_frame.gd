# src/core/realm_frame.gd — de onde nasce a noite, em relacao ao reino (ADR 0070).
#
# A Podridao nasce nas duas bordas e o Lume arde na base dela (ADR 0034). Com a sede no
# centro da regiao, as bordas eram as da regiao. Numa fundacao livre o reino pode nascer
# em qualquer sitio do mundo (ADR 0066), e a noite tem de vir de fora das muralhas dele,
# e nao de um sitio que ficou para tras: as bordas passam a ser meia regiao para cada lado
# da sede. Nos reinos do centro e nos estandartes antigos, ficam onde sempre estiveram.
class_name RealmFrame
extends RefCounted

const MEIO := 0.5


## As duas bordas de onde a noite nasce: (oeste, leste).
static func edges() -> Vector2:
	var largura := SimLoop.world_width
	var centro := SimLoop.core_x if SimLoop.arrival.free_site else largura * MEIO
	return Vector2(centro - largura * MEIO, centro + largura * MEIO)


## A borda do lado `side` (negativo: oeste).
static func edge(side: int) -> float:
	var bordas := edges()
	return bordas.y if side > 0 else bordas.x


## A mancha acabada de nascer passa para a borda do reino: o RotSystem nasce nas da
## regiao (0 e a largura), e o rasto e o Lume vao com ela.
static func place(rot: RotSystem) -> void:
	var regiao := SimLoop.world_width if rot.state.side > 0 else 0.0
	var desvio := edge(rot.state.side) - regiao
	if is_zero_approx(desvio):
		return
	rot.state.x += desvio
	rot.state.trail_from += desvio
	rot.state.trail_to += desvio
