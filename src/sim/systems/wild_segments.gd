class_name WildSegments
extends RefCounted

const VERSAO := 1
## Dentro do segmento de borda, a quantos px da terra de dentro fica a beira.
const BORDO_PX := 256.0
## Por segmento: o tipo, a variante, o sitio do assunto e a semente da decoracao.
const SORTEIOS := 4
const U_TIPO := 0
const U_VARIANTE := 1
const U_SITIO := 2
const U_SEMENTE := 3
const ESCALA_SEMENTE := 16777216.0
## O assunto fica longe das pontas do segmento (§21: uma coisa em que o olho pousa).
const MARGEM := 0.25
const TIPO_DA_ZONA := {1: &"threshold", 2: &"settlement", 3: &"fortress", 4: &"edge"}
const ACAMPAMENTO := &"vagrant_camp"
const MERCENARIOS := &"mercenary_camp"
## As chaves de cada segmento gravado.
const ZONA := &"zone"
const POVO := &"people"
const DE := &"from"
const PARA := &"to"
const MISTURA := &"mix"
const TIPO := &"kind"
const ID := &"id"
const ASSUNTO := &"subject"
const SITIO := &"at"
const SEMENTE := &"seed"
const PASSAGEM := &"passages"

var plan := WorldPlan.new()
var width := 0.0
## Sobe a cada segmento novo e a cada save lido: quem desenha sabe quando redesenhar.
var revision := 0
var _biome_peoples: Dictionary = {}
var _kit: Array[SegmentData] = []
var _registos := {WorldPlan.OESTE: [], WorldPlan.LESTE: []}


func _init(kit: Array[SegmentData] = [], biome_peoples: Dictionary = {}) -> void:
	_biome_peoples = biome_peoples.duplicate()
	_kit = kit.duplicate()
	_kit.sort_custom(
		func(a: SegmentData, b: SegmentData) -> bool: return String(a.id) < String(b.id)
	)


## Um mundo novo: o plano, a largura de um segmento, e nada gerado ainda.
func setup(plano: WorldPlan, largura_segmento: float) -> void:
	plan = plano
	width = largura_segmento
	_registos = {WorldPlan.OESTE: [], WorldPlan.LESTE: []}
	revision += 1


func count(lado: int) -> int:
	return (_registos[lado] as Array).size()


func at(lado: int, k: int) -> Dictionary:
	return (_registos[lado] as Array)[k]


func full(lado: int) -> bool:
	return count(lado) >= plan.size(lado)


## Gera o segmento seguinte de um lado e devolve-o, ou {} se o lado ja chegou a borda.
func grow(
	lado: int,
	sorteios: PackedFloat32Array,
	clima: float,
	cluster: float,
	biomas: PackedStringArray,
	bordas: Dictionary
) -> Dictionary:
	if full(lado) or sorteios.size() < SORTEIOS or width <= 0.0:
		return {}
	var k := count(lado)
	var zona := plan.zone(lado, k)
	var entre := plan.between(lado, k)
	var bioma := _bioma(biomas, int(entre.y))
	var native := bioma
	if zona == WorldPlan.Zone.TRAIL and entre.z < BuildSystem.METADE:
		native = _bioma(biomas, int(entre.x))
	var kit: Array[SegmentData] = []
	for data in _kit:
		if _biome_peoples.is_empty() or data.people == _biome_peoples.get(native, &"enramados"):
			kit.append(data)
	var linha: SegmentData = null
	if zona == WorldPlan.Zone.TRAIL:
		var fim := _falta_encontro(lado, k)
		var antes := _tipos(lado)
		var vizinho: StringName = at(lado, k - 1)[ID] if k > 0 else &""
		var u := [sorteios[U_TIPO], sorteios[U_VARIANTE]]
		linha = TrailPick.choose(kit, antes, vizinho, clima, cluster, u[0], u[1], fim)
	elif zona == WorldPlan.Zone.EDGE:
		linha = TrailPick.edge(kit, StringName(bordas.get(bioma, &"")), sorteios[U_VARIANTE])
	else:
		var linhas := TrailPick.of_kind(kit, TIPO_DA_ZONA[zona])
		linha = TrailPick.variant(linhas, sorteios[U_VARIANTE], &"")
	if linha == null:
		return {}
	var registo := {
		ZONA: zona,
		POVO: int(entre.y),
		DE: _bioma(biomas, int(entre.x)),
		PARA: bioma,
		MISTURA: entre.z,
		TIPO: linha.kind,
		ID: linha.id,
		ASSUNTO: linha.subject,
		SITIO: sorteios[U_SITIO],
		SEMENTE: int(sorteios[U_SEMENTE] * ESCALA_SEMENTE),
		PASSAGEM: linha.passages,
	}
	(_registos[lado] as Array).append(registo)
	revision += 1
	return registo


func x_of(lado: int, k: int, largura: float) -> float:
	return largura + float(k) * width if lado == WorldPlan.LESTE else -float(k + 1) * width


func subject_x(lado: int, k: int, largura: float) -> float:
	var sitio := lerpf(MARGEM, 1.0 - MARGEM, float(at(lado, k)[SITIO]))
	return x_of(lado, k, largura) + width * sitio


## Quantos segmentos tem de haver de um lado para o rei em `x` ver `alcance` px a frente.
func needed(lado: int, x: float, largura: float, alcance: float) -> int:
	if width <= 0.0:
		return 0
	var alem := x - largura if lado == WorldPlan.LESTE else -x
	return clampi(ceili((alem + alcance) / width), 0, plan.size(lado))


## Onde se pode andar: da beira de uma borda a beira da outra (ou so a regiao).
func limits(largura: float) -> Vector2:
	var w := plan.size(WorldPlan.OESTE)
	var e := plan.size(WorldPlan.LESTE)
	var oeste := -float(w - 1) * width - BORDO_PX if w > 0 else 0.0
	var leste := largura + float(e - 1) * width + BORDO_PX if e > 0 else largura
	return Vector2(oeste, leste)


## O que ja foi gerado, em x de mundo: a camara nunca mostra para la disto.
func extent(largura: float) -> Vector2:
	return Vector2(-float(count(WorldPlan.OESTE)) * width, largura + count(WorldPlan.LESTE) * width)


## A maior distancia, alem das bordas da regiao, a que se pode andar.
func reach(largura: float) -> float:
	var limites := limits(largura)
	return maxf(-limites.x, limites.y - largura)


func camps(largura: float) -> PackedFloat32Array:
	return _onde(
		largura,
		func(r: Dictionary) -> bool: return r[TIPO] == ACAMPAMENTO and not r.get(&"deserted", false)
	)


func mercenaries(largura: float) -> PackedFloat32Array:
	return _onde(
		largura,
		func(r: Dictionary) -> bool: return r[TIPO] == MERCENARIOS and not r.get(&"deserted", false)
	)


## As bocas das masmorras: os segmentos cuja linha traz uma passagem (§21, a ruina).
func dungeons(largura: float) -> PackedFloat32Array:
	return _onde(largura, func(r: Dictionary) -> bool: return int(r.get(PASSAGEM, 0)) > 0)


## Vector2i(lado, indice) do segmento gerado em que `x` cai, ou (0, -1).
func find(x: float, largura: float) -> Vector2i:
	if width <= 0.0 or (x >= 0.0 and x <= largura):
		return Vector2i(0, -1)
	var lado := WorldPlan.LESTE if x > largura else WorldPlan.OESTE
	var k := floori((x - largura) / width) if lado == WorldPlan.LESTE else floori(-x / width)
	return Vector2i(lado, k) if k < count(lado) else Vector2i(0, -1)


func to_dict() -> Dictionary:
	return {
		&"v": VERSAO,
		&"width": width,
		&"plan": plan.to_dict(),
		&"west": (_registos[WorldPlan.OESTE] as Array).duplicate(true),
		&"east": (_registos[WorldPlan.LESTE] as Array).duplicate(true),
	}


## Um save de antes do mundo continuo nao tem terras: fica o plano de agora (§62).
func from_dict(d: Dictionary) -> void:
	revision += 1
	var registos := {WorldPlan.OESTE: [], WorldPlan.LESTE: []}
	if d.has(&"plan") and d[&"plan"] is Dictionary:
		var p := WorldPlan.new()
		p.from_dict(d[&"plan"])
		plan = p
		width = float(d.get(&"width", width))
		for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
			var lista: Variant = d.get(&"west" if lado == WorldPlan.OESTE else &"east", [])
			for r: Variant in lista if lista is Array else []:
				if r is Dictionary and r.has(TIPO):
					registos[lado].append(r)
	_registos = registos


func _falta_encontro(lado: int, k: int) -> bool:
	if k + 1 < plan.size(lado) and plan.zone(lado, k + 1) == WorldPlan.Zone.TRAIL:
		return false
	var j := k - 1
	while j >= 0 and plan.zone(lado, j) == WorldPlan.Zone.TRAIL:
		if TrailPick.encounter(_kit, at(lado, j)[TIPO]):
			return false
		j -= 1
	return true


func _onde(largura: float, serve: Callable) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in count(lado):
			if serve.call(at(lado, k)):
				saida.append(subject_x(lado, k, largura))
	return saida


static func _bioma(biomas: PackedStringArray, povo: int) -> StringName:
	return StringName(biomas[povo]) if povo >= 0 and povo < biomas.size() else &""


func _tipos(lado: int) -> Array:
	return (_registos[lado] as Array).map(func(r: Dictionary) -> StringName: return r[TIPO])
