# src/world/light_field.gd — as luzes do mundo neste frame (§80, ADR 0034, 0048).
#
# Quem as acende ja existia: as obras com `light_radius` (fogueira e farol), o
# archote aceso de quem se conduz, e o Lume roxo na base da Podridao. Faltava um
# sitio que as juntasse, e por isso cada desenho perguntava pela sua — o BandView
# pela candeia, o CreatureView pelas fogueiras — e o cenario por nenhuma.
#
# Junta-se tambem a LAREIRA do nucleo. Nao e uma regra nova: o Torchlight ja diz
# que a volta do nucleo nao e escuro (`in_dark`, meia largura dele), e o Kingdom
# acende o mesmo fogo no centro do acampamento. O que faltava era ver-se. Desde a
# Q-190 (03/10/2026) e fogo que se compra: arde, e afasta, so na noite paga (Hearth).
#
# Calcula-se uma vez por frame, e todos leem a mesma lista.
class_name LightField
extends RefCounted

## A lareira: a forca das paragens, mais fraca do que uma fogueira (0,5) porque
## e o lar e nao o fogo da ronda, e a que altura da porta arde. Greybox (Q-079).
const LAREIRA := {"forca": 0.4, "alto": 18.0}
## O archote arde na mao, e nao no chao: a altura de uma mao de tropa.
const MAO := 30.0
## O aviso da tarde (Q-125): o Lume a acender-se no horizonte, antes da noite.
const AVISO := {"raio": 0.35, "fundo": 0.6, "forca": 0.5}

## O relogio do ecra conta em milissegundos; a cintilacao, em segundos.
const MILISSEGUNDOS := 1000.0

static var _frame := -1
static var _por_faixa: Dictionary = {}


## As luzes de uma faixa, ja a cintilar. A mesma lista para todos neste frame.
static func of(faixa: int) -> Array[Glow]:
	var agora := Engine.get_process_frames()
	if agora != _frame:
		_frame = agora
		_por_faixa = _gather(Time.get_ticks_msec() / MILISSEGUNDOS)
	var lista: Array[Glow] = []
	lista.assign(_por_faixa.get(faixa, []))
	return lista


## Esquece o que juntou: um jogo novo, ou um teste, nao herda as luzes do outro.
static func reset() -> void:
	_frame = -1
	_por_faixa = {}


static func _gather(tempo: float) -> Dictionary:
	var faixas := {}
	for faixa in Band.Kind.values():
		faixas[faixa] = [] as Array[Glow]
	if SimLoop.state == null:
		return faixas
	var perfil := SimFactory.rot_profile()
	var fogo := WorldLight.fire_stops(perfil)
	for vaga in SimLoop.builds.slots:
		var onde := Vector2(vaga.x, WorldPalette.ground_of(int(vaga.band)))
		var raio := WorldLight.hearth_radius(vaga)
		if raio > 0.0:
			if HearthArt.handles(vaga.kind):  # o farol arde no topo, e dali alumia
				onde.y -= HearthArt.flame_height(vaga.kind)
			var forca := WorldLight.hearth_strength(vaga)
			faixas[vaga.band].append(
				Glow.new(onde, vaga.band, raio, forca, fogo, Flicker.Kind.FIRE)
			)
		elif vaga.kind == BuildSlot.NUCLEO and vaga.standing() and SimLoop.night.dark.hearth.lit:
			var porta := onde - Vector2(0.0, LAREIRA.alto)
			var meia := RulesFactory.rules().hearth_radius_px  # o chao que ela guarda (Q-190)
			faixas[vaga.band].append(
				Glow.new(porta, vaga.band, meia, LAREIRA.forca, fogo, Flicker.Kind.FIRE)
			)
	_archote(faixas, perfil, fogo)
	for rot: RotSystem in [SimLoop.night.rot, SimLoop.night.other_rot]:
		_lume(faixas, rot, perfil)
	for faixa: int in faixas:
		var vivas: Array[Glow] = []
		for luz: Glow in faixas[faixa]:
			vivas.append(luz.alive(tempo, perfil.lantern_dither_px))
		faixas[faixa] = vivas
	return faixas


## O archote aceso de quem se conduz (Q-029): metade da forca, na mao dele. Sem ele, e
## com pouca luz, a tocha da mao (HandLight, UX-07): mais curta e mais fraca.
static func _archote(faixas: Dictionary, perfil: RotProfile, fogo: PackedColorArray) -> void:
	var rei := SimLoop.units.index_of(Assume.driven())
	if rei < 0:
		return
	var faixa := SimLoop.units.bands[rei]
	var onde := Vector2(SimLoop.units.xs[rei], WorldPalette.ground_of(faixa) - MAO)
	var raio := perfil.torch_radius_px
	var forca := WorldLight.MEIA
	if not SimLoop.night.dark.torch.lit():
		if not HandLight.carried(HandLight.dark_now(), false):
			return
		onde = HandLight.tip(rei)
		raio *= HandLight.LUZ.raio
		forca = HandLight.LUZ.forca
	faixas[faixa].append(Glow.new(onde, faixa, raio, forca, fogo, Flicker.Kind.FIRE))


## O Lume na base dela (ADR 0034): inteiro na superficie, e nas outras faixas so o
## que a Divida ja deixou chegar (§75). De tarde, e o aviso no horizonte (Q-125).
static func _lume(faixas: Dictionary, rot: RotSystem, perfil: RotProfile) -> void:
	if rot == null:
		return
	var roxo := WorldLight.stops(perfil)
	var dia := SimLoop.state.day
	if not rot.active():
		if rot.announced == 0:
			return
		var x := RealmFrame.edge(rot.announced)
		var parte: float = AVISO.fundo if rot.deep(dia) else AVISO.raio
		var horizonte := Vector2(x, float(Band.HORIZON))
		var raio := perfil.lantern_radius_base * parte
		var sup := int(Band.Kind.SURFACE)
		faixas[sup].append(Glow.new(horizonte, sup, raio, AVISO.forca, roxo, Flicker.Kind.LUME))
		return
	var raio := WorldLight.radius(perfil, dia)
	var alcance := WorldLight.debt_reach(SimLoop.night.voice.debt.tier())
	for faixa: int in faixas:
		var aqui := raio if faixa == int(Band.Kind.SURFACE) else raio * alcance
		if aqui <= 0.0:
			continue
		var onde := Vector2(WorldLight.nest_x(rot), WorldPalette.ground_of(faixa))
		faixas[faixa].append(Glow.new(onde, faixa, aqui, 1.0, roxo, Flicker.Kind.LUME))
