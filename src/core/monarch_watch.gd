# src/core/monarch_watch.gd — o monarca no jogo: o perfil de quem reina, a escolha, o
# companheiro pago e a coroacao (§08, §15, §16; ADR 0052, o dono a 02/10/2026).
#
# A cola entre o Monarchy (puro) e o SimLoop. "Somente imperadores sao controlaveis": o
# jogador conduz sempre quem tem a coroa, e o perfil dele diz o resto — a habilidade do
# botao direito, a classe das fases, o companheiro e o que ele vende. O Rei conserva o
# escudeiro; o Bardo da Nia canta pago (RoyalSong); o escudeiro do Imperador Arqueiro
# vende flechas pagas com as moedas da bolsa dele, e sem moedas nao ha flechas novas.
class_name MonarchWatch
extends RefCounted

const TABELA := &"monarchs"
const ESCUDO := &"shield"
const CANTO := &"song"
const FLECHAS := &"arrows"
## O rotulo do coin_spent de cada servico (§46).
const BARDO := &"bard"
const ALJAVA := &"arrows"


## O perfil em jogo: o escolhido, ou o Rei antes da escolha e num save antigo.
static func data() -> MonarchData:
	var perfil := SimLoop.field.monarchy.current() if SimLoop.field != null else Monarchy.REI
	return Registry.entry(TABELA, perfil) as MonarchData


static func skill_class() -> StringName:
	return data().skill_class


static func skill() -> StringName:
	return data().skill


## Os monarcas da escolha inicial, pela ordem da tabela.
static func choices() -> Array[MonarchData]:
	var lista: Array[MonarchData] = []
	for recurso in Registry.entries(TABELA):
		lista.append(recurso as MonarchData)
	lista.sort_custom(func(a: MonarchData, b: MonarchData) -> bool: return a.order < b.order)
	return lista


## A escolha (§08): o rei e o companheiro que nasceu com ele passam aos do perfil, sem
## nascer ninguem a mais. Uma vez so; um perfil que nao existe nao escolhe nada.
static func begin(perfil: StringName) -> bool:
	var campo := SimLoop.field
	if campo == null or not Registry.has_entry(TABELA, perfil):
		return false
	var dados := Registry.entry(TABELA, perfil) as MonarchData
	var rei := SimLoop.king_id
	var companheiro := int(campo.monarchy.bonds.get(rei, UnitSystem.NENHUM))
	var corpo := Registry.entry(&"units", dados.unit) as UnitData
	var companhia := Registry.entry(&"units", dados.companion) as UnitData
	if not campo.monarchy.begin(SimLoop.units, rei, companheiro, perfil, corpo, companhia):
		return false
	_aljava(rei, corpo)
	sync()
	return true


## O companheiro que nasce com o monarca (Greybox), ligado por id desde o primeiro tick.
static func bond(rei: int, companheiro: int) -> void:
	SimLoop.field.monarchy.bonds[rei] = companheiro
	sync()


## Um tick: o companheiro que morreu fica perdido, o incentivo conta, e a classe do Rei so
## esta em jogo com o Rei no trono (MU-22) — com o escudeiro do vinculo, e nenhum outro.
static func tick(delta: float) -> void:
	var campo := SimLoop.field
	campo.monarchy.watch(SimLoop.units, delta)
	sync()


static func sync() -> void:
	var campo := SimLoop.field
	var dados := data()
	campo.classes.active = dados.skill_class == Monarchy.REI
	var escudeiro := int(campo.monarchy.bonds.get(SimLoop.king_id, UnitSystem.NENHUM))
	campo.classes.squire_id = escudeiro if dados.service == ESCUDO else UnitSystem.NENHUM


## O Verbo 2 sem mais nada onde pegar: pagar ao companheiro (Q-114, Q-199, Q-200).
static func pay(units: UnitSystem, rei: int, campo: FieldWork) -> bool:
	if campo == null:
		return false
	match data().service:
		ESCUDO:
			return KingVerbs.arm_squire(units, rei, campo)
		CANTO:
			return _ao_bardo(units, rei, campo)
		FLECHAS:
			return _flechas(units, rei, campo)
	return false


## O companheiro a mao do rei: vivo, na faixa dele e ao alcance do Verbo 2.
static func at_hand(units: UnitSystem, rei: int) -> int:
	var alcance := SimFactory.curve().recruit_notice_px
	return SimLoop.field.monarchy.at_hand(units, rei, alcance)


## Se o monarca em jogo pode evoluir: o Rei pela classe dele, os outros pela do perfil.
static func can_evolve(campo: FieldWork, sementes: int) -> bool:
	var classe := skill_class()
	if classe == Monarchy.REI:
		return campo.classes.can_evolve(sementes)
	return campo.hero_progress.can_evolve(classe, sementes)


static func evolve(campo: FieldWork, estado: GameState) -> bool:
	var classe := skill_class()
	if classe == Monarchy.REI:
		return campo.classes.evolve(estado)
	return campo.hero_progress.evolve(classe, estado)


## A coroa passou de `velho` a `novo` (§16): o companheiro vivo segue o herdeiro, e o
## herdeiro do Arqueiro traz a sua aljava, com as flechas iniciais (Q-200, Q-202).
static func crowned(velho: int, novo: int) -> void:
	SimLoop.field.monarchy.crown(velho, novo)
	var i := SimLoop.units.index_of(novo)
	if i != UnitSystem.NENHUM:
		_aljava(novo, Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData)
	sync()


static func _aljava(rei: int, corpo: UnitData) -> void:
	if corpo == null or corpo.ammo <= 0:
		return
	var flechas := int(corpo.ability_params.get(&"start_ammo", corpo.ammo))
	SimLoop.field.supply.arm(SimLoop.units, SimLoop.units.index_of(rei), corpo, flechas)


## Uma moeda da bolsa da imperatriz para o orcamento do Bardo, ate ao teto (Q-199).
static func _ao_bardo(units: UnitSystem, rei: int, campo: FieldWork) -> bool:
	var b := at_hand(units, rei)
	var r := units.index_of(rei)
	if b == UnitSystem.NENHUM or r == UnitSystem.NENHUM or units.carried_coins[r] <= 0:
		return false
	var corpo := Registry.entry(&"units", units.data_ids[b]) as UnitData
	var teto := int(corpo.ability_params.get(&"budget_cap", 0))
	if campo.monarchy.fund(units.ids[b], 1, teto) <= 0:
		return false
	units.carried_coins[r] -= 1
	EventBus.queue(&"coin_spent", [1, BARDO])
	return true


## Um lote de flechas do escudeiro, pago com uma moeda da bolsa do imperador (Q-200).
## O lote e o do escudeiro (6), e nao o da banca do arco (12).
static func _flechas(units: UnitSystem, rei: int, campo: FieldWork) -> bool:
	var r := units.index_of(rei)
	var e := at_hand(units, rei)
	if e == UnitSystem.NENHUM or r == UnitSystem.NENHUM:
		return false
	var corpo := Registry.entry(&"units", units.data_ids[r]) as UnitData
	var antes := campo.supply.left(units, r, corpo)
	var gasto := campo.supply.refill(units, r, corpo, squire_lot(units.data_ids[e]))
	if gasto > 0:
		EventBus.queue(&"coin_spent", [gasto, ALJAVA])
	return campo.supply.left(units, r, corpo) > antes


## Quantas flechas o escudeiro da por uma moeda (Q-200); sem o parametro, o da banca.
static func squire_lot(squire: StringName) -> int:
	var dados := Registry.entry(&"units", squire) as UnitData
	if dados != null and dados.ability_params.has(&"arrows_per_coin"):
		return int(dados.ability_params[&"arrows_per_coin"])
	return RulesFactory.rules().arrows_per_coin


## Se quem se conduz corre neste passo: a tecla, com o folego dele (Q-193). Montado, o
## cavalo galopa sem folego, e o do monarca recupera.
static func runs(quer: bool, dt: float) -> bool:
	var campo := SimLoop.field
	var c := SimFactory.curve()
	var montado := campo.mount.rider != UnitSystem.NENHUM and campo.mount.rider == Assume.driven()
	var cap := c.king_run_stamina_s * (c.king_run_evolved_mult if evolved(campo) else 1.0)
	var corre := campo.stamina.step(quer and not montado, dt, cap, c.king_run_refill_s)
	return quer if montado else corre


## Se o monarca em jogo ja evoluiu: o Rei pela classe dele, os outros pelo perfil.
static func evolved(campo: FieldWork) -> bool:
	var classe := skill_class()
	if classe == Monarchy.REI:
		return campo.classes != null and campo.classes.phase > ClassSystem.PRIMEIRA
	return campo.hero_progress.phase_of(classe) > 1
