# tools/autopilot.gd — um jogador de mentira, para a vistoria (§25, §61).
#
# Fora do jogo: `tools/` esta no exclude_filter do export.
#
# Sem ninguem a jogar, o greybox e degenerado: ninguem recruta, ninguem constroi,
# e a noite 1 leva o castelo-arvore (Q-068). Uma partida assim nao exercita
# metade do tick, e por isso nao encontra defeitos nele.
#
# Isto e o minimo que faz o ciclo do §25 andar: apanha moedas, recruta quem
# encontra, e paga as obras que estao por levantar. NAO joga bem de proposito —
# nao escolhe, nao poupa, nao defende um flanco. Serve para o jogo ANDAR, e o
# que se mede e se ele anda sem se partir.
#
# Passa pelo mesmo caminho que um humano: enfileira intencoes (§61) e escreve um
# alvo de movimento, exactamente como o `input_router.gd`. Um piloto que chamasse
# `drop_coin` directamente nao provava nada sobre o jogo que as pessoas jogam.
class_name Autopilot
extends RefCounted

## A que distancia do alvo se considera chegado e se larga a moeda. E a
## tolerancia de um gesto, como a PASSAGE_PX do §11 — nao e balanceamento.
const CHEGOU_PX := 12.0

## A que distancia se recruta de passagem. E o recruit_notice_px do §25 lido de
## data/? Nao: e o alcance do GESTO, e nao do sistema — o piloto so desvia o
## caminho por quem ja esta ao lado.
const PERTO_PX := 90.0


## Um passo do piloto. Escolhe para onde ir e larga quando chega.
static func step(loop: Node) -> void:
	var rei: int = loop.units.index_of(loop.king_id)
	if rei == UnitSystem.NENHUM or not loop.units.alive(rei):
		return
	var onde: float = loop.units.xs[rei]
	var alvo := _destino(loop, rei, onde)
	if is_inf(alvo):
		return
	loop.units.set_target_x(loop.king_id, alvo)
	var saco: int = loop.units.carried_coins[rei]
	if absf(alvo - onde) <= CHEGOU_PX and saco > 0:
		_largar(loop, rei)


## Para onde ir. Por esta ordem: uma moeda no chao, alguem por recrutar, uma obra
## por levantar. E a ordem do §25 — primeiro ter com que pagar, depois gente,
## depois muro.
static func _destino(loop: Node, rei: int, onde: float) -> float:
	# Ao crepusculo volta-se para dentro, e quem te segue vem contigo: uma noite
	# passada fora do muro com a gente atras deixava o nucleo sem ninguem (§25).
	if int(ClockService.clock.current_phase()) >= int(GameClock.Phase.DUSK):
		if not loop.night.rot.active():
			return loop.core_x
		# Na borda do nucleo do lado da mancha: e ai que as criaturas mordem.
		var lado := signf(loop.night.rot.position_x() - loop.core_x)
		return loop.core_x + lado * _meio_nucleo(loop)
	var saco: int = loop.units.carried_coins[rei]
	# Com o saco vazio nao ha nada a fazer senao ir buscar moeda. Com moeda na
	# mao vai-se GASTAR: um piloto que corresse atras da moeda que acabou de
	# largar ficava preso a largar e a apanhar a mesma, no mesmo sitio, o dia
	# inteiro — foi o que ele fez na primeira corrida.
	if saco <= 0:
		return _moeda_mais_perto(loop, onde)
	# Recruta quem passa ao lado — e o minuto 0:20 do §25, e nao custa desvio
	# nenhum — e no resto do tempo paga a obra mais perto que o saco chega para
	# levantar. Sem isto o piloto gastava as seis moedas da partida em gente e
	# ficava sem renda nenhuma: ao dia 2 nao tinha com que fazer mais nada.
	var gente := _por_recrutar(loop, onde)
	if not is_inf(gente) and absf(gente - onde) <= PERTO_PX:
		return gente
	var obra := _obra(loop, onde, saco)
	if not is_inf(obra):
		return obra
	if not is_inf(gente):
		return gente
	return _moeda_mais_perto(loop, onde)


static func _moeda_mais_perto(loop: Node, onde: float) -> float:
	var melhor := INF
	var moedas: CoinSystem = loop.coins
	for i in moedas.count():
		var x: float = moedas.xs[i]
		if is_inf(melhor) or absf(x - onde) < absf(melhor - onde):
			melhor = x
	return melhor


## §25, minuto 0:20: "largas uma moeda ao lado de quem nao e de ninguem e ele
## passa a ser teu".
static func _por_recrutar(loop: Node, onde: float) -> float:
	var melhor := INF
	var unidades: UnitSystem = loop.units
	for i in unidades.count():
		if unidades.owners[i] != RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var x: float = unidades.xs[i]
		if is_inf(melhor) or absf(x - onde) < absf(melhor - onde):
			melhor = x
	return melhor


## §55: a obra levanta-se largando moedas em cima dela. O piloto escolhe a mais
## perto que o saco chega para levantar, e prefere as que RENDEM — uma partida
## que gasta as primeiras moedas em muro fica sem economia (§06, circuito 1).
static func _obra(loop: Node, onde: float, saco: int) -> float:
	var melhor := INF
	var rende := false
	# A tarde prepara a noite: o que "rende" passa a ser o que trava (§05).
	var tarde := int(ClockService.clock.current_phase()) == int(GameClock.Phase.AFTERNOON)
	for vaga in loop.builds.slots:
		var custo: int = vaga.next_cost()
		if vaga.kind == BuildSlot.NUCLEO or custo <= 0 or custo > saco:
			continue
		var da_renda: bool = vaga.blocks if tarde else vaga.yield_per_day > 0.0
		if rende and not da_renda:
			continue
		var troca := da_renda and not rende
		if is_inf(melhor) or troca or absf(vaga.x - onde) < absf(melhor - onde):
			melhor = vaga.x
			rende = da_renda
	return melhor


static func _largar(loop: Node, rei: int) -> void:
	(
		loop
		. intents
		. queue(
			IntentQueue.Kind.DROP_COIN,
			{
				&"x": loop.units.xs[rei],
				&"band": loop.units.bands[rei] as Band.Kind,
				&"amount": InputRouter.UMA,
				&"source": Verbs.JOGADOR,
			}
		)
	)


static func _meio_nucleo(loop: Node) -> float:
	for vaga in loop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga.width * BuildSystem.METADE
	return 0.0
