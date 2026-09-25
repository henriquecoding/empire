# src/world/accessibility_filter.gd — contraste e daltonismo (§26; GB-25, GB-26).
#
# O §26 poe os dois na lista do que se faz: "controlos de contraste — baixo, um
# shader de saturacao/contraste global" e "modos para daltonismo — medio, a
# paleta e quente/fria, boa base. Testa a Podridao contra o terreno em
# protanopia". Sao o mesmo filtro: uma camada entre o mundo e a interface que le
# o ecra e o devolve com duas contas.
#
# As contas vivem aqui e nao no shader: as matrizes passam-lhe como uniforms, e
# o `apply()` faz em GDScript exactamente o que ele faz — e e esse que se testa.
# O dossie nao escolhe o algoritmo (Q-093): a simulacao e a de Machado et al.
# (2009), com severidade total, e a correccao e a de Fidaner et al. (2005), a
# que leva o que o olho perde para os canais que ele ve.
#
# Com o modo desligado e contraste 1 a camada esconde-se: o jogo por omissao e o
# da §80, pixel a pixel, e o `make silhueta` mede o mesmo que media.
class_name AccessibilityFilter
extends CanvasLayer

enum Mode { OFF, PROTANOPIA, DEUTERANOPIA, TRITANOPIA }

## Entre o mundo (0) e a interface (2): o texto nao passa pelo filtro, e o texto
## e o que ja tem o contraste que precisa.
const CAMADA := 1
const SHADER := preload("res://shaders/accessibility.gdshader")

## Machado, Oliveira e Fernandes (2009), severidade 1, em linhas: a cor que um
## olho com esta deficiencia ve.
const SIMULACAO := {
	Mode.PROTANOPIA:
	[
		Vector3(0.152286, 1.052583, -0.204868),
		Vector3(0.114503, 0.786281, 0.099216),
		Vector3(-0.003882, -0.048116, 1.051998),
	],
	Mode.DEUTERANOPIA:
	[
		Vector3(0.367322, 0.860646, -0.227968),
		Vector3(0.280085, 0.672501, 0.047413),
		Vector3(-0.011820, 0.042940, 0.968881),
	],
	Mode.TRITANOPIA:
	[
		Vector3(1.255528, -0.076749, -0.178779),
		Vector3(-0.078411, 0.930809, 0.147602),
		Vector3(0.004733, 0.691367, 0.303900),
	],
}

## Fidaner, Lin e Ozguven (2005): o erro (o que o olho perde) vai para os canais
## que ele ainda separa. Vermelho-verde leva-o ao verde e ao azul; azul-amarelo,
## ao vermelho e ao verde.
const CORRECAO_VERMELHO_VERDE := [
	Vector3(0.0, 0.0, 0.0), Vector3(0.7, 1.0, 0.0), Vector3(0.7, 0.0, 1.0)
]
const CORRECAO_AZUL := [Vector3(1.0, 0.0, 0.7), Vector3(0.0, 1.0, 0.7), Vector3(0.0, 0.0, 0.0)]
const NADA := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
const IDENTIDADE := [Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0)]

## A gama do slider de contraste. Nao vem do dossie (Q-093): abaixo de 0,75 a
## noite castanha da §80 fecha-se num so tom; acima de 1,5 o dia queima.
const CONTRASTE := {"min": 0.75, "max": 1.5, "passo": 0.05}
const MEIO := 0.5
## Um estado que nunca e o de ninguem: obriga o primeiro _aplicar() a escrever.
const NENHUM_ESTADO := Vector2(-1.0, -1.0)

var _material: ShaderMaterial
var _tela: ColorRect
var _estado := NENHUM_ESTADO


func _ready() -> void:
	layer = CAMADA
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_tela = ColorRect.new()
	_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tela.material = _material
	add_child(_tela)
	_aplicar()


## O que a camada vale depois de passar por este filtro: e o shader, em GDScript.
static func apply(cor: Color, contraste: float, modo: Mode) -> Color:
	var c := Vector3(cor.r, cor.g, cor.b)
	var visto := _vezes(rows_of(modo), c)
	c = (c + _vezes(correction_of(modo), c - visto)).clamp(Vector3.ZERO, Vector3.ONE)
	c = ((c - Vector3.ONE * MEIO) * contraste + Vector3.ONE * MEIO).clamp(Vector3.ZERO, Vector3.ONE)
	return Color(c.x, c.y, c.z, cor.a)


## Como um olho com esta deficiencia ve a cor, sem correccao nenhuma. E o que a
## matriz de QA (A4, A15) pede para medir.
static func simulate(cor: Color, modo: Mode) -> Color:
	var v := _vezes(rows_of(modo), Vector3(cor.r, cor.g, cor.b))
	return Color(clampf(v.x, 0.0, 1.0), clampf(v.y, 0.0, 1.0), clampf(v.z, 0.0, 1.0), cor.a)


static func identity(contraste: float, modo: Mode) -> bool:
	return modo == Mode.OFF and is_equal_approx(contraste, 1.0)


static func rows_of(modo: Mode) -> Array:
	return SIMULACAO.get(modo, IDENTIDADE)


static func correction_of(modo: Mode) -> Array:
	match modo:
		Mode.PROTANOPIA, Mode.DEUTERANOPIA:
			return CORRECAO_VERMELHO_VERDE
		Mode.TRITANOPIA:
			return CORRECAO_AZUL
	return NADA


## O que se escolhe na pausa vale ja: pergunta-se a cada frame, e so se mexe no
## shader quando mudou.
func _process(_delta: float) -> void:
	_aplicar()


func _aplicar() -> void:
	var prefs := Preferences.shared()
	var contraste := clampf(prefs.number(Preferences.CONTRAST), CONTRASTE.min, CONTRASTE.max)
	var modo := int(prefs.number(Preferences.COLORBLIND))
	var agora := Vector2(contraste, modo)
	if agora == _estado:
		return
	_estado = agora
	_tela.visible = not identity(contraste, modo as Mode)
	_material.set_shader_parameter(&"simulacao", _base(rows_of(modo as Mode)))
	_material.set_shader_parameter(&"correcao", _base(correction_of(modo as Mode)))
	_material.set_shader_parameter(&"contraste", contraste)


## As linhas da matriz como as colunas de uma Basis: no shader `cor * M` e M
## vezes a cor, e e assim que as contas daqui e de la sao a mesma.
static func _base(linhas: Array) -> Basis:
	return Basis(linhas[0], linhas[1], linhas[2])


static func _vezes(linhas: Array, v: Vector3) -> Vector3:
	return Vector3(
		(linhas[0] as Vector3).dot(v), (linhas[1] as Vector3).dot(v), (linhas[2] as Vector3).dot(v)
	)
