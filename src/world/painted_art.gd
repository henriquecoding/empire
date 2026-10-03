# src/world/painted_art.gd — as obras que nao tem arte do dono, pintadas (§22, ADR 0051).
#
# O dono, a 02/10/2026: "faca as casas e construcoes terem de fato sprites, agora estao
# todas invisiveis". So o castelo-arvore, a casa de treino, a oficina e o armazem tinham
# arte; o resto era um poligono liso, e o sitio por construir um contorno a 18%.
#
# Cada obra que sobra tem aqui um sprite, pintado uma vez pelo PixelPainter e guardado
# como textura. A interface e a do OriginalArt — box, texture, draw_on —, e por isso o
# BuildingSkins desenha uns e outros da mesma maneira, em todos os pontos do SiteStage.
# A paleta e a da arte do dono: o dia em que ele desenhar uma destas, troca-se a linha
# no BuildingSkins e o sprite pintado sai de uso.
class_name PaintedArt
extends RefCounted

const PALETA := {
	"ink": Color("0b0b0b"),
	"plaster": Color("f1e8cd"),
	"plaster_shade": Color("d6c9a4"),
	"timber": Color("825c2e"),
	"timber_dark": Color("4f2e10"),
	"timber_light": Color("a87a42"),
	"log": Color("8a5d2e"),
	"log_light": Color("b07c43"),
	"log_end": Color("d9a866"),
	"roof": Color("0f8aac"),
	"roof_light": Color("64cbe8"),
	"roof_dark": Color("0c4150"),
	"stone": Color("ece2c6"),
	"stone_shade": Color("c7bc9c"),
	"mortar": Color("958c6e"),
	"grey": Color("a19d9e"),
	"grey_dark": Color("4c4849"),
	"iron": Color("565b63"),
	"iron_light": Color("8c939b"),
	"opening": Color("0f1110"),
	"glass": Color("0f8aac"),
	"glass_light": Color("64cbe8"),
	"soil": Color("6b4a2f"),
	"soil_dark": Color("463020"),
	"crop": Color("8aa84a"),
	"wheat": Color("d9b65a"),
	"wheat_dark": Color("a8842f"),
	"water": Color("2f6f80"),
	"water_light": Color("6fb5c0"),
	"hen": Color("f4efe2"),
	"comb": Color("c23a2a"),
	"beak": Color("e0a030"),
	"banner": Color("a83a2e"),
	"gold": Color("e3b341"),
	"straw": Color("d6b86a"),
	"straw_dark": Color("a8893f"),
	"rope": Color("b89a6a"),
	"bell": Color("c9a24a"),
	"bell_dark": Color("7d5f22"),
	"fire": Color("f0a030"),
	"ember": Color("c0501e"),
	"ore": Color("b8794a"),
	"root": Color("4a3524"),
	"leaf": Color("5f7d36"),
}

## As obras de buildings.csv com sprite proprio; as outras vao pela forma (BuildingSkins).
const OBRAS := {
	&"archer_tower": &"archer_tower",
	&"high_tower": &"high_tower",
	&"farm": &"farm",
	&"henhouse": &"henhouse",
	&"fishery": &"fishery",
	&"heir_house": &"manor",
	&"embassy": &"manor",
	&"citizen_house": &"cottage",
	&"tender_ward": &"bell",
	&"bow_rack": &"bow_rack",
	&"mount_stable": &"stable",
	&"cow_stable": &"stable",
	&"lumber_camp": &"lumber",
	&"sawmill": &"lumber",
	&"smelter": &"furnace",
	&"ore_pit": &"mine",
	&"passage_seal": &"seal",
	&"fire_barrel": &"barrel",
	&"root_moat": &"spikes",
	&"consecrated_altar": &"altar",
	&"root_sanctuary": &"altar",
}
## O muro tem um sprite por nivel do §10: estacaria, palicada, pedra, ferro e bastiao.
const MURO := "wall_%d"
const MEIO := 0.5

static var _definicoes: Dictionary = {}
static var _texturas: Dictionary = {}


## O sprite pintado de uma obra, ou vazio se ela nao tem um. `nivel` so conta no muro.
static func profile(vaga: BuildSlot, nivel: int) -> StringName:
	if vaga.two_paths():
		return StringName(MURO % clampi(nivel, 1, WallSprites.NIVEIS))
	if OBRAS.has(vaga.kind):
		return OBRAS[vaga.kind]
	var nativa := NativeSprites.profile(vaga.kind)
	return nativa if has(nativa) else &""


static func has(id: StringName) -> bool:
	return _todas().has(id)


## A imagem, pintada agora: e o que os testes leem, sem precisar de ecra.
static func image(id: StringName) -> Image:
	var d: Dictionary = _todas()[id]
	var paleta: Dictionary = PALETA.merged(d.get("palette", {}), true)
	return PixelPainter.paint(d.size, d.strokes, paleta)


static func texture(id: StringName) -> Texture2D:
	if not _texturas.has(id):
		_texturas[id] = ImageTexture.create_from_image(image(id))
	return _texturas[id]


func box(id: StringName, foot: Vector2) -> Rect2:
	var tamanho := Vector2(_todas()[id].size)
	return Rect2(foot - Vector2(floorf(tamanho.x * MEIO), tamanho.y), tamanho)


func draw_on(canvas: CanvasItem, id: StringName, foot: Vector2, tint: Color) -> void:
	canvas.draw_texture_rect(texture(id), box(id, foot.floor()), false, tint)


static func _todas() -> Dictionary:
	if _definicoes.is_empty():
		for fonte: Dictionary in [
			WallSprites.all(), TowerSprites.all(), FarmSprites.all(), HouseSprites.all()
		]:
			_definicoes.merge(fonte)
		_definicoes.merge(NativeSprites.all())
		_definicoes.merge(SeatSprites.all())  # a sede por estagio e a carroca (ADR 0059)
	return _definicoes
