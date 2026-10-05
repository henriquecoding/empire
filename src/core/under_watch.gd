# src/core/under_watch.gd — onde ha subsolo, de que e feito, e a primeira descida (o
# pedido do dono de 02/10/2026; §11, §17, §21; Q-186, ADR 0046).
#
# O dono: "o local onde aparece e aleatorio, mas coerente com o local; nos imperios e
# comum ter subsolos com locais onde se pode armazenar coisas ou com uma sala secreta no
# imperador". Daqui sai a parte autorada de cada sitio (UndergroundSites):
#   · um porao em cada passagem do imperio — armazem, adega, celeiro —, entre os dois
#     muros que a passagem tem de cada lado, e grande o bastante para o poco de minerio
#     e a camara da Semente Real que la estao (§25 11:00);
#   · a sala secreta debaixo do castelo, com um alcapao num sitio sorteado do chao dele;
#   · a masmorra de cada ruina das terras, dentro do segmento dela;
#   · a cavidade natural de cada falha de rocha de um limiar (ADR 0072).
# E a cola: le o SimLoop e o RngService e escreve no UndergroundSites, que e puro. As
# salas so nascem na primeira descida (`enter`), pela semente e pela chave do sitio.
#
# ADR 0072 (o relatorio de 05/10/2026): cada sitio tem uma causa que se ve — a passagem,
# a sede, o arco caido, a falha — e uma familia que diz que salas lhe cabem. Uma ruina
# escolhe a funcao que teve (cripta, deposito, cisterna) e so leva salas dessa funcao; a
# reserva real ja nao traz arcas nem frestas que nao respondem; a caverna nao tem escada.
class_name UnderWatch
extends RefCounted

const SAL := 229
const SAL_TESOURO := 233
const HATCH_KEY := "hatch"
const CELLAR_KEY := "cellar_%d"
const DUNGEON_KEY := "dungeon_%d_%d"
const CAVE_KEY := "cave_%d_%d"
const SAL_USO := 241
## O assunto de limiar que e uma formacao de rocha: a ancora de uma caverna (§7.2).
const FALHA := &"rock_fault"
## A boca da caverna abre no pe da rocha da direita da falha (WildLands.FALHA, 18 a 104 px
## do assunto): ve-se de onde vem, e nao tapa o que o guia diz do limiar no assunto.
const FALHA_BOCA_PX := 60.0
## O alcapao abre a esta distancia do meio do castelo: nunca no meio (onde o rei nasce e o
## escudeiro espera) e nunca fora dele.
const ALCAPAO_PX := Vector2(70.0, 190.0)
## A folga entre a parede de um sitio e o muro, a beira do castelo ou do segmento.
const FOLGA := 10.0
## A camara do arco caido (WildTunnel.CAMARA) e a sala de entrada de uma masmorra.
const CAMARA_PX := 196.0
const MEIO := 0.5
const MINA := &"mine"
const SEMENTE := &"seed"
const ENTRADAS := {
	UndergroundSites.CELLAR: &"stair",
	UndergroundSites.HATCH: &"vault",
	UndergroundSites.DUNGEON: &"hall",
	UndergroundSites.CAVE: &"maw",
}
const TIPOS := {
	UndergroundSites.CELLAR: [&"storage", &"wine", &"granary"],
	UndergroundSites.HATCH: [&"storage", &"granary"],
	UndergroundSites.DUNGEON: [&"crypt", &"collapsed", &"cistern", &"ossuary"],
	UndergroundSites.CAVE: [&"hollow", &"roots", &"niche"],
}
const FAMILIAS := {
	UndergroundSites.CELLAR: &"home_cellar",
	UndergroundSites.HATCH: &"royal_reserve",
	UndergroundSites.DUNGEON: &"ruin",
	UndergroundSites.CAVE: &"cave",
}
## A funcao que a ruina teve escolhe as salas que lhe cabem (§5 do relatorio).
const USOS := {
	&"crypt": [&"crypt", &"ossuary", &"collapsed"],
	&"store": [&"storage", &"wine", &"collapsed"],
	&"cistern": [&"cistern", &"collapsed"],
}


## Os poroes das `passagens` e a sala secreta do castelo; os `muros` sao os x dos sitios
## de muro da regiao. Quem monta a regiao (o segmento) e que os da (§70: o nucleo nao le o
## mundo). Depois das obras: o poco de minerio e a camara da Semente Real ja tem sitio.
static func author_home(passagens: PackedFloat32Array, muros: PackedFloat32Array) -> void:
	if SimLoop.field == null:
		return
	var nucleo := SimLoop.core_x
	for k in passagens.size():
		var boca := passagens[k]
		var tecto := _entre_muros(boca, muros)
		var precisa := Vector2(boca, boca)
		var dentro := []
		for obra in SimLoop.builds.slots:
			if int(obra.band) == int(Band.Kind.UNDERGROUND) and _cabe(obra.x, tecto):
				precisa = _alargar(precisa, obra.x, obra.width)
				dentro.append([obra.x, MINA, obra.width])
		var segredos := SimLoop.secrets
		for s in segredos.ids.size():
			if segredos.bands[s] == int(Band.Kind.UNDERGROUND) and _cabe(segredos.xs[s], tecto):
				precisa = _alargar(precisa, segredos.xs[s], segredos.widths[s])
				dentro.append([segredos.xs[s], SEMENTE, segredos.widths[s]])
		var receita := spec(UndergroundSites.CELLAR, 0.0, dentro)
		var chave := CELLAR_KEY % k
		SimLoop.field.under.post(chave, UndergroundSites.CELLAR, boca, precisa, tecto, receita)
	var u := RngService.scatter(hash([SAL, HATCH_KEY]), 2)
	var lado := 1.0
	if u[0] < MEIO:
		lado = -lado
	var alcapao := nucleo + lado * lerpf(ALCAPAO_PX.x, ALCAPAO_PX.y, u[1])
	var meio := _nucleo_px() * MEIO - FOLGA
	var castelo := Vector2(nucleo - meio, nucleo + meio)
	var secreta := spec(UndergroundSites.HATCH, 0.0, [])
	var aqui := Vector2(alcapao, alcapao)
	SimLoop.field.under.post(HATCH_KEY, UndergroundSites.HATCH, alcapao, aqui, castelo, secreta)


## A masmorra da ruina do segmento (`lado`, `k`), presa a ele; ou, numa falha de rocha,
## a cavidade natural. `recusa` nao vazia: o sitio fica registado, mas sem entrada.
static func author_dungeon(campo: FieldWork, lado: int, k: int, recusa := &"") -> void:
	var x := campo.wilds.subject_x(lado, k, SimLoop.world_width)
	var x0 := campo.wilds.x_of(lado, k, SimLoop.world_width)
	var tecto := Vector2(x0 + FOLGA, x0 + campo.wilds.width - FOLGA)
	var gruta: bool = campo.wilds.at(lado, k).get(WildSegments.ASSUNTO) == FALHA
	if gruta:
		x += FALHA_BOCA_PX
	var tipo := UndergroundSites.CAVE if gruta else UndergroundSites.DUNGEON
	var precisa := Vector2(x, x) if gruta else Vector2(x - CAMARA_PX * MEIO, x + CAMARA_PX * MEIO)
	var receita := spec(tipo, 0.0 if gruta else CAMARA_PX, [])
	if not gruta:
		var u := RngService.scatter(hash([SAL_USO, lado, k]), 1)[0]
		var uso: StringName = USOS.keys()[mini(floori(u * USOS.size()), USOS.size() - 1)]
		receita[UndergroundSites.POOL] = USOS[uso]
		receita[&"use"] = uso
	receita[UndergroundSites.SEGMENT] = Vector2i(lado, k)
	if recusa != &"":
		receita[UndergroundSites.DENY] = recusa
	var chave := (CAVE_KEY if gruta else DUNGEON_KEY) % [lado, k]
	campo.under.post(chave, tipo, x, precisa, tecto, receita)


## A receita de um sitio, com as larguras e o numero de salas do rules.csv.
static func spec(tipo: StringName, entrada_px: float, dentro: Array) -> Dictionary:
	var regras := RulesFactory.rules()
	return {
		UndergroundSites.ROOM: Vector2(regras.und_room_min_px, regras.und_room_max_px),
		UndergroundSites.EXTRA: regras.und_extra_rooms,
		UndergroundSites.POOL: TIPOS[tipo],
		UndergroundSites.ENTRANCE: ENTRADAS[tipo],
		UndergroundSites.ENTRANCE_PX: entrada_px,
		UndergroundSites.FEATURES: dentro,
		UndergroundSites.RULES: rules(),
		UndergroundSites.FAMILY: FAMILIAS[tipo],
		UndergroundSites.MANDATORY: tipo in [UndergroundSites.CELLAR, UndergroundSites.HATCH],
	}


## O contrato de area util e os limites dos sitios opcionais (ADR 0072).
static func rules() -> UnderRules:
	return Registry.entry(&"economy", &"underground") as UnderRules


## A primeira descida por uma boca: o sitio dela nasce, pela semente e pela chave — a
## mesma jogatina da sempre o mesmo, outra jogatina da outro. A reserva real abre o bau
## vazio dela; a masmorra poe a recompensa no meio da baia, uma vez.
static func enter(x: float, alcance := Band.PASSAGE_PX) -> void:
	var campo := SimLoop.field
	if campo == null:
		return
	var i := campo.under.find(x, alcance)
	if i == UndergroundSites.NONE:
		return
	var chave := campo.under.key_of(i)
	var sorteios := RngService.scatter(hash([SAL, chave]), UndergroundSites.ROLLS)
	if not campo.under.generate(i, sorteios):
		return
	match campo.under.kind_of(i):
		UndergroundSites.HATCH:
			_tesouro(campo, i, chave)
			CellarWatch.sync()  # a cave real nasce ja com a largura habitavel inteira
		UndergroundSites.DUNGEON:
			DungeonWatch.place(campo, i)  # a recompensa nasce dentro, e nao na boca (SUB-11)


## As bocas que nao sao passagens: as ruinas e as cavernas das terras e o alcapao do
## castelo — so as que levam a algum lado (ADR 0072).
static func mouths(campo: FieldWork) -> PackedFloat32Array:
	return campo.under.mouths()


static func _tesouro(_campo: FieldWork, _i: int, chave: String) -> void:
	SimLoop.treasury.open(chave, 0)


## Entre o muro de cada lado da boca, com folga; sem muro de um lado, a beira da regiao.
static func _entre_muros(boca: float, muros: PackedFloat32Array) -> Vector2:
	var tecto := Vector2(0.0, SimLoop.world_width)
	for x in muros:
		if x < boca:
			tecto.x = maxf(tecto.x, x + FOLGA)
		elif x > boca:
			tecto.y = minf(tecto.y, x - FOLGA)
	return tecto


static func _cabe(x: float, tecto: Vector2) -> bool:
	return x >= tecto.x and x <= tecto.y


static func _alargar(precisa: Vector2, x: float, largura: float) -> Vector2:
	return Vector2(minf(precisa.x, x - largura * MEIO), maxf(precisa.y, x + largura * MEIO))


static func _nucleo_px() -> float:
	return float((Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData).width_px)
