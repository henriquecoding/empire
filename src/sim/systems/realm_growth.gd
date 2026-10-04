class_name RealmGrowth
extends RefCounted

enum Need { NONE, UNLISTED, WALL, FRONTIER, SUPPLY }

const HALF := 0.5

## Politicas geradas de realm_sites.csv, instaladas pelo RulesFactory.
static var sites: Dictionary = {}
## Estagio da sede -> quantidade de linhas de muralhas, por flanco.
static var wall_rings: Dictionary = {}


## O mundo conserva os slots e os ids; so publica o convite quando faz sentido.
## Obra paga, em curso ou herdada nunca desaparece por uma muralha cair.
static func visible(obras: BuildSystem, vaga: BuildSlot, estado: GameState = null) -> bool:
	if vaga.kind == BuildSlot.NUCLEO or vaga.level > 0 or vaga.paid > 0:
		return true
	if vaga.state != BuildSlot.State.EMPTY:
		return true
	return (
		RealmLadder.allows(obras, vaga)
		and Discoveries.known(estado, vaga.kind)
		and allows(obras, vaga)
	)


static func allows(obras: BuildSystem, vaga: BuildSlot) -> bool:
	return refusal(obras, vaga) == Need.NONE


## A causa que o guia mostra: area defendida, proxima frente ou producao de apoio.
static func refusal(obras: BuildSystem, vaga: BuildSlot) -> Need:
	var sede := RealmLadder.seat(obras)
	if sede == null or vaga.territory > 0 or vaga.kind == BuildSlot.NUCLEO or vaga.level > 0:
		return Need.NONE
	var politica := policy(vaga)
	if politica == null:
		return Need.UNLISTED
	if not supplied(obras, politica.requires_any):
		return Need.SUPPLY
	match politica.placement:
		&"wilderness", &"native":
			return Need.NONE
		&"wall":
			return Need.NONE if next_wall(obras, vaga) else Need.FRONTIER
		&"camp":
			return Need.NONE if _camp_plot(obras, vaga, sede) else Need.WALL
	return Need.NONE if protected(obras, vaga, politica.wall_level) else Need.WALL


static func policy(vaga: BuildSlot) -> RealmSiteData:
	return sites.get(&"wall" if vaga.two_paths() else vaga.kind)


## O edificio inteiro fica atras de uma defesa de pe, do seu lado do nucleo.
## O nucleo, uma torre ou uma defesa de um povo vizinho nao reivindicam territorio.
static func protected(obras: BuildSystem, vaga: BuildSlot, nivel: int = 1) -> bool:
	var sede := RealmLadder.seat(obras)
	if sede == null:
		return true
	for muro in obras.slots:
		if not _wall(muro) or muro.level < nivel or not muro.holds():
			continue
		if (muro.x - sede.x) * (vaga.x - sede.x) <= 0.0:
			continue
		if _inside(muro, vaga, sede):
			return true
	return false


## So o proximo marco de cada lado se oferece; nao se salta o reino inteiro.
static func next_wall(obras: BuildSystem, vaga: BuildSlot) -> bool:
	var sede := RealmLadder.seat(obras)
	if sede == null or vaga.level > 0:
		return true
	if _next(obras, vaga.x, sede.x) != vaga:
		return false
	var ring := 0
	for muro in obras.slots:
		if not _wall(muro) or (muro.x - sede.x) * (vaga.x - sede.x) <= 0.0:
			continue
		if absf(muro.x - sede.x) < absf(vaga.x - sede.x):
			ring += 1
	return ring < int(wall_rings.get(RealmLadder.stage(obras), 0))


static func supplied(obras: BuildSystem, fontes: Array[StringName]) -> bool:
	if fontes.is_empty():
		return true
	for obra in obras.slots:
		if obra.territory == 0 and obra.holds() and fontes.has(obra.kind):
			return true
	return false


static func _wall(vaga: BuildSlot) -> bool:
	return vaga.territory == 0 and vaga.band == Band.Kind.SURFACE and vaga.two_paths()


static func _front(obras: BuildSystem, x: float, centro: float) -> BuildSlot:
	var frente: BuildSlot = null
	for muro in obras.slots:
		if not _wall(muro) or not muro.holds() or (muro.x - centro) * (x - centro) <= 0.0:
			continue
		if frente == null or absf(muro.x - centro) > absf(frente.x - centro):
			frente = muro
	return frente


static func _next(obras: BuildSystem, x: float, centro: float) -> BuildSlot:
	var frente := _front(obras, x, centro)
	var longe := absf(frente.x - centro) if frente != null else 0.0
	var proxima: BuildSlot = null
	for muro in obras.slots:
		if not _wall(muro) or (muro.x - centro) * (x - centro) <= 0.0:
			continue
		var distancia := absf(muro.x - centro)
		if distancia <= longe or muro.holds():
			continue
		if proxima == null or distancia < absf(proxima.x - centro):
			proxima = muro
	return proxima


## As ferramentas fundadoras cabem no traçado da primeira muralha, mesmo por erguer.
## Sem esta excecao nao ha como formar quem levanta a primeira defesa.
static func _camp_plot(obras: BuildSystem, vaga: BuildSlot, sede: BuildSlot) -> bool:
	var primeiro: BuildSlot = null
	for muro in obras.slots:
		if not _wall(muro) or (muro.x - sede.x) * (vaga.x - sede.x) <= 0.0:
			continue
		if primeiro == null or absf(muro.x - sede.x) < absf(primeiro.x - sede.x):
			primeiro = muro
	return primeiro != null and _inside(primeiro, vaga, sede)


static func _inside(muro: BuildSlot, vaga: BuildSlot, sede: BuildSlot) -> bool:
	var limite := absf(muro.x - sede.x) - muro.width * HALF
	return absf(vaga.x - sede.x) + vaga.width * HALF < limite
