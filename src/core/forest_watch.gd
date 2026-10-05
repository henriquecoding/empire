# src/core/forest_watch.gd — plantar a floresta do mundo (ADR 0070).
#
# A floresta de casa planta-se uma vez por partida, no primeiro passo, quando ja ha
# passagens, provisoes, acampamentos, estatuas e tocas; as das terras geradas
# plantam-se quando o segmento nasce (Frontier). Antes da floresta reserva-se o que o
# mapa precisa; depois a densidade do bosque (Woods) e a especie de cada bioma enchem
# o resto; por fim, cada toca que vive de arvores ganha o abrigo que a regra pede.
#
# Num segmento de transicao as duas pontas pesam como no chao (WildGround): a especie
# de cada celula sai do bioma de onde se vem ou do bioma para onde se vai, pelo peso
# da mistura no sitio dela, e a densidade minima mistura-se pelo mesmo peso.
#
# Um save de antes da floresta planta-a ao carregar, sem nunca por uma arvore em cima
# do que ja esta construido nem dentro da clareira da sede.
class_name ForestWatch
extends RefCounted

const HOME := 0
const SAL := 241
const SAL_ESPECIE := 243
## A orla do bosque: quanto acima do minimo a densidade tem de ir para a arvore ser
## certa, e a probabilidade logo acima dele (a mesma lei do cenario, Wilds).
const ORLA := {"largo": 0.35, "piso": 0.15}
const ARVORE := &"tree"
## A zona dos ids das arvores postas para abrigar uma toca.
const ZONA_ABRIGO := 99
const ABRIGOS_POR_TOCA := 8
## Os sorteios de cada celula: a orla, o bioma da mistura e a especie.
const SORTEIOS := 3
const QUAL := 2
## [de, para, mistura a esquerda, mistura a direita]: os indices das misturas.
const MISTURA_A := 2
const MISTURA_B := 3
const MEIO := 0.5
const SEM_ARVORES := WorldPlan.Zone.EDGE


static func rules() -> ForestRules:
	return Registry.entry(&"economy", &"forest") as ForestRules


static func flora() -> Array:
	return Registry.entries(&"flora")


## As especies que crescem em `biome`.
static func of_biome(biome: StringName) -> Array[FloraData]:
	var saida: Array[FloraData] = []
	for especie: FloraData in flora():
		if especie.biomes.has(biome):
			saida.append(especie)
	return saida


## A floresta de casa, uma vez. Chamado em cada passo; so trabalha da primeira vez.
static func ensure(field: FieldWork) -> void:
	var w := field.woodland
	if w.generated or SimLoop.world_width <= 0.0 or SimLoop.state == null:
		return
	var regras := rules()
	var reservado := _home_reserved(field, regras.reserve_px)
	var bioma := _home_biome()
	_plant(w, HOME, Vector2(0.0, SimLoop.world_width), [bioma, bioma, 0.0, 0.0], reservado)
	_groves(field, Vector2(0.0, SimLoop.world_width), reservado)
	w.generated = true
	w.version = regras.generator_version


## As arvores de um segmento gerado, quando nasce ou quando um save antigo o traz.
static func zone(field: FieldWork, side: int, k: int) -> void:
	var w := field.woodland
	var chave := "%d:%d" % [side, k]
	if w.zones.has(chave) or field.wilds.width <= 0.0:
		return
	w.zones[chave] = true
	var r := field.wilds.at(side, k)
	if int(r[WildSegments.ZONA]) == SEM_ARVORES:
		return
	var x0 := field.wilds.x_of(side, k, SimLoop.world_width)
	var span := Vector2(x0, x0 + field.wilds.width)
	var m := field.wilds.plan.mix_ends(side, k)
	var pontas := Vector2(m.x, m.y) if side == WorldPlan.LESTE else Vector2(m.y, m.x)
	var reservado := _zone_reserved(field, side, k, rules().reserve_px)
	var biomas := [StringName(r[WildSegments.DE]), StringName(r[WildSegments.PARA])]
	biomas.append_array([pontas.x, pontas.y])
	_plant(w, 1 + 2 * k + (1 if side == WorldPlan.LESTE else 0), span, biomas, reservado)
	_groves(field, span, reservado)


## `biomas`: [de, para, mistura a esquerda, mistura a direita] do intervalo `span`.
static func _plant(w: Woodland, zona: int, span: Vector2, biomas: Array, reservado: Array) -> void:
	var regras := rules()
	var ruido := Woods.noise()
	var desvio := float(SimLoop.state.region) * Woods.TROCO
	var roll := func(celula: int) -> Array:
		return Array(RngService.scatter(hash([SAL, zona, celula]), 1))
	var pick := func(celula: int, x: float) -> StringName:
		var d := RngService.scatter(hash([SAL_ESPECIE, zona, celula]), SORTEIOS)
		var t := lerpf(
			float(biomas[MISTURA_A]), float(biomas[MISTURA_B]), (x - span.x) / (span.y - span.x)
		)
		var lista := of_biome(biomas[1] if d[1] < t else biomas[0])
		if lista.is_empty():
			return &""
		var especie := lista[mini(floori(d[QUAL] * lista.size()), lista.size() - 1)]
		var acima := Woods.density(ruido, x + desvio) - especie.density_min
		if acima < 0.0 or d[0] > ORLA.piso + acima / ORLA.largo:
			return &""
		return especie.id
	var arvores := ForestPlan.place(
		zona, span.x, span.y, regras.tree_step_px, roll, pick, reservado
	)
	for a: Array in arvores:
		w.plant(int(a[0]), float(a[1]), StringName(a[2]))


## Cada toca que vive de arvores (a do veado) nasce com o abrigo que a regra pede.
static func _groves(field: FieldWork, span: Vector2, reservado: Array) -> void:
	var regras := rules()
	var w := field.woodland
	var abrigo := Influence.kinds(flora(), Influence.SHELTER)
	var tocas := field.hunting.burrows
	for k in tocas.xs.size():
		var x: float = tocas.xs[k]
		if tocas.kinds[k] != String(ARVORE) or x < span.x or x >= span.y:
			continue
		var especies := of_biome(_biome_at(field, x))
		var sombra: Array[FloraData] = []
		for e in especies:
			if abrigo.has(e.id):
				sombra.append(e)
		if sombra.is_empty():
			continue
		var tem := w.count_near(x, regras.shelter_radius, abrigo)
		var sitios := ForestPlan.grove(
			x, regras.shelter_radius, regras.shelter_min, tem, regras.tree_step_px, reservado
		)
		for s in sitios.size():
			var id := ForestPlan.id_of(ZONA_ABRIGO, k * ABRIGOS_POR_TOCA + s)
			w.plant(id, sitios[s], sombra[(k + s) % sombra.size()].id)


static func _home_biome() -> StringName:
	var regioes := SimLoop.state.chapters.regions
	var r := SimLoop.state.region
	return StringName(regioes[r]) if r >= 0 and r < regioes.size() else Wilds.BIOMA_POR_OMISSAO


static func _biome_at(field: FieldWork, x: float) -> StringName:
	var lado := WorldPlan.LESTE if x > SimLoop.world_width else WorldPlan.OESTE
	if x >= 0.0 and x <= SimLoop.world_width:
		return _home_biome()
	var k := (
		floori((x - SimLoop.world_width) / field.wilds.width)
		if lado > 0
		else floori(-x / field.wilds.width)
	)
	if k < 0 or k >= field.wilds.count(lado):
		return _home_biome()
	return StringName(field.wilds.at(lado, k)[WildSegments.PARA])


## O que a floresta de casa nunca tapa.
static func _home_reserved(field: FieldWork, folga: float) -> Array:
	var r: Array = []
	for x in SimLoop.passages:
		r.append(Vector2(x - Band.PASSAGE_PX - folga, x + Band.PASSAGE_PX + folga))
	var pontos: Array[float] = [0.0, SimLoop.world_width]  # as bases do Lume (Q-156)
	pontos.append_array(Array(field.camps))
	pontos.append_array(Array(SimLoop.secrets.xs))
	pontos.append_array(Array(SimLoop.secrets.chapters))
	pontos.append_array(Array(SimLoop.night.amargueiros.xs))
	pontos.append_array(Array(UnderWatch.mouths(field)))
	var o := SimLoop.arrival
	if o.active:
		pontos.append_array([o.cache_x, SimLoop.seat.cart_x])
	for x in pontos:
		r.append(Vector2(x - folga, x + folga))
	r.append_array(_burrows_reserved(field, folga))
	r.append_array(_built_reserved())
	return r


## O que a floresta de um segmento nunca tapa: o assunto dele e as tocas que nao sao
## de arvores. Numa terra de outro povo, o sitio inteiro das casas dele.
static func _zone_reserved(field: FieldWork, side: int, k: int, folga: float) -> Array:
	var r := _burrows_reserved(field, folga)
	var x := field.wilds.subject_x(side, k, SimLoop.world_width)
	var zona := int(field.wilds.at(side, k)[WildSegments.ZONA])
	var povo := zona in [WorldPlan.Zone.LAND, WorldPlan.Zone.FORTRESS]
	var casas := RulesFactory.rules().realm_wall_offset + folga if povo else folga
	r.append(Vector2(x - casas, x + casas))
	for boca in UnderWatch.mouths(field):
		r.append(Vector2(boca - folga, boca + folga))
	return r


static func _burrows_reserved(field: FieldWork, folga: float) -> Array:
	var r: Array = []
	var tocas := field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] != String(ARVORE):
			r.append(Vector2(tocas.xs[k] - folga, tocas.xs[k] + folga))
	return r


## O que ja se ergueu, e a clareira da sede quando o reino ja esta fundado (um save
## de antes da floresta, ou uma fundacao feita antes do primeiro passo).
static func _built_reserved() -> Array:
	var r: Array = []
	for vaga in SimLoop.builds.slots:
		if (
			vaga.band == Band.Kind.SURFACE
			and (vaga.level > 0 or vaga.state != BuildSlot.State.EMPTY)
		):
			r.append(Vector2(vaga.x - vaga.width * MEIO, vaga.x + vaga.width * MEIO))
	if not SimLoop.arrival.active or SimLoop.arrival.choice != &"":
		var raio := LastCartWatch.rules().foundation_clear_radius
		r.append(Vector2(SimLoop.core_x - raio, SimLoop.core_x + raio))
	return r
