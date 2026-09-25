# src/world/biome_greybox.gd — a greybox de um bioma, em formas lisas (GB-02).
#
# §22: "nada de cenario se pinta antes de ter sido jogado como forma lisa". Isto
# e a forma lisa de cada um dos seis biomas: os planos de imagem do §11 em
# cinzento, cada um no valor que o parallax_layers.csv da a sua camada — num
# preset aberto o fundo clareia, num fechado escurece —, as formas do que o
# bioma tem (biomes.csv, `resources`), o marco do povo (peoples.csv,
# `landmark`), e as marcas que o ticket pede: a linha do chao e as tres faixas.
#
# Nenhuma cor e decisao de arte: e cinzento, e o valor sai dos dados. As alturas
# dos planos sao as do §11 e as de Band; o resto e geometria de greybox (Q-079).
class_name BiomeGreybox
extends Node2D

## As seis camadas do parallax_layers.csv (§22), pelo numero delas.
enum Camada { CEU = 1, MONTANHA, COLINA, MEIO, JOGO, FRENTE }

## A largura de um ecra (§19), que e o que cada greybox fotografa.
const ECRA := 1280.0
## Os planos de imagem do §11, em y: ceu ate 300, distancia ate ao horizonte.
## A distancia parte-se em duas camadas (montanha e colina) a meio.
const DISTANCIA := 300.0
const COLINA := 360.0
const PRIMEIRO_PLANO := 640.0
## O cinzento de referencia (camada 5, delta zero) e o de cada camada a partir dele.
const CINZA := 0.42
## Geometria das formas: fracoes da largura, e alturas em px.
const COPA_ALTO := 160.0
const AGUA_ALTO := 18.0
const MARCO_LARGO := 0.06
const MARCO_ALTO := 330.0
const LINHA := 3.0
const LETRA := 14
## Os recursos, da esquerda para a direita: onde comeca o primeiro, o passo, e a
## largura de cada forma; a rocha e mais estreita. O primeiro plano sao dois marcos.
const RECURSO_X := 0.15
const RECURSO_PASSO := 0.3
const RECURSO_LARGO := 0.2
const ROCHA_LARGO := 0.12
const METADE := 0.5
const MARCO_DESDE_A_DIREITA := 3.0
const FRENTE_LARGO := 2.0
## Quanto escurece cada coisa face ao plano dela, e a cor das marcas.
const RECURSO_ESCURO := 0.25
const MARCO_ESCURO := 0.4
const MARCA := Color(0.95, 0.85, 0.3)
const MARCA_FRACA := 0.4

@export var biome: StringName = &"ancient_forest"
@export var width: float = ECRA


func _draw() -> void:
	for s in shapes(biome, width):
		match s[&"kind"]:
			&"rect":
				draw_rect(s[&"rect"], s[&"color"])
			&"line":
				draw_line(s[&"from"], s[&"to"], s[&"color"], LINHA)
			&"label":
				draw_string(
					ThemeDB.fallback_font,
					s[&"at"],
					s[&"text"],
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					LETRA,
					s[&"color"]
				)


## As formas da greybox deste bioma, de tras para a frente. Pura: le o Registry
## e devolve dicionarios — e isso que o teste mede sem abrir uma janela.
static func shapes(biome_id: StringName, largura: float) -> Array[Dictionary]:
	var dados := Registry.entry(&"biomes", biome_id) as BiomeData
	var povo := Registry.entry(&"peoples", dados.people) as PeopleData
	var planos := [
		[Camada.CEU, 0.0, DISTANCIA],
		[Camada.MONTANHA, DISTANCIA, COLINA],
		[Camada.COLINA, COLINA, float(Band.HORIZON)],
		[Camada.MEIO, float(Band.HORIZON), float(Band.GROUND_LINE)],
		[Camada.JOGO, float(Band.GROUND_LINE), float(Band.SCREEN_BOTTOM)],
	]
	var saida: Array[Dictionary] = []
	for p in planos:
		saida.append(_rect(Rect2(0.0, p[1], largura, p[2] - p[1]), _cinza(dados, p[0]), p[0]))
	if dados.atmosphere_preset == &"closed":
		# Fechado (§11): a copa tapa o ceu, e o fundo escurece.
		saida.append(
			_rect(Rect2(0.0, 0.0, largura, COPA_ALTO), _cinza(dados, Camada.FRENTE), Camada.FRENTE)
		)
	saida.append_array(_recursos(dados, largura))
	saida.append(_marco(dados, povo, largura))
	# O primeiro plano (§11, 640-720): silhueta escura por cima de tudo.
	var fundo := Rect2(
		0.0,
		PRIMEIRO_PLANO,
		largura * MARCO_LARGO * FRENTE_LARGO,
		Band.SCREEN_BOTTOM - PRIMEIRO_PLANO
	)
	saida.append(_rect(fundo, _cinza(dados, Camada.FRENTE), Camada.FRENTE))
	saida.append_array(_marcas(dados, largura))
	return saida


## O cinzento da camada: o de referencia mais o value_delta do preset do bioma.
static func _cinza(dados: BiomeData, camada: int) -> Color:
	var c := Registry.entry(
		&"biomes/parallax", StringName("%s_%d" % [dados.parallax_preset, camada])
	)
	var v := clampf(CINZA + (c as ParallaxLayerData).value_delta, 0.0, 1.0)
	return Color(v, v, v)


static func _rect(r: Rect2, cor: Color, camada: int) -> Dictionary:
	return {&"kind": &"rect", &"rect": r, &"color": cor, &"layer": camada}


## Uma forma por recurso do bioma, no plano onde o §21 o poe: a agua e a rocha
## no plano de jogo, o bosque e os fungos no plano medio, o campo no chao.
static func _recursos(dados: BiomeData, largura: float) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	var chao := float(Band.GROUND_LINE)
	var meio := float(Band.HORIZON)
	var k := 0
	for recurso in dados.resources:
		var x := largura * (RECURSO_X + RECURSO_PASSO * k)
		var r := Rect2(x, chao - AGUA_ALTO, largura * RECURSO_LARGO, AGUA_ALTO)
		if recurso == &"forest" or recurso == &"fungi":
			r = Rect2(
				x,
				meio - COPA_ALTO * METADE,
				largura * RECURSO_LARGO,
				chao - meio + COPA_ALTO * METADE
			)
		elif recurso == &"rock":
			r = Rect2(x, chao - COPA_ALTO * METADE, largura * ROCHA_LARGO, COPA_ALTO * METADE)
		var d := _rect(r, _cinza(dados, Camada.MEIO).darkened(RECURSO_ESCURO), Camada.MEIO)
		d[&"resource"] = recurso
		saida.append(d)
		k += 1
	return saida


## O marco do povo (§21): visivel de tres segmentos, a furar a faixa aerea. O
## do Sob-Raiz e um poco, e desce em vez de subir.
static func _marco(dados: BiomeData, povo: PeopleData, largura: float) -> Dictionary:
	var x := largura * (1.0 - MARCO_LARGO * MARCO_DESDE_A_DIREITA)
	var chao := float(Band.GROUND_LINE)
	var r := Rect2(x, chao - MARCO_ALTO, largura * MARCO_LARGO, MARCO_ALTO)
	if povo.landmark == &"shaft":
		r = Rect2(x, chao, largura * MARCO_LARGO, Band.SCREEN_BOTTOM - chao)
	var d := _rect(r, _cinza(dados, Camada.JOGO).darkened(MARCO_ESCURO), Camada.JOGO)
	d[&"landmark"] = povo.landmark
	return d


## A linha do chao, o horizonte, e as tres faixas com o nome escrito (GB-02).
static func _marcas(dados: BiomeData, largura: float) -> Array[Dictionary]:
	var fraca := MARCA.darkened(MARCA_FRACA)
	var saida: Array[Dictionary] = [
		_linha(float(Band.GROUND_LINE), largura, MARCA, &"ground"),
		_linha(float(Band.HORIZON), largura, fraca, &"horizon"),
		_linha(float(Band.AERIAL_BOTTOM), largura, fraca, &"aerial"),
	]
	var faixas := {
		&"AERIAL": Band.AERIAL_BOTTOM,
		&"SURFACE": Band.GROUND_LINE,
		&"UNDERGROUND": Band.SCREEN_BOTTOM,
	}
	for nome: StringName in faixas:
		saida.append(_texto(Vector2(LETRA, float(faixas[nome]) - LETRA), String(nome), nome))
	saida.append(_texto(Vector2(LETRA, LETRA * FRENTE_LARGO), String(dados.id), &""))
	return saida


static func _linha(y: float, largura: float, cor: Color, marca: StringName) -> Dictionary:
	return {
		&"kind": &"line",
		&"from": Vector2(0, y),
		&"to": Vector2(largura, y),
		&"color": cor,
		&"mark": marca
	}


static func _texto(onde: Vector2, texto: String, faixa: StringName) -> Dictionary:
	return {&"kind": &"label", &"at": onde, &"text": texto, &"color": MARCA, &"band": faixa}
