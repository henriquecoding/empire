# src/sim/systems/storage.gd — o armazenamento de quem se joga (Q-153).
#
# O dono, no painel (29/09/2026): "Equipments faz parte do armazenamento do
# personagem, cada personagem jogavel [tem] um tipo de armazenamento que deve ser
# desenvolvido e bem feito." Cada classe da §08 traz o seu (storages.csv): o cinto
# do rei, a aljava do arqueiro, os alforges do cavaleiro selado. O que la vai tem
# tipo e teto por tipo, e o que nao cabe nao entra. Trocar de personagem (o Verbo 2
# sobre uma tropa da classe, §08) troca o armazenamento: fica o que cabe no novo, e
# o resto cai para quem o largue no chao.
#
# As moedas nao entram: vao no saco do corpo (§02), que toda a gente tem. O que
# entra e o que se leva para usar — o archote (Q-029) e o primeiro.
#
# Puro: os tetos vem do StorageData; quem da e quem gasta sao os outros sistemas.
class_name Storage
extends RefCounted

## O archote (Q-029): o primeiro item que um personagem leva.
const ARCHOTE := &"torch"

## O id do StorageData em uso (storages.csv).
var kind: StringName = &""
## Onde se traz no corpo — a camada Equipments desenha-o ai.
var worn: StringName = &""
## Os alforges da montaria de quem o traz (Q-169): o que aqui nao cabe vai la, e o que
## aqui falta tira-se de la. Nulo a pe.
var spill: Storage

var _tetos: Dictionary = {}  # StringName -> int
var _itens: Dictionary = {}  # StringName -> int


func _init(dados: StorageData = null) -> void:
	if dados != null:
		refit(dados)


## Quantos `item` cabem aqui, alforges incluidos; zero se nao se leva.
func cap(item: StringName) -> int:
	return int(_tetos.get(item, 0)) + (spill.cap(item) if spill != null else 0)


func count(item: StringName) -> int:
	return int(_itens.get(item, 0)) + (spill.count(item) if spill != null else 0)


func room(item: StringName) -> int:
	return maxi(0, cap(item) - count(item))


## Guarda ate `quantos`, aqui primeiro e o resto nos alforges; devolve quantos entraram.
func put(item: StringName, quantos: int) -> int:
	var aqui := int(_itens.get(item, 0))
	var entram := clampi(quantos, 0, maxi(0, int(_tetos.get(item, 0)) - aqui))
	if entram > 0:
		_itens[item] = aqui + entram
	return entram + (spill.put(item, quantos - entram) if spill != null else 0)


## Tira ate `quantos`, daqui primeiro; devolve quantos sairam.
func take(item: StringName, quantos: int) -> int:
	var aqui := int(_itens.get(item, 0))
	var saem := clampi(quantos, 0, aqui)
	if saem > 0:
		_itens[item] = aqui - saem
	return saem + (spill.take(item, quantos - saem) if spill != null else 0)


## Os itens que este armazenamento leva, ordenados (§42).
func kinds() -> Array[StringName]:
	var saida: Array[StringName] = []
	for item in _tetos:
		saida.append(item)
	for item in spill.kinds() if spill != null else []:
		if not item in saida:
			saida.append(item)
	saida.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return saida


## Quao cheio vai, de 0 a 1 — o que a camada Equipments mostra, como o saco que
## enche do §24.
func fill() -> float:
	var teto := 0
	var leva := 0
	for item in kinds():
		teto += cap(item)
		leva += count(item)
	return 0.0 if teto <= 0 else float(leva) / float(teto)


## Passa a outro armazenamento (trocar de personagem, §08). Fica o que cabe no
## novo; devolve o que ja nao cabe, item -> quantos, para quem o largue no chao.
func refit(dados: StorageData) -> Dictionary:
	kind = dados.id
	worn = dados.worn
	_tetos = {}
	for item: StringName in dados.holds:
		_tetos[item] = int(dados.holds[item])
	var caiu := {}
	for item: StringName in _itens.keys():
		var sobra := int(_itens[item]) - int(_tetos.get(item, 0))
		if sobra > 0:
			caiu[item] = sobra
			_itens[item] = int(_tetos.get(item, 0))
	return caiu


func to_dict() -> Dictionary:
	return {&"kind": kind, &"items": _itens.duplicate()}


## O que se levava. O tipo vem da classe, nao do save: um save de outra versao, com
## outros tetos, fica com o que cabe (§62).
func from_dict(d: Dictionary) -> void:
	_itens = {}
	var itens: Dictionary = d.get(&"items", {})
	for item in itens:  # so aqui: os alforges guardam-se com a montaria (Q-169)
		var fica := clampi(int(itens[item]), 0, int(_tetos.get(StringName(item), 0)))
		if fica > 0:
			_itens[StringName(item)] = fica
