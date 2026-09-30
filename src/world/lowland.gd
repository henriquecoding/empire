# src/world/lowland.gd — a terra por cima do corte de solo: o chao, e o que cresce nele,
# pela semente (o pedido do dono de 30/09/2026; §11; ADR 0039).
#
# O dono: "o subsolo so fica aparente ao acessa-lo; quero que tenha vegetacao aparente
# sempre, ou lagos, caminhos, dentre outras coisas". E a §11 ja o dizia: "a tela e
# dividida ao meio, em baixo e so paisagem". Isto diz o que ha nessa paisagem e onde
# (os caminhos e os lagos sao do LowlandLayout); o LowlandArt desenha-o e o SoilCover
# tira-o quando o rei desce.
#
# As plantas vem do Wilds, com o ruido do bosque — o MESMO do campo de cima, para o
# bosque descer da estrada e a clareira tambem. Nas terras geradas, as cores e as plantas
# passam de um povo para o outro como o chao delas (WildGround). Os caminhos estao presos
# as beiras do plano, e nao ao que ja foi gerado: um troco feito nao muda quando nasce o
# seguinte, e por isso as plantas de cada um guardam-se (a `cache` do `of`).
#
# Cenario: nada disto entra na simulacao nem no save.
class_name Lowland
extends RefCounted

## O que o `of` devolve.
const TROCOS := &"spans"
const CAMINHOS := &"paths"
const LAGOS := &"lakes"
const PLANTAS := &"plants"
## Um troco de chao: de onde a onde, os biomas das pontas, a mistura, e as cores delas.
const A := &"a"
const B := &"b"
const DE := &"from"
const PARA := &"to"
const MISTURA := &"mix"
const ESQ := &"left"
const DIR := &"right"

## O pe das plantas, da fila de tras (junto a estrada, fundo 1) a da frente (fundo 0), e
## a escala de cada metade: o que esta mais perto e maior.
const FILAS := {"tras": 536.0, "frente": 712.0, "perto": 0.5}
const ESCALAS := [3.0, 2.0]
## A erva e a pedra que ha em todo o lado, alem do campo do bioma; e o campo do bioma
## mais denso, porque aqui ha mais chao do que na faixa de cima.
const SEMPRE := [[Wilds.Plant.GRASS, 18.0, 0.0], [Wilds.Plant.ROCK, 170.0, 0.3]]
const DENSO := 0.7
const SAL := 83
## A fila de cada planta, em quantos degraus: e a ordem em que se desenham.
const FUNDOS := 32
const SEM_LAGO := -1.0


## A terra toda: os trocos de chao (a regiao e cada segmento gerado), os caminhos
## (Vector3: x no topo, x no fundo, dobra), os lagos (Vector4: centro e meios eixos) e,
## por troco, as plantas em quadruplos do Wilds (tipo, x, fundo, variante), de tras para
## a frente. `cache` guarda as plantas de cada troco entre chamadas.
static func of(
	terras: WildSegments,
	largura: float,
	regiao: int,
	bioma: StringName,
	bocas: PackedFloat32Array,
	cache: Dictionary = {}
) -> Dictionary:
	var trocos := spans(terras, largura, bioma)
	var chao := Vector2(0.0, largura)
	if terras != null and terras.width > 0.0:
		chao = terras.limits(largura)
	var caminhos := LowlandLayout.paths(chao, regiao, bocas)
	var chance := func(x: float) -> float: return _chance_em(trocos, x)
	var lagos := LowlandLayout.lakes(chao, regiao, caminhos, chance)
	var plantas: Array[PackedFloat32Array] = []
	for s in trocos:
		var span := Vector2(s[A], s[B])
		var perto := LowlandLayout.within(span, caminhos, lagos)
		var chave := [RngService.world_seed(), regiao, span, s[DE], s[PARA], s[MISTURA], perto]
		if not cache.has(chave):
			cache[chave] = _plantas(s, regiao, perto[0], perto[1])
		plantas.append(cache[chave])
	return {TROCOS: trocos, CAMINHOS: caminhos, LAGOS: lagos, PLANTAS: plantas}


## As bocas de onde nenhum caminho sai: as passagens da regiao.
static func avoided() -> PackedFloat32Array:
	return SimLoop.passages.duplicate()


## A regiao (nas cores de casa, com o campo do bioma dela) e cada segmento gerado, com as
## pontas do chao dele — na borda, so ate a beira.
static func spans(terras: WildSegments, largura: float, bioma: StringName) -> Array[Dictionary]:
	var casa := WildGround.colors({}, 0.0)
	var regiao := _troco(Vector2(0.0, largura), bioma, bioma, Vector2.ZERO, casa, casa)
	var saida: Array[Dictionary] = [regiao]
	if terras == null:
		return saida
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in terras.count(lado):
			var r := terras.at(lado, k)
			var p := WildGround.ends(terras, lado, k)
			var chao := WildGround.ground_span(r, lado, terras.x_of(lado, k, largura), terras.width)
			var de := StringName(r.get(WildSegments.DE, &""))
			var para := StringName(r.get(WildSegments.PARA, de))
			var cores := [WildGround.colors(r, p.x), WildGround.colors(r, p.y)]
			saida.append(_troco(chao, de, para, Vector2(p.x, p.y), cores[0], cores[1]))
	return saida


## As quatro cores do chao em `x` (campo, caminho, terra, rocha: as do WildGround); fora
## do chao ja gerado, as do troco mais perto.
static func colors_at(trocos: Array, x: float) -> Array[Color]:
	var s: Dictionary = trocos[0]
	for t: Dictionary in trocos:
		if _longe(t, x) < _longe(s, x):
			s = t
	var saida: Array[Color] = []
	for i in (s[ESQ] as Array).size():
		saida.append((s[ESQ][i] as Color).lerp(s[DIR][i], _onde(s, x)))
	return saida


## O pe de uma planta do fundo `fundo`, e a escala a que se desenha.
static func foot(x: float, fundo: float) -> Vector2:
	return Vector2(x, floorf(lerpf(FILAS.frente, FILAS.tras, fundo)))


static func scale_of(fundo: float) -> float:
	return ESCALAS[0] if fundo < FILAS.perto else ESCALAS[1]


static func _troco(
	chao: Vector2, de: StringName, para: StringName, mistura: Vector2, esq: Array, dir: Array
) -> Dictionary:
	return {A: chao.x, B: chao.y, DE: de, PARA: para, MISTURA: mistura, ESQ: esq, DIR: dir}


## A que distancia esta `x` do troco: zero dentro dele.
static func _longe(s: Dictionary, x: float) -> float:
	return maxf(0.0, maxf(s[A] - x, x - s[B]))


## Onde cai `x` no troco, de 0 (a ponta esquerda) a 1.
static func _onde(s: Dictionary, x: float) -> float:
	return clampf(inverse_lerp(s[A], s[B], x), 0.0, 1.0)


## A chance de um lago em `x`, pelo bioma do sitio; onde ainda nao ha chao, nenhuma.
static func _chance_em(trocos: Array, x: float) -> float:
	for s: Dictionary in trocos:
		if _longe(s, x) <= 0.0:
			var t := lerpf(s[MISTURA].x, s[MISTURA].y, _onde(s, x))
			return LowlandLayout.chance_of(s[DE], s[PARA], t)
	return SEM_LAGO


## O campo do bioma, mais denso, e a erva e a pedra de todo o lado.
static func _camadas(bioma: StringName) -> Array:
	var saida := []
	for c: Array in Wilds.table(Wilds.CAMPO, bioma):
		saida.append([c[0], c[1] * DENSO, c[2]])
	return saida + SEMPRE


## As plantas de um troco, de um bioma ou do outro pela mistura no sitio (WildGround),
## fora dos caminhos e da agua, e sem subir acima da linha onde se anda. Arrumadas por
## fila, de tras para a frente.
static func _plantas(
	s: Dictionary, regiao: int, caminhos: Array, lagos: Array
) -> PackedFloat32Array:
	var span := Vector2(s[A], s[B])
	var filas: Array[Array] = []
	for fila in FUNDOS:
		filas.append([])
	var pontas := [DE] if s[DE] == s[PARA] else [DE, PARA]
	for ponta in pontas:
		var camadas := _camadas(s[ponta])
		var todas := Wilds.plants(camadas, span.x, span.y, regiao, SAL, Wilds.woods())
		if pontas.size() > 1:
			todas = WildGround.half(todas, span, s[MISTURA], ponta == PARA)
		for i in range(0, todas.size(), Wilds.PLANTA):
			var pe := foot(todas[i + 1], todas[i + 2])
			var alto := FloraArt.height(int(todas[i])) * scale_of(todas[i + 2])
			var livre := not LowlandLayout.blocked(pe, caminhos, lagos)
			if livre and pe.y - alto >= float(Band.GROUND_LINE):
				var fila := mini(int(todas[i + 2] * FUNDOS), FUNDOS - 1)
				filas[fila].append_array(todas.slice(i, i + Wilds.PLANTA))
	var saida := PackedFloat32Array()
	for fila in range(FUNDOS - 1, -1, -1):
		saida.append_array(PackedFloat32Array(filas[fila]))
	return saida
