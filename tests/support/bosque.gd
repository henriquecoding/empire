# tests/support/bosque.gd — o que os testes do Amargueiro (§74) montam: um muro,
# uma tropa morta, moedas pousadas e uma serra que acaba. Os numeros vem todos de
# data/; aqui so ha a geometria da regiao de teste.
extends RefCounted

const MEU_IMPERIO := 7
const PASSO := 1.0 / 30.0
const NUCLEO := 2000.0
const LARGURA := 4000.0
const MURO := 2400.0
const FORA := 3000.0
const DENTRO := 2200.0
const TITULO := "TITLE_FIRST_WALL"


static func perfil() -> RotProfile:
	return Registry.entry(&"rot", &"default") as RotProfile


static func destino(id: StringName) -> AmargueiroData:
	return Registry.entry(&"rot/amargueiros", id) as AmargueiroData


## Um muro de pe em x. So interessa que trave: e o que separa dentro de fora.
static func muro(obras: BuildSystem, x: float) -> void:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = &"stakes"
	vaga.blocks = true
	vaga.costs = PackedInt32Array([1])
	vaga.works = PackedFloat32Array([1.0])
	vaga.healths = PackedInt32Array([10])
	vaga.level = 1
	vaga.health = 10
	vaga.state = BuildSlot.State.DONE
	vaga.width = 32.0
	obras.post(vaga)


## Uma tropa tua, morta em x. E o que o combate deixa na coluna (§16, §50).
static func morto(unidades: UnitSystem, estado: GameState, tropa: StringName, x: float) -> int:
	var dados := Registry.entry(&"units", tropa) as UnitData
	var unit_id := unidades.spawn(estado, dados, MEU_IMPERIO, x)
	var i := unidades.index_of(unit_id)
	unidades.healths[i] = 0
	unidades.states[i] = UnitFsm.State.DEAD
	return unit_id


static func alvorada(
	bosque: AmargueiroSystem, dia: int, u: UnitSystem, o: BuildSystem, titulos := {}
) -> Array[Dictionary]:
	return bosque.at_dawn(dia, u, o, NUCLEO, LARGURA, titulos)


static func moedas_pousadas(estado: GameState, x: float, quantas: int) -> CoinSystem:
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	for _i in quantas:
		moedas.drop(estado, x, Band.Kind.SURFACE, 1, 0.0)
	for _t in 300:
		moedas.tick(PASSO)
	return moedas


## Paga o corte com o Verbo 1 e poe alguem ao pe da arvore ate a serra acabar —
## o §55 inteiro: a moeda cai, e o progresso e presenca.
static func cortar(
	bosque: AmargueiroSystem, estado: GameState, u: UnitSystem, o: BuildSystem, x: float
) -> Array[Dictionary]:
	o.absorb(moedas_pousadas(estado, x, destino(&"fell").cost_coins))
	u.spawn(estado, Registry.entry(&"units", &"builder"), MEU_IMPERIO, x)
	var eventos: Array[Dictionary] = []
	for _t in int((destino(&"fell").work_seconds + 1.0) / PASSO):
		o.tick(PASSO, u)
		eventos.append_array(bosque.harvest(o))
	return eventos


## A noite como o SimLoop a monta, com tropas, obras e moedas proprias.
static func noite(u: UnitSystem, o: BuildSystem) -> NightWatch:
	return NightWatch.new(
		u, o, CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	)
