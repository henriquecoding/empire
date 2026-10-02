# src/ui/touch_layout.gd — onde esta cada controlo de toque no ecra (ADR 0047).
#
# O polegar mora nos cantos de baixo. A esquerda, a zona da alavanca: ela nasce onde o
# polegar pousa. A direita, um arco de botoes a volta do maior, a MOEDA — o Verbo 1 e o
# gesto que acontece milhares de vezes por partida (§24). A pausa fica no canto de
# cima, por baixo do painel de combate (Q-186), e nao muda de lado nem de tamanho.
#
# Tudo e contado a 1280x720, o ecra de base (§67), a partir do canto do lado do
# polegar: o canhoto e o espelho, e o tamanho escala os botoes e o afastamento ao
# canto, que assim nunca se tocam. Os numeros sao tolerancias do gesto, como o
# deadzone do project.godot e o RODA_ZONA do InputRouter — nao sao balanceamento.
class_name TouchLayout
extends RefCounted

enum Role { NONE, STICK, DROP, ATTACK, ASSUME, SKILL, WHEEL, PAUSE, WORLD }

const BASE := Vector2(1280.0, 720.0)
## Cada botao: x e y do centro contados do canto de baixo do lado do polegar, e o raio.
## A MOEDA e o centro do arco; ATAQUE, INTERAGIR e a habilidade estao a 150 px dela, a
## esquerda, a diagonal e em cima; a roda, que se usa uma vez por dia, mais longe.
const BOTOES := {
	Role.DROP: Vector3(130.0, 130.0, 62.0),
	Role.ATTACK: Vector3(280.0, 130.0, 52.0),
	Role.ASSUME: Vector3(236.0, 236.0, 44.0),
	Role.SKILL: Vector3(130.0, 280.0, 42.0),
	Role.WHEEL: Vector3(393.0, 226.0, 40.0),
}
## A pausa: x contado da direita e y de cima. Por baixo do painel de combate.
const PAUSA := Vector3(58.0, 196.0, 32.0)
## Quanto o dedo pode errar para fora do desenho e ainda ser o botao.
const FOLGA := 14.0
const ENTRE_PAINEL := 18.0
## A alavanca em repouso (do canto de baixo do lado dela), o raio e a margem ao ecra.
const ALAVANCA := {"x": 190.0, "y": 140.0, "raio": 96.0, "margem": 12.0}
## A zona onde o polegar pousa para andar: a fraccao da largura do lado dele, e de onde
## para baixo. Acima e o mundo: o ceu, o castelo, os bichos.
const ZONA := {"largura": 0.42, "topo": 0.40}
## O tamanho que se escolhe nas opcoes (§45).
const ESCALA := {"min": 0.8, "max": 1.4}

var scale: float = 1.0:
	set(valor):
		scale = clampf(valor, ESCALA.min, ESCALA.max)
var left_handed := false
var screen := BASE
## A escala da interface: o painel de combate cresce num canvas pequeno (Q-186).
var ui_scale := 1.0


func centre(papel: Role) -> Vector2:
	if papel == Role.PAUSE:
		var painel := CombatBar.place(screen, ui_scale)
		var y := maxf(PAUSA.y, painel.end.y + ENTRE_PAINEL + PAUSA.z)
		return Vector2(screen.x - PAUSA.x, y)
	if not BOTOES.has(papel):
		return Vector2.ZERO
	var b: Vector3 = BOTOES[papel]
	return _lado(Vector2(b.x * scale, screen.y - b.y * scale))


func radius(papel: Role) -> float:
	if papel == Role.PAUSE:
		return PAUSA.z
	return (BOTOES[papel] as Vector3).z * scale if BOTOES.has(papel) else 0.0


## O raio que o dedo acerta: o desenho e a folga.
func reach(papel: Role) -> float:
	return radius(papel) + FOLGA * (1.0 if papel == Role.PAUSE else scale)


## Quem e o dedo que pousa em `p`: a pausa, o botao mais perto (pela fraccao do raio,
## para as folgas de dois botoes nao se roubarem), a zona da alavanca, ou o mundo.
func role_at(p: Vector2) -> Role:
	if p.distance_to(centre(Role.PAUSE)) <= reach(Role.PAUSE):
		return Role.PAUSE
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
	var borda := screen.x * ZONA.largura
	var do_lado := p.x > screen.x - borda if left_handed else p.x < borda
	return do_lado and p.y > screen.y * ZONA.topo


func stick_radius() -> float:
	return ALAVANCA.raio * scale


## Onde a alavanca se desenha quando ninguem lhe toca: ensina onde pousar o polegar.
func stick_home() -> Vector2:
	var x := ALAVANCA.x * scale
	return Vector2(screen.x - x if left_handed else x, screen.y - ALAVANCA.y * scale)


## A base desenhada para um polegar em `p`: o mais perto dele que cabe no ecra.
func stick_base(p: Vector2) -> Vector2:
	var borda := stick_radius() + ALAVANCA.margem
	return Vector2(clampf(p.x, borda, screen.x - borda), clampf(p.y, borda, screen.y - borda))


## Os botoes ficam do lado do polegar que nao anda: a direita, ou a esquerda no canhoto.
func _lado(p: Vector2) -> Vector2:
	return p if left_handed else Vector2(screen.x - p.x, p.y)
