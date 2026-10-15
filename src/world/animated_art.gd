# src/world/animated_art.gd — os bichos e as criaturas animados do dono, a 64x64 (ADR 0083).
#
# O dono, a 15/10/2026: «Implemente isso no meu jogo», com os dois pacotes de 14/10 — doze
# especies de animais e oito criaturas da Podridao, cada uma com as suas accoes quadro a
# quadro. O tools/export_animated.py confere-os e escreve art/export/animated/ com um
# manifesto da forma que o OriginalArt le: as poses do golpe (CombatFx), a morte com pele
# (DeathBurst) e a mascara branca do flash servem a arte nova sem mudar.
#
# Os desenhos olham para a direita e espelham-se em volta dos pes. A escala e sempre
# inteira, para o pixel ficar pixel: as criaturas a que mais se aproxima do porte do
# Bestiary (Q-219), os animais a uma so, para guardarem entre eles as proporcoes que o
# pacote lhes deu (Q-264). Sem manifesto, quem desenha volta ao que desenhava antes.
class_name AnimatedArt
extends RefCounted

const ROOT := "res://art/export/animated/"
const MILISSEGUNDOS := 1000.0
## A escala dos animais que andam pelo mundo, a caca e o cavalo que a segue: e o
## sprite_scale da caca com arte no wildlife.csv (Q-218; o animated_art_test guarda que
## coincidem), a mesma para todos, para guardarem as proporcoes do pacote entre eles.
const ANIMAL_SCALE := 2
## As galinhas e as vacas ficam a escala da obra onde vivem: a 1:1, um pixel da arte e um
## pixel do mundo, como as personagens (ASSET_BIBLE); a 2x, a galinha ficava da altura do
## galinheiro (Q-264).
const FARM_SCALE := 1
const IDLE := &"idle"
const PREFIXOS := ["beast_", "animal_"]
const CREATURES := {
	Silhouette.Form.RASTEJO: &"beast_crawler",
	Silhouette.Form.ASA: &"beast_winged",
	Silhouette.Form.BRUTO: &"beast_brute",
	Silhouette.Form.BROCA: &"beast_burrower",
	Silhouette.Form.ARIETE: &"beast_slime_ram",
	Silhouette.Form.COLOSSO: &"beast_devourer",
	Silhouette.Form.ZELADOR: &"beast_tender",
}
## A caca do wildlife.csv com arte. O pavao do dono toma o lugar do faisao (o dono, 15/10/2026):
## o id `pheasant` fica, porque as tocas gravadas guardam a especie por ele.
const WILDLIFE := {
	&"rabbit": &"animal_rabbit",
	&"pheasant": &"animal_peacock",
	&"fox": &"animal_fox",
	&"deer": &"animal_deer",
	&"white_stag": &"animal_white_stag",
	&"boar": &"animal_boar",
}
## A montaria do mounts.csv com arte.
const MOUNTS := {&"draft_horse": &"animal_draft_horse"}
## Quem vive a porta de cada obra do buildings.csv (§06: as galinhas ca fora, as vacas vivas).
const FARM := {
	&"henhouse": [&"animal_hen", &"animal_rooster"],
	&"cow_stable": [&"animal_cow", &"animal_cow"],
}

static var _assets: Dictionary = {}
static var _lido := false
static var _art := OriginalArt.new()


## A entrada do manifesto de `id`, ou vazia: so os ids desta arte, e so com o export.
static func entry(id: StringName) -> Dictionary:
	if not _desta(id):
		return {}
	if not _lido:
		_lido = true
		var texto := FileAccess.get_file_as_string(ROOT + "manifest.json")
		var manifesto: Variant = JSON.parse_string(texto) if not texto.is_empty() else null
		if manifesto is Dictionary:
			_assets = manifesto.get("assets", {})
	return _assets.get(String(id), {})


static func has(id: StringName) -> bool:
	return not entry(id).is_empty()


static func has_action(id: StringName, action: StringName) -> bool:
	return entry(id).get("tags", {}).has(String(action))


## O corpo de `id` em repouso, a escala 1, com os pes em (0, 0).
static func body(id: StringName) -> Rect2:
	var b: Array = entry(id).get("body_bounds", [0, 0, 0, 0])
	return Rect2(b[0], b[1], b[2], b[OriginalArt.BODY_HEIGHT_INDEX])


## A escala inteira que poe `id` mais perto de `altura` px de mundo; nunca menos de 1.
static func scale_to(id: StringName, altura: float) -> int:
	var alto := body(id).size.y
	return maxi(1, roundi(altura / alto)) if alto > 0.0 else 1


## Quanto dura `action` de `id`, em segundos, ao ritmo dela (um alias pode ser mais rapido).
static func seconds(id: StringName, action: StringName) -> float:
	var item := entry(id)
	var tag: Dictionary = item.get("tags", {}).get(String(action), {})
	if tag.is_empty():
		return 0.0
	var total := 0.0
	for k in range(int(tag.from_frame), int(tag.to_frame) + 1):
		total += float(item.durations_ms[k])
	return total / MILISSEGUNDOS / float(tag.get("speed", 1.0))


## O quadro de `action` ao fim de `tempo` segundos dela. Sem essa accao, o repouso; uma
## accao que nao se repete fica no ultimo quadro.
static func frame(id: StringName, action: StringName, tempo: float) -> int:
	var item := entry(id)
	var tags: Dictionary = item.get("tags", {})
	var tag: Dictionary = tags.get(String(action), tags.get(String(IDLE), {}))
	if tag.is_empty():
		return 0
	var ms := tempo * MILISSEGUNDOS * float(tag.get("speed", 1.0))
	return OriginalArt.frame_in(
		item.durations_ms, int(tag.from_frame), int(tag.to_frame), ms, bool(tag.get("loop", true))
	)


## A pose de um corpo de `id` com os pes em `pe`, virado e a `escala` inteira; `estica`
## e o aperto do golpe (CombatFx), que volta sempre a 1.
static func posed(
	pe: Vector2, frente: float, escala: int, estica: Vector2 = Vector2.ONE
) -> Transform2D:
	return OriginalArt.posed(pe, frente, estica * float(escala))


## A caixa do corpo desenhado com essa pose: a da vida, da sombra e da morte.
static func box(id: StringName, pose: Transform2D) -> Rect2:
	var b := body(id)
	var a := pose * b.position
	var c := pose * b.end
	return Rect2(Vector2(minf(a.x, c.x), minf(a.y, c.y)), (c - a).abs())


static func draw(
	canvas: CanvasItem, id: StringName, quadro: int, pose: Transform2D, tint: Color
) -> void:
	_art.draw_posed(canvas, id, tint, quadro, pose)


## Os mesmos pixeis, numa cor so (o branco do golpe, a silhueta da noite).
static func flat(
	canvas: CanvasItem, id: StringName, quadro: int, pose: Transform2D, cor: Color
) -> void:
	_art.mask_posed(canvas, id, cor, quadro, pose)


## O que se ve no escuro: os olhos e os dentes das criaturas (a cor mais clara da paleta).
static func glow(
	canvas: CanvasItem, id: StringName, quadro: int, pose: Transform2D, cor: Color
) -> void:
	if entry(id).has("eyes_texture"):
		_art.mask_posed(canvas, id, cor, quadro, pose, "eyes_texture")


## Um bicho com a luz que lhe chega, como os sprites das tropas (SpriteLighting, §80):
## perto da luz a cor dele, longe a silhueta quente, e no meio as duas.
static func lit(
	canvas: CanvasItem, id: StringName, quadro: int, pose: Transform2D, luz: Lighting, x: float
) -> void:
	var perto := clampf(maxf(luz.ambient.v, luz.reach(x)), 0.0, 1.0)
	if perto < 1.0:
		flat(canvas, id, quadro, pose, WorldPalette.SILHUETA)
	if perto > 0.0:
		var cor := luz.on(x)
		cor.a = perto
		draw(canvas, id, quadro, pose, cor)


static func _desta(id: StringName) -> bool:
	var nome := String(id)
	for prefixo: String in PREFIXOS:
		if nome.begins_with(prefixo):
			return true
	return false
