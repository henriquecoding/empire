# src/sim/systems/under_fit.gd — o contrato de area util de um sitio do subsolo (o
# relatorio de 05/10/2026, §6; ADR 0072).
#
# "Nenhum subsolo acessivel pode consistir apenas na escada." Um sitio tem a chegada (a
# escada e onde se pousa), a folga para sair dela e voltar, as margens junto as paredes e
# — o que faltava — uma baia: um intervalo livre, contiguo e alcancavel, fora da chegada
# e do que la esta (o poco de minerio, a camara da Semente Real). Vazio e valido; uma
# escada sem chao nao e. Mede-se a uniao do que esta ocupado, para nao contar duas vezes
# o que se sobrepoe, e procura-se um intervalo inteiro, nunca a soma de bocados.
#
# Puro e estatico: as posicoes e os numeros (UnderRules) entram por parametro.
class_name UnderFit
extends RefCounted

const OK := &""
const EMPTY := &"empty"
const MOUTH_OUTSIDE := &"mouth_outside"
const NO_BAY := &"no_bay"
const NO_ROOM := &"no_room"
const BUDGET := &"budget"
const HALF := 0.5
const NONE := Vector2(NAN, NAN)
## Os limites vivem em Vector2, de 32 bits: um centesimo de px nao e chao nenhum.
const EPS := 0.01


## O envelope de referencia: chegada, folga, baia e margens (§6.2).
static func envelope(r: UnderRules) -> float:
	return r.arrival_px + r.clear_px + r.bay_px + r.margin_px


## A chegada com a folga de circulacao: o que a baia nunca conta.
static func arrival(mouth: float, r: UnderRules) -> Vector2:
	var meio := r.arrival_px * HALF + r.clear_px
	return Vector2(mouth - meio, mouth + meio)


## Os intervalos livres dentro de `inside`, por ordem: sem a chegada e sem `blocked`.
static func gaps(inside: Vector2, mouth: float, blocked: Array, r: UnderRules) -> Array[Vector2]:
	var ocupado: Array[Vector2] = [arrival(mouth, r)]
	for v: Vector2 in blocked:
		ocupado.append(v)
	ocupado.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var saida: Array[Vector2] = []
	var x := inside.x
	for v in ocupado:
		if v.x > x and x < inside.y:
			saida.append(Vector2(x, minf(v.x, inside.y)))
		x = maxf(x, v.y)
	if x < inside.y:
		saida.append(Vector2(x, inside.y))
	return saida


## A baia de um sitio com estes limites: o intervalo livre mais largo, ja sem margens.
static func bay(span: Vector2, mouth: float, blocked: Array, r: UnderRules) -> Vector2:
	if is_nan(span.x):
		return NONE
	var margem := r.margin_px * HALF
	var melhor := NONE
	for g in gaps(Vector2(span.x + margem, span.y - margem), mouth, blocked, r):
		if is_nan(melhor.x) or g.y - g.x > melhor.y - melhor.x:
			melhor = g
	return melhor


## Porque um sitio com estes limites nao serve, ou OK.
static func check(span: Vector2, mouth: float, blocked: Array, r: UnderRules) -> StringName:
	if is_nan(span.x):
		return EMPTY
	var meio := r.arrival_px * HALF
	if mouth - meio < span.x - EPS or mouth + meio > span.y + EPS:
		return MOUTH_OUTSIDE
	var b := bay(span, mouth, blocked, r)
	return OK if not is_nan(b.x) and b.y - b.x >= r.bay_px - EPS else NO_BAY


## O envelope mais curto que cobre `need` e tem baia, dentro de `cap`: a baia a direita
## da chegada ou a esquerda (num empate, a direita). NONE se nao cabe — e entao a entrada
## nao se publica (§6.3).
static func plan(
	mouth: float, need: Vector2, cap: Vector2, blocked: Array, r: UnderRules
) -> Vector2:
	if is_nan(cap.x):
		return NONE
	var margem := r.margin_px * HALF
	var lead := r.arrival_px * HALF + margem
	var chegada := arrival(mouth, r)
	var direita := NONE
	var esquerda := NONE
	for g in gaps(Vector2(cap.x + margem, cap.y - margem), mouth, blocked, r):
		if g.y - g.x < r.bay_px - EPS:
			continue
		if g.x >= chegada.y and is_nan(direita.x):
			direita = Vector2(minf(need.x, mouth - lead), maxf(need.y, g.x + r.bay_px + margem))
		if g.y <= chegada.x:
			esquerda = Vector2(minf(need.x, g.y - r.bay_px - margem), maxf(need.y, mouth + lead))
	var melhor := NONE
	for p: Vector2 in [direita, esquerda]:
		if is_nan(p.x) or p.x < cap.x - EPS or p.y > cap.y + EPS:
			continue
		if is_nan(melhor.x) or p.y - p.x < melhor.y - melhor.x:
			melhor = p
	return melhor


## `cap` encolhido ate nao tocar em nenhum obstaculo, do lado da boca. NONE se um deles
## cobre a boca: dois sitios nunca disputam o mesmo chao (SUB-06).
static func clip(cap: Vector2, mouth: float, obstacles: Array) -> Vector2:
	var saida := cap
	for o: Vector2 in obstacles:
		if is_nan(o.x) or is_nan(saida.x):
			continue
		if o.y <= mouth:
			saida.x = maxf(saida.x, o.y)
		elif o.x >= mouth:
			saida.y = minf(saida.y, o.x)
		else:
			return NONE
	return saida if not is_nan(saida.x) and saida.x < saida.y else NONE


## O objetivo de um sitio: o meio da baia, fora da chegada, com aproximacao (SUB-11).
static func goal(span: Vector2, mouth: float, blocked: Array, r: UnderRules) -> float:
	var b := bay(span, mouth, blocked, r)
	return mouth if is_nan(b.x) else (b.x + b.y) * HALF


## O bau: na baia, a `chest_px` da ponta dela que da para a chegada (SUB-12).
static func chest(span: Vector2, mouth: float, blocked: Array, r: UnderRules) -> float:
	var b := bay(span, mouth, blocked, r)
	if is_nan(b.x):
		return NAN
	return b.x + r.chest_px if b.x >= mouth else b.y - r.chest_px


## Quantas entradas opcionais cabem num povo com este comprimento elegivel (§7.3): um
## tecto, e nao uma quota a preencher.
static func optional_budget(eligible_px: float, r: UnderRules) -> int:
	return mini(r.optional_max, floori(maxf(0.0, eligible_px) / maxf(1.0, r.optional_spacing_px)))
