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
## Ate onde, em raios, uma luz ainda chega a um pixel: o bordo dissolve-se um pouco
## para la do raio (o `dissolve` do shader), e isto e com folga.
const ALCANCE := 1.5
## Por plano: quanto as luzes chegam (x) e quantas vezes leva a razao do chao (y).
## Greybox, como as alturas do Silhouette (Q-079): sao a composicao, nao o jogo.
const PLANOS := {
	Depth.SKY: Vector2(0.5, 0.0),
	Depth.FAR: Vector2(0.2, 0.0),
	Depth.MID: Vector2(0.55, 0.5),
	Depth.GROUND: Vector2(1.0, 1.0),
	Depth.BELOW: Vector2(0.9, 2.0),
}

## As vistas pintadas para uma hora (a noite, o crepusculo) ja trazem a luz dela: levam o
## material PINTADA, onde o ambiente da fase nao lhes cai por cima (ADR 0086) — menos o da
## noite, que cai com ela (night_weight): a noite e castanha (§80, ADR 0011).
const PINTADA := 100
const PINTADA_AMBIENTE := Vector3(1.0, 1.0, 1.0)

static var _materiais: Dictionary = {}
static var _frame := -1
static var _luz := Lighting.new()
static var _clock: ClockData
static var _comum: Dictionary = {}
static var _noite := 0.0


## O material de um plano. O mesmo para todos os nos desse plano.
static func material(plano: Depth, pintada := false) -> ShaderMaterial:
	var chave := int(plano) + (PINTADA if pintada else 0)
	if not _materiais.has(chave):
		var novo := ShaderMaterial.new()
		novo.shader = SHADER
		_materiais[chave] = novo
	return _materiais[chave]


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
	_noite = night_weight(int(relogio.current_phase()), relogio.phase_progress())
	var transformada := no.get_viewport_transform()  # com a escala do ecra
	_comum = uniforms(_luz, transformada, transformada * PresentationBounds.of(no))
	_comum[&"luz_celula"] = float(SimFactory.rot_profile().lantern_dither_px)  # §80: 2 px
	for chave: int in _materiais:
		feed(_materiais[chave], (chave % PINTADA) as Depth, chave >= PINTADA)


## Os uniforms de um plano num material qualquer: o do cenario, ou um que ja tenha
## o seu shader e inclua o world_light (a terra do SoilCover).
static func feed(alvo: ShaderMaterial, plano: Depth, pintada := false) -> void:
	if _comum.is_empty():
		return
	for nome: StringName in _comum:
		alvo.set_shader_parameter(nome, _comum[nome])
	alvo.set_shader_parameter(&"ambiente", ambient_of(_luz, _clock, plano, pintada, _noite))
	alvo.set_shader_parameter(&"alcance", PLANOS[plano].x)


## O ambiente de um plano com a luz `luz`. A noite o plano desce pela razao do chao (§80).
## Uma vista pintada nao leva o ambiente da fase, so o da noite, com o peso `noite` dela.
static func ambient_of(
	luz: Lighting, dados: ClockData, plano: Depth, pintada := false, noite := 0.0
) -> Vector3:
	var regra: Vector2 = PLANOS[plano]
	var razao := pow(BandLight.ground_ratio(dados), regra.y)
	var tecto := lerpf(1.0, razao, luz.dark)
	var ambiente := _vec(WorldPalette.dim(luz.ambient, tecto))
	return PINTADA_AMBIENTE.lerp(ambiente, noite) if pintada else ambiente


## Quanto da noite ha agora, como para uma variante da noite (OwnerScenery.phase_weight):
## toda nela, a entrar na segunda metade do crepusculo e a sair na primeira da alvorada.
static func night_weight(fase: int, progresso: float) -> float:
	return OwnerScenery.phase_weight([GameClock.Phase.NIGHT], fase, progresso)


## As luzes de uma Lighting, postas em px de ecra pela transformada do canvas. E
## publica porque e a conta que se testa: o shader so a aplica. So vao as que se veem:
## cada pixel de cada plano percorre a lista, e de dia (forca zero) ou fora do `ecra`
## uma luz custava o mesmo e nao dava nada (o dono, 03/10/2026: "esta muito lento").
static func uniforms(
	luz: Lighting, canvas: Transform2D, ecra := PresentationBounds.TUDO
) -> Dictionary:
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
		var raio := glow.radius * escala
		if glow.strength * forca <= 0.0 or not ecra.grow(raio * ALCANCE).has_point(p):
			continue
		onde.append(Vector4(p.x, p.y, raio, glow.strength * forca))
		bordo.append(_vec(glow.stops[0]))
		meio.append(_vec(glow.stops[1]))
		nucleo.append(_vec(glow.stops[2]))
	var acesas := onde.size()
	while onde.size() < MAX_LUZES:  # o shader declara 16: um array mais curto nao chega la
		onde.append(Vector4.ZERO)
		nucleo.append(Vector3.ZERO)
		meio.append(Vector3.ZERO)
		bordo.append(Vector3.ZERO)
	return {
		&"luzes": acesas,
		&"onde": onde,
		&"nucleo": nucleo,
		&"meio": meio,
		&"bordo": bordo,
		&"escala": escala,
		&"teto": Lighting.TETO,
	}


static func _vec(cor: Color) -> Vector3:
	return Vector3(cor.r, cor.g, cor.b)
