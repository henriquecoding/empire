# src/sim/systems/hunting_system.gd — a caca (§06, §25): quem caca, o que cai e para
# onde vai. Os bichos saem das tocas (Burrows, Q-106), aos poucos e de dia, e cada
# toca da o bicho que faz sentido no sitio dela (Q-150): o veado leva dois tiros. Desde
# a ADR 0057 o bicho anda (Herd): `rabbits` sao as tocas de quem esta fora, e o sitio
# onde ele esta agora e o `herd.where` dessa toca.
class_name HuntingSystem
extends RefCounted

## Sem coelho de abertura: um x negativo, que nenhuma clareira tem (HuntWatch).
const SEM_INTRO := -1.0
## A queda de caca que vai para o chao, e nao para o saco de quem cacou (ADR 0057).
const GROUND := &"ground"

var season_mult := 1.0
var day := 0
## Os bichos que estao agora fora das tocas, pelo x da toca (Q-150, ADR 0057).
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
## Onde anda cada bicho, e o raro que saiu no lugar do de sempre (ADR 0057).
var herd := Herd.new()
## Quanto de caca cada cacador teu leva no saco (id -> moedas). So isto se entrega
## ao rei: o preco que pagaste para o recrutar fica com ele (Q-111).
var bagged: Dictionary = {}
## Onde os cacadores vao atras da caca: a regiao de casa (Q-217). Os bichos das terras
## geradas sao de quem la passa.
var home := Vector2(-INF, INF)
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


## `delta` segundos: de dia, as tocas vivas poem bichos a porta, um de cada vez. `roll`
## da o sorteio do raro (0..1) de cada bicho que sai; sem ele, nunca sai o raro. `ritmos`
## e o tempo de cada bicho entre dois (Q-217); sem ele, o `periodo`.
func grow(
	delta: float, daylight: bool, periodo: float, roll := Callable(), ritmos: Dictionary = {}
) -> void:
	if not daylight:
		return
	for x in burrows.grow(delta * season_mult, periodo, rabbits, ritmos):
		rabbits.append(x)
		herd.arrive(x, Herd.rare(wildlife, burrows.game_at(x), roll))


## O bicho da toca `x`: o raro que de la saiu, ou o de sempre.
func species_at(x: float) -> WildlifeData:
	var id: StringName = herd.variants.get(x, burrows.game_at(x))
	return wildlife.get(id, _rabbit)


## As tocas a `raio` destes x perdem-se, e o bicho que estava a porta foge com elas.
func wither(perigos: PackedFloat32Array, raio: float) -> Array[float]:
	var perdidas := burrows.wither(perigos, raio)
	for x in perdidas:
		rabbits.erase(x)
		wounds.erase(x)
		herd.forget(x)
	return perdidas


## O alvo de caca cede ao combate e aos postos; nunca atravessa faixas.
func plan(units: UnitSystem, daylight: bool) -> void:
	if not daylight or rabbits.is_empty():
		return
	for id in _hunters(units):
		var i := units.index_of(id)
		if units.owners[i] == RecruitSystem.SEM_DONO or units.job_ids[i] != UnitSystem.NENHUM:
			continue
		var toca := _nearest(units.xs[i], true)
		if is_nan(toca):
			continue
		var prey := herd.where(toca)
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
		if absf(herd.where(prey) - units.xs[i]) <= _range(units, i):
			_kill(units, i, prey, drops)
	return drops


func to_dict() -> Dictionary:
	return {
		&"day": day,
		&"rabbits": rabbits.duplicate(),
		&"intro_done": intro_done,
		&"intro_x": intro_x,
		&"burrows": burrows.to_dict(),
		&"bagged": bagged.duplicate(),
		&"wounds": wounds.duplicate(),
		&"herd": herd.to_dict(),
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
	herd = Herd.new()
	herd.from_dict(saved.get(&"herd", {}))


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


## A toca do bicho mais perto de `x`, pelo sitio onde ele anda agora; `em_casa`, so os
## de casa (NAN se nao ha nenhum).
func _nearest(x: float, em_casa := false) -> float:
	var nearest := NAN
	for prey in rabbits:
		if em_casa and (prey < home.x or prey > home.y):
			continue
		if is_nan(nearest) or absf(herd.where(prey) - x) < absf(herd.where(nearest) - x):
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
		var gap := absf(herd.where(intro_x) - units.xs[i])
		var antes := absf(herd.where(intro_x) - units.xs[best]) if best >= 0 else INF
		if gap <= _range(units, i) and gap < antes:
			best = i
	if best >= 0:
		_kill(units, best, intro_x, drops)
		intro_done = true


## Um golpe de `damage` no bicho da toca `prey`. Cai quando o dano chega a vida dele
## (o veado, dois; Q-150), e cai-lhe a caca que vale onde ele estava. `ground`: as
## moedas caem no chao uma a uma, para quem passar as apanhar (ADR 0057).
func hurt(prey: float, damage: int, hunter: int, ground := false) -> Array[Dictionary]:
	var bicho := species_at(prey)
	var ferida := int(wounds.get(prey, 0)) + maxi(1, damage)
	if ferida < bicho.max_health:
		wounds[prey] = ferida
		herd.provoked[prey] = true  # o javali ferido carrega (ADR 0057)
		return []
	var onde := herd.where(prey)
	wounds.erase(prey)
	rabbits.erase(prey)
	herd.forget(prey)
	var queda := {&"x": onde, &"band": Band.Kind.SURFACE, &"source": &"hunt", &"hunter": hunter}
	if not ground:
		queda[&"amount"] = bicho.coin_yield
		return [queda]
	var moedas: Array[Dictionary] = []
	queda[&"amount"] = 1
	queda[GROUND] = true
	for k in bicho.coin_yield:
		moedas.append(queda.duplicate())
	return moedas


## O bicho da toca `prey` sai do mundo sem deixar caca: a Podridao apanhou-o. Devolve o
## bicho que era, para se levantar como criatura (WildlifeData.rots_into).
func lose(prey: float) -> WildlifeData:
	var bicho := species_at(prey)
	wounds.erase(prey)
	rabbits.erase(prey)
	herd.forget(prey)
	return bicho


func _kill(units: UnitSystem, i: int, prey: float, drops: Array[Dictionary]) -> void:
	var arma := _profiles[units.data_ids[i]] as UnitData
	units.cooldowns[i] = arma.attack_interval
	drops.append_array(hurt(prey, arma.damage, units.ids[i]))


func _range(units: UnitSystem, i: int) -> float:
	return (_profiles[units.data_ids[i]] as UnitData).range_px
