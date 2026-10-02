# src/world/scenery_light.gd — a luz do cenario, plano a plano (§80, ADR 0048).
#
# Cada plano do cenario levava a cor da fase no `modulate`, e um `modulate` e uma
# cor so para o plano inteiro: de noite o chao era o mesmo castanho a volta de uma
# fogueira e a duzentos passos dela. Agora cada plano leva o shader world_light, e
# isto e quem lhe da, uma vez por frame, o que ele precisa — o ambiente que o olho
# ve e as luzes da superficie, em px de ecra.
#
# Os planos nao recebem a luz por igual, e e o §80 §1 que diz porque: o plano de
# jogo tem a paleta toda e e onde a luz cai; o fundo tem tecto de valores. A noite o
# chao desce abaixo do ceu pela razao do §80 (BandLight.ground_ratio) — o primeiro
# plano duas vezes —, e e isso que poe as silhuetas contra um horizonte mais claro.
# De dia nada desce: a razao entra com o escuro.
class_name SceneryLight
extends RefCounted

enum Depth { SKY, FAR, MID, GROUND, BELOW }

const SHADER := preload("res://shaders/world_light.gdshader")
const MAX_LUZES := 16
## Por plano: quanto as luzes chegam (x) e quantas vezes leva a razao do chao (y).
## Greybox, como as alturas do Silhouette (Q-079): sao a composicao, nao o jogo.
const PLANOS := {
	Depth.SKY: Vector2(0.5, 0.0),
	Depth.FAR: Vector2(0.2, 0.0),
	Depth.MID: Vector2(0.55, 0.5),
	Depth.GROUND: Vector2(1.0, 1.0),
	Depth.BELOW: Vector2(0.9, 2.0),
}

static var _materiais: Dictionary = {}
static var _frame := -1
static var _luz := Lighting.new()
static var _clock: ClockData
static var _comum: Dictionary = {}


## O material de um plano. O mesmo para todos os nos desse plano.
static func material(plano: Depth) -> ShaderMaterial:
	if not _materiais.has(plano):
		var novo := ShaderMaterial.new()
		novo.shader = SHADER
		_materiais[plano] = novo
	return _materiais[plano]


## Poe a luz deste frame em todos os materiais do cenario. Chamar mais de uma vez
## no mesmo frame nao faz nada: o primeiro no que chega paga por todos.
static func refresh(no: CanvasItem) -> void:
	var agora := Engine.get_process_frames()
	if agora == _frame or ClockService.clock == null:
		return
	_frame = agora
	if _clock == null:
		_clock = Registry.entry(&"economy", &"clock") as ClockData
	var relogio := ClockService.clock
	var sup := int(Band.Kind.SURFACE)
	_luz.light(_clock, sup, int(relogio.current_phase()), relogio.phase_progress())
	_comum = uniforms(_luz, no.get_viewport_transform())  # com a escala do ecra
	_comum[&"luz_celula"] = float(SimFactory.rot_profile().lantern_dither_px)  # §80: 2 px
	for plano: Depth in _materiais:
		feed(_materiais[plano], plano)


## Os uniforms de um plano num material qualquer: o do cenario, ou um que ja tenha
## o seu shader e inclua o world_light (a terra do SoilCover).
static func feed(alvo: ShaderMaterial, plano: Depth) -> void:
	if _comum.is_empty():
		return
	for nome: StringName in _comum:
		alvo.set_shader_parameter(nome, _comum[nome])
	var regra: Vector2 = PLANOS[plano]
	var razao := pow(BandLight.ground_ratio(_clock), regra.y)
	var tecto := lerpf(1.0, razao, _luz.dark)
	alvo.set_shader_parameter(&"ambiente", _vec(WorldPalette.dim(_luz.ambient, tecto)))
	alvo.set_shader_parameter(&"alcance", regra.x)


## As luzes de uma Lighting, postas em px de ecra pela transformada do canvas. E
## publica porque e a conta que se testa: o shader so a aplica.
static func uniforms(luz: Lighting, canvas: Transform2D) -> Dictionary:
	var onde := PackedVector4Array()
	var nucleo := PackedVector3Array()
	var meio := PackedVector3Array()
	var bordo := PackedVector3Array()
	var escala := canvas.get_scale().x
	var forca := Lighting.GANHO * luz.dark
	for glow in luz.glows:
		if onde.size() >= MAX_LUZES or glow.stops.size() < WorldLight.PARAGENS:
			break
		var p := canvas * glow.center
		onde.append(Vector4(p.x, p.y, glow.radius * escala, glow.strength * forca))
		bordo.append(_vec(glow.stops[0]))
		meio.append(_vec(glow.stops[1]))
		nucleo.append(_vec(glow.stops[2]))
	while onde.size() < MAX_LUZES:  # o shader declara 16: um array mais curto nao chega la
		onde.append(Vector4.ZERO)
		nucleo.append(Vector3.ZERO)
		meio.append(Vector3.ZERO)
		bordo.append(Vector3.ZERO)
	return {
		&"luzes": mini(luz.glows.size(), MAX_LUZES),
		&"onde": onde,
		&"nucleo": nucleo,
		&"meio": meio,
		&"bordo": bordo,
		&"escala": escala,
		&"teto": Lighting.TETO,
	}


static func _vec(cor: Color) -> Vector3:
	return Vector3(cor.r, cor.g, cor.b)
