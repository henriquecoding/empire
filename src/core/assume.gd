# src/core/assume.gd — quem o jogador conduz, e o que vai com ele (§08, §24; Q-153, Q-169;
# ADR 0052, o dono a 02/10/2026).
#
# "Somente imperadores sao controlaveis": conduz-se quem tem a coroa. O Verbo 2 ja nao
# assume tropas de classe, e o monarca deixou de ter trela (Q-150): todos os monarcas
# exploram ate a beira do mundo gerado. A coluna `pilot` fica para a troca entre
# imperadores encontrados (UN-17); sem ela, conduz-se o rei.
class_name Assume
extends RefCounted

## O povo -> a classe jogavel dele (peoples.csv), lido na primeira vez.
static var _povos := {}


## Quem o jogador conduz agora: o rei, ou o imperador da troca (UN-17) se estiver vivo.
static func driven() -> int:
	if SimLoop.field == null or SimLoop.units == null:
		return SimLoop.king_id
	return SimLoop.field.roster.driven(SimLoop.units, SimLoop.king_id)


## Se e o titular da coroa que o jogador conduz: so ele gere (§08) e abre a roda (§24).
static func king() -> bool:
	return driven() == SimLoop.king_id


static func peoples() -> Dictionary:
	if _povos.is_empty():
		for recurso in Registry.entries(&"peoples"):
			var povo := recurso as PeopleData
			_povos[povo.id] = povo.playable_class
	return _povos


## Onde quem se conduz pode andar: ate a beira do mundo (Frontier). Sem trela para
## ninguem — a Q-150 deu-a ao rei, e a ADR 0052 tirou-a (MU-02).
static func limits(_unit_id: int) -> Vector2:
	return Frontier.walk_limits()


## Passo 4: quem morreu deixa de ser conduzido; e os archotes vao no armazenamento de
## quem se conduz (Q-153).
static func plan(unidades: UnitSystem, rei: int, _nucleo: Vector2, campo: FieldWork) -> void:
	campo.roster.forget_dead(unidades)
	if SimLoop.night != null:
		SimLoop.night.dark.torch.storage = storage(unidades, rei, campo)


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


## Se quem se conduz marca alvos com o gatilho direito: a habilidade do monarca e a marca
## (o Imperador Arqueiro, ADR 0052), ou a classe dele tem o verbo mark_target (Q-086).
static func marks(campo: FieldWork) -> bool:
	if SimLoop.units.pilot == UnitSystem.NENHUM:
		return MonarchWatch.skill() == &"mark" or campo.classes.marks()
	var i := SimLoop.units.index_of(SimLoop.units.pilot)
	var classe := campo.roster.class_of_body(SimLoop.units.data_ids[i]) if i >= 0 else &""
	var dados := Registry.entry(&"classes", classe) as ClassData if classe != &"" else null
	return dados != null and dados.verb == &"mark_target"


## A alvorada: o corpo de cada classe sem tropa cujo povo conquistaste chega ao nucleo, e
## passa a IA (ADR 0052): nao se assume.
static func dawn(unidades: UnitSystem, estado: GameState, rei: int, campo: FieldWork) -> void:
	var x := SimLoop.core_x
	for novo in campo.roster.arrive(unidades, estado, rei, x, estado.conquests, peoples()):
		var dados := unidades.data_ids[unidades.index_of(novo)]
		EventBus.queue(&"unit_spawned", [novo, dados, x, int(Band.Kind.SURFACE)])
