# src/core/assume.gd — quem o jogador conduz, e o Verbo 2 que troca de classe (§08, §24;
# Q-150, Q-162, Q-178, o dono a 30/09/2026).
#
# A cola entre o Roster (puro) e o jogo: le o SimLoop, o Registry e a curva. O rei gere
# e fica no imperio; as classes vao para longe. Quem o jogador nao conduz faz o que faz
# a tropa do tipo dele — o rei, largado, volta ao nucleo e espera la.
class_name Assume
extends RefCounted

## Longe do nucleo mais do que isto, o rei largado volta para la; mais perto, fica.
const EM_CASA := 0.5
## O proposito do unit_promoted quando uma tropa passa a corpo jogavel (§46).
const CLASSE := &"class"

## O povo -> a classe jogavel dele (peoples.csv), lido na primeira vez.
static var _povos := {}


## Quem o jogador conduz agora: o corpo de classe assumido, ou o rei.
static func driven() -> int:
	if SimLoop.field == null or SimLoop.units == null:
		return SimLoop.king_id
	return SimLoop.field.roster.driven(SimLoop.units, SimLoop.king_id)


## Se e o rei que o jogador conduz: so ele gere (§08) e so ele abre a roda (§24).
static func king() -> bool:
	return driven() == SimLoop.king_id


## As classes que se podem assumir nesta partida (§13: as dos povos conquistados).
static func unlocked() -> PackedStringArray:
	return SimLoop.field.roster.unlocked(SimLoop.state.conquests, peoples())


static func peoples() -> Dictionary:
	if _povos.is_empty():
		for recurso in Registry.entries(&"peoples"):
			var povo := recurso as PeopleData
			_povos[povo.id] = povo.playable_class
	return _povos


## Onde quem se conduz pode andar: ate a beira do mundo (Frontier), e o rei so ate
## `king_leash_px` alem das bordas da regiao de casa (Q-150: "quem sai mais pra longe
## sao as classes jogaveis").
static func limits(unit_id: int) -> Vector2:
	var limites := Frontier.walk_limits()
	if unit_id != SimLoop.king_id:
		return limites
	var trela := SimFactory.curve().king_leash_px
	return Vector2(maxf(limites.x, -trela), minf(limites.y, SimLoop.world_width + trela))


## O alcance do Verbo 2 de trocar de classe: o de quem repara numa moeda (§25).
static func reach() -> float:
	return SimFactory.curve().recruit_notice_px


## O Verbo 2 que troca de classe. Com o rei: assume o corpo ou a tropa tua ao pe dele
## (§08). Com um corpo de classe: volta ao rei, ao pe dele. Verdadeiro se trocou.
static func switch(unidades: UnitSystem, rei: int, campo: FieldWork) -> bool:
	if campo == null:
		return false
	if unidades.pilot != UnitSystem.NENHUM:
		return campo.roster.back(unidades, rei, reach())
	var ids_antes := {}
	for i in unidades.count():
		ids_antes[unidades.ids[i]] = unidades.data_ids[i]
	var quem := campo.roster.take(unidades, rei, reach(), unlocked())
	if quem == UnitSystem.NENHUM:
		return false
	var agora := unidades.data_ids[unidades.index_of(quem)]
	if ids_antes.get(quem, agora) != agora:
		EventBus.queue(&"unit_promoted", [quem, ids_antes[quem], agora])
	return true


## Passo 4: quem morreu deixa de ser conduzido; o rei largado volta ao nucleo; e os
## archotes vao no armazenamento de quem se conduz (Q-153).
static func plan(unidades: UnitSystem, rei: int, nucleo: Vector2, campo: FieldWork) -> void:
	campo.roster.forget_dead(unidades)
	if SimLoop.night != null:
		SimLoop.night.dark.torch.storage = storage(unidades, rei, campo)
	if unidades.pilot == UnitSystem.NENHUM:
		return
	var r := unidades.index_of(rei)
	if r != UnitSystem.NENHUM and unidades.alive(r):
		if absf(unidades.xs[r] - nucleo.x) > nucleo.y * EM_CASA:
			unidades.set_target_x(rei, nucleo.x)


## O armazenamento de quem se conduz: o cinto do rei, ou o do corpo da classe.
static func storage(unidades: UnitSystem, rei: int, campo: FieldWork) -> Storage:
	if unidades.pilot == UnitSystem.NENHUM or unidades.pilot == rei:
		return campo.classes.storage
	return campo.roster.storage_of(unidades, unidades.pilot)


## Os alforges do cavalo vao com quem o monta (Q-169): o armazenamento dele prolonga-se
## neles, e o de mais ninguem.
static func saddle(unidades: UnitSystem, campo: FieldWork) -> void:
	var monta := campo.mount.rider
	var armazem: Storage = null
	if monta == SimLoop.king_id:
		armazem = campo.classes.storage
	elif monta != UnitSystem.NENHUM:
		armazem = campo.roster.storage_of(unidades, monta)
	campo.mount.link(armazem)


## Se quem se conduz marca alvos com o gatilho direito: a classe dele tem o verbo
## mark_target (§24, Q-086). O rei marca pela classe dele (ClassSystem).
static func marks(campo: FieldWork) -> bool:
	if SimLoop.units.pilot == UnitSystem.NENHUM:
		return campo.classes.marks()
	var i := SimLoop.units.index_of(SimLoop.units.pilot)
	var classe := campo.roster.class_of_body(SimLoop.units.data_ids[i]) if i >= 0 else &""
	var dados := Registry.entry(&"classes", classe) as ClassData if classe != &"" else null
	return dados != null and dados.verb == &"mark_target"


## A alvorada: o corpo de cada classe sem tropa cujo povo conquistaste chega ao nucleo.
static func dawn(unidades: UnitSystem, estado: GameState, rei: int, campo: FieldWork) -> void:
	var x := SimLoop.core_x
	for novo in campo.roster.arrive(unidades, estado, rei, x, estado.conquests, peoples()):
		var dados := unidades.data_ids[unidades.index_of(novo)]
		EventBus.queue(&"unit_spawned", [novo, dados, x, int(Band.Kind.SURFACE)])
