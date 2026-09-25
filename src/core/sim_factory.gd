# src/core/sim_factory.gd — quem monta os sistemas puros a partir do Registry.
#
# Existe por causa da regra 2 do AGENTS.md: src/sim/ nao conhece o Registry. Os
# sistemas recebem os dados JA CARREGADOS no construtor — a curva, os postos, as
# tropas, as criaturas — e por isso alguem, algures, tem de os ir buscar. Esse
# alguem e este ficheiro, e assim o SimLoop fica com os onze passos e nao com
# doze linhas de carregamento (ADR 0020).
#
# Tudo estatico: nao guarda estado, nao e autoload, e nao corre no _ready() de
# ninguem — e chamado do start(), que e depois de o Registry estar cheio
# (regra 8b, ADR 0020).
class_name SimFactory
extends RefCounted

const TABELA_ECONOMIA := &"economy"
const CURVA := &"curve"
const RELOGIO := &"clock"
const TABELA_POSTOS := &"jobs"
const TABELA_TROPAS := &"units"
const TABELA_CRIATURAS := &"creatures"
const TABELA_PODRIDAO := &"rot"
const PODRIDAO := &"default"
const TABELA_AMARGUEIROS := &"rot/amargueiros"
const TABELA_CAPITULOS := &"world/chapters"
const TABELA_DIARIOS := &"lore/journals"
const TABELA_BIOMAS := &"biomes"
const MUNDO := &"world"


static func curve() -> EconomyCurve:
	return Registry.entry(TABELA_ECONOMIA, CURVA) as EconomyCurve


## Uma tabela inteira por id, para quem precisa de perguntar por data_id dentro
## do tick sem ir ao indice de recursos.
static func by_id(tabela: StringName) -> Dictionary:
	var mapa := {}
	for recurso in Registry.entries(tabela):
		mapa[recurso.get(&"id")] = recurso
	return mapa


## Os cinco niveis do §10, POR NIVEL. O Registry devolve por id, que e ordem
## alfabetica — bastion, iron_wall, palisade, stakes, stone_wall — e uma escada
## montada nessa ordem custava 65 no primeiro degrau. Ordenar aqui, uma vez, e o
## que impede que cada sitio que a monta se lembre disso por sua conta.
static func walls_by_level() -> Array[WallData]:
	var niveis: Array[WallData] = []
	for recurso in Registry.entries(&"walls"):
		niveis.append(recurso as WallData)
	niveis.sort_custom(func(a: WallData, b: WallData) -> bool: return a.level < b.level)
	return niveis


static func job_board() -> JobBoard:
	return JobBoard.new(curve(), by_id(TABELA_POSTOS), by_id(TABELA_TROPAS))


## O combate precisa do quadro de postos: "a torre nao da dano — da certeza"
## (§07), e quem esta numa torre so se sabe perguntando ao posto que ocupa.
static func combat(postos: JobBoard) -> CombatSystem:
	var contacto := ContactQueue.new(curve())
	return CombatSystem.new(by_id(TABELA_TROPAS), by_id(TABELA_CRIATURAS), contacto, postos)


static func morale() -> MoraleSystem:
	return MoraleSystem.new(curve(), by_id(TABELA_TROPAS))


static func economy() -> EconomySystem:
	var relogio := Registry.entry(TABELA_ECONOMIA, RELOGIO) as ClockData
	return EconomySystem.new(curve(), relogio.phase_durations.size())


## O perfil da Podridao. Publico porque a candeia do §74 tambem se le dele, e
## quem a desenha nao tem — nem deve ter — o RotSystem por perto (F1-17).
static func rot_profile() -> RotProfile:
	return Registry.entry(TABELA_PODRIDAO, PODRIDAO) as RotProfile


## A janela entre invocacoes, em segundos (§51: a cada 4-7 s). Quem sorteia e o
## SimLoop, no fluxo `rot`; a simulacao nao pode (§42, §70).
static func rot_window() -> Vector2:
	return rot_profile().summon_interval


static func rot() -> RotSystem:
	var criaturas: Array[CreatureData] = []
	for recurso in Registry.entries(TABELA_CRIATURAS):
		criaturas.append(recurso as CreatureData)
	return RotSystem.new(rot_profile(), criaturas)


## O que a noite deixa no campo (§74): os tres destinos, e a escala de quem morre.
static func amargueiros() -> AmargueiroSystem:
	return AmargueiroSystem.new(rot_profile(), by_id(TABELA_AMARGUEIROS), by_id(TABELA_TROPAS))


## A voz da Podridao (§75): as doze ofertas, e a tabela das tropas para saber
## quem e o monarca — que nenhum preco leva.
static func offers() -> OfferSystem:
	var lista: Array[OfferData] = []
	for recurso in Registry.entries(&"rot/offers"):
		lista.append(recurso as OfferData)
	return OfferSystem.new(rot_profile(), lista, by_id(TABELA_TROPAS))


## O Zelador (§75): o tender de creatures.csv, que nao e invocado pela massa.
static func tender() -> Tender:
	return Tender.new(Registry.entry(TABELA_CRIATURAS, &"tender") as CreatureData)


## Os nomes (§76): os nove titulos, o teto e o luto da curva, e as duas tabelas
## que dizem o que um feito e — quem o fez, e o que se abateu.
static func titles() -> TitleSystem:
	var lista: Array[TitleData] = []
	for recurso in Registry.entries(&"lore/titles"):
		lista.append(recurso as TitleData)
	return TitleSystem.new(lista, curve(), by_id(TABELA_TROPAS), by_id(TABELA_CRIATURAS))


## As regioes da campanha: uma por povo, e um povo por bioma (§21: "uma regiao =
## um povo = um imperio a conquistar"). Pela ordem do Registry, que e a dos ids.
static func campaign_regions() -> PackedStringArray:
	return Registry.ids(TABELA_BIOMAS)


## O povo de cada regiao, pela mesma ordem.
static func campaign_peoples() -> PackedStringArray:
	var povos := PackedStringArray()
	for id in campaign_regions():
		povos.append(String((Registry.entry(TABELA_BIOMAS, StringName(id)) as BiomeData).people))
	return povos


## O bioma do povo de um segmento: o do segmento de partida e a regiao de casa.
static func biome_of_segment(segmento: StringName) -> StringName:
	var povo := (Registry.entry(&"segments", segmento) as SegmentData).people
	return (Registry.entry(&"peoples", povo) as PeopleData).biome


## Os capitulos desta campanha (§77), sorteados no fluxo `world` (§42, §54).
static func chapter_plan(regioes: PackedStringArray) -> ChapterPlan:
	var lista: Array[ChapterData] = []
	for recurso in Registry.entries(TABELA_CAPITULOS):
		lista.append(recurso as ChapterData)
	var sorteio := func(de: int, ate: int) -> int: return RngService.int_range(MUNDO, de, ate)
	return ChapterPlan.draw(regioes, lista, curve().chapters_per_campaign, sorteio)
