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
#   · a masmorra de cada ruina das terras, dentro do segmento dela.
# E a cola: le o SimLoop e o RngService e escreve no UndergroundSites, que e puro. As
# salas so nascem na primeira descida (`enter`), pela semente e pela chave do sitio.
class_name UnderWatch
extends RefCounted

const SAL := 229
const SAL_TESOURO := 233
const HATCH_KEY := "hatch"
const CELLAR_KEY := "cellar_%d"
const DUNGEON_KEY := "dungeon_%d_%d"
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
}
const TIPOS := {
	UndergroundSites.CELLAR: [&"storage", &"wine", &"granary"],
	UndergroundSites.HATCH: [&"treasury", &"escape"],
	UndergroundSites.DUNGEON: [&"crypt", &"collapsed", &"cistern", &"ossuary"],
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
				dentro.append([obra.x, MINA])
		var segredos := SimLoop.secrets
		for s in segredos.ids.size():
			if segredos.bands[s] == int(Band.Kind.UNDERGROUND) and _cabe(segredos.xs[s], tecto):
				precisa = _alargar(precisa, segredos.xs[s], segredos.widths[s])
				dentro.append([segredos.xs[s], SEMENTE])
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


## A masmorra da ruina do segmento (`lado`, `k`), presa a ele.
static func author_dungeon(campo: FieldWork, lado: int, k: int) -> void:
	var x := campo.wilds.subject_x(lado, k, SimLoop.world_width)
	var x0 := campo.wilds.x_of(lado, k, SimLoop.world_width)
	var tecto := Vector2(x0 + FOLGA, x0 + campo.wilds.width - FOLGA)
	var precisa := Vector2(x - CAMARA_PX * MEIO, x + CAMARA_PX * MEIO)
	var receita := spec(UndergroundSites.DUNGEON, CAMARA_PX, [])
	var chave := DUNGEON_KEY % [lado, k]
	campo.under.post(chave, UndergroundSites.DUNGEON, x, precisa, tecto, receita)


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
	}


## A primeira descida por uma boca: o sitio dela nasce, pela semente e pela chave — a
## mesma jogatina da sempre o mesmo, outra jogatina da outro. A sala secreta guarda o
## tesouro do imperador, que cai uma vez (as moedas vao no save, como as da masmorra).
static func enter(x: float, alcance := Band.PASSAGE_PX) -> void:
	var campo := SimLoop.field
	if campo == null:
		return
	var i := campo.under.find(x, alcance)
	if i == UndergroundSites.NONE:
		return
	var chave := campo.under.key_of(i)
	var sorteios := RngService.scatter(hash([SAL, chave]), UndergroundSites.ROLLS)
	if campo.under.generate(i, sorteios) and campo.under.kind_of(i) == UndergroundSites.HATCH:
		_tesouro(campo, i, chave)


## As bocas que nao sao passagens: as ruinas das terras e o alcapao do castelo.
static func mouths(campo: FieldWork) -> PackedFloat32Array:
	var bocas := campo.wilds.dungeons(SimLoop.world_width)
	bocas.append_array(campo.under.hatches())
	return bocas


static func _tesouro(campo: FieldWork, i: int, chave: String) -> void:
	var u := RngService.scatter(hash([SAL_TESOURO, chave]), 2)
	var premio := DungeonLoot.draw(RulesFactory.rules(), 0.0, u[0], u[1])
	var onde := campo.under.mouth_of(i)
	for sala: Dictionary in campo.under.rooms(i):
		if sala[UndergroundSites.KIND] == &"treasury":
			onde = (float(sala[UndergroundSites.A]) + float(sala[UndergroundSites.B])) * MEIO
	var moedas := int(premio[&"coins"])
	for _m in moedas:
		SimLoop.coins.drop(SimLoop.state, onde, Band.Kind.UNDERGROUND, 1, 0.0)
	EventBus.queue(&"coin_dropped", [onde, int(Band.Kind.UNDERGROUND), moedas, &"secret_room"])


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
