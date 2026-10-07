# src/world/resume.gd — retomar a partida pelo save mais novo que se abre (§62, BUG-03).
#
# Havia tres slots, e so se tentava o de sequencia maior: se esse viesse sem mundo, a
# retoma desistia e comecava um jogo novo com um save velho bom no disco. Agora tentam-se
# todos, do mais novo para o mais velho. Um save estragado salta-se e fica no disco, para
# quem o quiser ver; uma partida acabada — a derrota ou a travessia — nao: e a regra do
# jogo, e um save mais velho nao a desfaz.
class_name Resume
extends RefCounted

enum Outcome { RESUMED, ENDED, BROKEN }

## Se a ultima retoma usou um save mais velho do que o mais novo.
static var recovered := false


## Abre o save mais novo que der. Verdadeiro se ha partida a continuar.
static func latest() -> bool:
	recovered = false
	var lista := SaveService.by_recency()
	for slot in lista:
		match open(slot):
			Outcome.RESUMED:
				recovered = slot != lista[0] or _unreadable(lista)
				if recovered:
					push_warning("save: havia um save estragado; retomado o slot %d" % slot)
				return true
			Outcome.ENDED:
				return false
	return false


## Poe a partida do slot no SimLoop e diz o que ela e.
static func open(slot: int) -> Outcome:
	if not SaveService.playable(slot):
		return Outcome.BROKEN
	var estado := SaveService.restore(slot)
	if estado == null:
		return Outcome.BROKEN
	SimLoop.resume(estado, SaveService.restore_rng(slot))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(slot))
	if Defeat.happened() or SimLoop.state.crossed:
		return Outcome.ENDED
	return Outcome.RESUMED if SimLoop.units.count() > 0 else Outcome.BROKEN


## Um slot com ficheiro que nem a moldura deixa ler: o by_recency() ja o deixou de fora,
## e por isso nao se sabe a sequencia dele — mas houve um save que se perdeu, e diz-se.
static func _unreadable(lista: Array[int]) -> bool:
	for slot in SaveService.SLOTS:
		if SaveService.has_slot(slot) and not lista.has(slot):
			return true
	return false
