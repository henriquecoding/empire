# src/core/wild_hunt.gd — a caca das terras geradas e o ritmo de cada bicho (Q-217,
# ADR 0058).
#
# O WildBurrows e puro; isto le os dados, o RngService e o mundo. Cada segmento de
# trilho que nasce ao andar ganha as suas tocas, sorteadas pelo SITIO (lado e indice),
# como o Frontier sorteia o resto do segmento: o mesmo segmento da as mesmas tocas. Os
# bichos ja la estao quando o rei chega — nao nascem a frente dele —, e cada toca volta a
# dar o seu bicho `respawn_s` segundos de luz depois de ele sair, varias vezes por dia e
# nunca de noite. Os cacadores de casa ficam na regiao (HuntingSystem.home).
class_name WildHunt
extends RefCounted

const SAL := 211
const TABELA := &"wildlife"
const METADE := 0.5

## O ritmo de cada bicho por duracao do dia: pedido a cada tick, lido dos dados uma vez.
static var _ritmos := {}


## O HuntWatch.prepare, e a seguir as terras que ja existiam ganham as tocas delas: as
## de casa vem primeiro: o coelho inicia a renda nos prados, fora da Clareira (ADR 0062).
static func prepare(campo: FieldWork, dia: int, core_x: float, largura: float, fase: int) -> void:
	var antes := campo.hunting.burrows.placed()
	HuntWatch.prepare(campo.hunting, dia, core_x, largura, fase)
	campo.hunting.home = Vector2(0.0, largura)
	HuntHabitats.reserve(campo.hunting, SimLoop.builds)
	if antes or not campo.hunting.burrows.placed():
		return
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in campo.wilds.count(lado):
			author(campo, lado, k, largura)


## As tocas do segmento `k` do `lado`, se ainda la nao estao, com o bicho ja a porta.
static func author(campo: FieldWork, lado: int, k: int, largura: float) -> void:
	var hunt := campo.hunting
	var terras := campo.wilds
	if not hunt.burrows.placed() or terras.width <= 0.0:
		return
	var registo := terras.at(lado, k)
	if int(registo[WildSegments.ZONA]) != WorldPlan.Zone.TRAIL:
		return
	var inicio := terras.x_of(lado, k, largura)
	var span := Vector2(inicio, inicio + terras.width)
	var bichos: Array[WildlifeData] = []
	for dados in species(_bioma(registo)):
		if HuntHabitats.supports(dados, span, largura * METADE):
			bichos.append(dados)
	var tocas := WildBurrows.draw(
		inicio,
		terras.width,
		terras.subject_x(lado, k, largura),
		StringName(registo[WildSegments.TIPO]),
		bichos,
		RngService.scatter(hash([SAL, lado, k]), WildBurrows.SORTEIOS),
		k == 0
	)
	var ritmos := rhythms(ClockService.clock.day_seconds() if ClockService.clock else 0.0)
	for toca in tocas:
		var x: float = toca[WildBurrows.X]
		if hunt.burrows.xs.has(x):
			continue
		var bicho := StringName(toca[WildBurrows.BICHO])
		hunt.burrows.add(x, float(ritmos.get(bicho, 0.0)), String(toca[WildBurrows.SITIO]), bicho)
		HuntHabitats.reserve(hunt, SimLoop.builds)
		if hunt.burrows.alive[hunt.burrows.xs.size() - 1] == 0:
			continue
		if not hunt.rabbits.has(x):
			hunt.rabbits.append(x)
			hunt.herd.arrive(x)


## Os segundos de luz entre dois bichos da mesma toca, por bicho (id -> s), num dia de
## `dia_s` segundos: num dia mais longo, o bicho volta no mesmo PONTO do dia.
static func rhythms(dia_s: float) -> Dictionary:
	if _ritmos.has(dia_s):
		return _ritmos[dia_s]
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var escala := dia_s / relogio.day_seconds if dia_s > 0.0 else 1.0
	var saida := {}
	for recurso in Registry.entries(TABELA):
		var dados := recurso as WildlifeData
		if dados.respawn_s > 0.0:
			saida[dados.id] = dados.respawn_s * escala
	_ritmos[dia_s] = saida
	return saida


## Os bichos que vivem no `bioma` e saem de tocas nas terras, do mais miudo para o mais
## caro: o coelho primeiro, como nas tocas de casa.
static func species(bioma: StringName) -> Array[WildlifeData]:
	var saida: Array[WildlifeData] = []
	for recurso in Registry.entries(TABELA):
		var dados := recurso as WildlifeData
		if dados.per_segment_max > 0 and dados.biomes.has(bioma):
			saida.append(dados)
	saida.sort_custom(HuntWatch.cheaper)
	return saida


## A metade de perto de um trilho e do povo de onde se vem; a de longe, do outro (§21).
static func _bioma(registo: Dictionary) -> StringName:
	var mistura := float(registo.get(WildSegments.MISTURA, 1.0))
	return StringName(registo[WildSegments.DE] if mistura < METADE else registo[WildSegments.PARA])
