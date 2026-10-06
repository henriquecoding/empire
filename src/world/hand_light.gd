# src/world/hand_light.gd — a tocha na mao de quem se conduz, quando ha pouca luz (UX-07).
#
# O dono, 06/10/2026: "na alvorada e nos momentos de pouca iluminacao os imperadores
# carregam tochas ou algo luminoso na mao para nao ficar tao escuro o jogo". E so luz e
# desenho: nao e o archote do Q-029, que se compra, arde `torch_burn_s` e afasta as
# emboscadas do escuro. Esta nao se gasta, nao conta para o `Torchlight.in_dark` e da
# menos luz do que ele, para nao se confundir com a protecao; quando o archote arde, e
# ele que se ve.
class_name HandLight
extends RefCounted

## A partir de que escuro (Lighting.dark, 0 ao meio-dia e 1 na noite funda) se acende:
## o principio da alvorada, o fim da tarde, o crepusculo e a noite. A manha e o
## meio-dia nao chegam la.
const ACESA := 0.15
## A luz dela, em fraccoes do archote: o raio do torch_radius_px, e a forca das paragens.
const LUZ := {"raio": 0.7, "forca": 0.4}
## A chama, mais pequena do que a do archote (0,55 no BandView).
const CHAMA := 0.5
## A mao, em fraccoes da caixa do corpo: quanto para a frente, e a que altura do topo.
const MAO := Vector2(0.34, 0.5)
## O cabo: quanto sobe da mao, quanto se inclina para a frente e a grossura.
const CABO := Vector3(16.0, 5.0, 2.0)
const MADEIRA := Color("6b4a2c")
## Sem perfil de arte, a caixa de uma tropa do greybox.
const CAIXA := Vector2(24.0, 48.0)
const HALF := 0.5

static var _clock: ClockData
static var _lado := {"x": NAN, "lado": 1.0}
static var _art := OriginalArt.new()


## O escuro que o olho ve agora, pela hora do relogio.
static func dark_now() -> float:
	if ClockService.clock == null:
		return 0.0
	if _clock == null:
		_clock = Registry.entry(&"economy", &"clock") as ClockData
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	return Lighting.darkness(_clock, BandLight.seen(_clock, fase, relogio.phase_progress()))


## Se a tocha da mao arde: ha pouca luz, e o archote comprado nao esta aceso.
static func carried(dark: float, torch_lit: bool) -> bool:
	return not torch_lit and dark >= ACESA


## A ponta da tocha de quem se conduz, no indice `rei` das unidades.
static func tip(rei: int) -> Vector2:
	var units := SimLoop.units
	var foot := Vector2(units.xs[rei], WorldPalette.ground_of(units.bands[rei]))
	var perfil := OriginalArt.unit_profile(units.data_ids[rei])
	var corpo := Rect2(foot - Vector2(CAIXA.x * HALF, CAIXA.y), CAIXA)
	if perfil != &"":
		corpo = _art.body_box(perfil, foot)
	var lado := facing(units.xs[rei])
	var mao := Vector2(
		corpo.get_center().x + lado * corpo.size.x * MAO.x,
		corpo.position.y + corpo.size.y * MAO.y
	)
	return mao + Vector2(lado * CABO.y, -CABO.x)


## Para onde olha quem se conduz: para onde andou da ultima vez.
static func facing(x: float) -> float:
	if not is_nan(_lado.x) and not is_equal_approx(x, _lado.x):
		_lado.lado = signf(x - _lado.x)
	_lado.x = x
	return _lado.lado


## O cabo e a chama, num canvas sem luz: a chama e ela a luz (§80).
static func draw_on(
	canvas: CanvasItem, ponta: Vector2, cores: PackedColorArray, tempo: float
) -> void:
	var lado := float(_lado.lado)
	var mao := ponta - Vector2(lado * CABO.y, -CABO.x)
	canvas.draw_line(mao, ponta, MADEIRA, CABO.z)
	FlameArt.draw_on(canvas, ponta, CHAMA, cores, tempo)
