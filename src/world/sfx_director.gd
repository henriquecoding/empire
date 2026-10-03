# src/world/sfx_director.gd — quem ouve os sinais da §46 e toca as pistas (§23, ADR 0054).
#
# A Audio Bible: "o audio ouve eventos, nunca decide nada". Este no liga-se ao EventBus
# e toca o que a folha de pistas (SfxCues) diz, com os sons do SynthSfx: a variacao de
# tom de cada pista, o maximo de vozes iguais e a distancia a camara a partir da qual ja
# nao se ouve. A simulacao nao sabe que ele existe.
#
# A moeda que entra numa obra e a unica que nao vem de um sinal: o §55 paga pela moeda
# no chao, sem evento. Ve-se o `paid` de cada obra subir, e cada moeda toca um pouco
# mais aguda do que a anterior, ate a obra ficar paga — o tilintar que conta do Kingdom.
# A ultima nao se ve (o pago volta a zero quando a obra arranca): e o build_started.
#
# Uma pista pedida antes de o aquecimento a fazer nao se perde: passa a frente e toca
# quando estiver feita, se ainda for a tempo — antes de passar o que ela duraria.
class_name SfxDirector
extends Node

## Vozes ao mesmo tempo. A Audio Bible da 24 ao jogo todo; a musica ainda nao existe.
const VOZES := 16
## Na borda da distancia de uma pista, o som ja so se ouve a isto.
const LONGE_DB := -12.0
## O tom da moeda numa obra sobe de 1 ate 1 + SUBIDA com o que ja esta pago.
const SUBIDA := 0.5
## O martelo de uma obra em curso, no maximo uma vez neste intervalo (s).
const MARTELO_S := 0.35
const MOEDA := &"sfx_coin_spend"

## A ultima pista que tocou, para os testes e para quem depura.
var last_cue: StringName = &""
var _vozes: Array[AudioStreamPlayer] = []
var _pistas: Array[StringName] = []
var _pago := {}
var _martelo := 0.0
## As pistas a espera do aquecimento: cue -> [x, tom, segundos a espera].
var _adiadas := {}


func _ready() -> void:
	for i in VOZES:
		var voz := AudioStreamPlayer.new()
		add_child(voz)
		_vozes.append(voz)
		_pistas.append(&"")
	for sinal: StringName in [&"dawn_broke", &"dusk_fell", &"night_started"]:
		EventBus.connect(sinal, _sinal_global.bind(sinal).unbind(1))
	EventBus.wall_breached.connect(func(_id: int) -> void: play(&"sfx_wall_breached"))
	EventBus.cavity_revealed.connect(func(_id: int) -> void: play(&"sfx_cavity_reveal"))
	EventBus.royal_impulse_used.connect(func(_id: StringName) -> void: play(&"sfx_impulse"))
	EventBus.fortress_conquered.connect(
		func(_f: int, _p: StringName) -> void: play(&"stg_conquest")
	)
	EventBus.succession_started.connect(func(_h: int) -> void: play(&"stg_succession"))
	EventBus.coin_dropped.connect(
		func(x: float, _b: int, _a: int, _s: StringName) -> void: play(&"sfx_coin_drop", x)
	)
	EventBus.coin_collected.connect(
		func(quem: int, _a: int) -> void: play(&"sfx_coin_collect", x_of(quem))
	)
	EventBus.coin_spent.connect(
		func(_a: int, _p: StringName) -> void: play(MOEDA, x_of(Assume.driven()))
	)
	EventBus.attack_launched.connect(_no_ataque)
	EventBus.unit_damaged.connect(_no_dano)
	EventBus.unit_died.connect(
		func(_id: int, x: float, _b: int, _d: PackedStringArray) -> void: play(&"sfx_death_unit", x)
	)
	EventBus.creature_died.connect(
		func(_id: int, x: float, _b: int) -> void: play(&"sfx_death_creature", x)
	)
	EventBus.build_progressed.connect(_na_obra)
	EventBus.build_started.connect(_obra_paga.unbind(1))
	EventBus.build_completed.connect(func(id: int) -> void: play(&"sfx_build_complete", _obra(id)))
	EventBus.building_destroyed.connect(
		func(_id: int, x: float) -> void: play(&"sfx_building_destroyed", x)
	)
	EventBus.wall_upgraded.connect(
		func(id: int, _n: int) -> void: play(&"sfx_wall_upgrade", _obra(id))
	)
	EventBus.unit_promoted.connect(
		func(id: int, _de: StringName, _a: StringName) -> void: play(&"sfx_recruit", x_of(id))
	)


func _process(delta: float) -> void:
	_martelo = maxf(0.0, _martelo - delta)
	SynthSfx.warm()  # aos bocados, para nao travar o arranque nem a web
	_tocar_adiadas(delta)
	if SimLoop.builds != null:
		_moedas_nas_obras()


## Toca a pista `cue` vinda de `x` (NAN = de todo o lado). Devolve se tocou.
func play(cue: StringName, x: float = NAN, tom: float = 1.0) -> bool:
	if not Preferences.on(Preferences.SOUND):
		return false
	if not SynthSfx.ready(cue):
		_adiadas[cue] = [x, tom, 0.0]  # o aquecimento ainda nao chegou a esta pista
		SynthSfx.hurry(cue)
		return false
	var pista := SfxCues.of(cue)
	var volume := volume_at(pista, x, _camara_x())
	if is_nan(volume) or _tocando(cue) >= int(pista[SfxCues.MAXIMO]):
		return false
	var k := _livre()
	var variacao: float = pista[SfxCues.TOM]
	if variacao > 0.0:
		tom *= RngService.float_range(RngService.VISUAL, 1.0 - variacao, 1.0 + variacao)
	_vozes[k].stream = SynthSfx.stream(cue)
	_vozes[k].volume_db = volume
	_vozes[k].pitch_scale = tom
	_vozes[k].play()
	_pistas[k] = cue
	last_cue = cue
	return true


## O volume de uma pista a `x` com a camara em `camara`: o da folha ao pe, LONGE_DB
## menos na borda da distancia dela, e NAN para la dela.
static func volume_at(pista: Dictionary, x: float, camara: float) -> float:
	var alcance: float = pista[SfxCues.DISTANCIA]
	var base: float = pista[SfxCues.VOLUME]
	if alcance <= 0.0 or is_nan(x) or is_nan(camara):
		return base
	var longe := absf(x - camara) / alcance
	return NAN if longe > 1.0 else base + LONGE_DB * longe


## O tom da moeda que entra numa obra: sobe com o que ja esta pago (Kingdom).
static func pay_pitch(pago: int, custo: int) -> float:
	return 1.0 + SUBIDA * clampf(float(pago) / float(maxi(1, custo)), 0.0, 1.0)


## O x de uma tropa ou de uma criatura pelo id, ou NAN.
static func x_of(id: int) -> float:
	if SimLoop.units != null and SimLoop.units.index_of(id) != UnitSystem.NENHUM:
		return SimLoop.units.xs[SimLoop.units.index_of(id)]
	if SimLoop.creatures != null and SimLoop.creatures.index_of(id) != CombatSystem.NENHUM:
		return SimLoop.creatures.xs[SimLoop.creatures.index_of(id)]
	return NAN


func _sinal_global(sinal: StringName) -> void:
	for cue: StringName in SfxCues.CUES:
		if SfxCues.of(cue)[SfxCues.EVENTO] == sinal:
			play(cue)


func _no_ataque(de: int, _para: int, _acertou: bool) -> void:
	var i := SimLoop.units.index_of(de) if SimLoop.units != null else UnitSystem.NENHUM
	var arco := false
	if i != UnitSystem.NENHUM:
		var dados := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		arco = dados != null and not MeleeSweep.melee(dados)
	play(&"sfx_attack_bow" if arco else &"sfx_attack_sword", x_of(de))


func _no_dano(quem: int, _quanto: int, _de: int) -> void:
	if quem == Assume.driven():
		play(&"sfx_king_hit")
	else:
		play(&"sfx_hit_flesh", x_of(quem))


func _na_obra(id: int, _racio: float) -> void:
	if _martelo <= 0.0 and play(&"sfx_build_hammer", _obra(id)):
		_martelo = MARTELO_S


func _obra(id: int) -> float:
	var i := SimLoop.builds.index_of(id) if SimLoop.builds != null else BuildSystem.NENHUM
	return SimLoop.builds.slots[i].x if i != BuildSystem.NENHUM else NAN


## A obra ficou paga: o absorb ja lhe tirou o custo, e a sondagem nao via a moeda.
func _obra_paga(id: int) -> void:
	var i := SimLoop.builds.index_of(id) if SimLoop.builds != null else BuildSystem.NENHUM
	if i == BuildSystem.NENHUM:
		return
	var vaga: BuildSlot = SimLoop.builds.slots[i]
	_pago[id] = vaga.paid
	play(MOEDA, vaga.x, 1.0 + SUBIDA)


func _tocar_adiadas(delta: float) -> void:
	for cue: StringName in _adiadas.keys():
		var pedido: Array = _adiadas[cue]
		pedido[2] += delta
		if pedido[2] > SynthSfx.duration(cue):
			_adiadas.erase(cue)  # ja nao vai a tempo
		elif SynthSfx.ready(cue):
			_adiadas.erase(cue)
			play(cue, pedido[0], pedido[1])


func _moedas_nas_obras() -> void:
	for vaga in SimLoop.builds.slots:
		var antes: int = _pago.get(vaga.id, vaga.paid)
		_pago[vaga.id] = vaga.paid
		if vaga.paid > antes:
			play(MOEDA, vaga.x, pay_pitch(vaga.paid, vaga.next_cost()))


func _tocando(cue: StringName) -> int:
	var quantas := 0
	for k in _vozes.size():
		quantas += 1 if _pistas[k] == cue and _vozes[k].playing else 0
	return quantas


## Uma voz parada, ou a que toca ha mais tempo quando estao todas ocupadas.
func _livre() -> int:
	var melhor := 0
	for k in _vozes.size():
		if not _vozes[k].playing:
			_pistas[k] = &""
			return k
		if _vozes[k].get_playback_position() > _vozes[melhor].get_playback_position():
			melhor = k
	return melhor


func _camara_x() -> float:
	var camara := get_viewport().get_camera_2d() if is_inside_tree() else null
	return camara.get_screen_center_position().x if camara != null else NAN
