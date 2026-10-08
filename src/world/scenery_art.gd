# src/world/scenery_art.gd — os cenarios pintados em camadas do dono (a entrega de
# 08/10/2026, exportada por tools/export_scenery.py; ADR 0081).
#
# Le o manifesto de art/export/scenery: por cena, cada camada com o retangulo que ocupa no
# quadro (em px do quadro, ja recortada ao alfa) e o bloco em que foi pintada (o ceu vem em
# blocos de 8x4 e guarda-se pequeno). Diz se ha arte para todos os biomas — so entao o jogo
# troca o cenario procedural pelo pintado — e desenha uma camada em mosaico, recortada a
# janela e as linhas pedidas, sem reamostrar: cada pixel do dono cai num pixel do mundo.
#
# As texturas carregam-se a pedido (`load`) e quem as desenha guarda-as enquanto as mostra:
# a que ninguem mostra sai da memoria. Um reino inteiro e uma dezena de MB de video.
class_name SceneryArt
extends RefCounted

## Como se repete o quadro: uma vez (um marco), em mosaico, ou em mosaico com um quadro
## sim e outro nao virado (o ceu: um gradiente, onde so a junta se nota). Virado, o quadro
## perde um texel em cada ponta: as pontas dos ceus pintados sao mais claras do que o resto.
enum Mosaico { UM, REPETIR, ESPELHAR }

const MANIFESTO := "res://art/export/scenery/manifest.json"
const CENAS := "scenes"
const CAMADAS := "layers"
const QUADRO := "canvas"
const RETANGULO := "rect"
const ESCALA := "scale"
const FICHEIRO := "file"
const TIPO := "kind"
const REINO := "kingdom"
const TRANSICAO := "transition"
const LIMIAR_X := "threshold_x"
## O quadro inteiro, de cima a baixo: o que se pede sem corte.
const TUDO := Vector2(0.0, 720.0)

static var _manifesto: Dictionary = {}
static var _lido := false
static var _pintado := -1
static var _mapa: SceneryMap
static var _chave_mapa: Array = []


## Se ha arte pintada para todos os biomas da campanha: o cenario procedural fica para
## um bioma sem reino pintado, e nunca os dois misturados.
static func painted() -> bool:
	if _pintado < 0:
		var biomas := Registry.ids(&"biomes")
		var cenas := _cenas()
		_pintado = int(not biomas.is_empty() and not cenas.is_empty())
		for id in biomas:
			_pintado = _pintado if cenas.has(String(id)) else 0
	return _pintado == 1


## O mapa do mundo de agora: refaz-se so quando nasce um segmento, se atravessa ou se
## retoma (a revisao das terras), como o resto do cenario.
static func map() -> SceneryMap:
	var terras: WildSegments = SimLoop.field.wilds if SimLoop.field != null else null
	var chave := [
		terras.revision if terras != null else -1,
		SimLoop.world_width,
		Wilds.biome_now(),
		SimLoop.state.region if SimLoop.state != null else -1,
	]
	if _mapa == null or chave != _chave_mapa:
		_chave_mapa = chave
		_mapa = SceneryMap.of(SceneryMap.runs(terras, SimLoop.world_width, chave[2]), pairs())
	return _mapa


## As transicoes pintadas por `SceneryMap.key(de, para)`: com o de onde se vem a esquerda.
static func pairs() -> Dictionary:
	var saida := {}
	var cenas := _cenas()
	for id: String in cenas:
		var cena: Dictionary = cenas[id]
		if cena.get(TIPO) != TRANSICAO:
			continue
		var largura := float(cena[QUADRO][0])
		var limiar := float(cena[LIMIAR_X])
		saida[SceneryMap.key(StringName(cena["from"]), StringName(cena["to"]))] = {
			SceneryMap.CENA: StringName(id), SceneryMap.MEIA: Vector2(limiar, largura - limiar)
		}
	return saida


## As cenas do manifesto, por id.
static func scenes() -> PackedStringArray:
	return PackedStringArray(_cenas().keys())


## O que o manifesto diz de uma camada: FICHEIRO, RETANGULO (no quadro) e ESCALA.
static func layer(cena: StringName, camada: StringName) -> Dictionary:
	return _camada(cena, camada)


## Se a cena tem esta camada.
static func has(cena: StringName, camada: StringName) -> bool:
	return _camada(cena, camada).size() > 0


## A largura do quadro da cena: o periodo do mosaico.
static func width(cena: StringName) -> float:
	var dados: Dictionary = _cenas().get(String(cena), {})
	return float(dados[QUADRO][0]) if dados.has(QUADRO) else 0.0


static func texture(cena: StringName, camada: StringName) -> Texture2D:
	var dados := _camada(cena, camada)
	return load(String(dados[FICHEIRO])) as Texture2D if dados.has(FICHEIRO) else null


## Desenha a camada em mosaico: `janela` e Vector3(origem, de, ate) — um quadro comeca em
## `origem` (x do mundo) e repete-se de largura em largura, e so se pinta entre `de` e
## `ate`; `corte` sao as linhas de cima e de baixo. Devolve a textura, para quem desenha a
## guardar enquanto a mostra.
static func draw_layer(
	canvas: CanvasItem,
	cena: StringName,
	camada: StringName,
	janela: Vector3,
	corte := TUDO,
	alfa := 1.0
) -> Texture2D:
	return _desenhar(canvas, cena, camada, janela, Vector3(corte.x, corte.y, alfa), Mosaico.REPETIR)


## O mesmo, com os quadros impares virados: as pontas de dois quadros vizinhos sao a mesma
## coluna, e nao ha junta.
static func draw_mirrored(
	canvas: CanvasItem,
	cena: StringName,
	camada: StringName,
	janela: Vector3,
	corte := TUDO,
	alfa := 1.0
) -> Texture2D:
	return _desenhar(
		canvas, cena, camada, janela, Vector3(corte.x, corte.y, alfa), Mosaico.ESPELHAR
	)


## O mesmo, mas so o quadro que comeca na origem: um marco nao se repete.
static func draw_once(
	canvas: CanvasItem,
	cena: StringName,
	camada: StringName,
	janela: Vector3,
	corte := TUDO,
	alfa := 1.0
) -> Texture2D:
	return _desenhar(canvas, cena, camada, janela, Vector3(corte.x, corte.y, alfa), Mosaico.UM)


## `corte` leva a linha de cima, a de baixo e o alfa.
static func _desenhar(
	canvas: CanvasItem,
	cena: StringName,
	camada: StringName,
	janela: Vector3,
	corte: Vector3,
	modo: Mosaico
) -> Texture2D:
	var dados := _camada(cena, camada)
	var tex := texture(cena, camada)
	if tex == null or corte.z <= 0.0:
		return tex
	var r: Array = dados[RETANGULO]
	var s: Array = dados[ESCALA]
	var y0 := maxf(float(r[1]), corte.x)
	var y1 := minf(float(r[1] + r[3]), corte.y)
	var espelho := modo == Mosaico.ESPELHAR
	var aparar := float(s[0]) if espelho else 0.0
	var largura := float(r[2]) - 2.0 * aparar
	var periodo := largura if espelho else width(cena)
	if y1 <= y0 or periodo <= 0.0:
		return tex
	var repetir := modo != Mosaico.UM
	var primeiro := floori((janela.y - janela.x) / periodo) if repetir else 0
	var ultimo := floori((janela.z - janela.x) / periodo) if repetir else 0
	for n in range(primeiro, ultimo + 1):
		var inicio := janela.x + float(n) * periodo
		var esquerda := inicio + (0.0 if espelho else float(r[0]))
		# Um quadro virado desenha-se direito, numa transformada que o vira a volta do meio dele.
		var virado := espelho and posmod(n, 2) == 1
		var eixo := 2.0 * inicio + periodo
		var a := maxf(esquerda, eixo - janela.z if virado else janela.y)
		var b := minf(esquerda + largura, eixo - janela.y if virado else janela.z)
		if b <= a:
			continue
		if virado:
			canvas.draw_set_transform(Vector2(eixo, 0.0), 0.0, Vector2(-1.0, 1.0))
		var fonte := Rect2(
			(a - esquerda + aparar) / float(s[0]),
			(y0 - float(r[1])) / float(s[1]),
			(b - a) / float(s[0]),
			(y1 - y0) / float(s[1])
		)
		var tinta := Color(1.0, 1.0, 1.0, corte.z)
		canvas.draw_texture_rect_region(tex, Rect2(a, y0, b - a, y1 - y0), fonte, tinta)
		if virado:
			canvas.draw_set_transform(Vector2.ZERO)
	return tex


static func _camada(cena: StringName, camada: StringName) -> Dictionary:
	var dados: Dictionary = _cenas().get(String(cena), {})
	return (dados.get(CAMADAS, {}) as Dictionary).get(String(camada), {})


static func _cenas() -> Dictionary:
	if not _lido:
		_lido = true
		var texto := FileAccess.get_file_as_string(MANIFESTO)
		var lido: Variant = JSON.parse_string(texto) if not texto.is_empty() else null
		_manifesto = lido if lido is Dictionary else {}
	return _manifesto.get(CENAS, {})
