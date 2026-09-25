# src/sim/systems/tender.gd — o Zelador (§75).
#
# "Uma figura que anda atras da mancha, nao ataca, e olha para o teu nucleo. Se
# chegar ao nucleo, leva uma tropa nomeada. Pode ser afastado, nao morto."
# Aparece com a Divida da Candeia no limiar tender_from_debt, e vai-se com ela a
# alvorada.
#
# Nao e uma criatura do CreatureSystem: nao tem vida, nao tem massa, nao entra
# no combate — o creatures.csv da-lhe max_health 0, e no CreatureSystem isso e
# morrer no primeiro tick. Anda por conta propria e so tem duas regras: nunca
# passa a frente da mancha, e um muro de pe para-o — nao ataca, por isso nao
# o rompe (Q-092). Afasta-lo e o gesto que falta.
class_name Tender
extends RefCounted

const NENHUM := -1
const REI := &"king"

var active: bool = false
var x: float = 0.0
## Ja levou a desta noite. Uma por noite: e uma pessoa, e nao uma colheita.
var took: bool = false

var _velocidade: float


func _init(dados: CreatureData) -> void:
	assert(dados != null, "o Zelador precisa do tender de creatures.csv")
	_velocidade = dados.move_speed


func dusk(rot_x: float) -> void:
	active = true
	x = rot_x
	took = false


func dawn() -> void:
	active = false


## Um passo para o nucleo. Verdadeiro quando esta dentro do raio dele.
func tick(delta: float, rot_x: float, nucleo: float, raio: float, obras: BuildSystem) -> bool:
	if not active:
		return false
	var rumo := signf(nucleo - x)
	var alvo := x + rumo * _velocidade * delta
	if absf(alvo - nucleo) < absf(rot_x - nucleo):
		alvo = rot_x if absf(rot_x - nucleo) < absf(x - nucleo) else x
	var muro := obras.barrier(x, alvo, Band.Kind.SURFACE)
	if muro != null:
		alvo = muro.x - rumo * muro.width * BuildSystem.METADE
		if absf(alvo - nucleo) > absf(x - nucleo):
			alvo = x
	x = alvo
	return absf(x - nucleo) <= raio


## Leva uma tropa nomeada tua, a de id mais baixo, e tira-lhe o nome. Devolve o
## id, ou NENHUM se ja levou esta noite ou se nao ha ninguem com nome.
func take(unidades: UnitSystem, titulos: Dictionary, tropas: Dictionary) -> int:
	if took:
		return NENHUM
	var escolhida := NENHUM
	for i in unidades.count():
		var unit_id := unidades.ids[i]
		if not titulos.has(unit_id) or not unidades.alive(i):
			continue
		if unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var dados: UnitData = tropas.get(unidades.data_ids[i])
		if dados != null and dados.tags.has(REI):
			continue
		if escolhida == NENHUM or unit_id < escolhida:
			escolhida = unit_id
	if escolhida == NENHUM:
		return NENHUM
	took = true
	unidades.remove(escolhida)
	titulos.erase(escolhida)
	return escolhida


func to_dict() -> Dictionary:
	return {&"active": active, &"x": x, &"took": took}


func from_dict(d: Dictionary) -> void:
	active = d.get(&"active", active)
	x = d.get(&"x", x)
	took = d.get(&"took", took)
