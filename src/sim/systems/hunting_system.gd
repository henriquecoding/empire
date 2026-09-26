class_name HuntingSystem
extends RefCounted

## Sem coelho de abertura: um x negativo, que nenhuma clareira tem (HuntWatch).
const SEM_INTRO := -1.0

var day := 0
var rabbits: Array[float] = []
var intro_done := false
## O coelho do minuto 1:10 (§25): a primeira clareira do dia 1, junto ao castelo.
var intro_x := SEM_INTRO
## As clareiras que o dia ainda vai abrir, por vaga (Q-106): a caca reparte-se
## pela luz em vez de se esgotar na primeira meia hora.
var pending: Array = []
## Quanto de caca cada cacador teu leva no saco (id -> moedas). So isto se entrega
## ao rei: o preco que pagaste para o recrutar fica com ele (Q-111).
var bagged: Dictionary = {}
var _profiles: Dictionary
var _rabbit: WildlifeData


func _init(profiles: Dictionary, rabbit: WildlifeData) -> void:
	_profiles = profiles
	_rabbit = rabbit


func open_day(number: int, clearings: Array[float], waves: int = 1) -> void:
	if number <= day:
		return
	day = number
	pending = []
	for _k in maxi(1, waves):
		pending.append([])
	for i in clearings.size():
		pending[i % pending.size()].append(clearings[i])
	rabbits.assign(pending.pop_front())
	intro_x = clearings[0] if number == 1 and not clearings.is_empty() else SEM_INTRO


## Abre a vaga seguinte, se ainda houver.
func release() -> void:
	if not pending.is_empty():
		rabbits.append_array(pending.pop_front())


## O alvo de caca cede ao combate e aos postos; nunca atravessa faixas.
func plan(units: UnitSystem, daylight: bool) -> void:
	if not daylight or rabbits.is_empty():
		return
	for id in _hunters(units):
		var i := units.index_of(id)
		if units.owners[i] == RecruitSystem.SEM_DONO or units.job_ids[i] != UnitSystem.NENHUM:
			continue
		var prey := _nearest(units.xs[i])
		var data: UnitData = _profiles[units.data_ids[i]]
		if absf(prey - units.xs[i]) > data.range_px:
			units.set_target_x(id, prey)
		else:
			units.set_target_x(id, units.xs[i])


## Um coelho, uma moeda fisica (§25); usa a cadencia da arma, nao renda por tick.
## So quem tem dono caca; o arqueiro sem dono caca uma vez, e so o coelho do 1:10.
func resolve(units: UnitSystem, daylight: bool, intro_ready: bool) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if not daylight:
		return drops
	var hunters := _hunters(units)
	if intro_ready and not intro_done and day == 1:
		_intro(units, hunters, drops)
	for id in hunters:
		var i := units.index_of(id)
		if units.owners[i] == RecruitSystem.SEM_DONO:
			continue
		if rabbits.is_empty() or units.cooldowns[i] > 0.0:
			continue
		var prey := _nearest(units.xs[i])
		if absf(prey - units.xs[i]) <= _range(units, i):
			_kill(units, i, prey, drops)
	return drops


## O cacador teu guarda a moeda da caca no saco, se couber (§02: o arqueiro leva
## 11). Devolve o que fica para cair no chao: a caca de quem nao e de ninguem, e
## a que nao cabe.
func bag(units: UnitSystem, drops: Array[Dictionary]) -> Array[Dictionary]:
	var chao: Array[Dictionary] = []
	for d in drops:
		var i := units.index_of(d.get(&"hunter", RecruitSystem.NENHUM))
		var quanto: int = d[&"amount"]
		if i < 0 or units.owners[i] == RecruitSystem.SEM_DONO:
			chao.append(d)
			continue
		if units.carried_coins[i] + quanto > units.coin_capacities[i]:
			chao.append(d)
			continue
		units.carried_coins[i] += quanto
		bagged[units.ids[i]] = int(bagged.get(units.ids[i], 0)) + quanto
	return chao


## Quem leva caca e esta a `alcance` do rei, na mesma faixa, entrega-lha — ate
## onde o saco do rei chegar. Devolve quantas moedas entraram no saco do rei.
func deliver(units: UnitSystem, rei: int, alcance: float) -> int:
	var r := units.index_of(rei)
	if r < 0 or not units.alive(r):
		return 0
	var entregue := 0
	var ordem := bagged.keys()
	ordem.sort()
	for quem in ordem:
		var i := units.index_of(quem)
		if i < 0 or not units.alive(i):
			bagged.erase(quem)
			continue
		if units.bands[i] != units.bands[r] or absf(units.xs[i] - units.xs[r]) > alcance:
			continue
		var cabe := units.coin_capacities[r] - units.carried_coins[r]
		var n := mini(mini(int(bagged[quem]), units.carried_coins[i]), cabe)
		if n <= 0:
			continue
		units.carried_coins[i] -= n
		units.carried_coins[r] += n
		entregue += n
		bagged[quem] = int(bagged[quem]) - n
		if bagged[quem] <= 0:
			bagged.erase(quem)
	return entregue


func to_dict() -> Dictionary:
	return {
		&"day": day,
		&"rabbits": rabbits.duplicate(),
		&"intro_done": intro_done,
		&"intro_x": intro_x,
		&"pending": pending.duplicate(true),
		&"bagged": bagged.duplicate()
	}


func from_dict(saved: Dictionary) -> void:
	day = saved.get(&"day", 0)
	rabbits.assign(saved.get(&"rabbits", []))
	intro_done = saved.get(&"intro_done", false)
	intro_x = saved.get(&"intro_x", SEM_INTRO)
	pending = saved.get(&"pending", []).duplicate(true)
	bagged = saved.get(&"bagged", {}).duplicate()


func _hunters(units: UnitSystem) -> Array[int]:
	var ids: Array[int] = []
	for i in units.count():
		var data: UnitData = _profiles.get(units.data_ids[i])
		if (
			data == null
			or not data.tags.has(&"hunter")
			or units.healths[i] <= 0
			or not units.alive(i)
		):
			continue
		if units.bands[i] != Band.Kind.SURFACE:
			continue
		if units.states[i] in [UnitFsm.State.FIGHT, UnitFsm.State.FLEE]:
			continue
		ids.append(units.ids[i])
	ids.sort()
	return ids


func _nearest(x: float) -> float:
	var nearest := rabbits[0]
	for prey in rabbits:
		if absf(prey - x) < absf(nearest - x):
			nearest = prey
	return nearest


## O coelho do 1:10 e o que o jogador ve ao lado do castelo; cai-lhe o arqueiro
## sem dono mais perto dele, e nao o primeiro por id que tenha outro ao alcance
## fora do ecra. Se um cacador teu ja o levou, a demonstracao ja nao tem sentido.
func _intro(units: UnitSystem, hunters: Array[int], drops: Array[Dictionary]) -> void:
	if not rabbits.has(intro_x):
		intro_done = true
		return
	var best := UnitSystem.NENHUM
	for id in hunters:
		var i := units.index_of(id)
		if units.owners[i] != RecruitSystem.SEM_DONO or units.cooldowns[i] > 0.0:
			continue
		var gap := absf(intro_x - units.xs[i])
		if gap <= _range(units, i) and (best < 0 or gap < absf(intro_x - units.xs[best])):
			best = i
	if best >= 0:
		_kill(units, best, intro_x, drops)
		intro_done = true


func _kill(units: UnitSystem, i: int, prey: float, drops: Array[Dictionary]) -> void:
	rabbits.erase(prey)
	units.cooldowns[i] = (_profiles[units.data_ids[i]] as UnitData).attack_interval
	drops.append(
		{
			&"x": prey,
			&"band": Band.Kind.SURFACE,
			&"amount": _rabbit.coin_yield,
			&"source": &"hunt",
			&"hunter": units.ids[i]
		}
	)


func _range(units: UnitSystem, i: int) -> float:
	return (_profiles[units.data_ids[i]] as UnitData).range_px
