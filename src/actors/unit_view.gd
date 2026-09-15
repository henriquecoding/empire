# src/actors/unit_view.gd — a composicao por slots (§58).
#
# Cinco Sprite2D empilhados e um AnimationPlayer partilhado. Um sprite por
# combinacao de povo, cabeca, rosto, arma e efeito seria impossivel de manter —
# seis povos multiplicam-se depressa de mais. Custo de desenho despreziavel em
# 2D; poupanca de trabalho artistico enorme.
#
# A sombra de contacto nao e opcional: e o degrau 1 do §22, "o maior salto
# isolado do documento", e e o que separa figuras pousadas numa imagem de
# figuras que estao ali. Larga como o sprite, nunca alta como ele.
#
# Isto e apresentacao: le do Registry e do RngService, nao decide nada. A
# unidade que isto mostra e uma linha de dados algures, nao este no.
class_name UnitView
extends Node2D

## A ordem do §58. O indice na lista e o z_index dentro da unidade.
const SLOTS: Array[StringName] = [&"body", &"head", &"face", &"weapon", &"overlay"]
const SLOT_SHADOW := &"shadow"
const Z_SHADOW := -1

const SHADER := "res://shaders/palette_lut.gdshader"
const SOMBRA := "res://art/export/_placeholder/contact_shadow_18.png"

## A largura para que a sombra do placeholder foi desenhada. Escalar a partir
## dela e o que faz shadow_width do .tres significar pixeis e nao um factor.
const SOMBRA_BASE_PX := 18.0

var data: UnitData

var _sprites: Dictionary = {}
var _sombra: Sprite2D
var _material: ShaderMaterial
var _visivel: bool = true


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER)
	# Escrever os dois uniforms no arranque nao e redundante: o material so
	# devolve valores que alguem lhe pos, e "sem rampa" tem de ser um estado
	# real e nao a ausencia de um.
	set_palette(null, 0.0)
	_montar()


## Poe a unidade a mostrar um UnitData: a sombra ganha a largura certa e os
## slots que este tipo de unidade nao usa desaparecem.
func apply_data(dados: UnitData) -> void:
	data = dados
	_sombra.scale = Vector2.ONE * (float(dados.shadow_width) / SOMBRA_BASE_PX)
	for nome in SLOTS:
		_sprites[nome].visible = nome in dados.layer_slots


## A arte de um slot. null limpa-o — e assim que o rosto desaparece quando nao
## ha estado para mostrar.
func set_slot(nome: StringName, textura: Texture2D) -> void:
	assert(nome in SLOTS, "slot fora do §58: %s" % nome)
	var sprite: Sprite2D = _sprites[nome]
	sprite.texture = textura
	sprite.visible = textura != null and (data == null or nome in data.layer_slots)


func slot(nome: StringName) -> Sprite2D:
	return _sprites.get(nome)


## Um shader, quatro trabalhos (§60): hora do dia, variante de povo,
## encantamento e estado sao a mesma rampa com quantidades diferentes.
func set_palette(rampa: Texture2D, quantidade: float) -> void:
	_material.set_shader_parameter(&"lut", rampa)
	_material.set_shader_parameter(&"mix", clampf(quantidade, 0.0, 1.0))


func palette_mix() -> float:
	return _material.get_shader_parameter(&"mix")


## §58: "Cada unidade arranca a animacao num frame aleatorio do fluxo visual.
## Sem isto, 300 aldeoes respiram em unissono e parecem um exercito de clones."
## Fluxo visual, e nao um dos cinco deterministas: uma variante de animacao nao
## pode mexer no que a semente reproduz (§42).
func animation_offset(frames: int) -> int:
	if frames <= 1:
		return 0
	return RngService.int_range(RngService.VISUAL, 0, frames - 1)


## §58: fora do ecra continua a simular, para de animar. A simulacao nunca
## depende de estar visivel — e por isso isto so mexe na apresentacao.
func set_on_screen(visivel: bool) -> void:
	_visivel = visivel
	$Animacao.active = visivel


func on_screen() -> bool:
	return _visivel


func _montar() -> void:
	_sombra = Sprite2D.new()
	_sombra.name = "Sombra"
	_sombra.texture = load(SOMBRA)
	_sombra.z_index = Z_SHADOW
	# Multiplicativa e castanha-quente, nunca preta (§22 degrau 1). A cor vem da
	# propria textura; aqui so se garante que ela escurece em vez de tapar.
	_sombra.material = CanvasItemMaterial.new()
	(_sombra.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	add_child(_sombra)

	for i in SLOTS.size():
		var sprite := Sprite2D.new()
		sprite.name = String(SLOTS[i]).capitalize()
		sprite.z_index = i
		sprite.material = _material
		sprite.visible = false
		add_child(sprite)
		_sprites[SLOTS[i]] = sprite

	var animacao := AnimationPlayer.new()
	animacao.name = "Animacao"
	add_child(animacao)
