# src/world/coin_art.gd — a moeda que se ve, e o que se larga (§02, §24; o dono, 02/10).
#
# A moeda era um circulo de 3 px de raio: seis pixeis de largo, contra uma tropa de
# 47 e um rei de 94, e a noite um ponto que nao se encontrava. O dono, a 02/10/2026:
# "as moedas e itens que sao dropados devem ser bem grandes para serem bem vistos
# como e em Kingdom, e devem ter fisica e parecer-se com o que sao".
#
# Aqui e uma moeda: um disco de ouro de 36 px em pixeis de 4 (o dobro, Q-192) — o aro
# escuro, a face, o brilho de cima e a sombra de baixo, e um cunho ao meio. Gira no ar
# (a largura da face vem do CoinBounce) e, de lado, e so o aro. Duas a nove moedas juntas sao uma
# PILHA de moedas deitadas; dez ou mais sao um SACO. No chao, de vez em quando, a
# moeda pisca — e esse brilho nao leva luz, como uma chama (§80): e por ele que se
# da com uma moeda no escuro. O ouro apanha a luz que houver, e guarda um pouco do
# seu mesmo longe dela.
#
# Os desenhos sao mapas de pixeis em constantes (o portao G4 quer os numeros la,
# §47): cada letra e um tom da PALETA.
class_name CoinArt
extends RefCounted

const PIXEL := 2.0
## O pixel do que cai no chao: o dobro do PIXEL. O dono, a 03/10/2026 (Q-192): "quero
## que o tamanho seja o dobro do atual". O preco (PriceTag) continua no PIXEL.
const CHAO := 4.0
## A moeda de pe, de frente: aro (#), face (o), brilho (+), sombra (.), cunho (=); o
## espaco e vazio.
const FACE := [
	"  #####  ",
	" #o+ooo# ",
	"#o++ooo.#",
	"#o+o=oo.#",
	"#oo===o.#",
	"#ooo=oo.#",
	"#oooo...#",
	" #oo...# ",
	"  #####  ",
]
## Uma moeda deitada, para as pilhas: a face de cima e o aro de lado.
const DEITADA := [
	" #ooo+o# ",
	"#oo+oooo#",
	"#########",
]
## O saco de couro atado, com ouro a boca: couro (b), escuro (d), claro (l), atilho (c).
const SACO := [
	"     #o#     ",
	"    #o+o#    ",
	"   #o+oo.#   ",
	"    dcccd    ",
	"     dbd     ",
	"    dbbbd    ",
	"   dbllbbd   ",
	"  dbllbbbbd  ",
	" dbllbbbbbbd ",
	"dbllbbbbbbbbd",
	"dblbbbbbbbbbd",
	"dbbbbbbbbbbdd",
	" dbbbbbbbbdd ",
	"  ddddddddd  ",
]
const PALETA := {
	"#": Color("8a5a16"),
	"o": Color("f2c140"),
	"+": Color("fff1a8"),
	".": Color("c98f22"),
	"=": Color("d9a12c"),
	"b": Color("8a5a32"),
	"d": Color("5a3a20"),
	"l": Color("b07a48"),
	"c": Color("3a2614"),
}
## Quantas moedas juntas ja sao um saco, e quantas deitadas se desenham numa pilha.
const SACO_DE := 10
const PILHA_MAX := 6
## Quanto cada moeda deitada sobe sobre a de baixo, e quanto se desencontra.
const PILHA_PASSO := 2.0
const PILHA_DESVIO := [0, 1, -1, 1, 0, -1]
## Abaixo desta largura a moeda esta de lado, e o que se ve e o aro.
const DE_LADO := 0.25
## O ouro guarda isto da sua cor longe de qualquer luz.
const PROPRIO := 0.4
## O brilho no chao: de quanto em quanto tempo, quanto dura, e o desfasamento por
## moeda; e a cor, que nao leva luz.
const BRILHO := {"cada": 2.6, "dura": 0.28, "desfasa": 0.61}
const FAISCA := Color("fff8d8")
const MEIO := 0.5

static var _spans: Dictionary = {}


## O tamanho do que se desenha para esta quantia, em px: e o que a sombra mede.
static func size_of(quantia: int) -> Vector2:
	var mapa := _mapa(quantia)
	var alto := float(mapa.size())
	if quantia > 1 and quantia < SACO_DE:
		alto += PILHA_PASSO * float(mini(quantia, PILHA_MAX) - 1)
	return Vector2(float(String(mapa[0]).length()), alto) * CHAO


## Uma moeda (ou pilha, ou saco) com o pe em `pe`. `face` e a largura que se ve (1
## de frente); `cor` pinta cada tom com a luz que la chega.
static func draw_on(
	canvas: CanvasItem, pe: Vector2, quantia: int, face: float, cor: Callable, brilho: float
) -> void:
	var mapa := _mapa(quantia)
	var tons := tones(cor)
	if quantia > 1 and quantia < SACO_DE:
		for k in mini(quantia, PILHA_MAX):
			var desvio := float(PILHA_DESVIO[k % PILHA_DESVIO.size()]) * CHAO
			var em := pe + Vector2(desvio, -PILHA_PASSO * CHAO * float(k))
			paint(canvas, em, mapa, 1.0, tons, CHAO)
	elif face < DE_LADO and quantia <= 1:
		var alto := float(FACE.size()) * CHAO
		canvas.draw_rect(Rect2(pe - Vector2(CHAO * MEIO, alto), Vector2(CHAO, alto)), tons["#"])
	elif quantia >= SACO_DE:
		paint(canvas, pe, mapa, 1.0, tons, CHAO)  # um saco nao gira: tomba
	else:
		paint(canvas, pe, mapa, maxf(face, DE_LADO), tons, CHAO)
	if brilho > 0.0:
		var topo := pe - Vector2(size_of(quantia).x * MEIO * MEIO, size_of(quantia).y * MEIO)
		sparkle(canvas, topo, brilho, CHAO)


## Quanto brilha agora uma moeda pousada (0 a 1): de BRILHO.cada em BRILHO.cada
## segundos, desencontrada das outras pelo id.
static func glint(coin_id: int, agora: float) -> float:
	var t := fposmod(agora + float(coin_id) * BRILHO.desfasa, BRILHO.cada)
	if t >= BRILHO.dura:
		return 0.0
	return sin(PI * t / BRILHO.dura)


## A faisca: uma cruz de quatro pontas, maior no meio do brilho. Nao leva luz.
static func sparkle(canvas: CanvasItem, centro: Vector2, forca: float, px := PIXEL) -> void:
	var cor := Color(FAISCA, forca)
	var braco := roundf(forca * px * px)
	canvas.draw_rect(Rect2(centro - Vector2(px, px) * MEIO, Vector2(px, px)), cor)
	canvas.draw_rect(Rect2(centro - Vector2(braco, px * MEIO), Vector2(braco * 2, px)), cor)
	canvas.draw_rect(Rect2(centro - Vector2(px * MEIO, braco), Vector2(px, braco * 2)), cor)


## A cor de um tom de ouro com a luz da noite: a que la chega, sem nunca perder
## de todo a sua (PROPRIO).
static func lit(luz: Lighting, x: float) -> Callable:
	return func(c: Color) -> Color: return luz.body(c, x).lerp(c, PROPRIO)


## Cada letra de `paleta` ja com a luz que la chega.
static func tones(cor: Callable, paleta := PALETA) -> Dictionary:
	var tons := {}
	for letra: String in paleta:
		tons[letra] = cor.call(paleta[letra])
	return tons


static func _mapa(quantia: int) -> Array:
	if quantia >= SACO_DE:
		return SACO
	return DEITADA if quantia > 1 else FACE


## Um mapa com o pe ao meio de baixo, apertado na largura por `face`, em pixeis de `px`.
## As letras que nao estao em `tons` sao vazio.
static func paint(
	canvas: CanvasItem, pe: Vector2, mapa: Array, face: float, tons: Dictionary, px := PIXEL
) -> void:
	var largo := float(String(mapa[0]).length())
	var alto := float(mapa.size())
	canvas.draw_set_transform(pe.round(), 0.0, Vector2(face, 1.0))
	for linha in mapa.size():
		var y := (float(linha) - alto) * px
		for span: Vector3i in _linha(mapa, linha):
			var x := (float(span.x) - largo * MEIO) * px
			var letra := String(mapa[linha])[span.x]
			if tons.has(letra):
				canvas.draw_rect(Rect2(x, y, float(span.y) * px, px), tons[letra])
	canvas.draw_set_transform(Vector2.ZERO)


## Os trocos da mesma letra numa linha do mapa: (inicio, largura, 0). Calcula-se uma
## vez por mapa e fica.
static func _linha(mapa: Array, linha: int) -> Array[Vector3i]:
	var chave := "%d:%s" % [linha, mapa[linha]]
	if _spans.has(chave):
		return _spans[chave]
	var spans: Array[Vector3i] = []
	var texto := String(mapa[linha])
	var i := 0
	while i < texto.length():
		var j := i
		while j < texto.length() and texto[j] == texto[i]:
			j += 1
		if texto[i] != " ":
			spans.append(Vector3i(i, j - i, 0))
		i = j
	_spans[chave] = spans
	return spans
