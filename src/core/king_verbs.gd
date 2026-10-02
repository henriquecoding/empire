# src/core/king_verbs.gd — o Verbo 2 que so o rei tem (§08: "so o rei gere"): o escudeiro,
# a casa de conversao e a escolha A/B de uma muralha ou de uma melhoria (Q-114, Q-115,
# Q-136). Tirado do Verbs, que chegou as 250 linhas do §28 com a troca de classe.
class_name KingVerbs
extends RefCounted

const HALF := 0.5


## A gestao do Verbo 2 onde o rei esta: a casa de conversao, e a muralha ou a
## melhoria. Verdadeiro se alguma pegou.
static func place(units: UnitSystem, king: int, builds: BuildSystem, campo: FieldWork) -> bool:
	return choose_mode(units, king, builds, campo) or choose_wall(units, king, builds)


## "O rei pode dar 5 moedas ao escudeiro" (Q-114): o Verbo 2 sem mais nada onde
## pegar da-lhe uma moeda do saco, se ele esta ao pe e o escudo ainda a aceita.
static func arm_squire(units: UnitSystem, king: int, campo: FieldWork) -> bool:
	if campo == null or not squire_wants(units, king, campo.classes):
		return false
	units.carried_coins[units.index_of(king)] -= 1
	campo.classes.squire.arm(1)
	EventBus.queue(&"coin_spent", [1, &"squire"])
	return true


## Se o escudeiro, ao pe do rei, aceita uma moeda que o rei tem para dar.
static func squire_wants(units: UnitSystem, king: int, classes: ClassSystem) -> bool:
	var e := classes.squire_index(units, king)
	var i := units.index_of(king)
	if e == UnitSystem.NENHUM or i == UnitSystem.NENHUM or units.carried_coins[i] <= 0:
		return false
	var perto := classes.squire.escort_px() + SimFactory.curve().coin_pickup_px
	return classes.squire.coins_wanted() > 0 and absf(units.xs[e] - units.xs[i]) <= perto


## O Verbo 2 numa casa de conversao de pe: escolhe o outro modo (Q-115).
static func choose_mode(
	units: UnitSystem, king: int, builds: BuildSystem, campo: FieldWork
) -> bool:
	var i := units.index_of(king)
	if builds == null or campo == null or i < 0 or not units.alive(i):
		return false
	for slot in builds.slots:
		if slot.band != units.bands[i] or absf(slot.x - units.xs[i]) > slot.width * HALF:
			continue
		if campo.conversion.craft_of(slot) != null and slot.standing():
			return campo.conversion.choose(slot)
	return false


## A escolha A/B do §10, antes de pagar o segundo degrau; E partilha o Verbo 2. E
## a variante de uma melhoria (P-N, Q-136), antes da primeira moeda.
static func choose_wall(units: UnitSystem, king: int, builds: BuildSystem) -> bool:
	var i := units.index_of(king)
	if builds == null or i < 0 or not units.alive(i):
		return false
	for slot in builds.slots:
		if slot.band != units.bands[i] or absf(slot.x - units.xs[i]) > slot.width * HALF:
			continue
		if SlotVariant.choose(slot):
			return true
		if not wall_choice_open(slot):
			continue
		var path := (
			BuildSlot.Path.GUARNICAO
			if slot.path == BuildSlot.Path.FORTIFICACAO
			else BuildSlot.Path.FORTIFICACAO
		)
		return slot.choose_path(path)
	return false


## Se a escolha A/B ainda se faz nesta obra. O painel de contexto pergunta isto
## mesmo, para nunca anunciar um gesto que o verbo depois recusa.
static func wall_choice_open(slot: BuildSlot) -> bool:
	if not slot.two_paths() or slot.level > 1 or slot.paid > 0:
		return false
	return slot.state in [BuildSlot.State.EMPTY, BuildSlot.State.DONE]
