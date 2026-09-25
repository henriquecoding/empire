# src/sim/systems/feat_ledger.gd — os feitos registados (§76).
#
# "Ganha-se por feito registado: uma condicao que o sistema ja observa para
# outra coisa qualquer." Isto e o registo: quem abateu o que, quantas noites
# cada um passou num posto de cerco, quem esteve dentro da mancha, ha quantos
# dias tem a mesma arma. Nao da nomes — diz ao TitleSystem quem os merece.
#
# Cinco dos nove feitos tem hoje o que observar. Os outros quatro precisam de
# portoes (o unico sobrevivente de um portao), de arrastar corpos (§16), de
# cozinha e de ressurreicao (§16) — e nunca se cumprem ate la (Q-094).
#
# Puro. Os abates leem-se dos acontecimentos que o CombatSystem ja devolve: o
# ultimo golpe numa criatura e de quem a abateu.
class_name FeatLedger
extends RefCounted

## "10 Rastejantes abatidos" (§76) e o "Ariete de lodo" — o que tem a tag siege.
const RASTEJANTE := &"crawler"
const CERCO := &"siege"
## Os postos de cerco: o muro e a torre (jobs.csv).
const POSTOS_DE_CERCO: Array[StringName] = [&"wall", &"tower"]

var kills: Dictionary = {}
var rams: Dictionary = {}
var nights_post: Dictionary = {}
var days_armed: Dictionary = {}
## Quem esteve dentro da mancha esta noite. Conta so se estiver vivo a alvorada.
var stained: Dictionary = {}
## Os titulos que cada tropa ja mereceu, por ordem da tabela. Persiste: quem
## espera por vaga continua a merece-lo.
var earned: Dictionary = {}

var _ultimo_golpe: Dictionary = {}
var _criaturas: Dictionary
var _tropas: Dictionary


func _init(criaturas: Dictionary, tropas: Dictionary) -> void:
	_criaturas = criaturas
	_tropas = tropas


## Os acontecimentos do combate (§50), tal e qual o CombatSystem os devolve.
func observe(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		if not e.get(CombatSystem.CRIATURA, false):
			continue
		match int(e[CombatSystem.CHAVE]):
			CombatSystem.EV_DANO:
				_ultimo_golpe[e[CombatSystem.PARA]] = e[CombatSystem.DE]
			CombatSystem.EV_MORTE:
				_abate(e)


## Todas as tuas tropas entre `de` e `ate` em x, na superficie: estao dentro da
## mancha neste tick.
func stain(unidades: UnitSystem, de: float, ate: float) -> void:
	for i in unidades.count():
		if unidades.bands[i] == int(Band.Kind.SURFACE) and unidades.xs[i] >= de:
			if unidades.xs[i] <= ate and unidades.alive(i):
				stained[unidades.ids[i]] = true


## A alvorada, para uma tropa viva e tua: soma a noite e devolve os titulos que
## ela passou a merecer, pela ordem de `titulos`.
func dawn(unidades: UnitSystem, i: int, postos: JobBoard, titulos: Array[TitleData]) -> void:
	var unit_id := unidades.ids[i]
	var vaga := postos.slot_of(unidades.job_ids[i])
	if vaga != null and POSTOS_DE_CERCO.has(vaga.job_id):
		nights_post[unit_id] = nights_post.get(unit_id, 0) + 1
	var dados: UnitData = _tropas.get(unidades.data_ids[i])
	if dados != null and dados.weapon_kind != &"":
		days_armed[unit_id] = days_armed.get(unit_id, 0) + 1
	var ja: Array = earned.get(unit_id, [])
	for t in titulos:
		if not ja.has(String(t.id)) and _cumpriu(unit_id, t):
			ja.append(String(t.id))
	if not ja.is_empty():
		earned[unit_id] = ja


## Quem ja nao esta: o registo dela vai-se com ela.
func forget(unit_id: int) -> void:
	for tabela in [kills, rams, nights_post, days_armed, stained, earned]:
		tabela.erase(unit_id)


func to_dict() -> Dictionary:
	return {
		&"feat_kills": kills,
		&"feat_rams": rams,
		&"feat_nights_post": nights_post,
		&"feat_days_armed": days_armed,
		&"feat_stained": stained,
		&"feat_earned": earned,
	}


func from_dict(d: Dictionary) -> void:
	kills = d.get(&"feat_kills", kills)
	rams = d.get(&"feat_rams", rams)
	nights_post = d.get(&"feat_nights_post", nights_post)
	days_armed = d.get(&"feat_days_armed", days_armed)
	stained = d.get(&"feat_stained", stained)
	earned = d.get(&"feat_earned", earned)


func _abate(e: Dictionary) -> void:
	var creature_id: int = e[CombatSystem.DE]
	var quem: int = _ultimo_golpe.get(creature_id, UnitSystem.NENHUM)
	_ultimo_golpe.erase(creature_id)
	if quem == UnitSystem.NENHUM:
		return
	var que: StringName = e.get(CombatSystem.QUEM, &"")
	if que == RASTEJANTE:
		kills[quem] = kills.get(quem, 0) + 1
	var dados: CreatureData = _criaturas.get(que)
	if dados != null and dados.tags.has(CERCO):
		rams[quem] = rams.get(quem, 0) + 1


func _cumpriu(unit_id: int, t: TitleData) -> bool:
	match t.condition_kind:
		&"nights_in_siege_post":
			return nights_post.get(unit_id, 0) >= t.condition_value
		&"killed_ram":
			return rams.get(unit_id, 0) >= t.condition_value
		&"kills":
			return kills.get(unit_id, 0) >= t.condition_value
		&"survived_inside_stain":
			return stained.get(unit_id, false)
		&"same_weapon_days":
			return days_armed.get(unit_id, 0) >= t.condition_value
	return false
