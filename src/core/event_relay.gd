# src/core/event_relay.gd — traduz o que os sistemas devolvem para os sinais da
# §46, e mais nada.
#
# Os sistemas de src/sim/ nao conhecem o catalogo de eventos: devolvem pedidos, e
# quem os chama e que enfileira (§43, passo 11; §46). Essa traducao e uma tabela
# de vocabulario, nao uma decisao — e por isso mora aqui, e nao dentro do
# SimLoop, que e dono da ORDEM dos onze passos e nao dos nomes deles (ADR 0020).
#
# As funcoes que devolvem alguma coisa devolvem SEMPRE o mesmo: as moedas a
# largar. Largar uma moeda e um efeito com fisica, sorteio e id novo — e isso e
# do SimLoop, que e quem tem o Verbo 1 (§61).
class_name EventRelay
extends RefCounted

## As chaves das moedas devolvidas.
const ONDE := &"x"
const FAIXA := &"band"
const QUANTO := &"amount"
const PORQUE := &"source"

const FONTE_MORTE := &"death"
const FONTE_PRODUCAO := &"production"
const PROPOSITO_RECRUTA := &"recruit"
const PROPOSITO_CORTE := &"amargueiro_fell"
const LENHO := &"bitter_wood"
const FONTE_SEGREDO := &"secret"


## Passo 4: as mudancas de estado da FSM (§52).
static func units(mudancas: Array[Dictionary]) -> void:
	for m in mudancas:
		EventBus.queue(&"unit_state_changed", [m[&"unit_id"], m[&"from"], m[&"to"]])


## Passo 5: a apanha e o recrutamento (F1-04).
##
## O §46 nao tem sinal para "deixou de ser de ninguem" — o unit_promoted e do
## JobSystem no catalogo, e usa-lo aqui era inventar. O recrutamento anuncia-se
## com o coin_spent, que o §46 da a "Build, recrutamento" (Q-063).
static func pickup(apanhas: Array[Dictionary]) -> void:
	for a in apanhas:
		EventBus.queue(&"coin_collected", [a[RecruitSystem.UNIDADE], a[RecruitSystem.MOEDAS]])
		if a[RecruitSystem.RECRUTADO]:
			EventBus.queue(&"coin_spent", [a[RecruitSystem.PRECO], PROPOSITO_RECRUTA])


## Passos 4 e 6: o combate. Devolve o que as mortes largaram (§50: "toda a morte
## larga: arma, moedas transportadas, ou corpo. Nada desaparece em silencio").
static func combat(eventos: Array[Dictionary]) -> Array[Dictionary]:
	var larga: Array[Dictionary] = []
	for e in eventos:
		match int(e[CombatSystem.CHAVE]):
			CombatSystem.EV_ATAQUE:
				EventBus.queue(
					&"attack_launched",
					[e[CombatSystem.DE], e[CombatSystem.PARA], e[CombatSystem.ACERTOU]]
				)
			CombatSystem.EV_DANO:
				_dano(e)
			CombatSystem.EV_MORTE:
				_morte(e, larga)
			CombatSystem.EV_OBRA:
				builds(e[CombatSystem.EVENTOS])
			CombatSystem.EV_CONTACTO:
				_contacto(e)
			CombatSystem.EV_FAIXA:
				var faixas: Array = e[CombatSystem.PARA]
				EventBus.queue(&"passage_used", [e[CombatSystem.DE], faixas[0], faixas[1]])
	return larga


## Passo 8: as obras (§55). O tremor de ecra do wall_breached e do §24 e quem o
## faz e a apresentacao, que ouve o sinal.
static func builds(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		var vaga: BuildSlot = e[BuildSystem.VAGA]
		match int(e[BuildSystem.CHAVE]):
			BuildSystem.EV_INICIADA:
				EventBus.queue(&"build_started", [vaga.id, vaga.kind])
			BuildSystem.EV_PROGRESSO:
				EventBus.queue(&"build_progressed", [vaga.id, e[BuildSystem.RACIO]])
			BuildSystem.EV_COMPLETA:
				_completa(vaga, e[BuildSystem.NIVEL])
			BuildSystem.EV_DANO:
				EventBus.queue(&"building_damaged", [vaga.id, e[BuildSystem.RACIO]])
			BuildSystem.EV_DESTRUIDA:
				EventBus.queue(&"building_destroyed", [vaga.id, vaga.x])
			BuildSystem.EV_ROMPIDA:
				EventBus.queue(&"wall_breached", [vaga.id])


## Passo 7: a producao do §49. A materia sai como moeda por cima da obra que a
## produziu — o §49 proibe um inventario do jogador, e e essa proibicao que
## mantem os dois verbos intactos. A plantacao apanhada pelo rasto e arrasada
## aqui mesmo; as outras so param, e isso e a ausencia de um evento.
static func economy(eventos: Array[Dictionary], obras: BuildSystem) -> Array[Dictionary]:
	var larga: Array[Dictionary] = []
	for e in eventos:
		var vaga: BuildSlot = e[EconomySystem.VAGA]
		if e[EconomySystem.CHAVE] == EconomySystem.EV_MOEDA:
			(
				larga
				. append(
					{
						ONDE: vaga.x,
						FAIXA: int(vaga.band),
						QUANTO: e[EconomySystem.QUANTO],
						PORQUE: FONTE_PRODUCAO,
					}
				)
			)
			continue
		builds(obras.damage(vaga.id, vaga.health))
	return larga


## Passo 4: a moral (§07). O §46 tem unit_fled para a saida e unit_state_changed
## para as duas pontas — quem foge muda de estado e isso conta-se na mesma.
static func morale(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		var quem: int = e[MoraleSystem.UNIDADE]
		EventBus.queue(&"unit_state_changed", [quem, e[MoraleSystem.DE], e[MoraleSystem.PARA]])
		if e[MoraleSystem.CHAVE] == MoraleSystem.EV_FUGIU:
			EventBus.queue(&"unit_fled", [quem, e[MoraleSystem.PORQUE]])


## Passo 2: o que a Podridao invocou.
static func summoned(pedido: SpawnRequest, massa: float) -> void:
	EventBus.queue(&"rot_summoned", [pedido.creature_id, pedido.x, massa])


## §50: os slots de contacto tem sinal proprio no catalogo da §46, e sao os
## unicos dois que dizem "este atacante passou a engajar" e "deixou de engajar".
static func _contacto(e: Dictionary) -> void:
	var vaga: int = e[ContactQueue.VAGA]
	var lugar: int = e[ContactQueue.LUGAR]
	if e[ContactQueue.CHAVE] == ContactQueue.EV_LIVRE:
		EventBus.queue(&"contact_slot_freed", [vaga, lugar])
		return
	EventBus.queue(&"contact_slot_taken", [vaga, lugar, e[ContactQueue.QUEM]])


static func _dano(e: Dictionary) -> void:
	if e[CombatSystem.CRIATURA]:
		return  # o §46 nao tem creature_damaged: a criatura so anuncia a morte
	EventBus.queue(
		&"unit_damaged", [e[CombatSystem.PARA], e[CombatSystem.QUANTO], e[CombatSystem.DE]]
	)


static func _morte(e: Dictionary, larga: Array[Dictionary]) -> void:
	var moedas: int = e[CombatSystem.MOEDAS]
	if moedas > 0:
		(
			larga
			. append(
				{
					ONDE: e[CombatSystem.ONDE],
					FAIXA: e[CombatSystem.FAIXA],
					QUANTO: moedas,
					PORQUE: FONTE_MORTE,
				}
			)
		)
	if e[CombatSystem.CRIATURA]:
		EventBus.queue(
			&"creature_died", [e[CombatSystem.DE], e[CombatSystem.ONDE], e[CombatSystem.FAIXA]]
		)
		return
	var drops := PackedStringArray()
	for d in e.get(CombatSystem.LARGA, []):
		drops.append(String(d))
	EventBus.queue(
		&"unit_died", [e[CombatSystem.DE], e[CombatSystem.ONDE], e[CombatSystem.FAIXA], drops]
	)


## §55: cada subida de muro emite wall_upgraded, que muda material, silhueta e
## numero de slots de contacto — os tres ao mesmo tempo, porque sao a mesma
## decisao de design. O primeiro nivel e uma obra nova, e por isso leva os dois.
static func _completa(vaga: BuildSlot, nivel: int) -> void:
	if nivel == 1:
		EventBus.queue(&"build_completed", [vaga.id])
	if vaga.blocks:
		EventBus.queue(&"wall_upgraded", [vaga.id, nivel])


## Passo 5: o corte de um Amargueiro (§74). O pagamento e um coin_spent como o
## de uma obra; o Lenho e material produzido, e vai para o imperio (§45).
static func amargueiros(eventos: Array[Dictionary], estado: GameState) -> void:
	for e in eventos:
		match int(e[AmargueiroSystem.CHAVE]):
			AmargueiroSystem.EV_CORTE:
				EventBus.queue(&"coin_spent", [e[AmargueiroSystem.QUANTO], PROPOSITO_CORTE])
			AmargueiroSystem.EV_CORTADA:
				estado.bitter_wood += int(e[AmargueiroSystem.QUANTO])
				var lenho := [e[AmargueiroSystem.ID], LENHO, e[AmargueiroSystem.QUANTO]]
				EventBus.queue(&"material_produced", lenho)


## Passo 5: um segredo achado (§17) e a Semente Real que ele deu (§46).
static func secrets(achados: Array[Dictionary]) -> void:
	for a in achados:
		EventBus.queue(&"secret_found", [a[SecretSites.ID]])
		if int(a[SecretSites.SEMENTES]) > 0:
			EventBus.queue(&"seed_royal_gained", [a[SecretSites.SEMENTES], FONTE_SEGREDO])


## Passo 5, na alvorada: quem ganhou nome (§76). A §46 nao tem sinal para um
## titulo; o unit_promoted e o que mais se lhe chega — "de" nada "para" o
## titulo —, e e o que a encomendacao do XIII-09 vai ouvir (Q-088).
static func names(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		if int(e[NameSystem.CHAVE]) == NameSystem.EV_NOMEADO:
			EventBus.queue(&"unit_promoted", [e[NameSystem.UNIDADE], &"", e[NameSystem.TITULO]])
