# src/world/owner_scenery.gd — as composicoes do dono, separadas em planos, no mundo (a
# entrega de 15 e 16/10/2026; ADR 0086).
#
# Le art/export/scenery_owner/manifest.json, escrito por tools/export_owner_scenery.py: por
# vista, os planos (ceu, nuvens, longe, meio, perto) e o chao (under, terrain) que saem de UMA
# pintura do dono, com o chao ja em y 517 e 618,5. O manifesto diz tambem que vista e o reino
# de cada povo, que vistas mudam com a hora ou a estacao, que sitio de agua pinta cada povo e
# que transicao pinta cada fronteira. `patch` poe isso no manifesto dos cenarios em camadas
# (SceneryArt): os reinos trocam de planos, as variantes, os sitios e a transicao nova entram
# como cenas, e o resto do caminho (SceneryMap, SceneryPlane, SceneryStrip) e o de sempre.
class_name OwnerScenery
extends RefCounted

const MANIFESTO := "res://art/export/scenery_owner/manifest.json"
const VARIANTE := "variant"
const SITIO := "site"
## A largura do quadro de um reino e de um sitio: o perto mostra-se uma vez em cada 2560.
const QUADRO_REINO := 2560.0
const QUADRO_TRANSICAO := 1280.0
## O limiar de uma transicao nova fica a meio do quadro, como nas treze da ADR 0081.
const LIMIAR_TRANSICAO := 640.0
## As fases e as estacoes pelo nome com que o manifesto as escreve.
const FASES := {
	"dawn": GameClock.Phase.DAWN,
	"morning": GameClock.Phase.MORNING,
	"noon": GameClock.Phase.NOON,
	"afternoon": GameClock.Phase.AFTERNOON,
	"dusk": GameClock.Phase.DUSK,
	"night": GameClock.Phase.NIGHT,
}
const ESTACOES := {
	"spring": Seasons.SPRING,
	"summer": Seasons.SUMMER,
	"autumn": Seasons.AUTUMN,
	"winter": Seasons.WINTER
}
## A variante de uma fase entra na metade final da fase de antes e sai na primeira metade
## da de depois; a de uma estacao muda durante a alvorada do primeiro dia.
const ENTRA := 0.5
const SAI := 0.5
## As chaves de cada camada que sai de `weights`: a vista, quanto se ve e se e pintada.
const VISTA := &"view"
const PESO := &"weight"
const PINTADA := &"painted"
## O sitio de agua de um bioma: a meia largura no mundo e a coluna do quadro com a agua.
const MEIA := &"half"
const ANCORA := &"anchor"
const MEIA_SITIO := 640.0
## O peso da camada sozinha, sem as que vem por cima: o que um plano opaco (o ceu) usa.
const BRUTO := &"raw"
## Para o desenho so se refazer quando um peso anda o bastante para se ver.
const DEGRAUS := 32.0
## Quanto mais depressa que o peso dela uma camada com buracos chega ao alfa inteiro.
const ADIANTO := 2.0

static var _dados: Dictionary = {}
static var _lido := false
static var _quadro := -1
static var _agora: Dictionary = {}


static func manifest() -> Dictionary:
	if not _lido:
		_lido = true
		var texto := FileAccess.get_file_as_string(MANIFESTO)
		var lido: Variant = JSON.parse_string(texto) if not texto.is_empty() else null
		_dados = lido if lido is Dictionary else {}
	return _dados


## Os planos e o chao das vistas do dono por cima dos do manifesto dos cenarios em camadas.
static func patch(legado: Dictionary) -> void:
	var dados := manifest()
	var cenas: Dictionary = legado.get(SceneryArt.CENAS, {})
	if dados.is_empty() or cenas.is_empty():
		return
	var vistas: Dictionary = dados.get("views", {})
	for bioma: String in dados.get("kingdoms", {}):
		var reino: Dictionary = dados.kingdoms[bioma]
		if cenas.has(bioma) and vistas.has(reino.base):
			cenas[bioma][SceneryArt.CAMADAS] = vistas[reino.base].layers.duplicate(true)
			cenas[bioma][SceneryArt.QUADRO] = [QUADRO_REINO, float(Band.SCREEN_BOTTOM)]
	for grupo: String in ["kingdoms", "sites"]:
		for chave: String in dados.get(grupo, {}):
			var c: Dictionary = dados[grupo][chave]
			var usadas: Array = c.get("variants", []).map(
				func(v: Dictionary) -> String: return v.view
			)
			if grupo == "sites":
				usadas.append(c.base)
			for nome: String in usadas:
				if vistas.has(nome) and not cenas.has(nome):
					cenas[nome] = {
						SceneryArt.TIPO: SITIO if nome == c.base else VARIANTE,
						SceneryArt.QUADRO: [QUADRO_REINO, float(Band.SCREEN_BOTTOM)],
						SceneryArt.CAMADAS: vistas[nome].layers,
					}
	for id: String in dados.get("transitions", {}):
		_transicao(cenas, id, dados.transitions[id], vistas)


## Uma transicao: o chao e o marco da vista do dono no lugar dos que la estavam (o fundo
## continua a ser a mistura dos dois reinos). Um par que ainda nao tinha transicao ganha uma.
static func _transicao(cenas: Dictionary, id: String, t: Dictionary, vistas: Dictionary) -> void:
	if not vistas.has(t.view):
		return
	var chao: Dictionary = vistas[t.view].layers
	if not cenas.has(id):
		cenas[id] = {
			SceneryArt.TIPO: SceneryArt.TRANSICAO,
			SceneryArt.QUADRO: [QUADRO_TRANSICAO, float(Band.SCREEN_BOTTOM)],
			SceneryArt.LIMIAR_X: LIMIAR_TRANSICAO,
			"from": t.from,
			"to": t.to,
			SceneryArt.CAMADAS: {},
		}
	var camadas: Dictionary = cenas[id][SceneryArt.CAMADAS]
	for camada: String in ["under", "terrain", "water", "foreground"]:
		camadas.erase(camada)
	for camada: String in ["under", "terrain", "landmark"]:
		if chao.has(camada):
			camadas[camada] = chao[camada]


## O sitio de agua de cada bioma: a vista e o x do quadro onde fica o meio da agua.
static func sites() -> Dictionary:
	var saida := {}
	var dados: Dictionary = manifest().get("sites", {})
	for bioma: String in dados:
		var s: Dictionary = dados[bioma]
		saida[StringName(bioma)] = {
			VISTA: StringName(s.base),
			ANCORA: float(s.anchor_x),
			MEIA: float(s.get("half", MEIA_SITIO)),
		}
	return saida


## As regras de variante de uma cena (um reino pelo bioma, ou um sitio pela vista dele).
static func rules(cena: StringName) -> Array:
	var dados := manifest()
	for grupo: String in ["kingdoms", "sites"]:
		var de: Dictionary = dados.get(grupo, {})
		for chave: String in de:
			var c: Dictionary = de[chave]
			if (grupo == "kingdoms" and chave == String(cena)) or c.base == String(cena):
				return c.get("variants", [])
	return []


## O que se ve de uma cena agora, de tras para a frente: a base e cada variante com o peso
## dela. Desenhadas por esta ordem, os pesos somam 1 onde as camadas se tapam; uma variante
## de uma fase e pintada com a luz dela (PINTADA), uma de uma estacao leva a do dia.
static func weights(
	cena: StringName, regras: Array, fase: int, progresso: float, estacao: Vector2i
) -> Array[Dictionary]:
	var camadas: Array[Dictionary] = [{VISTA: cena, PESO: 1.0, BRUTO: 1.0, PINTADA: false}]
	var estacoes := regras.filter(func(r: Dictionary) -> bool: return r.has("season"))
	var fases := regras.filter(func(r: Dictionary) -> bool: return r.has("phases"))
	for r: Dictionary in estacoes + fases:
		var w := (
			season_weight(ESTACOES.get(r.season, -1), estacao, fase, progresso)
			if r.has("season")
			else phase_weight(_fases(r.phases), fase, progresso)
		)
		if w > 0.0:
			for c in camadas:
				c[PESO] *= 1.0 - w
			camadas.append({VISTA: StringName(r.view), PESO: w, BRUTO: w, PINTADA: r.has("phases")})
	return camadas.filter(func(c: Dictionary) -> bool: return c[PESO] > 0.0)


## Quanto se ve de uma variante das `fases`: toda nelas, a entrar no fim da de antes e a sair
## no comeco da de depois.
static func phase_weight(fases: Array, fase: int, progresso: float) -> float:
	var n := FASES.size()
	if fases.has(fase):
		return 1.0
	if fases.has((fase + 1) % n):
		return smoothstep(ENTRA, 1.0, progresso)
	if fases.has((fase + n - 1) % n):
		return 1.0 - smoothstep(0.0, SAI, progresso)
	return 0.0


## Quanto se ve da variante da `estacao`: `agora` e (a estacao de hoje, a de ontem). No dia em
## que a estacao muda, a troca faz-se durante a alvorada.
static func season_weight(estacao: int, agora: Vector2i, fase: int, progresso: float) -> float:
	var hoje := float(agora.x == estacao)
	var ontem := float(agora.y == estacao)
	if agora.x == agora.y or fase != GameClock.Phase.DAWN:
		return hoje
	return lerpf(ontem, hoje, smoothstep(0.0, 1.0, progresso))


## O que se ve da cena neste frame, pelo relogio e pelas estacoes do jogo. Sem relogio (um
## teste, uma captura fria), so a base.
static func now(cena: StringName) -> Array[Dictionary]:
	var frame := Engine.get_process_frames()
	if frame != _quadro:
		_quadro = frame
		_agora.clear()
	if not _agora.has(cena):
		var regras := rules(cena)
		var relogio := ClockService.clock
		if regras.is_empty() or relogio == null:
			_agora[cena] = weights(cena, [], 0, 0.0, Vector2i.ZERO)
		else:
			var dia := relogio.day
			var est := SimLoop.field.seasons if SimLoop.field != null else null
			var estacao := Vector2i(est.at(dia), est.at(dia - 1)) if est != null else Vector2i.ZERO
			var fase := int(relogio.current_phase())
			_agora[cena] = weights(cena, regras, fase, relogio.phase_progress(), estacao)
	return _agora[cena]


## O alfa com que se desenha uma camada de `weights`, por ordem. Uma camada opaca leva o
## peso dela sozinha por cima das de baixo: e uma troca exacta. Uma com buracos nao pode,
## que a de baixo veria-se onde a de cima e transparente: as de baixo vao-se ate metade do
## caminho, e o fundo so passa (um oitavo, no pior momento) enquanto as duas se trocam.
static func alpha(camada: Dictionary, opaca: bool) -> float:
	var bruto: float = camada[BRUTO]
	return bruto if opaca else minf(bruto, ADIANTO * camada[PESO])


## Os pesos das cenas, aos degraus: muda quando o que se ve muda.
static func signature(cenas: Array) -> Array:
	var saida := []
	for cena: StringName in cenas:
		for c in now(cena):
			saida.append([c[VISTA], roundf(c[PESO] * DEGRAUS)])
	return saida


static func _fases(nomes: Array) -> Array:
	return nomes.map(func(n: String) -> int: return FASES.get(n, -1))
