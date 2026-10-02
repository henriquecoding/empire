# src/world/sprites_native.gd — as casas dos povos do mundo continuo (§21, ADR 0051).
#
# Cada povo tem a cor dele e o telhado dele, que sao o que se le de longe numa terra que
# nao e a tua: o telhado em dente dos Enramados, o de chamine da Fornalha, o achatado da
# Fenda. A casa, a obra e a defesa sao a mesma casa terrea; a obra leva caixotes e um
# toldo, a defesa estacas a frente e o escudo por cima da porta. A paleta sai da cor do
# povo, e o resto e o da arte do dono. Tracos do PixelPainter, com a origem nos pes.
class_name NativeSprites
extends RefCounted

const COLORS := {
	&"enramados": Color("91744c"),
	&"portuarios": Color("7597a1"),
	&"fenda": Color("bd9178"),
	&"horta": Color("b39b52"),
	&"fornalha": Color("755865"),
	&"sobraiz": Color("a286ac"),
	&"geada": Color("b8d6de"),
	&"bruma": Color("758657"),
	&"mercenary": Color("9b6c53"),
}
const ROOFS := {
	&"enramados": [-44, -48, -20, -82, 0, -70, 20, -82, 44, -48],
	&"portuarios": [-48, -46, 0, -62, 48, -46],
	&"fenda": [-40, -50, -40, -62, 40, -62, 40, -50],
	&"horta": [-46, -48, 0, -78, 46, -48],
	&"fornalha": [-42, -48, -22, -64, -22, -90, -8, -90, -8, -64, 42, -48],
	&"sobraiz": [-46, -48, -30, -68, 0, -78, 30, -68, 46, -48],
	&"geada": [-46, -48, -28, -76, 0, -86, 28, -76, 46, -48],
	&"bruma": [-44, -48, 0, -94, 44, -48],
	&"mercenary": [-44, -48, 0, -76, 44, -48],
}
const TIPOS := [&"house", &"work", &"defense"]
const NATIVA := "native_%s_%s"
## Da cor do povo: o reboco mais claro, e o telhado em tres tons.
const TONS := {"plaster": 0.6, "plaster_shade": 0.35, "roof": 0.15, "roof_dark": 0.5}
const TOM_CLARO := 0.3
const TAMANHO := Vector2i(96, 96)

const HOUSE := [
	["o", -38, -4, 76, 4, "stone_shade"],
	["o", -36, -50, 72, 47, "plaster"],
	["r", -35, -49, 70, 3, "plaster_shade"],
	["a", -8, -30, 16, 27, "timber_dark"],
	["a", -6, -28, 12, 25, "timber"],
	["o", 14, -40, 14, 12, "timber_dark"],
	["r", 16, -38, 10, 8, "glass"],
	["r", 20, -38, 2, 8, "timber_dark"],
	["o", -28, -40, 14, 12, "timber_dark"],
	["r", -26, -38, 10, 8, "glass"],
	["r", -22, -38, 2, 8, "timber_dark"],
]
const WORK := [
	["o", -47, -12, 12, 12, "timber"],
	["l", -46, -11, -36, -1, "timber_dark"],
	["o", -44, -22, 9, 10, "timber_light"],
	["p", [36, -40, 47, -30, 47, -27, 36, -33], "roof_light"],
	["r", 45, -27, 2, 27, "timber_dark"],
]
const DEFENSE := [
	["p", [-5, -48, 5, -48, 5, -40, 0, -36, -5, -40], "banner"],
	["r", -1, -46, 2, 7, "gold"],
	["p", [-46, 0, -46, -18, -43, -23, -40, -18, -40, 0], "log"],
	["p", [-38, 0, -38, -20, -35, -25, -32, -20, -32, 0], "log"],
	["p", [32, 0, 32, -20, 35, -25, 38, -20, 38, 0], "log"],
	["p", [40, 0, 40, -18, 43, -23, 46, -18, 46, 0], "log"],
]


## O sprite de uma obra de um povo, ou vazio se a obra nao e de nenhum.
static func profile(kind: StringName) -> StringName:
	var nome := String(kind)
	for tipo: StringName in TIPOS:
		var fim := "_" + String(tipo)
		if nome.ends_with(fim):
			var povo := StringName(nome.trim_suffix(fim))
			if COLORS.has(povo):
				return StringName(NATIVA % [povo, tipo])
	return &""


static func all() -> Dictionary:
	var todas := {}
	for povo: StringName in COLORS:
		var paleta := _paleta(COLORS[povo])
		var telhado := [["p", ROOFS[povo], "roof"]]
		var extra := {&"house": [], &"work": WORK, &"defense": DEFENSE}
		for tipo: StringName in TIPOS:
			var tracos: Array = HOUSE + telhado + extra[tipo]
			var id := StringName(NATIVA % [povo, tipo])
			todas[id] = {"size": TAMANHO, "strokes": tracos, "palette": paleta}
	return todas


static func _paleta(cor: Color) -> Dictionary:
	return {
		"plaster": cor.lightened(TONS.plaster),
		"plaster_shade": cor.lightened(TONS.plaster_shade),
		"roof": cor.darkened(TONS.roof),
		"roof_dark": cor.darkened(TONS.roof_dark),
		"roof_light": cor.lightened(TOM_CLARO),
	}
