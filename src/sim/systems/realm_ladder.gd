# src/sim/systems/realm_ladder.gd — a escada da sede, e o que cada estagio abre (ADR 0059).
#
# O dono, a 03/10/2026, sobre o plano do reino: *«aplique esse relatorio»*. O reino
# deixa de nascer castelo: o monarca chega a uma Clareira, paga a fundacao e a sede
# sobe por estagios — Acampamento, Povoado, Vila, Vila Fortificada, Fortaleza. O
# estagio e o nivel do nucleo, pago e levantado como os degraus de um muro (§55); aqui
# fica so a pergunta que as outras obras fazem: o estagio de agora ja as deixa pagar?
#
# Uma obra que nenhum estagio lista fica fechada. O muro abre por nivel: a
# estacaria no Acampamento, a palicada no Povoado, e assim por diante. O estagio
# soma-se ao resto do que um degrau pede — a estatua, a conquista, o Lenho —, nao o
# substitui (plano §17.1).
#
# Puro. Quem escreve os mapas e o RulesFactory, a partir de realm_stages.csv.
class_name RealmLadder
extends RefCounted

const NENHUM := -1
## O nucleo por fundar: o nivel 0 do nucleo.
const CLAREIRA := 0
## O Acampamento: a primeira sede fundada.
const FUNDADO := 1

## obra ou nivel de muro (o id do walls.csv) -> o estagio que a abre.
static var gates: Dictionary = {}
## O id do walls.csv de cada nivel do muro, pela ordem: o degrau seguinte le-se aqui.
static var wall_levels: PackedStringArray = PackedStringArray()


## O estagio da sede: o nivel do nucleo. NENHUM numa regiao sem nucleo — uma regiao de
## teste —, onde nada se fecha.
static func stage(obras: BuildSystem) -> int:
	var nucleo := seat(obras)
	return nucleo.level if nucleo != null else NENHUM


## O nucleo desta regiao, ou null.
static func seat(obras: BuildSystem) -> BuildSlot:
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga
	return null


## Se o reino ja foi fundado. Uma regiao sem nucleo conta como fundada.
static func founded(obras: BuildSystem) -> bool:
	return stage(obras) != CLAREIRA


## O estagio que o degrau seguinte desta obra pede. O proprio nucleo nao pede nenhum:
## e ele a escada.
static func required(vaga: BuildSlot) -> int:
	if vaga.kind == BuildSlot.NUCLEO:
		return CLAREIRA
	var chave := vaga.kind
	if vaga.two_paths() and vaga.level < wall_levels.size():
		chave = StringName(wall_levels[vaga.level])
	return int(gates.get(chave, NENHUM))


## Se o degrau seguinte desta obra ja se pode pagar com a sede no estagio de agora.
static func allows(obras: BuildSystem, vaga: BuildSlot) -> bool:
	var agora := stage(obras)
	if agora == NENHUM or vaga.territory > 0:
		return true
	var precisa := required(vaga)
	return precisa != NENHUM and agora >= precisa
