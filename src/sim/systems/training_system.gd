# src/sim/systems/training_system.gd — a Casa de Treino (§09, §10).
#
# "Converte vagabundos em oficios. Um vagabundo entra, sai construtor. Custa
# moeda e um dia." O gesto e o de sempre (§61): moedas largadas em cima da casa
# de pe pagam o oficio; paga, o trabalhador teu mais perto entra, e o dia so
# conta com ele la dentro. Sai com o corpo, o saco e o posto do oficio.
#
# Puro: recebe as tropas e as casas ja carregadas (SimFactory.training) e
# devolve o que aconteceu; quem chama anuncia (unit_promoted, §46).
class_name TrainingSystem
extends RefCounted

const NENHUM := -1
const METADE := 0.5

const EV_PAGA := 0
const EV_ENTROU := 1
const EV_FORMADO := 2

const CHAVE := &"kind"
const UNIDADE := &"unit"
const CASA := &"house"
const QUANTO := &"amount"
const DE := &"from"
const PARA := &"to"

## Moedas ja pagas do proximo treino, por id de obra.
var paid: Dictionary = {}
## Quem esta a treinar: id de tropa -> [id da casa, segundos la dentro, x da casa].
var trainees: Dictionary = {}

var _tropas: Dictionary
var _casas: Dictionary


## `tropas` e UnitData por id; `casas` e o oficio que cada tipo de obra forma.
func _init(tropas: Dictionary, casas: Dictionary) -> void:
	_tropas = tropas
	_casas = casas


## O oficio que esta obra forma, ou null se nao forma nenhum.
func craft_of(vaga: BuildSlot) -> UnitData:
	return _tropas.get(_casas.get(vaga.kind, &""))


## Quanto falta pagar para o proximo treino nesta casa, ou zero se nao ha preco:
## nao forma nada, nao esta de pe, ja tem alguem la dentro, ou nao ha quem mandar.
func owed(vaga: BuildSlot, unidades: UnitSystem = null) -> int:
	var oficio := craft_of(vaga)
	if oficio == null or not vaga.standing() or _ocupada(vaga.id):
		return 0
	if unidades != null and _candidato(unidades, vaga) == NENHUM:
		return 0
	return maxi(0, oficio.recruit_cost - int(paid.get(vaga.id, 0)))


## Passo 5, a seguir as obras: as moedas pousadas numa casa pagam o treino.
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in obras.standing():
		var falta := owed(vaga, unidades)
		if falta <= 0:
			continue
		var valor := _apanhar(moedas, vaga, falta)
		if valor == 0:
			continue
		paid[vaga.id] = int(paid.get(vaga.id, 0)) + valor
		eventos.append({CHAVE: EV_PAGA, CASA: vaga.id, QUANTO: valor})
		if owed(vaga) > 0:
			continue
		# O troco de uma moeda que valia mais do que faltava fica para o seguinte.
		paid[vaga.id] = int(paid[vaga.id]) - craft_of(vaga).recruit_cost
		if int(paid[vaga.id]) <= 0:
			paid.erase(vaga.id)
		var quem := unidades.ids[_candidato(unidades, vaga)]
		trainees[quem] = [vaga.id, 0.0, vaga.x]
		eventos.append({CHAVE: EV_ENTROU, CASA: vaga.id, UNIDADE: quem})
	return eventos


## Passo 4: quem esta a treinar vai para a casa e la fica — escreve o alvo por
## cima do de seguir o rei e do posto, que correram antes.
func plan(unidades: UnitSystem) -> void:
	for quem in trainees:
		var i := unidades.index_of(quem)
		if i != NENHUM:
			unidades.job_ids[i] = NENHUM
			unidades.set_target_x(quem, trainees[quem][2])


## Todos os ticks: o tempo de quem ja la esta. `dia` e a duracao do dia agora.
func tick(delta: float, unidades: UnitSystem, obras: BuildSystem, dia: float) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var ordem := trainees.keys()
	ordem.sort()
	for quem in ordem:
		var i := unidades.index_of(quem)
		var casa_i := obras.index_of(trainees[quem][0])
		if i == NENHUM or not unidades.alive(i) or unidades.healths[i] <= 0:
			trainees.erase(quem)
			continue
		if unidades.owners[i] == RecruitSystem.SEM_DONO:
			trainees.erase(quem)
			continue
		var casa := obras.slots[casa_i] if casa_i != NENHUM else null
		if casa == null or casa.state == BuildSlot.State.RUIN:
			trainees.erase(quem)
			continue
		if not casa.standing() or absf(unidades.xs[i] - casa.x) > casa.width * METADE:
			continue
		trainees[quem][1] += delta
		var oficio := craft_of(casa)
		if trainees[quem][1] < oficio.train_days * dia:
			continue
		trainees.erase(quem)
		var antes := unidades.data_ids[i]
		retrain(unidades, i, oficio)
		eventos.append({CHAVE: EV_FORMADO, UNIDADE: quem, DE: antes, PARA: oficio.id})
	return eventos


## A tropa passa a ser do oficio: corpo, vida, passo, saco e preco. Fica com o
## dono, a faixa e o sitio onde esta — e a mesma pessoa, com outro chapeu.
static func retrain(unidades: UnitSystem, i: int, oficio: UnitData) -> void:
	unidades.data_ids[i] = oficio.id
	unidades.max_healths[i] = oficio.max_health
	unidades.healths[i] = oficio.max_health
	unidades.speeds[i] = oficio.move_speed
	unidades.coin_capacities[i] = oficio.coin_capacity
	unidades.recruit_costs[i] = oficio.recruit_cost
	unidades.carried_coins[i] = mini(unidades.carried_coins[i], oficio.coin_capacity)


## §09, construtor: "+8% defesa das muralhas" enquanto houver um teu vivo. Nao
## soma: dois construtores nao dao duas vezes (Q-109).
func wall_defense(unidades: UnitSystem) -> float:
	var melhor := 0.0
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados != null:
			melhor = maxf(melhor, float(dados.ability_params.get(&"wall_defense", 0.0)))
	return melhor


func to_dict() -> Dictionary:
	return {&"paid": paid.duplicate(), &"trainees": trainees.duplicate(true)}


func from_dict(guardado: Dictionary) -> void:
	paid = guardado.get(&"paid", {}).duplicate()
	trainees = guardado.get(&"trainees", {}).duplicate(true)


func _ocupada(casa_id: int) -> bool:
	for quem in trainees:
		if trainees[quem][0] == casa_id:
			return true
	return false


## O trabalhador teu mais perto da casa, na mesma faixa, que ainda nao treina.
func _candidato(unidades: UnitSystem, vaga: BuildSlot) -> int:
	var melhor := NENHUM
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados == null or not dados.tags.has(&"worker") or trainees.has(unidades.ids[i]):
			continue
		if unidades.bands[i] != int(vaga.band):
			continue
		var d := absf(unidades.xs[i] - vaga.x)
		if melhor == NENHUM or d < absf(unidades.xs[melhor] - vaga.x):
			melhor = i
	return melhor


## Tira do chao, em cima da casa, ate `falta` moedas pousadas. Ids primeiro: o
## remove() do CoinSystem troca com a ultima.
func _apanhar(moedas: CoinSystem, vaga: BuildSlot, falta: int) -> int:
	var ids := PackedInt32Array()
	for c in moedas.count():
		if CoinTarget.pays(moedas, c, vaga):
			ids.append(moedas.ids[c])
	var valor := 0
	for coin_id in ids:
		if valor >= falta:
			break
		valor += moedas.amounts[moedas.index_of(coin_id)]
		moedas.remove(coin_id)
	return valor
