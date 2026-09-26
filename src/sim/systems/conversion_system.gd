# src/sim/systems/conversion_system.gd — o circuito 2 do §06, pelo algoritmo do §49.
#
# "Cada materia tem uma casa que a processa, e cada casa oferece a mesma decisao
# binaria: moeda agora, ou capacidade depois." Com a casa de pe, a materia dos
# produtores dela deixa de virar moeda no sitio: a casa consome-a (`cost` por
# conversao) e da moeda com o bonus (`coin_multiplier`) ou, com o oficio vivo, a
# capacidade (`capacity_kind`, `magnitude`) enquanto a conversao corre.
#
# O gesto e o Verbo 1 com outro alvo (§06): uma moeda largada na casa troca o
# modo — para capacidade so se tiveres o oficio (Q-112).
#
# Puro: recebe as conversoes, as materias e as tropas ja carregadas.
class_name ConversionSystem
extends RefCounted

## O que uma casa faz AGORA, e nao so o modo guardado (planejamento 26/09, §7):
## NONE nao e casa de conversao; COIN vende; WANTS_CRAFT tem a capacidade
## escolhida e vende porque falta o oficio; WAITING tem oficio e ainda nao deu
## a capacidade nesta fase; ACTIVE da-a.
enum Status { NONE, COIN, WANTS_CRAFT, WAITING, ACTIVE }

const METADE := 0.5
## Uma fraccao de materia que a soma das fases nao fecha (0,333 x 3) nao pode
## deixar de converter: e aritmetica de virgula, e nao regra.
const FOLGA := 0.0001

## O modo de cada casa, por id de obra. Sem entrada e moeda.
var modes: Dictionary = {}
## A moeda que cada casa ja juntou e ainda nao largou.
var value: Dictionary = {}
## As capacidades activas nesta fase: tipo -> magnitude.
var active: Dictionary = {}

var _conversoes: Dictionary
var _materias: Dictionary
var _tropas: Dictionary
var _unidades: UnitSystem


## `conversoes`: CraftData por tipo de casa; `materias`: materia por tipo de obra;
## `tropas`: UnitData por id.
func _init(conversoes: Dictionary, materias: Dictionary, tropas: Dictionary) -> void:
	_conversoes = conversoes
	_materias = materias
	_tropas = tropas


## As tropas do jogo, para saber se o oficio da capacidade esta vivo.
func bind(unidades: UnitSystem) -> void:
	_unidades = unidades


func craft_of(vaga: BuildSlot) -> CraftData:
	return _conversoes.get(vaga.kind)


func mode_of(vaga: BuildSlot) -> int:
	return modes.get(vaga.id, CraftData.Mode.COIN)


func capacity(kind: StringName) -> float:
	return active.get(kind, 0.0)


## Verdadeiro se a materia deste produtor vai para uma casa de pe.
func claims(produtor: BuildSlot, obras: BuildSystem) -> bool:
	return _casa_de(_materias.get(produtor.kind, &""), obras) != null


## Passo 7, a seguir a producao: cada casa de pe consome a materia dos seus
## produtores, por id (§42), e da moeda ou capacidade. Devolve moedas no formato
## do EconomySystem.
func on_phase(obras: BuildSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	active = {}
	for casa in obras.standing():
		var conv := craft_of(casa)
		if conv == null:
			continue
		var modo := _modo_efectivo(casa, conv)
		var corre := false
		for produtor in obras.standing():
			if _materias.get(produtor.kind, &"") != conv.material:
				continue
			corre = true
			while produtor.stock + FOLGA >= conv.cost:
				produtor.stock -= conv.cost
				if modo == CraftData.Mode.COIN:
					value[casa.id] = (
						float(value.get(casa.id, 0.0)) + conv.cost * conv.coin_multiplier
					)
		if modo == CraftData.Mode.CAPACITY and corre:
			active[conv.capacity_kind] = maxf(capacity(conv.capacity_kind), conv.magnitude)
		var moedas := int(floorf(float(value.get(casa.id, 0.0)) + FOLGA))
		if moedas > 0:
			value[casa.id] = float(value[casa.id]) - moedas
			(
				eventos
				. append(
					{
						EconomySystem.CHAVE: EconomySystem.EV_MOEDA,
						EconomySystem.VAGA: casa,
						EconomySystem.QUANTO: moedas,
						EconomySystem.ONDE: casa.x,
						EconomySystem.FAIXA: int(casa.band),
					}
				)
			)
	return eventos


## Uma moeda pousada numa casa troca o modo. Para capacidade, so com o oficio
## teu vivo; de volta a moeda, sempre. Devolve verdadeiro se trocou.
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> bool:
	_unidades = unidades
	for casa in obras.standing():
		var conv := craft_of(casa)
		if conv == null:
			continue
		var para := CraftData.Mode.COIN
		if mode_of(casa) == CraftData.Mode.COIN:
			if not _tem_oficio(conv.capacity_craft):
				continue
			para = CraftData.Mode.CAPACITY
		for c in moedas.count():
			if not CoinTarget.pays(moedas, c, casa):
				continue
			moedas.remove(moedas.ids[c])
			modes[casa.id] = para
			return true
	return false


## As capacidades nas tuas tropas: a vida maxima e o passo do perfil, mais o que
## a conversao da. Quem sobe ganha a diferenca de vida; quem desce nao morre dela.
func apply(unidades: UnitSystem, capacidades: Dictionary) -> void:
	var vida := float(capacidades.get(&"troop_health", 0.0))
	var passo := float(capacidades.get(&"troop_speed", 0.0))
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var perfil: UnitData = _tropas.get(unidades.data_ids[i])
		if perfil == null:
			continue
		var teto := roundi(perfil.max_health * (1.0 + vida))
		var diferenca := teto - unidades.max_healths[i]
		if diferenca != 0:
			unidades.max_healths[i] = teto
			unidades.healths[i] = clampi(unidades.healths[i] + diferenca, 1, teto)
		unidades.speeds[i] = perfil.move_speed * (1.0 + passo)


func to_dict() -> Dictionary:
	return {&"modes": modes.duplicate(), &"value": value.duplicate(), &"active": active.duplicate()}


func from_dict(guardado: Dictionary) -> void:
	modes = guardado.get(&"modes", {}).duplicate()
	value = guardado.get(&"value", {}).duplicate()
	active = guardado.get(&"active", {}).duplicate()


func _modo_efectivo(casa: BuildSlot, conv: CraftData) -> int:
	if mode_of(casa) == CraftData.Mode.CAPACITY and _tem_oficio(conv.capacity_craft):
		return CraftData.Mode.CAPACITY
	return CraftData.Mode.COIN


## O estado efectivo de `casa`. `active` e o que a ultima fase deu e o que o
## apply() poe nas tropas — por isso e ele, e nao o modo, que diz ACTIVE.
func status(casa: BuildSlot) -> Status:
	var conv := craft_of(casa)
	if conv == null:
		return Status.NONE
	if mode_of(casa) == CraftData.Mode.COIN:
		return Status.COIN
	if not _tem_oficio(conv.capacity_craft):
		return Status.WANTS_CRAFT
	return Status.ACTIVE if capacity(conv.capacity_kind) > 0.0 else Status.WAITING


## Se ha um deste oficio teu vivo — o que a capacidade precisa para correr.
func has_craft(oficio: StringName) -> bool:
	return _tem_oficio(oficio)


func _tem_oficio(oficio: StringName) -> bool:
	if _unidades == null:
		return false
	for i in _unidades.count():
		if _unidades.data_ids[i] == oficio and _unidades.alive(i):
			if _unidades.owners[i] != RecruitSystem.SEM_DONO and _unidades.healths[i] > 0:
				return true
	return false


func _casa_de(materia: StringName, obras: BuildSystem) -> BuildSlot:
	if materia == &"":
		return null
	for casa in obras.standing():
		var conv := craft_of(casa)
		if conv != null and conv.material == materia:
			return casa
	return null
