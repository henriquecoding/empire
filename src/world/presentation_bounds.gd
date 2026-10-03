class_name PresentationBounds
extends RefCounted

const MARGIN := 96.0
## Sem ecra (um teste, um canvas fora da arvore) ve-se tudo.
const TUDO := Rect2(-1e9, -1e9, 2e9, 2e9)


static func of(canvas: CanvasItem) -> Rect2:
	if canvas == null or not canvas.is_inside_tree():
		return TUDO
	var viewport := canvas.get_viewport_rect()
	var inverse := canvas.get_canvas_transform().affine_inverse()
	return (inverse * viewport).grow(MARGIN)


## Se uma coisa em `x`, com `meia` largura para cada lado, cai na largura de `vista`.
## O mundo e uma linha: so o x decide, e uma obra larga ve-se com o pe fora do ecra.
static func sees(vista: Rect2, x: float, meia := 0.0) -> bool:
	return x + meia >= vista.position.x and x - meia <= vista.end.x
