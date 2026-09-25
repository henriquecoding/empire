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

var rot: RotSystem
var amargueiros: AmargueiroSystem
var voice: OfferWatch
## Os nomes (§76): ganham-se na alvorada, e a noite e onde se fazem os feitos.
var names: TitleSystem
## A Colheita (§78): conta dias a alvorada, e os marcos de quem ficou pesam.
var harvest: HarvestSystem

var _tropas: UnitSystem
var _obras: BuildSystem
var _postos: JobBoard


## As tropas, as obras e as moedas sao as do SimLoop, e as mesmas durante o jogo
## inteiro: um corpo sai das colunas na alvorada, uma serra entra no
## BuildSystem (§55), e o preco de uma oferta cai no prato (§75).
func _init(tropas: UnitSystem, obras: BuildSystem, moedas: CoinSystem, postos: JobBoard) -> void:
	rot = SimFactory.rot()
	amargueiros = SimFactory.amargueiros()
	voice = OfferWatch.new(moedas, tropas, obras)
	names = SimFactory.titles()
	harvest = HarvestSystem.new(SimFactory.curve())
	_tropas = tropas
	_obras = obras
	_postos = postos


## Passo 2 do §43. `mundo` leva o x do nucleo e a largura da regiao: e para o
## nucleo que as criaturas caminham, e e da borda mais distante que ela nasce.
func tick(
	delta: float, fase: int, mudou: bool, estado: GameState, bichos: CreatureSystem, mundo: Vector2
) -> void:
	if mudou:
		_virar(fase, estado, bichos, mundo)
	amargueiros.harvest(_obras)  # a serra que acabou no passo 8 do tick anterior
	voice.titles = names.by_unit()
	voice.tick(delta, rot, estado.day, mundo, amargueiros)
	if not rot.active() or voice.paused(delta):
		return
	if rot.needs_interval():
		var janela := SimFactory.rot_window()
		rot.arm(RngService.float_range(&"rot", janela.x, janela.y))
	# O terreno consagrado de hoje sao os Marcos (§74). Fogueiras e barris sao
	# luz do §10 e nao consagram nada; o altar consagrado e da Fase 6.
	for pedido in rot.tick(delta, amargueiros.consecrated()):
		_invocar(pedido, estado, bichos, mundo.x)
	var meia := rot.state.width * BuildSystem.METADE
	names.stain(_tropas, rot.position_x() - meia, rot.position_x() + meia)  # §76
	EventBus.queue(&"rot_moved", [rot.position_x(), rot.state.width])


## Passo 6: o que o combate devolveu passa pelo registo dos feitos (§76) — quem
## abateu o que — e segue tal e qual para o EventRelay.
func feats(eventos: Array[Dictionary]) -> Array[Dictionary]:
	return names.observe(eventos)


## Os intervalos em x por onde ela ja passou. O §49 le isto para saber que um
## edificio nao produz hoje, e que uma plantacao foi arrasada.
func trail() -> Array[Vector2]:
	if not rot.active():
		return []
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	return [Vector2(de, maxf(rot.state.trail_from, rot.state.trail_to))]


func _virar(fase: int, estado: GameState, bichos: CreatureSystem, mundo: Vector2) -> void:
	if fase == GameClock.Phase.DAWN:
		# O dia do relogio e nao o do GameState: esse so e espelhado no fim do tick.
		# Os nomes leem-se ANTES de os corpos se levantarem: uma arvore nomeada e a
		# cara de alguem que tinha titulo (§74, §76), e o titulo so depois vai de luto.
		var dia := ClockService.clock.day
		amargueiros.at_dawn(dia, _tropas, _obras, mundo.x, mundo.y, names.by_unit())
		names.at_dawn(dia, _tropas, _postos)
		harvest.at_dawn()
	if fase == GameClock.Phase.DUSK:
		# O que o jogador escreveu de dia (§74): cada arvore de pe e massa.
		# O marco de um povo que ficou cria raiz e nao se corta (§78): e mais uma.
		rot.amargueiros = amargueiros.anonymous() + harvest.landmarks()
		rot.named_amargueiros = amargueiros.named()
		# O lado sai do fluxo `rot`: de que lado ela vem afeta a simulacao e por
		# isso reproduz-se com a semente. O dia 12 traz duas manchas (§51) e isso
		# sao duas NightWatch — e o F1-09 que as poe.
		var lado := 1 if RngService.int_range(&"rot", 0, 1) == 1 else -1
		if not voice.before_spawn(rot, estado.day):
			return  # §75: a decima segunda fechou o ciclo
		rot.spawn(estado.day, lado, mundo.y)
		voice.after_spawn(rot)
		EventBus.queue(&"rot_spawned", [rot.position_x(), rot.state.width, rot.mass(), lado])
		return
	if fase != GameClock.Phase.DAWN:
		return
	# O que ela invocou dissolve-se sempre: uma oferta pode te-la recolhido antes
	# da alvorada (§75, "a mancha contorna"), e o que ficou no campo nao fica.
	voice.dawn()
	if rot.active():
		rot.retreat()
		EventBus.queue(&"rot_retreated", [estado.day])
	for creature_id in bichos.dissolve():
		EventBus.queue(&"creature_died", [creature_id, rot.position_x(), int(Band.Kind.SURFACE)])


func _invocar(
	pedido: SpawnRequest, estado: GameState, bichos: CreatureSystem, nucleo: float
) -> void:
	var dados := Registry.entry(TABELA_CRIATURAS, pedido.creature_id) as CreatureData
	bichos.spawn(estado, dados, pedido.x, nucleo)
	EventRelay.summoned(pedido, rot.mass())
