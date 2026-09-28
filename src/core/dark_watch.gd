# src/core/dark_watch.gd — o escuro da noite, o archote e quem vem de la (Q-029).
#
# A ponte que a pureza obriga: o Torchlight (sim) diz QUANDO o escuro traz
# alguem; isto sorteia o lado no fluxo `rot` (§42), vai buscar a criatura ao
# Registry e invoca-a ao lado do rei. E vende o archote: uma moeda do rei largada
# numa fogueira de pe (`sells_torch`) e um archote no saco dele.
class_name DarkWatch
extends RefCounted

const NENHUM := -1
const METADE := 0.5

var torch: Torchlight
var _perfil: RotProfile


func _init() -> void:
	_perfil = SimFactory.rot_profile()
	torch = Torchlight.new(_perfil)


## Passo 2, com a noite: o rei no escuro sem archote chama quem la vive.
func tick(
	delta: float,
	fase: int,
	estado: GameState,
	bichos: CreatureSystem,
	obras: BuildSystem,
	nucleo_x: float
) -> void:
	var tropas := SimLoop.units
	var r := tropas.index_of(SimLoop.king_id)
	if r == NENHUM or not tropas.alive(r):
		return
	var noite := fase == GameClock.Phase.NIGHT
	var sup := tropas.bands[r] == int(Band.Kind.SURFACE)
	var escuro := sup and Torchlight.in_dark(tropas.xs[r], obras, nucleo_x, _meia(obras))
	if not torch.tick(delta, noite, escuro):
		return
	var lado := signf(RngService.unit_float(&"rot") - METADE)  # de qualquer lado
	var x := tropas.xs[r] + lado * _perfil.dark_ambush_px
	var dados := Registry.entry(&"creatures", _perfil.dark_creature) as CreatureData
	bichos.spawn(estado, dados, x, nucleo_x)
	EventRelay.summoned(SpawnRequest.new(dados.id, x, Band.Kind.SURFACE), 0.0)


## Uma moeda do rei numa fogueira de pe compra archotes (Q-029). Verdadeiro se
## comprou: a moeda fica na fogueira.
func buy_at(largada: Dictionary, obras: BuildSystem) -> bool:
	var x: float = largada[EventRelay.ONDE]
	for obra in obras.standing():
		if not obra.effects.has(&"sells_torch") or obra.band != int(largada[EventRelay.FAIXA]):
			continue
		if absf(obra.x - x) > obra.width * BuildSystem.METADE:
			continue
		var quantos := int(largada[EventRelay.QUANTO]) / maxi(1, _perfil.torch_cost)
		return torch.buy(quantos) > 0
	return false


func _meia(obras: BuildSystem) -> float:
	for obra in obras.slots:
		if obra.kind == BuildSlot.NUCLEO:
			return obra.width * BuildSystem.METADE
	return 0.0
