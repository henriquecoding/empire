# src/core/night_watch.gd — o ciclo da noite: quem nasce ao crepusculo, quem
# recua a alvorada, e quem e invocado pelo meio (§05, §51).
#
# Vive fora do SimLoop porque nao e um passo: e o que o passo 2 faz. O SimLoop
# guarda a ORDEM dos onze passos (ADR 0020) e chama isto uma vez; a mancha nasce,
# anda, invoca e recua sem que a lista de passos cresca com tres funcoes.
#
# E e tambem o que a noite deixa: os Amargueiros (§74) nascem na alvorada, pesam
# no crepusculo seguinte e, quando viram Marco, abrandam a mancha — tres pontas
# do mesmo ciclo, e por isso vivem aqui e nao num passo novo do §43. A voz dela
# — a Oferta e a Divida da Candeia (§75) — e o OfferWatch, que isto chama.
#
# A ponte que a pureza obriga esta toda aqui: o intervalo entre invocacoes vem
# sorteado do fluxo `rot`, o lado por onde ela chega tambem, e os CreatureData
# vem do Registry — tres coisas que a simulacao nao pode tocar (§42, §70).
class_name NightWatch
extends RefCounted

const TABELA_CRIATURAS := &"creatures"
## O poco de minerio "atrai Cavadores" (§06): a tag e da obra (Q-131).
const CHAMA_CAVADORES := &"attracts_burrowers"
## O que o escuro recebe no lugar da fase quando a noite ja nao tem Podridao.
const SEM_NOITE := -1

var other_rot: RotSystem
var rot: RotSystem
var amargueiros: AmargueiroSystem
var voice: OfferWatch
## Os nomes (§76): ganham-se na alvorada, e a noite e onde se fazem os feitos.
var names: TitleSystem
## A Colheita (§78): conta dias a alvorada, e os marcos de quem ficou pesam.
var harvest: HarvestSystem
## O escuro, o archote e quem vem de la (Q-029).
var dark: DarkWatch

var _tropas: UnitSystem
var _obras: BuildSystem
var _postos: JobBoard
var _moedas: CoinSystem
var _edificios: Dictionary
var _criaturas: Dictionary


## As tropas, as obras e as moedas sao as do SimLoop, e as mesmas durante o jogo
## inteiro: um corpo sai das colunas na alvorada, uma serra entra no
## BuildSystem (§55), e o preco de uma oferta cai no prato (§75).
func _init(tropas: UnitSystem, obras: BuildSystem, moedas: CoinSystem, postos: JobBoard) -> void:
	rot = SimFactory.rot()
	other_rot = SimFactory.rot()
	amargueiros = SimFactory.amargueiros()
	voice = OfferWatch.new(moedas, tropas, obras)
	names = SimFactory.titles()
	harvest = HarvestSystem.new(SimFactory.curve())
	dark = DarkWatch.new()
	_tropas = tropas
	_moedas = moedas
	_obras = obras
	_postos = postos
	_edificios = SimFactory.by_id(&"buildings")
	_criaturas = SimFactory.by_id(TABELA_CRIATURAS)


## Passo 2 do §43. `mundo` leva o x do nucleo e a largura da regiao: e para o
## nucleo que as criaturas caminham, e e da borda mais distante que ela nasce.
func tick(
	delta: float, fase: int, mudou: bool, estado: GameState, bichos: CreatureSystem, mundo: Vector2
) -> void:
	if mudou:
		_virar(fase, estado, bichos, mundo)
	SpiritWatch.felled(amargueiros.harvest(_obras))  # a serra acabada; o nome pesa (§74)
	voice.titles = names.by_unit()
	voice.tick(delta, rot, estado.day, mundo, amargueiros)
	# Uma noite saltada ou acabada pela Oferta ja nao tem escuro que chame ninguem.
	dark.tick(delta, fase if rot.active() else SEM_NOITE, estado, bichos, _obras, mundo.x)
	bichos.set_lights(dark.wards(_obras, mundo.x), SimFactory.rot_profile().light_recoil_s)
	RiftWatch.tick(self, delta, estado, bichos, mundo.x)
	CrownWatch.tick(bichos, rot)  # a coroa no chao (Q-167)
	if not rot.active():
		return
	if Discoveries.known(estado, &"sacrifice"):  # a Estatua da Oferenda (Q-016)
		Sacrifice.feed(rot, voice, _moedas)
	var borda := mundo.y if rot.state.side > 0 else 0.0
	Thieves.plan(bichos, _criaturas, _obras, _edificios, borda)  # o Alado (Q-129)
	if voice.paused(delta):
		return
	if rot.needs_interval():
		var janela := SimFactory.rot_window()
		rot.arm(RngService.float_range(&"rot", janela.x, janela.y))
	# O terreno consagrado sao os Marcos (§74); fogueiras e barris abrandam-na
	# pelo `rot_slow` deles (§05, Q-029). O altar consagrado e da Fase 6.
	for pedido in rot.tick(delta, amargueiros.consecrated(), FireZones.of(_obras)):
		_invocar(pedido, estado, bichos, mundo.x)
	var meia := rot.state.width * BuildSystem.METADE
	names.stain(_tropas, rot.position_x() - meia, rot.position_x() + meia)  # §76
	EventBus.queue(&"rot_moved", [rot.position_x(), rot.state.width])


## Passo 6: o que o combate devolveu passa pelo registo dos feitos (§76) — quem
## abateu o que — e segue tal e qual para o EventRelay.
func feats(eventos: Array[Dictionary]) -> Array[Dictionary]:
	return names.observe(eventos)


## O Verbo 1 em cima de uma arvore de pe, com uma Semente Real no imperio:
## consagra-a em vez de largar a moeda, e a moeda volta ao saco de quem a largou
## (§74, Q-095). Sem Semente, ou fora de uma base, cai a moeda.
func consecrate_at(estado: GameState, largada: Dictionary, quem: int) -> bool:
	var custo := (
		(Registry.entry(&"rot/amargueiros", AmargueiroSystem.CONSAGRAR) as AmargueiroData)
		. cost_seeds
	)
	if estado.royal_seeds < custo:
		return false
	var x: float = largada[EventRelay.ONDE]
	var meia := SimFactory.rot_profile().amargueiro_base_px * BuildSystem.METADE
	for i in amargueiros.count():
		var aqui := amargueiros.bands[i] == int(largada[EventRelay.FAIXA])
		if not aqui or absf(amargueiros.xs[i] - x) > meia:
			continue
		if not amargueiros.consecrate(i, _obras):
			return false
		estado.royal_seeds -= custo
		var u := _tropas.index_of(quem)
		if u != UnitSystem.NENHUM:
			_tropas.carried_coins[u] += int(largada[EventRelay.QUANTO])
		return true
	return false


## Qual dos tres finais, se a campanha acabasse agora (§79, ADR 0018).
func epilogue() -> StringName:
	var perfil := SimFactory.rot_profile()
	var divida := voice.debt
	var ficaram := harvest.kept.size() + SimLoop.field.realm.vassals.vassals.size()  # Q-103
	var soltos := harvest.released.size()
	return Epilogue.of(divida.debt, ficaram, soltos, perfil, divida.lume_out)


## Os intervalos em x por onde ela ja passou. O §49 le isto para saber que um
## edificio nao produz hoje, e que uma plantacao foi arrasada.
func trail() -> Array[Vector2]:
	if not rot.active():
		return []
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	return [Vector2(de, maxf(rot.state.trail_from, rot.state.trail_to))]


func _virar(fase: int, estado: GameState, bichos: CreatureSystem, mundo: Vector2) -> void:
	# A tarde diz de que lado vem a noite (Q-125): e o mesmo sorteio que o
	# crepusculo fazia, so mais cedo — nada do fluxo `rot` corre entre os dois.
	if fase == GameClock.Phase.AFTERNOON and rot.announced == 0:
		rot.announced = -1 if SimLoop.arrival.active and estado.day == 1 else _sortear_lado()
	if fase == GameClock.Phase.DAWN:
		# O dia do relogio e nao o do GameState: esse so e espelhado no fim do tick.
		# Os nomes leem-se ANTES de os corpos se levantarem: uma arvore nomeada e a
		# cara de alguem que tinha titulo (§74, §76), e o titulo so depois vai de luto.
		var dia := ClockService.clock.day
		CrownWatch.dawn()  # a coroa que ninguem levou volta, antes das raizes (Q-167)
		amargueiros.at_dawn(dia, _tropas, _obras, mundo.x, mundo.y, names.by_unit())
		names.at_dawn(dia, _tropas, _postos)
		harvest.at_dawn()
		Ward.dawn(_obras, dia)  # o sino perde carga, mais quanto mais tarde (Q-100)
		dark.hearth.dawn()  # a lareira apaga-se; acende-se paga ao crepusculo (Q-190)
	if fase == GameClock.Phase.DUSK:
		# O que o jogador escreveu de dia (§74): cada arvore de pe e massa.
		# O marco de um povo que ficou cria raiz e nao se corta (§78): e mais uma.
		rot.amargueiros = amargueiros.anonymous() + harvest.landmarks()
		rot.named_amargueiros = amargueiros.named()
		# O lado sai do fluxo `rot`: de que lado ela vem afeta a simulacao e por
		# isso reproduz-se com a semente. O dia 12 traz duas manchas (§51) e isso
		# sao duas NightWatch — e o F1-09 que as poe.
		var lado := rot.announced if rot.announced != 0 else _sortear_lado()
		rot.announced = 0
		# O subsolo (AUD-04): o poco chama o Cavador mais cedo (Q-131), e um lado
		# com as passagens escoradas nao lhe deixa caminho (Q-132).
		rot.lure_days = SimFactory.rot_profile().mine_lure_days if _chama() else 0
		rot.underground_open = not Passages.sealed_side(SimLoop.passages, _obras, mundo.x, lado)
		if not voice.before_spawn(rot, estado.day):
			return  # §75: a decima segunda fechou o ciclo
		dark.kindle()  # so ha lareira a pagar numa noite que vem (Q-190)
		rot.spawn(estado.day, lado, mundo.y)
		RiftWatch.spawn(self, estado, mundo)
		SettlementWatch.night(SimLoop.field)
		voice.after_spawn(rot)
		EventBus.queue(&"rot_spawned", [rot.position_x(), rot.state.width, rot.mass(), lado])
		return
	if fase != GameClock.Phase.DAWN:
		return
	# O que ela invocou dissolve-se sempre: uma oferta pode te-la recolhido antes
	# da alvorada (§75, "a mancha contorna"), e o que ficou no campo nao fica.
	voice.dawn(estado.day)
	if rot.active():
		rot.retreat()
		EventBus.queue(&"rot_retreated", [estado.day])
	_roubos(bichos)
	other_rot.retreat()
	var keep := DungeonWatch.guardians(SimLoop.field)
	keep.append_array(SimLoop.field.song.permanent())
	for creature_id in bichos.dissolve(keep):
		EventBus.queue(&"creature_died", [creature_id, rot.position_x(), int(Band.Kind.SURFACE)])


func _invocar(
	pedido: SpawnRequest, estado: GameState, bichos: CreatureSystem, nucleo: float
) -> void:
	var dados := Registry.entry(TABELA_CRIATURAS, pedido.creature_id) as CreatureData
	bichos.spawn(estado, dados, pedido.x, LastCartWatch.first_night_target(nucleo))
	EventRelay.summoned(pedido, rot.mass())


## Quem chegou vivo a alvorada com uma galinha levou-a (Q-129).
func _roubos(bichos: CreatureSystem) -> void:
	for perda in Thieves.escape(bichos, _obras, SimFactory.curve().chicken_theft_matter):
		var obra := _obras.slots[_obras.index_of(perda[Thieves.OBRA])]
		voice.debt.feed_lume(perda[Thieves.QUANTO])  # a galinha vai para o Lume
		var tipo: StringName = (_edificios[obra.kind] as BuildingData).material
		EventBus.queue(&"material_consumed", [obra.id, tipo, roundi(perda[Thieves.QUANTO])])


func _chama() -> bool:
	for obra in _obras.standing():
		var dados: BuildingData = _edificios.get(obra.kind)
		if dados != null and dados.tags.has(CHAMA_CAVADORES):
			return true
	return false


func _sortear_lado() -> int:
	return 1 if RngService.int_range(&"rot", 0, 1) == 1 else -1
