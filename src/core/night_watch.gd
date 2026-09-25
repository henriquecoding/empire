# src/core/night_watch.gd — o ciclo da noite: quem nasce ao crepusculo, quem
# recua a alvorada, e quem e invocado pelo meio (§05, §51).
#
# Vive fora do SimLoop porque nao e um passo: e o que o passo 2 faz. O SimLoop
# guarda a ORDEM dos onze passos (ADR 0020) e chama isto uma vez; a mancha nasce,
# anda, invoca e recua sem que a lista de passos cresca com tres funcoes.
#
# A ponte que a pureza obriga esta toda aqui: o intervalo entre invocacoes vem
# sorteado do fluxo `rot`, o lado por onde ela chega tambem, e os CreatureData
# vem do Registry — tres coisas que a simulacao nao pode tocar (§42, §70).
class_name NightWatch
extends RefCounted

const TABELA_CRIATURAS := &"creatures"

var rot: RotSystem

## Quem ficou no campo (§74). Vive aqui porque e a noite que o le e a alvorada
## que o escreve: a massa ao crepusculo, a raiz ao amanhecer.
var trees: AmargueiroSystem

## A voz da mancha e a Divida que ela sobe (§75). A ponte com o resto do jogo e
## o OfferDesk.
var offers: OfferSystem


func _init() -> void:
	rot = SimFactory.rot()
	trees = SimFactory.amargueiros()
	offers = SimFactory.offers()


## Passo 2 do §43. `mundo` leva o x do nucleo e a largura da regiao: e para o
## nucleo que as criaturas caminham, e e da borda mais distante que ela nasce.
func tick(
	delta: float, fase: int, mudou: bool, estado: GameState, bichos: CreatureSystem, mundo: Vector2
) -> void:
	if mudou:
		_virar(fase, estado, bichos, mundo)
	if not rot.active():
		return
	if rot.needs_interval():
		var janela := SimFactory.rot_window()
		rot.arm(RngService.float_range(&"rot", janela.x, janela.y))
	# O terreno consagrado que ja existe sao os Marcos (§74). Fogueiras e barris
	# sao da XIII-04 e ainda nao estao aqui.
	for pedido in rot.tick(delta, trees.markers()):
		_invocar(pedido, estado, bichos, mundo.x)
	EventBus.queue(&"rot_moved", [rot.position_x(), rot.state.width])


## Os intervalos em x por onde ela ja passou. O §49 le isto para saber que um
## edificio nao produz hoje, e que uma plantacao foi arrasada.
func trail() -> Array[Vector2]:
	if not rot.active():
		return []
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	return [Vector2(de, maxf(rot.state.trail_from, rot.state.trail_to))]


## A Alvorada do campo (§74): quem morreu desde ontem cria raiz ou desaparece.
## Corre no passo 5 e nao no 2, porque precisa das tropas e das muralhas.
func dawn(estado: GameState, unidades: UnitSystem, obras: BuildSystem, core_x: float) -> void:
	trees.at_dawn(estado, unidades, obras, core_x)


## A noite saltada ("O que brilha, e nada mais", §75): a mancha recua ja, e o
## que ela invocou dissolve-se como ao amanhecer.
func skip(estado: GameState, bichos: CreatureSystem) -> void:
	rot.retreat()
	EventBus.queue(&"rot_retreated", [estado.day])
	for creature_id in bichos.dissolve():
		EventBus.queue(&"creature_died", [creature_id, rot.position_x(), int(Band.Kind.SURFACE)])


func _virar(fase: int, estado: GameState, bichos: CreatureSystem, mundo: Vector2) -> void:
	if fase == GameClock.Phase.DUSK:
		# O lado sai do fluxo `rot`: de que lado ela vem afeta a simulacao e por
		# isso reproduz-se com a semente. O dia 12 traz duas manchas (§51) e isso
		# sao duas NightWatch — e o F1-09 que as poe.
		var lado := 1 if RngService.int_range(&"rot", 0, 1) == 1 else -1
		rot.amargueiros = trees.standing(false)
		rot.named_amargueiros = trees.standing(true)
		rot.refusals = offers.refusals(estado.day)
		rot.spawn(estado.day, lado, mundo.y)
		offers.night_time = 0.0
		EventBus.queue(&"rot_spawned", [rot.position_x(), rot.state.width, rot.mass(), lado])
		_da_divida(estado, bichos, mundo.x)
		return
	if fase == GameClock.Phase.DAWN and rot.active():
		skip(estado, bichos)


## O que nasce da Divida e nao da massa: o Zelador aos 6 (§75). Anda atras da
## mancha, para o nucleo, e nao bate em ninguem.
func _da_divida(estado: GameState, bichos: CreatureSystem, nucleo: float) -> void:
	for recurso in Registry.entries(TABELA_CRIATURAS):
		var dados := recurso as CreatureData
		if dados.from_debt > 0 and offers.debt.debt >= dados.from_debt:
			bichos.spawn(estado, dados, rot.position_x(), nucleo)


func _invocar(
	pedido: SpawnRequest, estado: GameState, bichos: CreatureSystem, nucleo: float
) -> void:
	var dados := Registry.entry(TABELA_CRIATURAS, pedido.creature_id) as CreatureData
	bichos.spawn(estado, dados, pedido.x, nucleo)
	EventRelay.summoned(pedido, rot.mass())
