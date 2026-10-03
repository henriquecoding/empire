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
## O proposito do coin_spent de uma moeda que ficou numa fogueira (§46).
const ARCHOTE := &"torch"
const LAREIRA := &"hearth"

var torch: Torchlight
var hearth := Hearth.new()  # a lareira do nucleo, paga a noite (Q-190)
var _perfil: RotProfile


func _init() -> void:
	_perfil = SimFactory.rot_profile()
	# O cinto do rei; o FieldWork troca-o pelo da classe, que e o que se grava (Q-153).
	var monarca := Registry.entry(&"classes", &"monarch") as ClassData
	torch = Torchlight.new(_perfil, SimFactory.storage(monarca))


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
	var r := tropas.index_of(Assume.driven())  # quem o jogador conduz no escuro (§08)
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


## A luz do archote aceso, como zona do LightWard (ADR 0034); vazia se apagado.
func ward() -> Vector4:
	var r := SimLoop.units.index_of(Assume.driven())
	if r == NENHUM or not torch.lit():
		return Vector4.ZERO
	var x := SimLoop.units.xs[r]
	var raio := _perfil.torch_radius_px
	return Vector4(x - raio, x + raio, float(_perfil.torch_repel_mass), 0.0)


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
		if torch.buy(quantos) <= 0:
			return false
		EventBus.queue(&"coin_spent", [int(largada[EventRelay.QUANTO]), ARCHOTE])  # §46
		return true
	return false


func _meia(obras: BuildSystem) -> float:
	for obra in obras.slots:
		if obra.kind == BuildSlot.NUCLEO:
			return obra.width * BuildSystem.METADE
	return 0.0


## As luzes que afastam: as obras, o archote e a lareira acesa (ADR 0034, Q-190).
func wards(obras: BuildSystem, nucleo_x: float) -> Array[Vector4]:
	var zonas := LightWard.of(obras, ward())
	var r := RulesFactory.rules()
	var lar := hearth.zone(nucleo_x, r.hearth_radius_px, r.hearth_repel_mass, r.hearth_rot_slow)
	if lar.y > lar.x:
		zonas.append(lar)
	return zonas


## Ao crepusculo, a lareira come o preco da noite da bolsa de quem reina (Q-190).
func kindle() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var bolsa := SimLoop.units.carried_coins[r] if r != NENHUM else 0
	var gasto := hearth.kindle(bolsa, RulesFactory.rules().hearth_night_cost)
	if gasto > 0:
		SimLoop.units.carried_coins[r] -= gasto
		EventBus.queue(&"coin_spent", [gasto, LAREIRA])
