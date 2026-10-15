# src/world/animated_beasts.gd — as criaturas da Podridao, animadas quadro a quadro (ADR 0083).
#
# O que cada uma faz no ecra sai do que a simulacao ja diz dela, e de mais nada:
#   · o golpe acompanha o da simulacao (CombatFx.attack_frame), como nas tropas;
#   · quem leva mostra o susto (hit) desde que o golpe chegou;
#   · quem aparece a meio da noite levanta-se do chao (spawn) — as que ja estavam quando
#     o jogo abriu, nao;
#   · o Alado que apanha uma galinha (Thieves) agarra-a (steal) e foge com ela (flee);
#   · quem entra numa luz que a aguenta recua (flee, ADR 0034);
#   · a andar, anda; o Ariete, com uma obra por alvo, investe (charge).
# As accoes do pacote sem nada na simulacao que as chame (o bote, o rugido, o agarrar da
# Consumidora) ficam na folha a espera de quem as chame.
class_name AnimatedBeasts
extends RefCounted

const NENHUM := -1
const ATTACK := &"attack"
const HIT := &"hit"
const SPAWN := &"spawn"
const STEAL := &"steal"
const FLEE := &"flee"
const WALK := &"walk"
const CHARGE := &"charge"
const IDLE := &"idle"

static var _escalas: Dictionary = {}
static var _original := OriginalArt.new()

var _nascidas: Dictionary = {}
var _saques: Dictionary = {}
var _primeiro := true
var _agora := 0.0


static func handles(forma: Silhouette.Form) -> bool:
	return AnimatedArt.CREATURES.has(forma) and AnimatedArt.has(AnimatedArt.CREATURES[forma])


static func id_of(forma: Silhouette.Form) -> StringName:
	return AnimatedArt.CREATURES.get(forma, &"")


## A escala inteira de uma forma: a que mais se aproxima do porte dela no Bestiary (Q-219).
static func scale_of(forma: Silhouette.Form) -> int:
	if not _escalas.has(forma):
		var porte := Bestiary.box(forma, 0.0, int(Band.Kind.SURFACE)).size.y
		_escalas[forma] = AnimatedArt.scale_to(id_of(forma), porte)
	return _escalas[forma]


## A pose de uma forma com os pes em `pe`, virada para `frente` e esticada pelo golpe.
static func pose(
	forma: Silhouette.Form, pe: Vector2, frente: float, estica: Vector2
) -> Transform2D:
	return AnimatedArt.posed(pe, frente, scale_of(forma), estica)


## Quem esta nas colunas neste frame: quem chegou agora levanta-se, e quem apanhou agora
## uma galinha agarra-a. Quem saiu das colunas sai daqui.
func observe(bichos: CreatureSystem, agora: float) -> void:
	_agora = agora
	var vivos := {}
	for i in bichos.count():
		var id := bichos.ids[i]
		vivos[id] = true
		if not _nascidas.has(id):
			_nascidas[id] = -INF if _primeiro else agora
		if bichos.loot_slots[i] == NENHUM:
			_saques.erase(id)
		elif not _saques.has(id):
			_saques[id] = agora
	_primeiro = false
	for registo: Dictionary in [_nascidas, _saques]:
		for id: int in registo.keys():
			if not vivos.has(id):
				registo.erase(id)


## O quadro que a criatura `i` mostra agora (o relogio e o do ultimo observe). `falta` e o
## cooldown de quem esta engajado (StrikePose.NUNCA se nao esta); `desfase` e o dela, para um
## enxame nao mexer as patas todas ao mesmo tempo.
func frame_of(
	forma: Silhouette.Form, bichos: CreatureSystem, i: int, anda: bool, falta: float, desfase: float
) -> int:
	var perfil := id_of(forma)
	var id := bichos.ids[i]
	var golpe := CombatFx.attack_frame(_original, perfil, id, falta)
	if golpe >= 0:
		return golpe
	for accao: StringName in [HIT, SPAWN, STEAL]:
		var desde := _since(accao, id)
		if desde >= 0.0 and desde < AnimatedArt.seconds(perfil, accao):
			return AnimatedArt.frame(perfil, accao, desde)
	return AnimatedArt.frame(perfil, loop_of(forma, bichos, i, anda), _agora + desfase)


## O ciclo de quem nao esta a meio de uma accao: fugir, investir, andar ou estar.
static func loop_of(
	forma: Silhouette.Form, bichos: CreatureSystem, i: int, anda: bool
) -> StringName:
	if bichos.loot_slots[i] != NENHUM or bichos.recoils[i] > 0.0:
		return FLEE
	if not anda:
		return IDLE
	if forma == Silhouette.Form.ARIETE and bichos.target_slots[i] != NENHUM:
		return CHARGE
	return WALK


## A criatura desenhada: o corpo com a tinta, o que brilha no escuro, e o branco do golpe.
static func draw(
	canvas: CanvasItem, forma: Silhouette.Form, quadro: int, posta: Transform2D, look: Dictionary
) -> void:
	var perfil := id_of(forma)
	AnimatedArt.draw(canvas, perfil, quadro, posta, look.tint)
	AnimatedArt.glow(canvas, perfil, quadro, posta, look.glow)
	if float(look.flash) > 0.0:
		AnimatedArt.flat(canvas, perfil, quadro, posta, Color(1.0, 1.0, 1.0, look.flash))


func _since(accao: StringName, id: int) -> float:
	match accao:
		HIT:
			return CombatFx.since_struck(id)
		SPAWN:
			return _agora - float(_nascidas.get(id, -INF))
		STEAL:
			return _agora - float(_saques.get(id, INF))
	return -1.0
