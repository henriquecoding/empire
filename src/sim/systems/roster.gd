# src/sim/systems/roster.gd — quem o jogador pode assumir, e quem assume (§08, §24;
# Q-150, Q-162, Q-178, o dono a 30/09/2026).
#
# O §08: "Trocar de classe e o Verbo 2 sobre uma tropa da classe correspondente. O
# personagem largado passa a IA com o comportamento normal daquela classe." E o dono:
# o rei fica sempre no imperio, e quem vai para longe sao as classes jogaveis — que sao
# maiores do que as tropas (Q-162). Por isso a tropa assumida passa ao corpo jogavel da
# classe (o `base_unit`, na escala 3), com a vida na mesma proporcao, e e esse corpo
# que o jogador conduz: a coluna `pilot` do UnitSystem, que os sistemas de IA deixam em
# paz. Um corpo por classe; o Verbo 2 desse corpo ao pe do rei volta ao rei.
#
# Uma classe sem tropa (o Trepador, os cavaleiros) chega ao nucleo na alvorada a seguir
# a conquista do povo dela (§13: "um novo personagem controlavel, com a silhueta daquele
# povo"), uma vez so. Cada corpo tem o seu armazenamento (Q-153).
#
# Puro: as classes, as tropas e os armazenamentos entram ja lidos.
class_name Roster
extends RefCounted

const NENHUM := -1
const REI := &"monarch"
const INICIO := &"start"
const STARTERS: Array[StringName] = [&"monarch", &"archer", &"bard"]

var starting_class: StringName = &""

## As classes cujo corpo ja chegou pela conquista, por id.
var arrived := PackedStringArray()
## O armazenamento de cada corpo jogavel que nao e o rei: unit id -> Storage.
var storages: Dictionary = {}

var _classes: Dictionary  # id -> ClassData
var _tropas: Dictionary  # id -> UnitData
var _armazens: Dictionary  # id -> StorageData


func _init(classes: Dictionary = {}, tropas: Dictionary = {}, armazens: Dictionary = {}) -> void:
	_classes = classes
	_tropas = tropas
	_armazens = armazens


## As classes que se podem assumir: as de inicio e as dos povos conquistados (§13).
## `classe_do_povo` e o povo -> a classe jogavel dele (peoples.csv).
func unlocked(conquistas: PackedStringArray, classe_do_povo: Dictionary) -> PackedStringArray:
	var saida := PackedStringArray()
	for id: StringName in _ids():
		if (_classes[id] as ClassData).unlock == INICIO:
			saida.append(String(id))
	for povo in conquistas:
		var classe := String(classe_do_povo.get(StringName(povo), &""))
		if not classe.is_empty() and not saida.has(classe):
			saida.append(classe)
	return saida


## A classe de quem tem este corpo, ou &"".
func class_of_body(data_id: StringName) -> StringName:
	for id: StringName in _ids():
		if (_classes[id] as ClassData).base_unit == data_id:
			return id
	return &""


## A classe cuja tropa e esta, ou &"".
func class_of_troop(data_id: StringName) -> StringName:
	for id: StringName in _ids():
		var troop := (_classes[id] as ClassData).troop
		if troop != &"" and troop == data_id:
			return id
	return &""


## O corpo vivo da classe que e de `dono`, ou NENHUM.
func body(unidades: UnitSystem, classe: StringName, dono: int) -> int:
	var dados: ClassData = _classes.get(classe)
	for i in unidades.count():
		if dados != null and unidades.data_ids[i] == dados.base_unit and unidades.alive(i):
			if unidades.owners[i] == dono:
				return unidades.ids[i]
	return NENHUM


## Quem o jogador conduz agora: o corpo assumido, se esta vivo; senao o rei.
func driven(unidades: UnitSystem, rei: int) -> int:
	var i := unidades.index_of(unidades.pilot)
	return unidades.pilot if i != NENHUM and unidades.alive(i) else rei


## A escolha do primeiro corpo; o rei e o saco do reino continuam no nucleo.
func begin(unidades: UnitSystem, estado: GameState, rei: int, classe: StringName) -> int:
	var r := unidades.index_of(rei)
	if not STARTERS.has(classe) or r == NENHUM or not unidades.alive(r):
		return NENHUM
	if starting_class != &"":
		return driven(unidades, rei)
	starting_class = classe
	if classe == REI:
		unidades.pilot = NENHUM
		return rei
	var dados: ClassData = _classes.get(classe)
	var quem := body(unidades, classe, unidades.owners[r])
	if quem == NENHUM:
		quem = unidades.spawn(estado, _tropas[dados.base_unit], unidades.owners[r], unidades.xs[r])
	unidades.pilot = quem
	storage_of(unidades, quem)
	return quem


## O Verbo 2 do rei: o corpo jogavel ou a tropa tua mais perto (a `alcance`, na faixa
## dele) de uma classe em `desbloqueadas`. A tropa passa a corpo. Devolve quem se
## assumiu, ou NENHUM.
func take(unidades: UnitSystem, rei: int, alcance: float, desbloqueadas: PackedStringArray) -> int:
	var r := unidades.index_of(rei)
	if r == NENHUM or not unidades.alive(r):
		return NENHUM
	var melhor := NENHUM
	var perto := alcance
	for i in unidades.count():
		if i == r or not unidades.alive(i) or unidades.owners[i] != unidades.owners[r]:
			continue
		var d := absf(unidades.xs[i] - unidades.xs[r])
		if unidades.bands[i] != unidades.bands[r] or d > perto:
			continue
		if _serve(unidades, i, unidades.owners[r], desbloqueadas):
			if d < perto or melhor == NENHUM or unidades.ids[i] < unidades.ids[melhor]:
				melhor = i
				perto = d
	if melhor == NENHUM:
		return NENHUM
	var classe := class_of_troop(unidades.data_ids[melhor])
	if classe != &"":
		raise(unidades, melhor, _tropas.get((_classes[classe] as ClassData).base_unit))
	unidades.pilot = unidades.ids[melhor]
	return unidades.pilot


## A tropa `i` passa ao corpo `corpo`: o id dos dados e os numeros dele, com a vida na
## mesma proporcao. Sem posto: quem o jogador conduz nao tem posto.
func raise(unidades: UnitSystem, i: int, corpo: UnitData) -> void:
	if corpo == null:
		return
	var antes := maxf(1.0, float(unidades.max_healths[i]))
	unidades.data_ids[i] = corpo.id
	unidades.healths[i] = roundi(unidades.healths[i] * corpo.max_health / antes)
	unidades.max_healths[i] = corpo.max_health
	unidades.speeds[i] = corpo.move_speed
	unidades.coin_capacities[i] = corpo.coin_capacity
	unidades.recruit_costs[i] = corpo.recruit_cost
	unidades.job_ids[i] = UnitSystem.NENHUM


## O Verbo 2 do corpo conduzido ao pe do rei (a `alcance`, na faixa dele): volta-se ao
## rei. Verdadeiro se voltou.
func back(unidades: UnitSystem, rei: int, alcance: float) -> bool:
	var i := unidades.index_of(unidades.pilot)
	var r := unidades.index_of(rei)
	if i == NENHUM or r == NENHUM or not unidades.alive(r):
		return false
	if unidades.bands[i] != unidades.bands[r] or absf(unidades.xs[i] - unidades.xs[r]) > alcance:
		return false
	unidades.pilot = NENHUM
	return true


## Quem se conduzia e morreu, ou saiu das colunas: conduz-se o rei (§16).
func forget_dead(unidades: UnitSystem) -> void:
	var i := unidades.index_of(unidades.pilot)
	if unidades.pilot != NENHUM and (i == NENHUM or not unidades.alive(i)):
		unidades.pilot = NENHUM


## A alvorada: o corpo de cada classe sem tropa cujo povo conquistaste chega a `x`,
## de `rei`, uma vez so. Devolve os ids de quem chegou.
func arrive(
	unidades: UnitSystem,
	estado: GameState,
	rei: int,
	x: float,
	conquistas: PackedStringArray,
	classe_do_povo: Dictionary
) -> Array[int]:
	var chegaram: Array[int] = []
	var r := unidades.index_of(rei)
	if r == NENHUM:
		return chegaram
	for povo in conquistas:
		var classe := StringName(classe_do_povo.get(StringName(povo), &""))
		var dados: ClassData = _classes.get(classe)
		if dados == null or classe == REI or dados.troop != &"" or arrived.has(String(classe)):
			continue
		var corpo: UnitData = _tropas.get(dados.base_unit)
		if corpo == null or body(unidades, classe, unidades.owners[r]) != NENHUM:
			continue
		arrived.append(String(classe))
		chegaram.append(unidades.spawn(estado, corpo, unidades.owners[r], x))
	return chegaram


## O armazenamento do corpo `unit_id` (Q-153), feito na primeira vez pela classe dele.
func storage_of(unidades: UnitSystem, unit_id: int) -> Storage:
	if storages.has(unit_id):
		return storages[unit_id]
	var i := unidades.index_of(unit_id)
	var classe: ClassData = _classes.get(class_of_body(unidades.data_ids[i]) if i >= 0 else &"")
	var guardado := Storage.new(_armazens.get(classe.storage) if classe != null else null)
	storages[unit_id] = guardado
	return guardado


func to_dict() -> Dictionary:
	var armazens := {}
	for unit_id: int in storages:
		armazens[unit_id] = (storages[unit_id] as Storage).to_dict()
	return {&"arrived": arrived, &"storages": armazens, &"starting_class": starting_class}


## Um save de antes das classes nao tem nada disto: ninguem chegou, nada se leva.
func from_dict(d: Dictionary) -> void:
	starting_class = StringName(d.get(&"starting_class", &"monarch"))
	arrived = PackedStringArray(d.get(&"arrived", PackedStringArray()))
	storages = {}
	var armazens: Variant = d.get(&"storages", {})
	for unit_id: Variant in armazens if armazens is Dictionary else {}:
		var guardado: Dictionary = armazens[unit_id]
		var novo := Storage.new(_armazens.get(StringName(guardado.get(&"kind", &""))))
		novo.from_dict(guardado)
		storages[int(unit_id)] = novo


func _serve(unidades: UnitSystem, i: int, dono: int, desbloqueadas: PackedStringArray) -> bool:
	var corpo := class_of_body(unidades.data_ids[i])
	if corpo != &"":
		return corpo != REI and desbloqueadas.has(String(corpo))
	var classe := class_of_troop(unidades.data_ids[i])
	return (
		classe != &""
		and desbloqueadas.has(String(classe))
		and body(unidades, classe, dono) == NENHUM
	)


func _ids() -> Array:
	var ids := _classes.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids
