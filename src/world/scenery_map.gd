# src/world/scenery_map.gd — que cena pintada cobre cada troco do mundo, e que fundo se ve
# de onde esta a camara (a entrega de cenarios em camadas de 08/10/2026; ADR 0081).
#
# O chao e o fundo pintados vem por povo (um reino por bioma) e por fronteira (uma
# transicao por par de biomas). O WorldPlan ja diz quem mora onde; aqui le-se isso como
# trocos de chao. O trilho e ainda da terra de onde se vem, e a terra muda no limiar —
# §21: «a fronteira entre povos nunca e um fade: e um portao, uma ponte, uma falha na
# rocha». Onde ha transicao pintada para o par, ela fica centrada nessa fronteira e os
# reinos encostam-se a ela; onde nao ha, os dois reinos encontram-se na fronteira.
#
# O fundo vive em parallax, e um plano distante nao tem sitio no mundo: escolhe-se pela
# camara — o reino de onde ela esta e, perto de uma fronteira, os dois misturados.
class_name SceneryMap
extends RefCounted

const CENA := &"scene"
const DE := &"from"
const ATE := &"to"
## O x do mundo onde comeca um quadro da cena: o mosaico de um reino conta-se do 0, para
## dois trocos do mesmo reino continuarem um no outro; a transicao, da fronteira.
const ORIGEM := &"origin"
## Quanto de uma transicao fica para cada lado da fronteira (Vector2, px de mundo).
const MEIA := &"half"
## Se o troco e uma transicao, centrada numa fronteira.
const LIMIAR := &"border"
const X := &"x"
const ESQUERDA := &"left"
const DIREITA := &"right"
const A := &"a"
const B := &"b"
const T := &"t"
## Meia largura da mistura do fundo, em px de mundo: o `background_mix_interval` das
## transicoes (de 400 a 880 num quadro de 1280, com a fronteira aos 640).
const MISTURA := 240.0

var stretches: Array[Dictionary] = []
var borders: Array[Dictionary] = []
var _trocos: Array[Dictionary] = []


## A chave de um par em `pares`: quem fica a esquerda e quem fica a direita.
static func key(esquerda: StringName, direita: StringName) -> String:
	return "%s>%s" % [esquerda, direita]


## Os trocos de chao do mundo, de oeste para leste, cada um com o seu bioma: a regiao de
## casa e cada segmento gerado (a borda so ate a beira). Os seguidos do mesmo bioma juntam-se.
static func runs(terras: WildSegments, largura: float, casa: StringName) -> Array[Dictionary]:
	var todos: Array[Dictionary] = [_troco(0.0, largura, casa)]
	if terras != null:
		for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
			for k in terras.count(lado):
				var registo := terras.at(lado, k)
				var x0 := terras.x_of(lado, k, largura)
				var span := WildGround.ground_span(registo, lado, x0, terras.width)
				todos.append(_troco(span.x, span.y, biome_of(registo)))
	todos.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p[DE] < q[DE])
	var juntos: Array[Dictionary] = []
	for t in todos:
		var ultimo: Dictionary = juntos.back() if not juntos.is_empty() else {}
		if (
			not ultimo.is_empty()
			and ultimo[CENA] == t[CENA]
			and is_equal_approx(ultimo[ATE], t[DE])
		):
			ultimo[ATE] = t[ATE]
		else:
			juntos.append(t)
	return juntos


## O bioma que o chao de um segmento mostra: num trilho, o da terra de onde se vem.
static func biome_of(registo: Dictionary) -> StringName:
	var trilho := int(registo.get(WildSegments.ZONA, -1)) == WorldPlan.Zone.TRAIL
	return StringName(registo.get(WildSegments.DE if trilho else WildSegments.PARA, &""))


## O mapa a partir dos trocos. `pares` diz, por `key(esquerda, direita)`, a transicao
## pintada desse par: Dictionary(CENA, MEIA). So entra onde cabe inteira entre as duas
## fronteiras vizinhas.
static func of(trocos: Array[Dictionary], pares: Dictionary) -> SceneryMap:
	var mapa := SceneryMap.new()
	mapa._trocos = trocos.duplicate(true)
	var lista: Array[Dictionary] = trocos.duplicate(true)
	var pintadas: Array[Dictionary] = []
	for i in range(1, lista.size()):
		var a := lista[i - 1]
		var b := lista[i]
		if a[CENA] == b[CENA] or not is_equal_approx(a[ATE], b[DE]):
			continue
		var x: float = b[DE]
		mapa.borders.append({X: x, ESQUERDA: a[CENA], DIREITA: b[CENA]})
		var par: Dictionary = pares.get(key(a[CENA], b[CENA]), {})
		if par.is_empty():
			continue
		var meia: Vector2 = par[MEIA]
		if x - meia.x < a[DE] or x + meia.y > b[ATE]:
			continue
		a[ATE] = x - meia.x
		b[DE] = x + meia.y
		pintadas.append({CENA: par[CENA], DE: a[ATE], ATE: b[DE], ORIGEM: a[ATE], LIMIAR: true})
	for t in lista:
		if t[ATE] > t[DE]:
			t[ORIGEM] = 0.0
			t[LIMIAR] = false
			mapa.stretches.append(t)
	mapa.stretches.append_array(pintadas)
	mapa.stretches.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p[DE] < q[DE])
	return mapa


## Os trocos que tocam a janela de `de` a `ate`, de oeste para leste.
func within(de: float, ate: float) -> Array[Dictionary]:
	return stretches.filter(func(t: Dictionary) -> bool: return t[ATE] > de and t[DE] < ate)


## O fundo com a camara em `x`: o reino de um lado (A), o do outro (B) e quanto do segundo
## se ve (T, de 0 a 1). Longe das fronteiras A e B sao o mesmo e T e 0.
func blend(x: float) -> Dictionary:
	for f in borders:
		var d: float = x - f[X]
		if absf(d) < MISTURA:
			return {A: f[ESQUERDA], B: f[DIREITA], T: smoothstep(-MISTURA, MISTURA, d)}
	var aqui := biome_at(x)
	return {A: aqui, B: aqui, T: 0.0}


## O bioma do troco onde esta `x`; fora do que ja ha, o da ponta mais perto.
func biome_at(x: float) -> StringName:
	if _trocos.is_empty():
		return &""
	for t in _trocos:
		if x < t[ATE]:
			return t[CENA]
	return _trocos.back()[CENA]


## Se o x cai numa fronteira com transicao pintada: o limiar ja tem o marco dela.
func painted_border(x: float) -> bool:
	for t in stretches:
		if t[LIMIAR] and x >= t[DE] and x < t[ATE]:
			return true
	return false


static func _troco(de: float, ate: float, cena: StringName) -> Dictionary:
	return {CENA: cena, DE: de, ATE: ate}
