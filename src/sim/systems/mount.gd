# src/sim/systems/mount.gd — o cavalo de tracao e os alforges (§12; Q-169, o dono a
# 30/09/2026).
#
# O dono: "O personagem que o jogador controla corre a 1,8x, o cavalo deve correr a 2,1x.
# O jogador pode armazenar ate 20 moedas na montaria ou outros itens, algo similar a Red
# Dead Redemption 2." A proposta punha folego na corrida; a resposta nao o pede, e correr
# continua sem custo (Q-149).
#
# O cavalo compra-se no estabulo (mounts.csv, `cost`): as moedas que o rei la larga
# pagam-no, como as da Casa de Treino. Quem o jogador conduz monta-o quando passa no
# estabulo, e o cavalo fica com quem o monta — o rei ou um corpo de classe. Montado anda a
# `speed_multiplier` e corre a `run_multiplier`. Os alforges levam `saddlebag_coins` moedas
# por cima do saco de quem monta, e os itens deles (storages.csv) juntam-se ao
# armazenamento dele (Storage.spill). Quem desmonta deixa nos alforges o que passou do
# saco. O cavalo de tracao e da superficie: quem desce ao subsolo desmonta, e se quem o
# monta cai, as moedas caem com ele e o cavalo volta ao estabulo.
#
# Puro: as moedas, as obras, as tropas e os dados entram de fora.
class_name Mount
extends RefCounted

const NENHUM := -1
const METADE := 0.5

## A montaria do reino (mounts.csv); vazio enquanto nao se comprou nenhuma.
var owned: StringName = &""
## Quem a monta; NENHUM com ela no estabulo.
var rider := NENHUM
## O que ja se pagou dela no estabulo.
var paid := 0
## As moedas que ficaram nos alforges quando quem a montava desmontou.
var coins := 0
## Os itens dos alforges.
var bags: Storage

var _dados: MountData
var _estabulo: StringName
var _ligado: Storage  # o armazenamento que os alforges prolongam agora


## `dados` e a montaria a venda no estabulo; `alforges`, o armazenamento dela.
func _init(dados: MountData = null, alforges: StorageData = null) -> void:
	_dados = dados
	_estabulo = dados.obtain_ref if dados != null else &""
	bags = Storage.new(alforges)


## Quanto falta pagar do cavalo neste sitio: so num estabulo de pe, sem cavalo comprado.
func owed(vaga: BuildSlot) -> int:
	if _dados == null or owned != &"" or vaga.kind != _estabulo or not vaga.standing():
		return 0
	return maxi(0, _dados.cost - paid)


## As moedas largadas no estabulo pagam o cavalo. Devolve o valor apanhado.
func absorb(moedas: CoinSystem, obras: BuildSystem) -> int:
	var valor := 0
	for vaga in obras.standing():
		var falta := owed(vaga)
		if falta <= 0:
			continue
		var apanhado := CoinTarget.take(moedas, vaga, falta)
		paid += apanhado
		valor += apanhado
		if paid >= _dados.cost:
			owned = _dados.id
			paid = 0
	return valor


## O passo de quem o jogador conduz: a pe, 1 ou `a_pe` a correr; montado, os do cavalo.
func pace(conduzido: int, correr: bool, a_pe: float) -> float:
	if rider == NENHUM or rider != conduzido or _dados == null:
		return a_pe if correr else 1.0
	var galope := _dados.run_multiplier if _dados.run_multiplier > 0.0 else _dados.speed_multiplier
	return galope if correr else _dados.speed_multiplier


## Todos os ticks: quem monta e desce ao subsolo desmonta; quem cai deixa-o voltar ao
## estabulo; e quem o jogador conduz monta-o ao passar no estabulo. Devolve verdadeiro se
## quem monta mudou — o armazenamento de quem monta muda com ele.
func tick(unidades: UnitSystem, conduzido: int, obras: BuildSystem) -> bool:
	if rider != NENHUM:
		var i := unidades.index_of(rider)
		if i == NENHUM or not unidades.alive(i):
			_largar(unidades, i, false)
			return true
		if unidades.bands[i] != int(_dados.band):
			dismount(unidades)
			return true
		return false
	var c := unidades.index_of(conduzido)
	if owned == &"" or c == NENHUM or not unidades.alive(c) or not _no_estabulo(unidades, c, obras):
		return false
	mount(unidades, conduzido)
	return true


## `quem` monta: o saco dele cresce os alforges, e as moedas deles passam ao saco.
func mount(unidades: UnitSystem, quem: int) -> void:
	var i := unidades.index_of(quem)
	if i == NENHUM or rider != NENHUM or owned == &"":
		return
	rider = quem
	unidades.coin_capacities[i] += _dados.saddlebag_coins
	unidades.carried_coins[i] += coins
	coins = 0


## Quem monta desmonta: o que passa do saco dele fica nos alforges.
func dismount(unidades: UnitSystem) -> void:
	_largar(unidades, unidades.index_of(rider), true)


## Os alforges passam a prolongar `armazem` (o de quem monta), e mais nenhum.
func link(armazem: Storage) -> void:
	if _ligado != null:
		_ligado.spill = null
	_ligado = armazem
	if armazem != null:
		armazem.spill = bags


func _largar(unidades: UnitSystem, i: int, guardar: bool) -> void:
	rider = NENHUM
	if i == NENHUM:
		return
	var saco := unidades.coin_capacities[i] - _dados.saddlebag_coins
	if guardar:
		coins = clampi(unidades.carried_coins[i] - saco, 0, _dados.saddlebag_coins)
		unidades.carried_coins[i] -= coins
	unidades.coin_capacities[i] = saco


func _no_estabulo(unidades: UnitSystem, c: int, obras: BuildSystem) -> bool:
	if unidades.bands[c] != int(_dados.band):
		return false
	for vaga in obras.standing():
		if vaga.kind == _estabulo and absf(unidades.xs[c] - vaga.x) <= vaga.width * METADE:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		&"owned": owned, &"rider": rider, &"paid": paid, &"coins": coins, &"bags": bags.to_dict()
	}


## Um save de antes do cavalo: nenhum comprado, os alforges vazios.
func from_dict(d: Dictionary) -> void:
	owned = StringName(d.get(&"owned", &""))
	rider = int(d.get(&"rider", NENHUM))
	paid = int(d.get(&"paid", 0))
	coins = int(d.get(&"coins", 0))
	bags.from_dict(d.get(&"bags", {}))
