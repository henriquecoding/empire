# src/sim/systems/name_system.gd — ninguem tem nome ate merecer um (§76).
#
# Um nome ganha-se por feito registado — uma condicao que o jogo ja observa
# para outra coisa — e nunca por escolha do jogador. Na alvorada, quem cumpriu
# um feito e nomeado, se houver vaga: nove, no maximo. Um titulo e unico
# enquanto o dono viver; morto, fica de luto tres dias e volta com ordinal — "O
# Segundo Que Ficou". O ordinal e a memoria do imperio.
#
# Puro. Le o que o combate devolve (quem matou quem) e o que as colunas dizem
# (quem esta em posto, quem esta dentro da mancha); devolve quem foi nomeado.
class_name NameSystem
extends RefCounted

enum { EV_NOMEADO, EV_A_ESPERA }

const CHAVE := &"kind"
const UNIDADE := &"unit_id"
const TITULO := &"title"
const ORDINAL := &"ordinal"

## Os feitos que o jogo ja sabe observar (Q-088). Os outros pedem portoes,
## arrastar corpos, cozinha, ressurreicao ou armas que se trocam.
const FEITOS: Array[StringName] = [
	&"kills", &"killed_ram", &"nights_in_siege_post", &"survived_inside_stain"
]
## "Posto de cerco": os postos de muralha e de torre (§10, jobs.csv).
const POSTOS_DE_CERCO: Array[StringName] = [&"wall", &"tower"]
const CERCO := &"siege"

## Quanto cada tropa ja fez: unit_id -> {feito: valor}.
var feats: Dictionary = {}
## Os nomes vivos: unit_id -> title_id, e o inverso.
var titles_of: Dictionary = {}
var holders: Dictionary = {}
## title_id -> o primeiro dia em que o titulo volta a poder ser ganho.
var mourning: Dictionary = {}
## title_id -> quantas vezes ja foi dado. O primeiro dono e o 1.
var ordinals: Dictionary = {}
## Quem cumpriu um feito e nao cabe nos nove: da um passo a frente (§76).
var waiting: PackedInt32Array = PackedInt32Array()

var _curva: EconomyCurve
var _titulos: Array[TitleData] = []
var _criaturas: Dictionary
var _dentro: Dictionary = {}


func _init(curva: EconomyCurve, titulos: Array[TitleData], criaturas: Dictionary) -> void:
	_curva = curva
	_criaturas = criaturas
	_titulos = titulos.duplicate()
	_titulos.sort_custom(
		func(a: TitleData, b: TitleData) -> bool: return String(a.id) < String(b.id)
	)


func named_count() -> int:
	return titles_of.size()


func title_of(unit_id: int) -> StringName:
	return titles_of.get(unit_id, &"")


func ordinal_of(unit_id: int) -> int:
	var t := title_of(unit_id)
	return ordinals.get(t, 0) if t != &"" else 0


## Todos os ticks, com o que o combate devolveu: quem deu o ultimo golpe numa
## criatura conta-a; num Ariete, parte o cerco. E quem esta dentro da mancha
## viva fica marcado para a alvorada.
func observe(eventos: Array[Dictionary], unidades: UnitSystem, rot: RotSystem) -> void:
	for e in eventos:
		if int(e[CombatSystem.CHAVE]) != CombatSystem.EV_MORTE or not e[CombatSystem.CRIATURA]:
			continue
		var quem: int = e.get(CombatSystem.POR, UnitSystem.NENHUM)
		if quem == UnitSystem.NENHUM:
			continue
		_somar(quem, &"kills", 1.0)
		var dados: CreatureData = _criaturas.get(e.get(CombatSystem.TIPO, &""))
		if dados != null and dados.tags.has(CERCO):
			_somar(quem, &"killed_ram", 1.0)
	if not rot.active():
		return
	var meia := rot.state.width * BuildSystem.METADE
	for i in unidades.count():
		if _tua(unidades, i) and unidades.bands[i] == Band.Kind.SURFACE:
			if absf(unidades.xs[i] - rot.position_x()) <= meia:
				_dentro[unidades.ids[i]] = true


## A alvorada, primeira metade: os nomeados que ja nao estao vivos. O titulo
## fica de luto; devolve-os como {unit_id: true}, que e o que o Amargueiro le
## para pesar a dobrar (§74).
func bury(estado: GameState, unidades: UnitSystem) -> Dictionary:
	var caidos := {}
	for unit_id in titles_of.keys():
		var i := unidades.index_of(unit_id)
		if i != UnitSystem.NENHUM and unidades.alive(i):
			continue
		var titulo: StringName = titles_of[unit_id]
		mourning[titulo] = estado.day + _curva.title_mourning_days
		holders.erase(titulo)
		titles_of.erase(unit_id)
		caidos[unit_id] = true
	return caidos


## A alvorada, segunda metade: conta a noite que passou e nomeia, por id
## crescente (§42), quem cumpriu um feito com titulo livre — ate aos nove.
func at_dawn(estado: GameState, unidades: UnitSystem, postos: JobBoard) -> Array[Dictionary]:
	var ordem := PackedInt32Array()
	for i in unidades.count():
		if not _tua(unidades, i):
			continue
		ordem.append(unidades.ids[i])
		var vaga := postos.slot_of(unidades.job_ids[i]) if postos != null else null
		if vaga != null and vaga.job_id in POSTOS_DE_CERCO:
			_somar(unidades.ids[i], &"nights_in_siege_post", 1.0)
		if _dentro.has(unidades.ids[i]):
			_somar(unidades.ids[i], &"survived_inside_stain", 1.0)
	_dentro = {}
	ordem.sort()
	waiting = PackedInt32Array()
	var eventos: Array[Dictionary] = []
	for unit_id in ordem:
		if titles_of.has(unit_id):
			continue
		var titulo := _merecido(unit_id, estado.day)
		if titulo == null:
			continue
		if named_count() >= _curva.named_cap:
			waiting.append(unit_id)
			eventos.append({CHAVE: EV_A_ESPERA, UNIDADE: unit_id, TITULO: titulo.id})
			continue
		eventos.append(_nomear(unidades, unit_id, titulo))
	return eventos


func to_dict() -> Dictionary:
	var d := {}
	for chave in [&"feats", &"titles_of", &"holders", &"mourning", &"ordinals", &"waiting"]:
		d[chave] = get(chave)
	return d


func from_dict(d: Dictionary) -> void:
	for chave in [&"feats", &"titles_of", &"holders", &"mourning", &"ordinals", &"waiting"]:
		if d.has(chave):
			set(chave, d[chave])


func _tua(unidades: UnitSystem, i: int) -> bool:
	return unidades.owners[i] != RecruitSystem.SEM_DONO and unidades.alive(i)


func _somar(unit_id: int, feito: StringName, quanto: float) -> void:
	var dela: Dictionary = feats.get(unit_id, {})
	dela[feito] = float(dela.get(feito, 0.0)) + quanto
	feats[unit_id] = dela


## O primeiro titulo, por id, cujo feito esta cumprido e que esta livre: sem
## dono vivo e fora do luto.
func _merecido(unit_id: int, dia: int) -> TitleData:
	var dela: Dictionary = feats.get(unit_id, {})
	for t in _titulos:
		if not t.condition_kind in FEITOS or holders.has(t.id):
			continue
		if dia < int(mourning.get(t.id, 0)):
			continue
		if float(dela.get(t.condition_kind, 0.0)) >= t.condition_value:
			return t
	return null


func _nomear(unidades: UnitSystem, unit_id: int, t: TitleData) -> Dictionary:
	holders[t.id] = unit_id
	titles_of[unit_id] = t.id
	ordinals[t.id] = int(ordinals.get(t.id, 0)) + 1
	if t.grant_kind == &"max_health":
		var i := unidades.index_of(unit_id)
		unidades.max_healths[i] += int(t.grant_value)
		unidades.healths[i] += int(t.grant_value)
	return {CHAVE: EV_NOMEADO, UNIDADE: unit_id, TITULO: t.id, ORDINAL: ordinals[t.id]}
