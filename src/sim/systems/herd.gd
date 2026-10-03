# src/sim/systems/herd.gd — a caca viva: pastar, fugir e carregar (ADR 0057).
#
# O dono, a 03/10/2026: "a caca e as criaturas devem ser desenvolvidas e trabalhadas a
# serio". Como em Kingdom, o bicho anda a volta da toca em vez de esperar parado a
# porta; quem chega perto fa-lo fugir — o veado de mais longe, o faisao mais cedo — ate
# ao fim do terreno dele, onde fica encurralado; e o javali nao foge: pasta sem medo
# e, ferido, carrega contra quem chega e bate ("carrega contra quem o caca"). Cada
# bicho continua a ter o nome da toca de onde saiu (o x dela).
#
# Puro e sem sorteio: o vaivem de quem pasta e um seno com a fase da toca, e os
# numeros vem do WildlifeData (wildlife.csv).
class_name Herd
extends RefCounted

const NENHUM := -1
const QUEM := &"who"
const DANO := &"damage"
const DE := &"from"

## Onde cada bicho esta agora, pelo x da toca dele.
var xs: Dictionary = {}
## Para que lado olha cada bicho: -1 a esquerda, 1 a direita.
var facing: Dictionary = {}
## Os segundos que cada bicho ja pastou: a fase do vaivem.
var ages: Dictionary = {}
## O bicho raro que saiu de uma toca no lugar do de sempre (o cervo branco).
var variants: Dictionary = {}
## Quanto falta para o bicho que carrega voltar a bater.
var cooldowns: Dictionary = {}
## Os bichos que nao fogem e ja foram feridos: esses carregam.
var provoked: Dictionary = {}
## As criaturas da Podridao a superficie (id -> Vector2(x, alcance)): de noite os bichos
## fogem delas, e a que chega ao alcance apanha o bicho (o dono, 03/10/2026).
var predators: Dictionary = {}
## As tocas dos bichos que a Podridao apanhou no ultimo passo: levantam-se inimigos.
var caught: Array[float] = []
## Quantos bichos ja sairam das tocas: a semente do sorteio do raro.
var born := 0
var _golpes: Array[Dictionary] = []


## Onde esta o bicho da toca `home`; sem registo, a porta dela.
func where(home: float) -> float:
	return float(xs.get(home, home))


## Um bicho novo a porta da toca `home`; `variant` e o raro que saiu no lugar dele.
func arrive(home: float, variant: StringName = &"") -> void:
	xs[home] = home
	ages[home] = 0.0
	facing[home] = 1.0
	born += 1
	if variant != &"":
		variants[home] = variant
	else:
		variants.erase(home)


func forget(home: float) -> void:
	for registo: Dictionary in [xs, facing, ages, variants, cooldowns, provoked]:
		registo.erase(home)


## O raro que sai no lugar de `base`, se o sorteio `roll` (0..1) o der (o cervo branco,
## ADR 0057); `bichos` e o WildlifeData por id. Sem sorteio, nunca sai o raro.
static func rare(bichos: Dictionary, base: StringName, roll: Callable) -> StringName:
	if not roll.is_valid():
		return &""
	var ids := bichos.keys()
	ids.sort()
	for id: StringName in ids:
		var dados: WildlifeData = bichos[id]
		if dados.rare_of == base and dados.rare_chance > 0.0 and roll.call() < dados.rare_chance:
			return id
	return &""


## Quem assusta a caca: os teus, vivos, na superficie (id -> x).
static func threats_of(units: UnitSystem) -> Dictionary:
	var saida := {}
	for i in units.count():
		if units.owners[i] == RecruitSystem.SEM_DONO or not units.alive(i):
			continue
		if units.healths[i] > 0 and units.bands[i] == Band.Kind.SURFACE:
			saida[units.ids[i]] = units.xs[i]
	return saida


## `delta` segundos para cada bicho de `homes`. `species` da o WildlifeData da toca, e
## `threats` sao os x de quem assusta (id -> x). Devolve os golpes de quem carrega.
func step(
	delta: float, homes: Array[float], species: Callable, threats: Dictionary
) -> Array[Dictionary]:
	_golpes = []
	caught = []
	var ids := threats.keys()
	ids.sort()
	for home in homes:
		var bicho: WildlifeData = species.call(home)
		if bicho == null:
			continue
		var x := where(home)
		var fera := _nearest_predator(x)
		if fera != Vector2.INF and absf(fera.x - x) <= fera.y:
			caught.append(home)
			continue
		if fera != Vector2.INF and bicho.flees and absf(fera.x - x) <= bicho.notice_px:
			x = _threatened(home, x, bicho, NENHUM, fera.x, delta)
			xs[home] = clampf(x, home - bicho.flee_px, home + bicho.flee_px)
			continue
		var quem := _nearest(threats, x, ids)
		cooldowns[home] = maxf(0.0, float(cooldowns.get(home, 0.0)) - delta)
		var sabe := bicho.flees or provoked.has(home)
		if sabe and quem != NENHUM and absf(float(threats[quem]) - x) <= bicho.notice_px:
			x = _threatened(home, x, bicho, quem, float(threats[quem]), delta)
		else:
			x = _graze(home, x, bicho, delta)
		xs[home] = clampf(x, home - bicho.flee_px, home + bicho.flee_px)
	return _golpes


## As criaturas que cacam os bichos: vivas, a superficie, e nao convertidas (`allies`).
static func predators_of(
	creatures: CreatureSystem, dados: Dictionary, allies: Dictionary = {}
) -> Dictionary:
	var saida := {}
	for c in creatures.count():
		var id := creatures.ids[c]
		var ficha: CreatureData = dados.get(creatures.data_ids[c])
		if ficha == null or allies.has(id) or not creatures.alive(c):
			continue
		if creatures.bands[c] == Band.Kind.SURFACE:
			saida[id] = Vector2(creatures.xs[c], ficha.range_px)
	return saida


## Os golpes de quem carrega, na vida de quem os leva. Devolve os golpes que pegaram.
static func bite(units: UnitSystem, golpes: Array[Dictionary]) -> Array[Dictionary]:
	var pegaram: Array[Dictionary] = []
	for golpe in golpes:
		var i := units.index_of(int(golpe[QUEM]))
		if i < 0 or not units.alive(i) or units.healths[i] <= 0:
			continue
		units.healths[i] = maxi(0, units.healths[i] - int(golpe[DANO]))
		pegaram.append(golpe)
	return pegaram


func to_dict() -> Dictionary:
	return {
		&"xs": xs.duplicate(),
		&"facing": facing.duplicate(),
		&"ages": ages.duplicate(),
		&"variants": variants.duplicate(),
		&"cooldowns": cooldowns.duplicate(),
		&"provoked": provoked.duplicate(),
		&"born": born,
	}


## Um save de antes da ADR 0057 nao traz a manada: cada bicho fica a porta da toca.
func from_dict(d: Dictionary) -> void:
	xs = d.get(&"xs", {}).duplicate()
	facing = d.get(&"facing", {}).duplicate()
	ages = d.get(&"ages", {}).duplicate()
	variants = d.get(&"variants", {}).duplicate()
	cooldowns = d.get(&"cooldowns", {}).duplicate()
	provoked = d.get(&"provoked", {}).duplicate()
	born = int(d.get(&"born", 0))


func _threatened(
	home: float, x: float, bicho: WildlifeData, quem: int, de: float, delta: float
) -> float:
	var lado := signf(x - de)
	if is_zero_approx(lado):
		lado = -float(facing.get(home, 1.0))
	if bicho.flees:
		facing[home] = lado
		return x + lado * bicho.move_speed * delta
	facing[home] = -lado
	var gap := absf(de - x)
	if gap > bicho.reach_px:
		return x - lado * minf(bicho.move_speed * delta, gap - bicho.reach_px)
	if bicho.damage > 0 and float(cooldowns[home]) <= 0.0:
		cooldowns[home] = bicho.attack_interval
		_golpes.append({QUEM: quem, DANO: bicho.damage, DE: home})
	return x


## Pastar: ir, a passo, para o ponto do vaivem a volta da toca.
func _graze(home: float, x: float, bicho: WildlifeData, delta: float) -> float:
	var idade := float(ages.get(home, 0.0)) + delta
	ages[home] = idade
	if bicho.roam_px <= 0.0 or bicho.graze_speed <= 0.0:
		return x
	var fase := idade * bicho.graze_speed / bicho.roam_px + fposmod(home, TAU)
	var alvo := home + bicho.roam_px * sin(fase)
	var passo := bicho.graze_speed * delta
	if absf(alvo - x) <= passo:
		return alvo
	facing[home] = signf(alvo - x)
	return x + facing[home] * passo


func _nearest_predator(x: float) -> Vector2:
	var melhor := Vector2.INF
	for fera: Vector2 in predators.values():
		if melhor == Vector2.INF or absf(fera.x - x) < absf(melhor.x - x):
			melhor = fera
	return melhor


## `ids` sao as chaves de `threats`, ja ordenadas: ordena-se uma vez por passo.
static func _nearest(threats: Dictionary, x: float, ids: Array) -> int:
	var melhor := NENHUM
	for quem: int in ids:
		if melhor == NENHUM or absf(float(threats[quem]) - x) < absf(float(threats[melhor]) - x):
			melhor = quem
	return melhor
