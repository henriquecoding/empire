# src/sim/systems/morale_system.gd — moral, fuga, e o raio do rei (§07, §52).
#
# O §07 escreve-o como "um unico modificador com raio, e tres consequencias":
#
#   · Muro cai      → tropas com vida < 30% e custo <= 4 fogem para o nucleo.
#   · Rei em campo  → NENHUMA tropa foge dentro de um raio de 260 px. A defesa
#                     aguenta — e o rei pode morrer. E a decisao tactica de
#                     maior risco do jogo.
#   · Impulso Vigilia (§15) → ninguem foge esta noite. Fase 2, e nao esta aqui.
#
# A segunda e a que da peso a por o rei na linha, e e a unica que transforma uma
# estatistica numa decisao: o raio nao protege quem esta longe, e ir la protege-
# los a custa de levar o monarca para onde as criaturas estao.
#
# O FLEE da tabela da §52 era, ate aqui, um estado que nada alcancava: "vida <
# 25% e classe permite" nao tinha quem o escrevesse. Passa a ter.
#
# Puro: nao e Node, nao conhece o catalogo de eventos e nao sorteia nada. Os
# numeros sao todos da curva — king_presence_radius, flee_health,
# breach_flee_health e breach_flee_max_cost.
class_name MoraleSystem
extends RefCounted

const NENHUM := -1

## §07: "Avanca sempre. Nao recua nem com o muro caido." E a tag do Berserker de
## Raiz em units.csv, e e a unica coisa que isenta alguem desta seccao inteira.
const SEM_RECUO := &"no_retreat"

## As chaves do que tick() devolve.
const CHAVE := &"kind"
const UNIDADE := &"unit_id"
const DE := &"from"
const PARA := &"to"
const PORQUE := &"reason"

const EV_FUGIU := 0
const EV_VOLTOU := 1

## As razoes, que o §46 leva no unit_fled.
const POR_VIDA := &"health"
const POR_BRECHA := &"breach"

## A Vigilia (§15): esta noite ninguem foge. Escrita pelo FieldWork a cada tick.
var steadfast := false
var _curva: EconomyCurve
var _dados: Dictionary = {}


func _init(curva: EconomyCurve, dados: Dictionary) -> void:
	assert(curva != null, "o MoraleSystem precisa de um EconomyCurve")
	_curva = curva
	_dados = dados


## Passo 4 do §43, depois de o combate escolher alvos: quem foge deixa de lutar.
##
## `brecha` e verdadeiro no tick em que um muro caiu. Por id crescente (§42).
func tick(unidades: UnitSystem, king_id: int, core_x: float, brecha: bool) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var rei_x := _onde_esta_o_rei(unidades, king_id)
	for unit_id in TargetPicker.ids_por_ordem(unidades.ids):
		var i := unidades.index_of(unit_id)
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		if unidades.states[i] == UnitFsm.State.FLEE:
			_talvez_volte(unidades, i, core_x, rei_x, eventos)
			continue
		_talvez_fuja(unidades, i, core_x, rei_x, brecha, eventos)
	return eventos


## O raio do §07, e o que ele quer dizer: quem esta dentro dele nao foge, e quem
## ja fugia volta ao trabalho. Sem rei em campo nao ha raio nenhum.
func protected(unidades: UnitSystem, i: int, rei_x: float) -> bool:
	if is_inf(rei_x):
		return false
	return absf(unidades.xs[i] - rei_x) <= _curva.king_presence_radius


## Verdadeiro se esta tropa pode fugir de todo. "Avanca sempre. Nao recua nem
## com o muro caido" e uma tag e nao um caso especial (§07).
func can_flee(unidades: UnitSystem, i: int) -> bool:
	var dados: UnitData = _dados.get(unidades.data_ids[i])
	return not steadfast and dados != null and not dados.tags.has(SEM_RECUO)


func _onde_esta_o_rei(unidades: UnitSystem, king_id: int) -> float:
	var rei := unidades.index_of(king_id)
	if rei == NENHUM or not unidades.alive(rei):
		return INF
	return unidades.xs[rei]


func _talvez_fuja(
	unidades: UnitSystem,
	i: int,
	core_x: float,
	rei_x: float,
	brecha: bool,
	eventos: Array[Dictionary]
) -> void:
	if protected(unidades, i, rei_x) or not can_flee(unidades, i):
		return
	var racio := float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i]))
	var porque := &""
	if racio < _curva.flee_health:
		porque = POR_VIDA
	elif brecha and racio < _curva.breach_flee_health:
		if unidades.recruit_costs[i] <= _curva.breach_flee_max_cost:
			porque = POR_BRECHA
	if porque == &"":
		return
	var antes := unidades.states[i] as UnitFsm.State
	unidades.states[i] = UnitFsm.State.FLEE
	unidades.set_target_x(unidades.ids[i], core_x)
	eventos.append(
		{
			CHAVE: EV_FUGIU,
			UNIDADE: unidades.ids[i],
			DE: antes,
			PARA: UnitFsm.State.FLEE,
			PORQUE: porque
		}
	)


## §52, a linha do FLEE: "sai quando chega ao nucleo, ou morre". E tambem quando
## o rei chega — que e a unica forma de a defesa aguentar sem ser por milagre.
func _talvez_volte(
	unidades: UnitSystem, i: int, core_x: float, rei_x: float, eventos: Array[Dictionary]
) -> void:
	var chegou := is_equal_approx(unidades.xs[i], core_x)
	if not chegou and not protected(unidades, i, rei_x):
		return
	unidades.states[i] = UnitFsm.State.WORK
	(
		eventos
		. append(
			{
				CHAVE: EV_VOLTOU,
				UNIDADE: unidades.ids[i],
				DE: UnitFsm.State.FLEE,
				PARA: UnitFsm.State.WORK,
			}
		)
	)
