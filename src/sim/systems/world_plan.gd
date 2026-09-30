# src/sim/systems/world_plan.gd — quem mora onde no mundo continuo (o pedido do dono
# de 30/09/2026; §21; ADR 0038).
#
# "Entre as regioes devem haver caminhos e trilhas para fazerem transicoes suaves;
# parece que foi programado para pular de um ponto a outro." A regiao de casa fica
# ao centro e os outros povos da campanha ficam ao longo do mundo, pela ordem do
# plano e alternando de lado — o primeiro a leste, onde fica a bifurcacao, o segundo
# a oeste, e assim por diante. Cada terra tem antes dela um trilho e um limiar (§21:
# "a fronteira entre povos nunca e um fade"), e acaba na fortaleza do povo (§21:
# "uma nas extremidades da regiao"). Depois do ultimo povo de cada lado ha um trilho
# e a borda (§21: "uma regiao tem de terminar em alguma coisa"). O mundo e do tamanho
# da campanha: e esse o limite.
#
# Puro: quem chama da o comprimento de cada trilho, sorteado pelo sitio.
class_name WorldPlan
extends RefCounted

enum Zone { TRAIL, THRESHOLD, LAND, FORTRESS, EDGE }

const OESTE := -1
const LESTE := 1
## O povo da regiao de partida: o indice 0 do plano da campanha.
const CASA := 0
const MEIO := 0.5

## Por lado, de dentro para fora: a zona de cada segmento e o povo a que pertence.
## Num trilho o povo e o do fim dele — aquele para onde se vai. Arrays e nao
## PackedInt32Array: um Packed dentro de um Dictionary copia-se ao ser lido, e o
## append ficava na copia.
var zones := {OESTE: [], LESTE: []}
var peoples := {OESTE: [], LESTE: []}


## O plano de uma campanha com `povos` alem do de casa. `terra` e quantos segmentos
## tem a terra de cada um, a fortaleza incluida; `trilho` e um Callable(lado, j) que
## da o comprimento do j-esimo trilho daquele lado.
static func draw(povos: int, terra: int, trilho: Callable) -> WorldPlan:
	var plano := WorldPlan.new()
	for k in range(1, povos + 1):
		var lado := LESTE if k % 2 == 1 else OESTE
		plano._por(lado, Zone.TRAIL, k, int(trilho.call(lado, plano._trilhos(lado))))
		plano._por(lado, Zone.THRESHOLD, k, 1)
		plano._por(lado, Zone.LAND, k, maxi(0, terra - 1))
		plano._por(lado, Zone.FORTRESS, k, 1)
	for lado in [OESTE, LESTE]:
		var ultimo := plano.last_people(lado)
		plano._por(lado, Zone.TRAIL, ultimo, int(trilho.call(lado, plano._trilhos(lado))))
		plano._por(lado, Zone.EDGE, ultimo, 1)
	return plano


func size(lado: int) -> int:
	return (zones[lado] as Array).size()


func zone(lado: int, k: int) -> int:
	return int((zones[lado] as Array)[k])


func people(lado: int, k: int) -> int:
	return int((peoples[lado] as Array)[k])


## O povo da terra mais de fora de um lado, ou o de casa se o lado nao tem nenhum.
func last_people(lado: int) -> int:
	var ultimo := CASA
	for k in size(lado):
		if zone(lado, k) == Zone.THRESHOLD:
			ultimo = people(lado, k)
	return ultimo


## A transicao do segmento `k`: Vector3(povo de onde se vem, povo para onde se vai,
## quanto ja se foi de um para o outro, de 0 a 1). Fora dos trilhos nao ha mistura.
func between(lado: int, k: int) -> Vector3:
	var para := people(lado, k)
	if zone(lado, k) != Zone.TRAIL:
		return Vector3(para, para, 1.0)
	var trilho := _trilho(lado, k)
	var origem := people(lado, trilho.x - 1) if trilho.x > 0 else CASA
	var mistura := (float(k - trilho.x) + MEIO) / float(trilho.y - trilho.x + 1)
	return Vector3(origem, para, mistura)


## A mistura nas duas pontas do segmento `k`, de dentro para fora. Ao longo de um
## trilho vai de 0 (a terra de onde se vem) a 1 (a terra para onde se vai), e cada
## segmento acaba onde o seguinte comeca: sem degraus. Fora dos trilhos e 1 e 1.
func mix_ends(lado: int, k: int) -> Vector2:
	if k < 0 or k >= size(lado) or zone(lado, k) != Zone.TRAIL:
		return Vector2.ONE
	var trilho := _trilho(lado, k)
	var n := float(trilho.y - trilho.x + 1)
	return Vector2(float(k - trilho.x) / n, float(k - trilho.x + 1) / n)


## As pontas do segmento `k`, de dentro para fora: 1 onde ha trilho dos dois lados da
## ponta, 0 onde ela encosta a uma estrada — a da regiao, a de um limiar ou a da terra
## de um povo. O caminho estreita-se e alarga-se entre uma e outra, e nao aos saltos.
func trail_ends(lado: int, k: int) -> Vector2:
	var aqui := _estreito(lado, k)
	return Vector2(float(aqui and _estreito(lado, k - 1)), float(aqui and _estreito(lado, k + 1)))


func to_dict() -> Dictionary:
	return {
		&"west": PackedInt32Array(zones[OESTE]),
		&"west_people": PackedInt32Array(peoples[OESTE]),
		&"east": PackedInt32Array(zones[LESTE]),
		&"east_people": PackedInt32Array(peoples[LESTE]),
	}


## Um plano estragado ou de outra versao fica vazio, e o mundo e so a regiao (§62).
func from_dict(d: Dictionary) -> void:
	for lado in [OESTE, LESTE]:
		var nome := "west" if lado == OESTE else "east"
		var z: Variant = d.get(StringName(nome), [])
		var p: Variant = d.get(StringName(nome + "_people"), [])
		var certos: bool = _lista(z) and _lista(p) and z.size() == p.size()
		zones[lado] = Array(z) if certos else []
		peoples[lado] = Array(p) if certos else []


static func _lista(v: Variant) -> bool:
	return v is PackedInt32Array or v is Array


func _por(lado: int, zona: int, povo: int, quantos: int) -> void:
	for _k in maxi(0, quantos):
		(zones[lado] as Array).append(zona)
		(peoples[lado] as Array).append(povo)


## O trilho a que pertence o segmento `k`: Vector2i(o primeiro, o ultimo).
func _trilho(lado: int, k: int) -> Vector2i:
	var de := k
	while de > 0 and zone(lado, de - 1) == Zone.TRAIL:
		de -= 1
	var ate := k
	while ate + 1 < size(lado) and zone(lado, ate + 1) == Zone.TRAIL:
		ate += 1
	return Vector2i(de, ate)


## Se o caminho e estreito no segmento `k`: nos trilhos e na borda sim; na regiao, que
## fica para dentro do primeiro, nao; para la da borda nao ha mais nada que o alargue.
func _estreito(lado: int, k: int) -> bool:
	if k < 0:
		return false
	if k >= size(lado):
		return true
	return zone(lado, k) == Zone.TRAIL or zone(lado, k) == Zone.EDGE


func _trilhos(lado: int) -> int:
	var n := 0
	for k in size(lado):
		n += 1 if zone(lado, k) == Zone.THRESHOLD or zone(lado, k) == Zone.EDGE else 0
	return n
