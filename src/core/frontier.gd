# src/core/frontier.gd — a cola do mundo continuo: le o SimLoop e o RngService e escreve
# no WildSegments, que e puro (o pedido do dono de 30/09/2026; §21; ADR 0038).
#
# Como o Minecraft gera os chunks a volta do jogador, aqui gera-se, de cada lado, o que
# comeca a um ecra do rei (ALCANCE_PX), sempre de dentro para fora e sem saltar nenhum.
# Os sorteios de cada segmento vem do RngService.scatter com uma chave que e o SITIO
# (lado e indice): o mesmo segmento sai igual venha o rei de onde vier e quando vier, e
# nao gasta a sequencia de quem simula. O clima vem de um ruido continuo pela semente.
#
# O que cada segmento traz ao jogo, quando nasce e quando se retoma o save:
#   · acampamento de mendigos — entra nos acampamentos (Q-122);
#   · acampamento de mercenarios — um mercenario a espera, ao preco dele (Camps);
#   · masmorra (a ruina do §21) — uma boca no Verbo 2 e, so da primeira vez, um monte de
#     moedas na camara la em baixo (as moedas vao no save; nao se repoem).
class_name Frontier
extends RefCounted

## Gera-se o que comeca a um ecra do rei: e a distancia de visao (a camara ve 1280 px).
const ALCANCE_PX := 1280.0
## Quao perto do acampamento um mercenario conta como "ja ha um a espera".
const CAMPO_PX := 96.0
const SAL := 53
const SAL_TRILHO := 59
const SAL_CLIMA := 67
const OITAVAS := 2
const GANHO := 0.8
const MEIO := 0.5
const MASMORRA := &"dungeon"
## O `u_monte` de quem retoma um save: nada nasce, e por isso nada cai na masmorra.
const RETOMA := -1.0
const TABELA_BIOMAS := &"biomes"


## O plano do mundo desta campanha: os povos do plano e o comprimento de cada trilho,
## sorteado pelo sitio (o j-esimo trilho de cada lado).
static func plan(estado: GameState) -> WorldPlan:
	var curva := SimFactory.curve()
	var gama := curva.world_trail_segments
	var trilho := func(lado: int, j: int) -> int:
		var u := RngService.scatter(hash([SAL_TRILHO, lado, j]), 1)[0]
		return gama.x + mini(floori(u * float(gama.y - gama.x + 1)), gama.y - gama.x)
	var povos := maxi(0, estado.chapters.regions.size() - 1)
	return WorldPlan.draw(povos, curva.world_land_segments, trilho)


## Passo 3: o que falta a frente do rei, de cada lado, e o que cada segmento novo traz.
static func grow(campo: FieldWork, unidades: UnitSystem, rei: int, largura: float) -> void:
	var i := unidades.index_of(rei)
	if i == UnitSystem.NENHUM or campo.wilds.width <= 0.0 or SimLoop.state == null:
		return
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		var falta := campo.wilds.needed(lado, unidades.xs[i], largura, ALCANCE_PX)
		while campo.wilds.count(lado) < falta:
			if not _crescer(campo, lado, largura):
				break


## Ao retomar: os acampamentos e as bocas dos segmentos guardados voltam a contar.
static func reapply(campo: FieldWork, largura: float) -> void:
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for k in campo.wilds.count(lado):
			_aplicar(campo, lado, k, largura, RETOMA)


## A boca de passagem onde o Verbo 2 pega (Verbs.destination), masmorras incluidas. As
## das masmorras nunca entram no SimLoop.passages: a noite le essas (Q-132).
static func at_mouth(x: float, passagens: PackedFloat32Array, em_baixo: bool) -> bool:
	if Passages.near(x, passagens) or em_baixo and Passages.near(x, SimLoop.passages):
		return true
	return (
		SimLoop.field != null
		and Passages.near(x, SimLoop.field.wilds.dungeons(SimLoop.world_width))
	)


## Onde se pode andar: da beira de uma borda a beira da outra.
static func walk_limits() -> Vector2:
	if SimLoop.field == null or SimLoop.field.wilds.width <= 0.0:
		return Vector2(-SimLoop.wild_px, SimLoop.world_width + SimLoop.wild_px)
	return SimLoop.field.wilds.limits(SimLoop.world_width)


static func _crescer(campo: FieldWork, lado: int, largura: float) -> bool:
	var k := campo.wilds.count(lado)
	var sorteios := RngService.scatter(hash([SAL, lado, k]), WildSegments.SORTEIOS + 1)
	var curva := SimFactory.curve()
	var ruido := RngService.noise(
		SAL_CLIMA, 1.0 / float(maxi(1, curva.wild_cluster_segments)), OITAVAS
	)
	var clima := clampf(MEIO + ruido.get_noise_1d(float(lado * (k + 1))) * GANHO, 0.0, 1.0)
	var regioes := SimLoop.state.chapters.regions
	var novo := campo.wilds.grow(lado, sorteios, clima, curva.wild_cluster, regioes, _bordas())
	if novo.is_empty():
		return false
	_aplicar(campo, lado, k, largura, sorteios[WildSegments.SORTEIOS])
	return true


## `u_monte` >= 0 so quando o segmento acabou de nascer: e dai que sai o monte da masmorra.
static func _aplicar(campo: FieldWork, lado: int, k: int, largura: float, u_monte: float) -> void:
	var registo := campo.wilds.at(lado, k)
	var x := campo.wilds.subject_x(lado, k, largura)
	if registo[WildSegments.TIPO] == WildSegments.ACAMPAMENTO and not campo.camps.has(x):
		campo.camps.append(x)
	if u_monte < 0.0:
		return
	if registo[WildSegments.TIPO] == WildSegments.MERCENARIOS:
		Camps.mercenaries(PackedFloat32Array([x]), SimLoop.units, SimLoop.state)
	if int(registo.get(WildSegments.PASSAGEM, 0)) > 0:
		var gama := SimFactory.curve().dungeon_coins
		var quanto := gama.x + mini(floori(u_monte * float(gama.y - gama.x + 1)), gama.y - gama.x)
		SimLoop.coins.drop(SimLoop.state, x, Band.Kind.UNDERGROUND, quanto, 0.0)
		EventBus.queue(&"coin_dropped", [x, int(Band.Kind.UNDERGROUND), quanto, MASMORRA])


## A borda de cada bioma (biomes.csv, edge_subject).
static func _bordas() -> Dictionary:
	var saida := {}
	for id in Registry.ids(TABELA_BIOMAS):
		var dados := Registry.entry(TABELA_BIOMAS, StringName(id)) as BiomeData
		saida[StringName(id)] = dados.edge_subject
	return saida
