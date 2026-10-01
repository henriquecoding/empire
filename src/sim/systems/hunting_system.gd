# src/sim/systems/hunting_system.gd — a caca (§06, §25): quem caca, o que cai e para
# onde vai. Os bichos saem das tocas (Burrows, Q-106), aos poucos e de dia, e cada
# toca da o bicho que faz sentido no sitio dela (Q-150): o veado leva dois tiros.
class_name HuntingSystem
extends RefCounted

## Sem coelho de abertura: um x negativo, que nenhuma clareira tem (HuntWatch).
const SEM_INTRO := -1.0

var season_mult := 1.0
var day := 0
## Os bichos que estao agora a porta das tocas, por x (coelhos e veados, Q-150).
var rabbits: Array[float] = []
## O dano que cada bicho a porta ja levou, por x: o veado aguenta um tiro (Q-150).
var wounds: Dictionary = {}
## WildlifeData por id: o bicho de cada toca. Sem ele, e o coelho.
var wildlife: Dictionary = {}
var intro_done := false
## O coelho do minuto 1:10 (§25): o da primeira toca no dia 1, junto ao castelo.
var intro_x := SEM_INTRO
## As tocas de onde os bichos saem aos poucos (Q-106, Q-120).
var burrows := Burrows.new()
## Quanto de caca cada cacador teu leva no saco (id -> moedas). So isto se entrega
## ao rei: o preco que pagaste para o recrutar fica com ele (Q-111).
var bagged: Dictionary = {}
var _profiles: Dictionary
var _rabbit: WildlifeData


func _init(profiles: Dictionary, rabbit: WildlifeData) -> void:
	_profiles = profiles
	_rabbit = rabbit


## Um dia novo. No primeiro, o bicho da primeira toca e o do 1:10 (§25).
func open_day(number: int) -> void:
	if number <= day:
		return
	day = number
	var primeira := burrows.xs[0] if burrows.placed() else SEM_INTRO
	intro_x = primeira if number == 1 else SEM_INTRO


## `delta` segundos: de dia, as tocas vivas poem bichos a porta, um de cada vez.
func grow(delta: float, daylight: bool, periodo: float) -> void:
	if daylight:
		rabbits.append_array(burrows.grow(delta * season_mult, periodo, rabbits))


## As tocas a `raio` destes x perdem-se, e o bicho que estava a porta foge com elas.
func wither(perigos: PackedFloat32Array, raio: float) -> Array[float]:
	var perdidas := burrows.wither(perigos, raio)
	for x in perdidas:
		rabbits.erase(x)
		wounds.erase(x)
	return perdidas


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
		&"burrows": burrows.to_dict(),
		&"bagged": bagged.duplicate(),
		&"wounds": wounds.duplicate(),
	}


func from_dict(saved: Dictionary) -> void:
	day = saved.get(&"day", 0)
	rabbits.assign(saved.get(&"rabbits", []))
	intro_done = saved.get(&"intro_done", false)
	intro_x = saved.get(&"intro_x", SEM_INTRO)
	burrows = Burrows.new()
	burrows.from_dict(saved.get(&"burrows", {}))
	bagged = saved.get(&"bagged", {}).duplicate()
	wounds = saved.get(&"wounds", {}).duplicate()


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
		if units.bands[i] != Band.Kind.SURFACE or units.ids[i] == units.pilot:
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


## Um tiro. O bicho cai quando o dano chega a vida dele (o veado, dois; Q-150), e
## cai-lhe a caca que ele vale.
func _kill(units: UnitSystem, i: int, prey: float, drops: Array[Dictionary]) -> void:
	var arma := _profiles[units.data_ids[i]] as UnitData
	units.cooldowns[i] = arma.attack_interval
	var bicho: WildlifeData = wildlife.get(burrows.game_at(prey), _rabbit)
	var ferida := int(wounds.get(prey, 0)) + maxi(1, arma.damage)
	if ferida < bicho.max_health:
		wounds[prey] = ferida
		return
	wounds.erase(prey)
	rabbits.erase(prey)
	drops.append(
		{
			&"x": prey,
			&"band": Band.Kind.SURFACE,
			&"amount": bicho.coin_yield,
			&"source": &"hunt",
			&"hunter": units.ids[i]
		}
	)


func _range(units: UnitSystem, i: int) -> float:
	return (_profiles[units.data_ids[i]] as UnitData).range_px
