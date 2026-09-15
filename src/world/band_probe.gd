# src/world/band_probe.gd — o que a scenes/tests/bands.tscn corre (F0-10).
#
# O criterio de saida da Fase 0, e a razao de existir: provar a matriz do §53 em
# vez de a afirmar.
#
# A cena tem tres colunas, uma por faixa, e cada uma atravessa as tres alturas
# de faixa de proposito — so assim "o aereo atravessa o subsolo" e uma medicao e
# nao uma frase. No arranque, a sonda percorre as nove combinacoes e escreve a
# tabela; depois o andarilho anda, para quem estiver a ver.
#
# Nao ha geometria neste ficheiro. As posicoes e os tamanhos vivem na cena, que
# e onde se veem e onde se mexem.
extends Node2D

const FAIXAS: Array[Band.Kind] = [Band.Kind.AERIAL, Band.Kind.SURFACE, Band.Kind.UNDERGROUND]
const NOMES := ["AEREA", "SUPERFICIE", "SUBSOLO"]

## Cadencia da demonstracao, nao balanceamento: nada no jogo a le.
const SEGUNDOS_POR_FAIXA := 2.0

var faixa: Band.Kind = Band.Kind.SURFACE

var _relogio: float = 0.0
var _indice: int = 0
var _velocidade: float = 0.0

@onready var _andarilho: CharacterBody2D = $Andarilho
@onready var _forma: CollisionShape2D = $Andarilho/ColisaoAndarilho
@onready var _rotulo: Label = $Estado
@onready var _camara: CameraRig = $CameraRig


func _ready() -> void:
	# O andarilho anda a velocidade de um vagabundo. Nao e decoracao: prova que
	# o caminho CSV -> .tres -> Registry -> cena esta ligado.
	_velocidade = (Registry.entry(&"units", &"vagrant") as UnitData).move_speed
	for coluna in $Terreno.get_children():
		BandLayers.apply_terrain(coluna, coluna.get_meta(&"band") as Band.Kind)
	_mudar_para(Band.Kind.SURFACE)
	_camara.follow(_andarilho)
	_escrever_tabela()


## As nove combinacoes, medidas com a fisica e nao deduzidas da tabela. A
## diagonal bate; tudo o resto atravessa.
func _escrever_tabela() -> void:
	print("§53 — o que colide com o que, medido:")
	print("           %s" % "  ".join(NOMES))
	for corpo in FAIXAS:
		var linha := PackedStringArray()
		for coluna in $Terreno.get_children():
			linha.append("bate " if _bate(corpo, coluna) else "passa")
		print("  %-11s %s" % [NOMES[int(corpo)], "       ".join(linha)])


## Poe o andarilho encostado a coluna, na altura da faixa, e pergunta a fisica.
func _bate(corpo: Band.Kind, coluna: StaticBody2D) -> bool:
	var antes := _andarilho.position
	var antes_faixa := faixa
	_mudar_para(corpo)
	_andarilho.position.x = coluna.position.x - _largura_da_coluna(coluna)
	var colisao := _andarilho.move_and_collide(Vector2(_largura_da_coluna(coluna), 0.0), true)
	_mudar_para(antes_faixa)
	_andarilho.position = antes
	return colisao != null


func _largura_da_coluna(coluna: StaticBody2D) -> float:
	var forma: RectangleShape2D = coluna.get_child(0).shape
	return forma.size.x


func _physics_process(delta: float) -> void:
	_relogio += delta
	if _relogio >= SEGUNDOS_POR_FAIXA:
		_relogio = 0.0
		_indice = (_indice + 1) % FAIXAS.size()
		_mudar_para(FAIXAS[_indice])

	var entrada := Input.get_axis(&"move_left", &"move_right")
	var avanco := entrada if not is_zero_approx(entrada) else 1.0
	_andarilho.move_and_collide(Vector2(avanco * _velocidade * delta, 0.0))
	_atualizar_rotulo()


## A unica linha que muda a faixa de alguma coisa neste projeto passa por aqui.
func _mudar_para(nova: Band.Kind) -> void:
	faixa = nova
	BandLayers.apply_body(_andarilho, nova)
	_andarilho.position.y = _altura(nova) - _meia_altura()


## A faixa decide o Y; guardar Y seria guardar duas vezes a mesma coisa (§45).
## O valor e a linha dos pes — a forma e que diz onde fica o centro.
func _altura(b: Band.Kind) -> float:
	match b:
		Band.Kind.AERIAL:
			return float(Band.AERIAL_BOTTOM)
		Band.Kind.SURFACE:
			return float(Band.GROUND_LINE)
		_:
			return float(Band.GROUND_LINE + Band.SOIL_CUT / 2)


func _meia_altura() -> float:
	return (_forma.shape as RectangleShape2D).size.y / 2


func _atualizar_rotulo() -> void:
	_rotulo.text = (
		"faixa %s · x %d · camada %d · mascara %d"
		% [
			NOMES[int(faixa)],
			int(_andarilho.position.x),
			_andarilho.collision_layer,
			_andarilho.collision_mask
		]
	)
