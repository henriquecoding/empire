# src/sim/systems/roster.gd — os corpos de classe que o reino tem, e o que cada um leva
# (§08, §13; Q-153, Q-162; ADR 0052).
#
# Ate a ADR 0052 era aqui que o jogador assumia uma tropa de classe pelo Verbo 2. O dono,
# a 02/10/2026: "somente imperadores sao controlaveis [...] tropas, oficios, diplomatas e
# companheiros permanecem sob IA". Assumir saiu: o que fica e o resto — o corpo de cada
# classe sem tropa (o Trepador, os cavaleiros), que chega ao nucleo na alvorada a seguir a
# conquista do povo dela, uma vez so, e passa a IA; e o armazenamento de cada corpo
# (Q-153). A coluna `pilot` continua, para a troca entre imperadores (UN-17).
#
# Puro: as classes, as tropas e os armazenamentos entram ja lidos.
class_name Roster
extends RefCounted

const NENHUM := -1
const REI := &"monarch"
const INICIO := &"start"

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
	return {&"arrived": arrived, &"storages": armazens}


## Um save de antes das classes nao tem nada disto: ninguem chegou, nada se leva. A escolha
## inicial antiga (starting_class) passou ao Monarchy na migracao v7.
func from_dict(d: Dictionary) -> void:
	arrived = PackedStringArray(d.get(&"arrived", PackedStringArray()))
	storages = {}
	var armazens: Variant = d.get(&"storages", {})
	for unit_id: Variant in armazens if armazens is Dictionary else {}:
		var guardado: Dictionary = armazens[unit_id]
		var novo := Storage.new(_armazens.get(StringName(guardado.get(&"kind", &""))))
		novo.from_dict(guardado)
		storages[int(unit_id)] = novo


func _ids() -> Array:
	var ids := _classes.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids
