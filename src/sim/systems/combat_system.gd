# src/sim/systems/combat_system.gd — legivel antes de emocionante (§50, §07).
#
# As quatro regras do §07 sao de design. A que manda neste ficheiro e de
# implementacao, e o §50 escreve-a sem rodeios: "sem uma ordem fixa, a mesma
# noite da resultados diferentes e a promessa da seed morre". Por isso a ordem
# esta escrita, por esta ordem, e nao emerge de nada:
#
#   1 · escolher alvos      — o TargetPicker, no passo 4 do §43
#   2 · resolver ataques    — resolve(), no passo 6
#   3 · aplicar dano        — tudo de uma vez, no fim
#   4 · mortes e o que cai  — depois do dano, nunca a meio
#
# O passo 3 e o que evita o defeito que o §43 descreve por palavras suas: "uma
# tropa morre e ainda ataca no mesmo tick". Os golpes sao todos decididos antes
# de qualquer vida mudar.
#
# Puro. O roll de precisao entra de fora, como o desvio do arco (§42, §70): quem
# chama liga-o ao fluxo `combat` e a noite reproduz-se com a semente. A §50
# insiste que o hit sai ja decidido — "a apresentacao nunca decide se acertou".
#
# Os campos com um underscore a frente do nome dos sistemas valem SO durante uma
# chamada a resolve(): sao o contexto do passo, e sao reescritos a cada um. E o
# que permite que os metodos de dentro nao levem cinco argumentos cada.
#
# O que NAO esta aqui: os slots de contacto e a fila do muro (F1-06); a precisao
# 1,0 dentro de torre, que precisa de saber quem esta dentro de uma (F1-06);
# moral e fuga (F1-12); o corpo que fica no chao (§16).
class_name CombatSystem
extends RefCounted

const NENHUM := -1

## Os acontecimentos devolvidos. Chaves de dicionario, nao nomes de sinal: a
## simulacao nao conhece a §46 e quem chama e que traduz (§43, passo 11).
const EV_ATAQUE := 0
const EV_DANO := 1
const EV_MORTE := 2
const EV_ESTADO := 3
const EV_OBRA := 4
## O que a fila de contacto devolve, a passar tal e qual (§50).
const EV_CONTACTO := 5
## Uma criatura que subiu do subsolo por uma passagem (§07, §25 minuto 12:00).
const EV_FAIXA := 6

const CHAVE := &"kind"
const DE := &"from"
const PARA := &"to"
const ACERTOU := &"hit"
const QUANTO := &"amount"
const ONDE := &"x"
const FAIXA := &"band"
const CRIATURA := &"creature"
const MOEDAS := &"coins"
const LARGA := &"drops"
const OBRA := &"slot"
const EVENTOS := &"events"
## O que a criatura era: o nome de um feito (§76) depende de QUEM se abateu.
const QUEM := &"data_id"

var picker: TargetPicker

var _dados_u: Dictionary = {}
var _dados_c: Dictionary = {}
## O quadro de postos. "A torre nao da dano — da certeza" (§07): e por aqui que
## se sabe se quem dispara esta numa.
var _postos: JobBoard
var _u: UnitSystem
var _c: CreatureSystem
var _o: BuildSystem
var _sorteio: Callable
var _eventos: Array[Dictionary] = []
var _golpes: Array[Dictionary] = []


func _init(
	unidades: Dictionary, criaturas: Dictionary, contacto: ContactQueue, postos: JobBoard
) -> void:
	_dados_u = unidades
	_dados_c = criaturas
	_postos = postos
	picker = TargetPicker.new(unidades, criaturas, contacto, postos)


func target_of(unit_id: int) -> int:
	return picker.target_of(unit_id)


func mark(unit_id: int, creature_id: int) -> void:
	picker.mark(unit_id, creature_id)


## Passo 4 do §43 para quem luta. Delegado, e nao repetido: a escolha tem regra
## propria e vive no TargetPicker.
func choose(
	unidades: UnitSystem,
	criaturas: CreatureSystem,
	obras: BuildSystem,
	passagens: PackedFloat32Array = PackedFloat32Array()
) -> Array[Dictionary]:
	return picker.choose(unidades, criaturas, obras, passagens)


## Passo 6 do §43. Os cooldowns ja desceram no passo 5, com o movimento — sao a
## mesma subtraccao, e faze-la duas vezes andava com o relogio do dobro.
func resolve(
	unidades: UnitSystem, criaturas: CreatureSystem, obras: BuildSystem, sorteio: Callable
) -> Array[Dictionary]:
	_u = unidades
	_c = criaturas
	_o = obras
	_sorteio = sorteio
	_eventos = []
	_golpes = []
	_tropas_batem()
	_criaturas_batem()
	_aplicar()
	_mortes_das_criaturas()
	_mortes_das_tropas()
	return _eventos


## As colunas de cooldown sao float32 e o delta e float64: um intervalo de 0,4 s
## descontado em passos de 0,4 s nao fica em zero, fica em 6e-9. Sem isto, uma
## arma podia nunca mais disparar por causa de um residuo que nem se ve.
func _a_recarregar(cooldown: float) -> bool:
	return cooldown > 0.0 and not is_zero_approx(cooldown)


func _tropas_batem() -> void:
	for unit_id in TargetPicker.ids_por_ordem(_u.ids):
		var alvo := picker.target_of(unit_id)
		var i := _u.index_of(unit_id)
		if alvo == NENHUM or i == NENHUM or _a_recarregar(_u.cooldowns[i]):
			continue
		var dados: UnitData = _dados_u.get(_u.data_ids[i])
		_u.cooldowns[i] = dados.attack_interval
		var acertou: bool = _sorteio.call() < Posts.accuracy(_postos, _u, i, dados)
		_eventos.append({CHAVE: EV_ATAQUE, DE: unit_id, PARA: alvo, ACERTOU: acertou})
		if acertou:
			_golpes.append({DE: unit_id, PARA: alvo, QUANTO: dados.damage, CRIATURA: true})


func _criaturas_batem() -> void:
	for creature_id in TargetPicker.ids_por_ordem(_c.ids):
		var c := _c.index_of(creature_id)
		if c == NENHUM or not _c.engaged(c) or _a_recarregar(_c.cooldowns[c]):
			continue
		var dados: CreatureData = _dados_c.get(_c.data_ids[c])
		_c.cooldowns[c] = dados.attack_interval
		var acertou: bool = _sorteio.call() < dados.accuracy
		var alvo := _c.target_ids[c]
		if alvo != NENHUM:
			_eventos.append({CHAVE: EV_ATAQUE, DE: creature_id, PARA: alvo, ACERTOU: acertou})
		if acertou:
			(
				_golpes
				. append(
					{
						DE: creature_id,
						PARA: alvo,
						QUANTO: dados.damage,
						CRIATURA: false,
						OBRA: _c.target_slots[c],
					}
				)
			)


## O dano todo de uma vez. E o passo que impede "morreu e ainda atacou": nenhuma
## vida muda enquanto houver golpes por decidir.
func _aplicar() -> void:
	for golpe in _golpes:
		if golpe[CRIATURA]:
			_c.damage(golpe[PARA], golpe[QUANTO])
			_eventos.append(_dano(golpe, true))
			continue
		if golpe[OBRA] != NENHUM:
			if _o != null:
				_eventos.append({CHAVE: EV_OBRA, EVENTOS: _o.damage(golpe[OBRA], golpe[QUANTO])})
			continue
		_u.damage(golpe[PARA], golpe[QUANTO])
		_eventos.append(_dano(golpe, false))


func _dano(golpe: Dictionary, criatura: bool) -> Dictionary:
	return {
		CHAVE: EV_DANO,
		DE: golpe[DE],
		PARA: golpe[PARA],
		QUANTO: golpe[QUANTO],
		CRIATURA: criatura,
	}


## As criaturas mortas saem das colunas aqui mesmo: ao contrario de uma tropa,
## que fica em DEAD ate ao amanhecer (§16), uma criatura nao deixa corpo. Larga
## as moedas do §25 — "uma moeda no chao onde morreu um Rastejante".
func _mortes_das_criaturas() -> void:
	for creature_id in TargetPicker.ids_por_ordem(_c.ids):
		var c := _c.index_of(creature_id)
		if _c.alive(c):
			continue
		(
			_eventos
			. append(
				{
					CHAVE: EV_MORTE,
					DE: creature_id,
					ONDE: _c.xs[c],
					FAIXA: int(_c.bands[c]),
					MOEDAS: _c.coin_drops[c],
					CRIATURA: true,
					QUEM: _c.data_ids[c],
				}
			)
		)
		_c.remove(creature_id)


## Uma tropa morta fica na coluna, em DEAD: o §16 da-lhe ressurreicao ate ao
## amanhecer e o §50 diz que toda a morte larga alguma coisa. Quem a remove — ou
## a ressuscita — e quem chama; aqui so se anuncia, uma vez.
func _mortes_das_tropas() -> void:
	for unit_id in TargetPicker.ids_por_ordem(_u.ids):
		var i := _u.index_of(unit_id)
		if _u.healths[i] > 0 or _u.states[i] == UnitFsm.State.DEAD:
			continue
		var dados: UnitData = _dados_u.get(_u.data_ids[i])
		_u.states[i] = UnitFsm.State.DEAD
		picker.forget(unit_id)
		(
			_eventos
			. append(
				{
					CHAVE: EV_MORTE,
					DE: unit_id,
					ONDE: _u.xs[i],
					FAIXA: int(_u.bands[i]),
					MOEDAS: _u.carried_coins[i],
					LARGA: dados.drops_on_death if dados != null else [],
					CRIATURA: false,
				}
			)
		)
