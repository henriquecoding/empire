# src/sim/systems/title_system.gd — ninguem tem nome ate merecer um (§76).
#
# Na alvorada, se uma tropa viva cumpriu um feito, o imperio nomeia-a. Quatro
# regras: nove nomes no maximo (named_cap), e o decimo fica a espera — "uma
# promessa por pagar"; um titulo e unico enquanto o dono vive; morto o dono, o
# titulo fica de luto title_mourning_days e volta com ordinal — O Segundo Que
# Ficou; e um nomeado pesa mais no campo (§74), que e o AmargueiroSystem a ler.
#
# Os campos do save sao os da §84: titles_holder, titles_ordinal,
# titles_mourning. Os feitos sao do FeatLedger; aqui so se da o nome.
#
# Das nove bonificacoes, so a vida maxima tem hoje onde pegar. As outras mexem
# na moral, na cadencia, no dano e na comida, e ficam registadas (Q-102).
class_name TitleSystem
extends RefCounted

const EV_NOMEADO := 0
const EV_ESPERA := 1
const EV_LUTO := 2

const CHAVE := &"kind"
const UNIDADE := &"unit_id"
const TITULO := &"title"
const ORDINAL := &"ordinal"

const REI := &"king"
const VIDA := &"max_health"

## titulo -> unit_id de quem o tem.
var holders: Dictionary = {}
## titulo -> quantos ja o tiveram (o primeiro e 1).
var ordinals: Dictionary = {}
## titulo -> o dia em que o luto acaba.
var mourning: Dictionary = {}
## Quem mereceu e nao tem vaga, pela ordem em que chegou.
var waiting: PackedInt32Array = PackedInt32Array()
var feats: FeatLedger

var _titulos: Array[TitleData] = []
var _teto: int
var _luto: int
var _tropas: Dictionary


func _init(
	titulos: Array[TitleData], curva: EconomyCurve, tropas: Dictionary, criaturas: Dictionary
) -> void:
	_titulos = titulos.duplicate()
	_titulos.sort_custom(
		func(a: TitleData, b: TitleData) -> bool: return String(a.id) < String(b.id)
	)
	_teto = curva.named_cap
	_luto = curva.title_mourning_days
	_tropas = tropas
	feats = FeatLedger.new(criaturas, tropas)


func count() -> int:
	return holders.size()


func title_of(unit_id: int) -> String:
	for t in holders:
		if holders[t] == unit_id:
			return t
	return ""


func ordinal_of(titulo: StringName) -> int:
	return ordinals.get(String(titulo), 0)


## unit_id -> titulo, de quem o tem. E o que o Amargueiro e a Oferta leem.
func by_unit() -> Dictionary:
	var saida := {}
	for t in holders:
		saida[holders[t]] = t
	return saida


func observe(eventos: Array[Dictionary]) -> Array[Dictionary]:
	feats.observe(eventos)
	return eventos


func stain(unidades: UnitSystem, de: float, ate: float) -> void:
	feats.stain(unidades, de, ate)


## A alvorada: primeiro o luto de quem se foi, depois os feitos da noite, e so
## entao os nomes — quem espera primeiro, pela ordem em que chegou.
func at_dawn(dia: int, unidades: UnitSystem, postos: JobBoard) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	_enterrar(dia, unidades, eventos)
	var tuas := _tuas(unidades)
	for unit_id in tuas:
		feats.dawn(unidades, unidades.index_of(unit_id), postos, _titulos)
	feats.stained.clear()
	var ordem := Array(waiting)
	for unit_id in tuas:
		if not ordem.has(unit_id):
			ordem.append(unit_id)
	for unit_id in ordem:
		if title_of(unit_id) != "" or not feats.earned.has(unit_id):
			continue
		var livre := _livre(feats.earned[unit_id], dia)
		if livre != "" and count() < _teto:
			_nomear(unit_id, livre, unidades, eventos)
		elif not waiting.has(unit_id):
			waiting.append(unit_id)
			eventos.append({CHAVE: EV_ESPERA, UNIDADE: unit_id})
	return eventos


func to_dict() -> Dictionary:
	var d := {
		&"titles_holder": holders,
		&"titles_ordinal": ordinals,
		&"titles_mourning": mourning,
		&"titles_waiting": waiting,
	}
	d.merge(feats.to_dict())
	return d


func from_dict(d: Dictionary) -> void:
	holders = d.get(&"titles_holder", holders)
	ordinals = d.get(&"titles_ordinal", ordinals)
	mourning = d.get(&"titles_mourning", mourning)
	waiting = d.get(&"titles_waiting", waiting)
	feats.from_dict(d)


## Quem tinha nome e ja nao esta — morreu, criou raiz, foi levado: o titulo fica
## de luto a partir de hoje.
func _enterrar(dia: int, unidades: UnitSystem, eventos: Array[Dictionary]) -> void:
	for t in holders.keys():
		var i := unidades.index_of(holders[t])
		if i != UnitSystem.NENHUM and unidades.alive(i):
			continue
		feats.forget(holders[t])
		holders.erase(t)
		mourning[t] = dia + _luto
		eventos.append({CHAVE: EV_LUTO, TITULO: t})
	for k in range(waiting.size() - 1, -1, -1):
		var i := unidades.index_of(waiting[k])
		if i == UnitSystem.NENHUM or not unidades.alive(i):
			feats.forget(waiting[k])
			waiting.remove_at(k)


## Tuas, vivas, sem o monarca, por id crescente (§42).
func _tuas(unidades: UnitSystem) -> PackedInt32Array:
	var ids := PackedInt32Array()
	for i in unidades.count():
		if not unidades.alive(i) or unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados != null and dados.tags.has(REI):
			continue
		ids.append(unidades.ids[i])
	ids.sort()
	return ids


## O primeiro dos merecidos que ninguem tem e que ja nao esta de luto.
func _livre(merecidos: Array, dia: int) -> String:
	for t in merecidos:
		if holders.has(t):
			continue
		if mourning.has(t) and dia < mourning[t]:
			continue
		return t
	return ""


func _nomear(unit_id: int, t: String, unidades: UnitSystem, eventos: Array[Dictionary]) -> void:
	mourning.erase(t)
	holders[t] = unit_id
	ordinals[t] = ordinals.get(t, 0) + 1
	var k := waiting.find(unit_id)
	if k >= 0:
		waiting.remove_at(k)
	for dados in _titulos:
		if String(dados.id) == t and dados.grant_kind == VIDA:
			var i := unidades.index_of(unit_id)
			unidades.max_healths[i] += int(dados.grant_value)
			unidades.healths[i] += int(dados.grant_value)
	eventos.append({CHAVE: EV_NOMEADO, UNIDADE: unit_id, TITULO: t, ORDINAL: ordinals[t]})
