# src/world/lowland_layout.gd — onde ficam os caminhos e os lagos da terra por cima do
# corte de solo (o pedido do dono de 30/09/2026: "vegetacao aparente sempre, ou lagos,
# caminhos"; §11; ADR 0039).
#
# Grelha com tremor presa ao mundo, como o Wilds: cada celula tem no maximo um caminho
# (ou um lago), num sitio tremido dentro dela, e a mesma celula da sempre o mesmo,
# venha o rei de onde vier. Os caminhos saem da estrada e descem ate ao fundo do ecra,
# longe das bocas das passagens; os lagos ficam entre eles, sem lhes tocar. A chance de
# um lago e a do bioma do sitio. O Lowland junta isto as plantas; o LowlandArt desenha.
class_name LowlandLayout
extends RefCounted

## Os caminhos: um por celula de `passo` px, com `chance`; o pe foge ate `desvio` para o
## lado e dobra ate `curva`; a largura vai de `topo` a `fundo` (o que esta perto e mais
## largo). Nenhum sai a menos de `margem` de uma boca de passagem ou da beira.
const CAMINHO := {
	"passo": 860.0,
	"chance": 0.55,
	"desvio": 240.0,
	"curva": 60.0,
	"topo": 10.0,
	"fundo": 30.0,
	"margem": 56.0
}
## Os lagos: um por celula de `passo` px, com meia largura e meia altura (achatados: a
## terra ve-se de lado) e o centro entre `y`. `folga` e a orla ate um caminho ou a beira.
const LAGO := {
	"passo": 1240.0, "rx": [70.0, 170.0], "ry": [13.0, 26.0], "y": [590.0, 640.0], "folga": 36.0
}
## A chance de um lago, por bioma: o alagado tem muitos, o vulcao quase nenhum.
const CHANCE_LAGO := {
	&"floodplain": 0.85,
	&"marsh": 0.9,
	&"coast": 0.6,
	&"ancient_forest": 0.55,
	&"glacier": 0.5,
	&"subterranean": 0.35,
	&"canyon": 0.2,
	&"volcanic": 0.15,
}
const CHANCE_LAGO_OMISSAO := 0.4
const SAL := {"lagos": 89, "caminhos": 97}
## Os sorteios de cada celula: se ha, onde, e a forma (o pe e a dobra de um caminho; a
## altura e os dois eixos de um lago).
const SORTEIOS := 5
const SORTE := 0
const SITIO := 1
const FUGA := 2
const DOBRA := 3
const LARGURA := 4
const MEIO := 0.5
const DOBRO := 2.0


## O centro de um caminho (x no topo, x no fundo, dobra) na altura `y`.
static func path_x(caminho: Vector3, y: float) -> float:
	var t := _descida(y)
	return lerpf(caminho.x, caminho.y, smoothstep(0.0, 1.0, t)) + sin(t * PI) * caminho.z


static func path_half(y: float) -> float:
	return lerpf(CAMINHO.topo, CAMINHO.fundo, _descida(y)) * MEIO


## Se `pe` cai num caminho ou num lago, com a orla.
static func blocked(pe: Vector2, caminhos: Array, lagos: Array) -> bool:
	for c: Vector3 in caminhos:
		if absf(pe.x - path_x(c, pe.y)) < path_half(pe.y) + LAGO.folga * MEIO:
			return true
	for l: Vector4 in lagos:
		var d := Vector2((pe.x - l.x) / (l.z + LAGO.folga), (pe.y - l.y) / (l.w + LAGO.folga))
		if d.length_squared() < 1.0:
			return true
	return false


## Os caminhos e os lagos que podem tocar o chao de `span.x` a `span.y`: o `blocked` de
## cada planta so pergunta a esses.
static func within(span: Vector2, caminhos: Array[Vector3], lagos: Array[Vector4]) -> Array:
	var alcance: float = CAMINHO.curva + CAMINHO.fundo + LAGO.folga
	var perto_c: Array[Vector3] = []
	for c in caminhos:
		if maxf(c.x, c.y) + alcance >= span.x and minf(c.x, c.y) - alcance <= span.y:
			perto_c.append(c)
	var perto_l: Array[Vector4] = []
	for l in lagos:
		if l.x + l.z + LAGO.folga >= span.x and l.x - l.z - LAGO.folga <= span.y:
			perto_l.append(l)
	return [perto_c, perto_l]


## Os caminhos do chao que vai de `chao.x` a `chao.y`, longe das `bocas`.
static func paths(chao: Vector2, regiao: int, bocas: PackedFloat32Array) -> Array[Vector3]:
	var saida: Array[Vector3] = []
	var passo: float = CAMINHO.passo
	for n in range(floori(chao.x / passo), floori(chao.y / passo) + 1):
		var d := RngService.scatter(hash([SAL.caminhos, regiao, n]), SORTEIOS)
		if d[SORTE] > CAMINHO.chance:
			continue
		var x := floorf((float(n) + Wilds.TREMOR.de + d[SITIO] * Wilds.TREMOR.largo) * passo)
		var pe := floorf(x + (d[FUGA] - MEIO) * DOBRO * CAMINHO.desvio)
		var margem: float = CAMINHO.margem + CAMINHO.fundo
		if minf(x, pe) < chao.x + margem or maxf(x, pe) > chao.y - margem:
			continue
		if _perto(x, bocas, CAMINHO.margem):
			continue
		saida.append(Vector3(x, pe, floorf((d[DOBRA] - MEIO) * DOBRO * CAMINHO.curva)))
	return saida


## Os lagos do chao, cada um com a chance do bioma em que cai (`chance.call(x)`), fora
## dos caminhos e da beira.
static func lakes(
	chao: Vector2, regiao: int, caminhos: Array[Vector3], chance: Callable
) -> Array[Vector4]:
	var saida: Array[Vector4] = []
	var passo: float = LAGO.passo
	for n in range(floori(chao.x / passo), floori(chao.y / passo) + 1):
		var d := RngService.scatter(hash([SAL.lagos, regiao, n]), SORTEIOS)
		var cx := floorf((float(n) + Wilds.TREMOR.de + d[SITIO] * Wilds.TREMOR.largo) * passo)
		var lago := Vector4(
			cx,
			floorf(lerpf(LAGO.y[0], LAGO.y[1], d[FUGA])),
			floorf(lerpf(LAGO.rx[0], LAGO.rx[1], d[DOBRA])),
			floorf(lerpf(LAGO.ry[0], LAGO.ry[1], d[LARGURA]))
		)
		var dentro := cx - lago.z - LAGO.folga > chao.x and cx + lago.z + LAGO.folga < chao.y
		if dentro and d[SORTE] <= float(chance.call(cx)) and not _no_caminho(lago, caminhos):
			saida.append(lago)
	return saida


## A chance de um lago num sitio que vai do bioma `de` ao `para`, a mistura `t`.
static func chance_of(de: StringName, para: StringName, t: float) -> float:
	var a: float = CHANCE_LAGO.get(de, CHANCE_LAGO_OMISSAO)
	var b: float = CHANCE_LAGO.get(para, CHANCE_LAGO_OMISSAO)
	return lerpf(a, b, t)


static func _descida(y: float) -> float:
	return clampf(inverse_lerp(float(Band.GROUND_LINE), float(Band.SCREEN_BOTTOM), y), 0.0, 1.0)


static func _perto(x: float, bocas: PackedFloat32Array, margem: float) -> bool:
	for boca in bocas:
		if absf(x - boca) <= margem:
			return true
	return false


static func _no_caminho(lago: Vector4, caminhos: Array[Vector3]) -> bool:
	for c in caminhos:
		for y in [lago.y - lago.w, lago.y, lago.y + lago.w]:
			if absf(path_x(c, y) - lago.x) - path_half(y) <= lago.z + LAGO.folga:
				return true
	return false
