# src/core/dawn_work.gd — a alvorada de um dia que nao e o primeiro: o que se paga, quem
# chega e quem e coroado (§06, §15, §16; Q-122, Q-124, Q-133). Tirado do FieldWork, que
# chegou as 250 linhas do §28.
class_name DawnWork
extends RefCounted


## A manutencao do dia que acabou, o vagabundo novo no acampamento do lado do dia
## (Q-122, Q-124), a marcha e o tributo (Q-103). Devolve o rei: o novo, se houve
## sucessao (§16).
static func run(
	campo: FieldWork,
	dia: int,
	unidades: UnitSystem,
	estado: GameState,
	obras: BuildSystem,
	economia: EconomySystem,
	rei: int,
	nucleo: Vector2
) -> int:
	if obras != null:
		rei = _coroar(campo, unidades, estado, obras, rei)
		var treino := campo.succession.dawn(obras, unidades, rei)
		if treino > 0:
			EventBus.queue(&"coin_spent", [treino, &"heir"])
	if economia != null:
		for e in campo.upkeep.dawn(unidades, rei, economia, dia):
			if e[UpkeepSystem.CHAVE] == UpkeepSystem.EV_PAGA:
				EventBus.queue(&"coin_spent", [e[UpkeepSystem.QUANTO], &"upkeep"])
			else:
				EventBus.queue(&"unit_fled", [e[UpkeepSystem.UNIDADE], &"upkeep"])
	if obras != null:
		for slot in obras.standing():
			var released := campo.seasons.release(dia, slot)
			if released > 0:
				SimLoop.coins.drop(estado, slot.x, slot.band, released, 0.0)
	_abastecer(campo, unidades, obras, rei)  # as aljavas, depois do soldo (Q-163)
	SpiritWatch.dawn(campo.spirit, dia, campo.upkeep.arrears())  # o soldo em atraso pesa (Q-102)
	Camps.dawn(campo.camps, dia, unidades, estado, campo.spirit.level(dia))
	Camps.mercenaries(campo.wilds.mercenaries(SimLoop.world_width), unidades, estado)  # Q-173
	var fork := SimLoop.secrets.chapters[0] if not SimLoop.secrets.chapters.is_empty() else nucleo.x
	campo.realm.dawn(dia, unidades, estado, rei, Vector2(nucleo.x, fork))  # Q-103
	Assume.dawn(unidades, estado, rei, campo)  # a classe do povo conquistado chega (§13)
	return rei


## Q-163: com a banca do arco de pe (rules.csv, `ammo_depot`), as aljavas das tuas tropas
## repoem-se do saco do rei, `arrows_per_coin` flechas por moeda, ate onde ele chegar.
static func _abastecer(
	campo: FieldWork, unidades: UnitSystem, obras: BuildSystem, rei: int
) -> void:
	var r := unidades.index_of(rei)
	if r == UnitSystem.NENHUM or not unidades.alive(r):
		return
	var regras := RulesFactory.rules()
	if not Supply.depot(obras, regras.ammo_depot):
		return
	var bolsa := unidades.carried_coins[r]
	var gasto := campo.supply.restock(unidades, unidades.owners[r], bolsa, regras.arrows_per_coin)
	if gasto > 0:
		unidades.carried_coins[r] -= gasto
		EventBus.queue(&"coin_spent", [gasto, &"arrows"])


## §16: "se houver sucessor, ele assume no amanhecer". O rei novo nasce no castelo
## (Q-137), sem moedas, e a ganancia sorteia-se de novo (§15, Q-133).
static func _coroar(
	campo: FieldWork, unidades: UnitSystem, estado: GameState, obras: BuildSystem, rei: int
) -> int:
	var i := unidades.index_of(rei)
	if rei == UnitSystem.NENHUM or (i != UnitSystem.NENHUM and unidades.healths[i] > 0):
		return rei
	var monarca := Registry.entry(&"units", &"monarch") as UnitData
	var novo := campo.succession.crown(estado, unidades, obras, monarca)
	if novo == UnitSystem.NENHUM:
		return rei
	var x := unidades.xs[unidades.index_of(novo)]
	EventBus.queue(&"unit_spawned", [novo, monarca.id, x, int(Band.Kind.SURFACE)])
	EventBus.queue(&"king_died", [campo.succession.owner, novo])
	EventBus.queue(&"succession_started", [novo])
	SimFactory.draw_greed(estado)
	SimLoop.king_id = novo  # quem manda passa a ser ele: o Verbo, a camara, o Defeat
	return novo
