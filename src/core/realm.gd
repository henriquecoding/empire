# src/core/realm.gd — o reino que fica e os povos que te pagam (§13; Q-103, Q-146,
# Q-154, o dono a 29/09/2026; ADR 0035).
#
# "O meu reino sera sempre o que eu comeco" e "o rei nunca sai para longe do
# reino; quem vai para longe sao as classes jogaveis". A bifurcacao deixou de
# levar o rei para a regiao seguinte: de dia, a partir do dia da marcha, o Verbo 2
# la manda quem esta perto dele — ate ao teto de cada papel — conquistar o povo
# seguinte do plano. Saem esta noite (§13: "o imperio fica desguarnecido"), e na
# alvorada seguinte voltam. Quando a fortaleza cai, o povo passa a vassalo: paga
# tributo todos os dias (§13: 4–6 moedas) e da as Sementes da conquista.
#
# O cerco (Q-166; relatorio Kingdom, K6): cada marcha tira a fortaleza a firmeza dos
# que foram, e ela nao volta; a fortaleza cai quando a conta chega a zero. Nem todos
# voltam — um sorteio por cabeca no fluxo combat, e a mesma semente da as mesmas
# baixas. Quem fica no campo nao volta as colunas, e o TitleSystem chora-o.
#
# Este ficheiro e a cola: le o SimLoop e os dados, e escreve nos dois sistemas
# puros (March, VassalSystem).
class_name Realm
extends RefCounted

const TRIBUTO := &"tribute"
## O tipo do segment_entered quando o ultimo povo passa a vassalo: a campanha acaba.
const TODOS := &"realm"
const CONQUISTA := &"conquest"

var march := March.new()
var vassals := VassalSystem.new()


## A regiao que a proxima marcha conquista: a primeira do plano que nao e a casa
## (a 0) nem ja e vassala. NENHUM quando ja nao ha quem conquistar.
func next_target(estado: GameState) -> int:
	var regioes := estado.chapters.regions
	for k in range(1, regioes.size()):
		if not vassals.has(_povo(regioes[k])):
			return k
	return March.NENHUM


## Porque e que a marcha nao sai agora, ou &"" se sai.
func refusal(unidades: UnitSystem, rei: int, estado: GameState) -> StringName:
	if march.marching():
		return &"MARCH_AWAY"
	if next_target(estado) == March.NENHUM:
		return &"MARCH_NOBODY_LEFT"
	if _quem(unidades, rei).size() < SimFactory.curve().march_min_party:
		return &"MARCH_TOO_FEW"
	return &""


## O povo da fortaleza seguinte, ou &"" quando ja todos te pagam.
func next_people(estado: GameState) -> StringName:
	var alvo := next_target(estado)
	return _povo(estado.chapters.regions[alvo]) if alvo != March.NENHUM else &""


## O reconhecimento (§13): Vector2i(a firmeza que sobra, a inteira) da fortaleza da
## proxima marcha; zeros quando ja nao ha quem conquistar.
func scouted(estado: GameState) -> Vector2i:
	var alvo := next_target(estado)
	if alvo == March.NENHUM:
		return Vector2i.ZERO
	var curva := SimFactory.curve()
	var base := curva.march_fortress_base
	var por := curva.march_fortress_per_region
	return Vector2i(march.firmness(alvo, base, por), March.fortress(alvo, base, por))


## Quanto a marcha tiraria a fortaleza se saisse agora.
func blow(unidades: UnitSystem, rei: int) -> int:
	return _quem(unidades, rei).size() * SimFactory.curve().march_siege_per_unit


## O Verbo 2 na bifurcacao, com ela aberta: a marcha sai. Verdadeiro se saiu.
func send(unidades: UnitSystem, rei: int, estado: GameState, dia: int) -> bool:
	if not refusal(unidades, rei, estado).is_empty():
		return false
	var alvo := next_target(estado)
	march.start(unidades, _quem(unidades, rei), alvo, dia, SimFactory.curve().march_nights)
	EventBus.queue(&"segment_entered", [StringName(estado.chapters.regions[alvo]), &"march"])
	return true


## A alvorada: a marcha que volta, e o tributo de quem ja e vassalo. `onde` e o x do
## nucleo, onde o tributo chega, e o da bifurcacao, por onde a marcha volta.
func dawn(dia: int, unidades: UnitSystem, estado: GameState, rei: int, onde: Vector2) -> void:
	var curva := SimFactory.curve()
	var massa := SimFactory.rot_profile().calendar_mass(maxi(1, dia - 1))
	var fim := vassals.dawn(massa, curva.vassal_erosion_per_mass, curva.vassals_can_fall)
	for povo: String in fim[&"fallen"]:
		EventBus.queue(&"trade_route_closed", [StringName(povo), &"consumed"])
	# Em montes do tamanho de um tributo: um monte maior do que o saco do rei nunca
	# se apanhava (CoinSystem.collect salta o que nao cabe).
	var falta := int(fim[&"coins"])
	while falta > 0:
		var monte := mini(falta, curva.vassal_tribute.y)
		SimLoop.drop_coin(onde.x, Band.Kind.SURFACE, monte, TRIBUTO)
		falta -= monte
	if march.due(dia):
		_voltar(dia, unidades, estado, rei, onde.y)


func _voltar(dia: int, unidades: UnitSystem, estado: GameState, rei: int, onde: float) -> void:
	var alvo := march.target
	var foram := march.finish()
	var curva := SimFactory.curve()
	var sorteios := PackedFloat32Array()
	for _linha in foram:  # um por cabeca, pela ordem em que foram (por id, §42)
		sorteios.append(RngService.unit_float(&"combat"))
	var r := unidades.index_of(rei)
	for linha in March.survivors(foram, sorteios, curva.march_loss_chance):
		var i := unidades.restore(linha)  # a mesma tropa: vida, moedas e nome (Q-146)
		unidades.xs[i] = onde
		unidades.target_xs[i] = onde
		unidades.has_targets[i] = 0
		unidades.job_ids[i] = UnitSystem.NENHUM
		unidades.bands[i] = int(Band.Kind.SURFACE)
		if r != UnitSystem.NENHUM:
			unidades.owners[i] = unidades.owners[r]
		var sinal := [unidades.ids[i], unidades.data_ids[i], onde, int(Band.Kind.SURFACE)]
		EventBus.queue(&"unit_spawned", sinal)
	if alvo < 0:
		return
	march.siege(alvo, foram.size() * curva.march_siege_per_unit)
	if march.firmness(alvo, curva.march_fortress_base, curva.march_fortress_per_region) > 0:
		return  # a fortaleza aguenta: a proxima marcha comeca onde esta parou
	var povo := _povo(estado.chapters.regions[alvo])
	EventBus.queue(&"fortress_conquered", [alvo, povo])
	var tributo := RngService.int_range(&"economy", curva.vassal_tribute.x, curva.vassal_tribute.y)
	vassals.add(povo, tributo, curva.vassal_strength, dia)
	if not estado.conquests.has(String(povo)):
		estado.conquests.append(String(povo))  # o que desbloqueia muros e fica no legado
	var sementes := RngService.int_range(&"economy", curva.vassal_seeds.x, curva.vassal_seeds.y)
	estado.royal_seeds += sementes
	EventBus.queue(&"people_assimilated", [povo])
	EventBus.queue(&"trade_route_opened", [povo, tributo])
	EventBus.queue(&"seed_royal_gained", [sementes, CONQUISTA])
	if next_target(estado) == March.NENHUM:  # todos te pagam: o fim da campanha (§79)
		estado.crossed = true
		EventBus.queue(&"segment_entered", [&"", TODOS])


func _quem(unidades: UnitSystem, rei: int) -> PackedInt32Array:
	var curva := SimFactory.curve()
	var perfis := SimFactory.by_id(&"units")
	return March.who(unidades, perfis, rei, curva.crossing_party_px, curva.march_party_caps)


static func _povo(bioma: String) -> StringName:
	var dados := Registry.entry(&"biomes", StringName(bioma)) as BiomeData
	return dados.people if dados != null else StringName(bioma)


func to_dict() -> Dictionary:
	return {&"march": march.to_dict(), &"vassals": vassals.to_dict()}


func from_dict(d: Dictionary) -> void:
	march.from_dict(d.get(&"march", {}))
	vassals.from_dict(d.get(&"vassals", {}))
