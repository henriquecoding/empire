# src/sim/systems/melee_sweep.gd — o golpe de perto atinge tudo o que alcanca (Q-185).
#
# O dono, a 03/10/2026: "os ataques corpo a corpo atingem aquilo que esta ao seu alcance e
# da dano nas criaturas que atingiu, se for criaturas pequenas sao jogadas um pouco para
# tras, criaturas grandes continuam inabaladas, arqueiros e ataques a distancia acertam um
# inimigo por vez". Quem nao dispara flechas bate em todas as criaturas da faixa dele, do
# lado do golpe, ate ao alcance da arma; as pequenas (scale_tier ate ao teto) recuam uns
# pixeis. A distancia, um alvo so — a perfuracao do Arqueiro evoluido continua a dela.
#
# Puro. A ordem dos alvos e a dos ids (§42), com o alvo escolhido sempre primeiro.
class_name MeleeSweep
extends RefCounted

## O que um golpe de perto leva para o empurrao: o x de quem bateu.
const DE_X := &"melee_from"
const METADE := 0.5


## Se este corpo bate de perto: sem aljava e sem a tag ranged.
static func melee(dados: UnitData) -> bool:
	return dados != null and dados.ammo <= 0 and not dados.tags.has(&"ranged")


## Meio corpo da criatura `c` no chao: metade do shadow_width dela (Q-219). `dados` e o
## CreatureData por id de dados; sem ele, um ponto.
static func half_body(dados: Dictionary, criaturas: CreatureSystem, c: int) -> float:
	var ficha: CreatureData = dados.get(criaturas.data_ids[c])
	return float(ficha.shadow_width) * METADE if ficha != null else 0.0


## Os alvos de um golpe que acertou `alvo`. `aliados` sao as criaturas do teu lado. O
## golpe chega a pele de cada uma (Q-219): `dados` e o CreatureData por id de dados.
static func targets(
	criaturas: CreatureSystem,
	x: float,
	faixa: int,
	alcance: float,
	alvo: int,
	aliados: Dictionary = {},
	dados: Dictionary = {}
) -> Array[int]:
	var todos: Array[int] = [alvo]
	var a := criaturas.index_of(alvo)
	if a < 0:
		return todos
	var lado := signf(criaturas.xs[a] - x)
	for id in TargetPicker.ids_por_ordem(criaturas.ids):
		var c := criaturas.index_of(id)
		if id == alvo or aliados.has(id) or not criaturas.alive(c):
			continue
		if int(criaturas.bands[c]) != faixa:
			continue
		var d := criaturas.xs[c] - x
		if (
			absf(d) <= alcance + half_body(dados, criaturas, c)
			and (lado == 0.0 or signf(d) != -lado)
		):
			todos.append(id)
	return todos


## Os alvos de quem a IA conduz: a perfuracao do Arqueiro evoluido, um alvo a distancia, ou
## o varrimento de perto.
static func hits(
	u: UnitSystem,
	criaturas: CreatureSystem,
	i: int,
	dados: UnitData,
	alvo: int,
	foco: ArcherFocus,
	aliados: Dictionary
) -> Array[int]:
	if foco != null and foco.piercing.has(u.ids[i]):
		return foco.pierced(u, criaturas, u.ids[i], alvo)
	if not melee(dados):
		return [alvo]
	return targets(criaturas, u.xs[i], int(u.bands[i]), dados.range_px, alvo, aliados)


## Depois do dano: a criatura pequena que sobreviveu a um golpe de perto (o golpe leva
## DE_X) recua `empurrao.x` px para longe de quem bateu; `empurrao.y` e o scale_tier mais
## alto que ainda recua. As grandes nao se mexem.
static func knock(
	criaturas: CreatureSystem, dados: Dictionary, golpe: Dictionary, empurrao: Vector2
) -> void:
	var c := criaturas.index_of(int(golpe[CombatSystem.PARA]))
	if not golpe.has(DE_X) or c < 0 or empurrao.x <= 0.0 or not criaturas.alive(c):
		return
	var corpo: CreatureData = dados.get(criaturas.data_ids[c])
	if corpo == null or corpo.scale_tier > int(empurrao.y):
		return
	var lado := signf(criaturas.xs[c] - float(golpe[DE_X]))
	criaturas.xs[c] += (lado if lado != 0.0 else 1.0) * empurrao.x
