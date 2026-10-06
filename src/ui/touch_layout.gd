# src/ui/touch_layout.gd — onde esta cada controlo de toque no ecra (ADR 0047).
#
# O polegar mora nos cantos de baixo. A esquerda, a zona da alavanca: ela nasce onde o
# polegar pousa. A direita, um arco de botoes a volta do maior, a MOEDA — o Verbo 1 e o
# gesto que acontece milhares de vezes por partida (§24). A pausa fica no canto de
# cima, junto ao relogio e ao objectivo, e nao muda de lado nem de tamanho. O
# CORRER fica no arco, em baixo e para o meio: e do polegar que nao anda.
#
# Tudo e contado a 1280x720, o ecra de base (§67), a partir do canto do lado do
# polegar: o canhoto e o espelho, e o tamanho escala os botoes e o afastamento ao
# canto, que assim nunca se tocam. Os numeros sao tolerancias do gesto, como o
# deadzone do project.godot e o RODA_ZONA do InputRouter — nao sao balanceamento.
class_name TouchLayout
extends RefCounted

enum Role { NONE, STICK, DROP, ATTACK, ASSUME, SKILL, WHEEL, PAUSE, WORLD, FIX, RUN }

const BASE := Vector2(1280.0, 720.0)
## Cada botao: x e y do centro contados do canto de baixo do lado do polegar, e o raio.
## Duas filas compactas deixam o centro livre; o CORRER fica junto ao ATAQUE.
## A corrida dura enquanto o dedo prime, como no teclado (Q-193).
const BOTOES := {
	Role.DROP: Vector3(84.0, 92.0, 52.0),
	Role.ATTACK: Vector3(206.0, 92.0, 44.0),
	Role.ASSUME: Vector3(86.0, 214.0, 42.0),
	Role.SKILL: Vector3(204.0, 204.0, 38.0),
	Role.WHEEL: Vector3(320.0, 198.0, 38.0),
	Role.RUN: Vector3(322.0, 82.0, 38.0),
}
## A pausa: x contado da direita e y de cima, na faixa do cabecalho.
const PAUSA := Vector3(42.0, 40.0, 26.0)
## Quanto o dedo pode errar para fora do desenho e ainda ser o botao.
const FOLGA := 14.0
## A alavanca em repouso (do canto de baixo do lado dela), o raio e a margem ao ecra.
const ALAVANCA := {"x": 136.0, "y": 110.0, "raio": 80.0, "margem": 12.0}
## O FIXAR: por cima da alavanca, do lado dela, contado como ela (UX-03).
const FIXAR := Vector3(136.0, 242.0, 38.0)
## Solta, a alavanca e a metade do ecra do lado do polegar, por baixo do HUD: o polegar
## que pousa um pouco mais acima ou mais ao centro anda, e nao espreita (UX-03).
const ZONA := 0.5
## O tamanho que se escolhe nas opcoes (§45).
const ESCALA := {"min": 0.8, "max": 1.4}
## Quanto a densidade do ecra pode crescer os botoes, por cima do tamanho escolhido: o
## tamanho das opcoes multiplica isto, e por isso conta tambem no telemovel (UX-06).
const TETO := 1.4

## O x livre entre os controlos dos dois lados, em px do canvas, do ultimo frame: por
## ali passam o contexto, os avisos e as legendas no toque, sem tapar um botao (UX-06).
static var span := Vector2.ZERO

var scale: float = 1.0:
	set(valor):
		scale = clampf(valor, ESCALA.min, ESCALA.max * TETO)
var left_handed := false
var screen := BASE
## A escala da interface: o painel de combate cresce num canvas pequeno (Q-186).
var ui_scale := 1.0
## A alavanca fixa no sitio: so o circulo dela anda, e o resto do ecra espreita (UX-03).
var fixed := false


func centre(papel: Role) -> Vector2:
	if papel == Role.PAUSE:
		return Vector2(screen.x - PAUSA.x * ui_scale, PAUSA.y * ui_scale)
	if papel == Role.FIX:
		var x := FIXAR.x * scale
		return Vector2(screen.x - x if left_handed else x, screen.y - FIXAR.y * scale)
	if not BOTOES.has(papel):
		return Vector2.ZERO
	var b: Vector3 = BOTOES[papel]
	return _lado(Vector2(b.x * scale, screen.y - b.y * scale))


func radius(papel: Role) -> float:
	if papel == Role.PAUSE:
		return PAUSA.z * ui_scale
	if papel == Role.FIX:
		return FIXAR.z * scale
	return (BOTOES[papel] as Vector3).z * scale if BOTOES.has(papel) else 0.0


## O raio que o dedo acerta: o desenho e a folga.
func reach(papel: Role) -> float:
	return radius(papel) + FOLGA * (ui_scale if papel == Role.PAUSE else scale)


## Quem e o dedo que pousa em `p`: a pausa, o FIXAR, o botao mais perto (pela fraccao do
## raio, para as folgas de dois botoes nao se roubarem), a alavanca, ou o mundo.
func role_at(p: Vector2) -> Role:
	for toque: Role in [Role.PAUSE, Role.FIX]:
		if p.distance_to(centre(toque)) <= reach(toque):
			return toque
	var melhor := Role.NONE
	var perto := 1.0
	for papel: Role in BOTOES:
		var fraccao := p.distance_to(centre(papel)) / reach(papel)
		if fraccao <= perto:
			melhor = papel
			perto = fraccao
	if melhor != Role.NONE:
		return melhor
	return Role.STICK if in_stick_zone(p) else Role.WORLD


func in_stick_zone(p: Vector2) -> bool:
	if fixed:
		return p.distance_to(stick_home()) <= stick_radius() + FOLGA * scale
	var borda := screen.x * ZONA
	var do_lado := p.x > screen.x - borda if left_handed else p.x < borda
	return do_lado and p.y > GameHud.FAIXA_TOPO * ui_scale


func stick_radius() -> float:
	return ALAVANCA.raio * scale


## Onde a alavanca se desenha quando ninguem lhe toca: ensina onde pousar o polegar.
func stick_home() -> Vector2:
	var x := ALAVANCA.x * scale
	return Vector2(screen.x - x if left_handed else x, screen.y - ALAVANCA.y * scale)


## O x livre entre os botoes, o FIXAR e a alavanca em repouso dos dois lados.
func free_span() -> Vector2:
	var de := 0.0
	var ate := screen.x
	var meio := screen.x * ZONA
	var papeis: Array = [Role.FIX, Role.STICK] + BOTOES.keys()
	for papel: Role in papeis:
		var x := stick_home().x if papel == Role.STICK else centre(papel).x
		var r := stick_radius() + ALAVANCA.margem if papel == Role.STICK else reach(papel)
		if x < meio:
			de = maxf(de, x + r)
		else:
			ate = minf(ate, x - r)
	return Vector2(de, ate)


## A base desenhada para um polegar em `p`: o mais perto dele que cabe no ecra.
func stick_base(p: Vector2) -> Vector2:
	var borda := stick_radius() + ALAVANCA.margem
	return Vector2(clampf(p.x, borda, screen.x - borda), clampf(p.y, borda, screen.y - borda))


## Os botoes ficam do lado do polegar que nao anda: a direita, ou a esquerda no canhoto.
func _lado(p: Vector2) -> Vector2:
	return p if left_handed else Vector2(screen.x - p.x, p.y)
