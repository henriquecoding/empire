# src/sim/systems/under_layout.gd — as salas de um sitio do subsolo, pelos sorteios dele
# (Q-186, ADR 0046), e o chao que o contrato de area util pede (ADR 0072). Tirado do
# UndergroundSites, que passava das 250.
#
# A sala de entrada fica sob a boca; juntam-se salas ate cobrir o que la esta e as extra
# sorteadas; e se no fim nao ha baia (UnderFit), alonga-se o sitio pelo lado onde o
# envelope mais curto cabe — uma conta e nao tentativas as cegas. Um bocado curto alarga
# a sala da ponta em vez de ser uma sala de 20 px. O que esta numa sala (o poco, a camara
# da Semente Real) entra nas features dela e ja nao lhe apaga a funcao (SUB-10).
#
# Puro e estatico: a boca, os limites, os sorteios e a receita entram por parametro.
class_name UnderLayout
extends RefCounted

const FIT := 0.5
const HALF := 0.5

static var _padrao: UnderRules


## Os numeros do contrato que vem na receita; sem eles, os do CSV por omissao.
static func rules(spec: Dictionary) -> UnderRules:
	if spec.get(UndergroundSites.RULES) is UnderRules:
		return spec[UndergroundSites.RULES]
	if _padrao == null:
		_padrao = UnderRules.new()
	return _padrao


## O chao que o que la esta ocupa: as features com largura.
static func blocked(spec: Dictionary) -> Array[Vector2]:
	var saida: Array[Vector2] = []
	for f: Array in spec.get(UndergroundSites.FEATURES, []):
		if f.size() > 2 and float(f[2]) > 0.0:
			saida.append(
				Vector2(float(f[0]) - float(f[2]) * HALF, float(f[0]) + float(f[2]) * HALF)
			)
	return saida


static func lay_out(
	mouth: float, need: Vector2, cap: Vector2, rolls: PackedFloat32Array, spec: Dictionary
) -> Array[Dictionary]:
	var sala: Vector2 = spec.get(UndergroundSites.ROOM, Vector2.ONE)
	var largura := maxf(
		lerpf(sala.x, sala.y, _u(rolls, 1)), float(spec.get(UndergroundSites.ENTRANCE_PX, 0.0))
	)
	largura = minf(largura, cap.y - cap.x)
	var a := clampf(mouth - largura * HALF, cap.x, cap.y - largura)
	var salas: Array[Dictionary] = [
		_sala(a, a + largura, spec.get(UndergroundSites.ENTRANCE, &""), _u(rolls, 2))
	]
	while (
		salas.front()[UndergroundSites.A] > maxf(need.x, cap.x)
		and _juntar(salas, -1, cap, rolls, spec)
	):
		pass
	while (
		salas.back()[UndergroundSites.B] < minf(need.y, cap.y)
		and _juntar(salas, 1, cap, rolls, spec)
	):
		pass
	var extra: int = spec.get(UndergroundSites.EXTRA, 0)
	for _e in mini(floori(_u(rolls, 0) * float(extra + 1)), extra):
		var lado := -1 if _u(rolls, UndergroundSites.PER_ROOM * (salas.size() + 1)) < HALF else 1
		if (
			not _juntar(salas, lado, cap, rolls, spec)
			and not _juntar(salas, -lado, cap, rolls, spec)
		):
			break
	for f: Array in spec.get(UndergroundSites.FEATURES, []):
		for s in salas:
			if float(f[0]) >= s[UndergroundSites.A] and float(f[0]) <= s[UndergroundSites.B]:
				(s[UndergroundSites.FEATS] as Array).append(f[1])
				break
	fit(salas, mouth, cap, rolls, spec)
	return salas


## Da ao sitio a baia que lhe falta, sem sair de `cap`. Falso se nao cabe.
static func fit(
	salas: Array[Dictionary],
	mouth: float,
	cap: Vector2,
	rolls: PackedFloat32Array,
	spec: Dictionary
) -> bool:
	var r := rules(spec)
	var span := Vector2(salas.front()[UndergroundSites.A], salas.back()[UndergroundSites.B])
	if UnderFit.check(span, mouth, blocked(spec), r) == UnderFit.OK:
		return true
	var alvo := UnderFit.plan(mouth, span, cap, blocked(spec), r)
	if is_nan(alvo.x):
		return false
	extend(salas, -1, alvo.x, spec, _u(rolls, 2 + UndergroundSites.PER_ROOM * salas.size()))
	extend(salas, 1, alvo.y, spec, _u(rolls, 2 + UndergroundSites.PER_ROOM * salas.size()))
	return true


## Leva a ponta do lado `lado` ate `ate`: uma sala nova se o bocado chega para uma, ou a
## sala da ponta mais larga se nao chega (§6.4: nada de salas de 20 px). `tipo` vazio e
## o da receita, pelo sorteio `u`.
static func extend(
	salas: Array, lado: int, ate: float, spec: Dictionary, u: float, tipo := &""
) -> bool:
	var fim: float = (
		salas.back()[UndergroundSites.B] if lado > 0 else salas.front()[UndergroundSites.A]
	)
	var falta := (ate - fim) * float(lado)
	if falta <= 0.0:
		return false
	var sala: Vector2 = spec.get(UndergroundSites.ROOM, Vector2.ONE)
	if falta < sala.x * FIT or salas.size() >= UndergroundSites.MAX_ROOMS:
		if lado > 0:
			salas.back()[UndergroundSites.B] = ate
		else:
			salas.front()[UndergroundSites.A] = ate
		return true
	var nova := _sala(minf(fim, ate), maxf(fim, ate), tipo if tipo != &"" else kind(spec, u), u)
	if lado > 0:
		salas.push_back(nova)
	else:
		salas.push_front(nova)
	return true


## Um save de antes da ADR 0072: a feature tinha apagado o tipo da sala. O tipo volta
## pelo sorteio guardado na sala (o mesmo que o escolheu), e a feature fica nas features.
static func mend_kinds(salas: Array, mouth: float, spec: Dictionary) -> bool:
	var feitas := {}
	for f: Array in spec.get(UndergroundSites.FEATURES, []):
		feitas[f[1]] = true
	var mudou := false
	for s: Dictionary in salas:
		if s.has(UndergroundSites.FEATS):
			continue
		s[UndergroundSites.FEATS] = []
		mudou = true
		if feitas.has(s[UndergroundSites.KIND]):
			(s[UndergroundSites.FEATS] as Array).append(s[UndergroundSites.KIND])
			var entrada: bool = s[UndergroundSites.A] <= mouth and mouth <= s[UndergroundSites.B]
			s[UndergroundSites.KIND] = (
				spec.get(UndergroundSites.ENTRANCE, &"")
				if entrada
				else kind(spec, float(s[UndergroundSites.ROLL]))
			)
	return mudou


## O tipo de uma sala da receita, pelo sorteio dela.
static func kind(spec: Dictionary, u: float) -> StringName:
	var tipos: Array = spec.get(UndergroundSites.POOL, [])
	if tipos.is_empty():
		return &""
	return tipos[mini(floori(u * tipos.size()), tipos.size() - 1)]


static func _juntar(
	salas: Array[Dictionary], lado: int, cap: Vector2, rolls: PackedFloat32Array, spec: Dictionary
) -> bool:
	var j := salas.size()
	if j >= UndergroundSites.MAX_ROOMS:
		return false
	var sala: Vector2 = spec.get(UndergroundSites.ROOM, Vector2.ONE)
	var largura := lerpf(sala.x, sala.y, _u(rolls, 1 + UndergroundSites.PER_ROOM * j))
	var u := _u(rolls, 2 + UndergroundSites.PER_ROOM * j)
	if lado < 0:
		var b: float = salas.front()[UndergroundSites.A]
		var a := maxf(cap.x, b - largura)
		if b - a < sala.x * FIT:
			return false
		salas.push_front(_sala(a, b, kind(spec, u), u))
	else:
		var a: float = salas.back()[UndergroundSites.B]
		var b := minf(cap.y, a + largura)
		if b - a < sala.x * FIT:
			return false
		salas.push_back(_sala(a, b, kind(spec, u), u))
	return true


static func _sala(a: float, b: float, tipo: StringName, u: float) -> Dictionary:
	return {
		UndergroundSites.A: a,
		UndergroundSites.B: b,
		UndergroundSites.KIND: tipo,
		UndergroundSites.ROLL: u,
		UndergroundSites.FEATS: []
	}


static func _u(rolls: PackedFloat32Array, i: int) -> float:
	return rolls[i] if i < rolls.size() else HALF
