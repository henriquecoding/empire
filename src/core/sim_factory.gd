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

## A que distancia de uma passagem o Verbo 2 ainda a alcanca, em px. Nao e
## balanceamento: e a tolerancia de um gesto, e o §11 nao lhe da numero. Fica
## ancorada na largura de uma tropa a escala 2 (§01) — Q-066.
const PASSAGEM_PX := 24.0


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


static func combat() -> CombatSystem:
	var contacto := ContactQueue.new(curve())
	return CombatSystem.new(by_id(TABELA_TROPAS), by_id(TABELA_CRIATURAS), contacto)


static func economy() -> EconomySystem:
	var relogio := Registry.entry(TABELA_ECONOMIA, RELOGIO) as ClockData
	return EconomySystem.new(curve(), relogio.phase_durations.size())


## A janela entre invocacoes, em segundos (§51: a cada 4-7 s). Quem sorteia e o
## SimLoop, no fluxo `rot`; a simulacao nao pode (§42, §70).
static func rot_window() -> Vector2:
	return (Registry.entry(TABELA_PODRIDAO, PODRIDAO) as RotProfile).summon_interval


static func rot() -> RotSystem:
	var criaturas: Array[CreatureData] = []
	for recurso in Registry.entries(TABELA_CRIATURAS):
		criaturas.append(recurso as CreatureData)
	return RotSystem.new(Registry.entry(TABELA_PODRIDAO, PODRIDAO) as RotProfile, criaturas)
