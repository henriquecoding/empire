# src/sim/systems/legacy.gd — o que fica quando se perde (§16; Q-088, Q-134).
#
# O §16: "Decay em vez de reset. Segue o Two Crowns, nao o Kingdom original. Ao
# cair, o jogador mantem: Sementes Reais, classes desbloqueadas, mapas revelados,
# segredos encontrados, e 40% das estruturas do imperio principal." Ate aqui o
# botao da derrota recomecava do zero (Q-088).
#
# O legado e um dicionario em tipos base — vai para um ficheiro e volta — com o
# que o jogo novo herda: as Sementes, os segredos achados, as conquistas, o plano
# da campanha, e as obras que ficam. Ficam as mais caras: a fraccao
# `decay_structures_kept` das obras de pe (arredondada), por moedas investidas e,
# no empate, por id. Levantam-se no mesmo sitio, no mesmo degrau e caminho — o
# segmento e o mesmo, e os ids dos sitios tambem (§21, §45).
#
# Puro: recebe o estado e as obras.
class_name Legacy
extends RefCounted

const SEMENTES := &"royal_seeds"
const ACHADOS := &"found"
const CONQUISTAS := &"conquests"
const PLANO := &"chapters"
const OBRAS := &"slots"
const ID := &"id"
const NIVEL := &"level"
const CAMINHO := &"path"


## O que o jogo novo herda desta partida.
static func of(estado: GameState, obras: BuildSystem, fracao: float) -> Dictionary:
	var ficam := []
	for obra in kept(obras, fracao):
		ficam.append({ID: obra.id, NIVEL: obra.level, CAMINHO: int(obra.path)})
	return {
		SEMENTES: estado.royal_seeds,
		ACHADOS: estado.found,
		CONQUISTAS: estado.conquests,
		PLANO: estado.chapters.to_dict(),
		OBRAS: ficam,
	}


## As obras que ficam, das mais caras para as mais baratas.
static func kept(obras: BuildSystem, fracao: float) -> Array[BuildSlot]:
	var de_pe: Array[BuildSlot] = []
	for obra in obras.standing():
		if obra.kind != BuildSlot.NUCLEO and obra.kind != AmargueiroSystem.CORTE and obra.level > 0:
			de_pe.append(obra)
	de_pe.sort_custom(
		func(a: BuildSlot, b: BuildSlot) -> bool:
			var ca := invested(a)
			var cb := invested(b)
			return ca > cb or (ca == cb and a.id < b.id)
	)
	return de_pe.slice(0, roundi(de_pe.size() * clampf(fracao, 0.0, 1.0)))


## As moedas que custaram os degraus que a obra ja tem.
static func invested(obra: BuildSlot) -> int:
	var total := 0
	for k in mini(obra.level, obra.costs.size()):
		total += obra.costs[k]
	return total


## Um jogo novo, ja montado, recebe o legado: o estado e as obras que ficam, de pe
## e inteiras. Um sitio que o mundo novo nao tem ignora-se (§62).
static func apply(d: Dictionary, estado: GameState, obras: BuildSystem) -> void:
	estado.royal_seeds = int(d.get(SEMENTES, estado.royal_seeds))
	estado.found = PackedStringArray(d.get(ACHADOS, estado.found))
	estado.conquests = PackedStringArray(d.get(CONQUISTAS, estado.conquests))
	var plano: Dictionary = d.get(PLANO, {})
	if not plano.is_empty():
		estado.chapters.from_dict(plano)
	for guardada: Dictionary in d.get(OBRAS, []):
		var i := obras.index_of(int(guardada.get(ID, BuildSlot.NENHUM)))
		if i == BuildSlot.NENHUM:
			continue
		var obra := obras.slots[i]
		obra.path = int(guardada.get(CAMINHO, int(obra.path))) as BuildSlot.Path
		obra.level = mini(int(guardada.get(NIVEL, 1)), obra.costs.size())
		obra.state = BuildSlot.State.DONE
		obra.progress = 0.0
		obra.paid = 0
		obra.health = obra.max_health()
