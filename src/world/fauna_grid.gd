# src/world/fauna_grid.gd — os bichos de cenario arrumados por troco de x.
#
# O Fauna percorria os 801 bichos de uma semente medida para mexer nos ~150 perto do ecra,
# e o FaunaView percorria-os outra vez para desenhar 25 (auditoria de desempenho de
# 08/10/2026). Aqui cada bicho que nao e do bando mora no troco de LARGO px onde esta, e
# quem pergunta por um intervalo de x so olha para os trocos que o tocam. A resposta e a
# do caminho comprido, e pela mesma ordem: indices crescentes, que e a ordem de desenho.
class_name FaunaGrid
extends RefCounted

const LARGO := 256.0

## Os indices do bando: voam sempre, e nao moram em troco nenhum.
var flock := PackedInt32Array()
var _trocos: Dictionary = {}  # troco -> Array dos indices que la moram
var _troco := PackedInt32Array()  # o troco de cada bicho, por indice
var _soltos := PackedInt32Array()  # os que nao sao do bando, por indice


func build(bichos: Array[Fauna.Bicho]) -> void:
	flock = PackedInt32Array()
	_soltos = PackedInt32Array()
	_trocos = {}
	_troco.resize(bichos.size())
	for i in bichos.size():
		if bichos[i].flock_index >= 0:
			flock.append(i)
		else:
			_soltos.append(i)
			_entrar(i, _de(bichos[i].x))


## O bando leva os seus: cada um vai para onde o Flock o pos, virado para onde foi.
func fly(bichos: Array[Fauna.Bicho], bando: Flock, delta: float) -> void:
	for i in flock:
		var b := bichos[i]
		var novo := bando.positions[b.flock_index]
		b.facing = signf(novo.x - b.x) if not is_equal_approx(novo.x, b.x) else b.facing
		b.x = novo.x
		b.y = novo.y
		b.phase += delta


## Os que nao sao do bando com x em [de, ate], por indice crescente.
func between(bichos: Array[Fauna.Bicho], de: float, ate: float) -> PackedInt32Array:
	var saida := PackedInt32Array()
	# Um intervalo sem fim (PresentationBounds.TUDO) tem mais trocos do que bichos.
	if absf(ate - de) / LARGO > _soltos.size():
		for i in _soltos:
			if bichos[i].x >= de and bichos[i].x <= ate:
				saida.append(i)
		return saida
	for t in range(_de(de), _de(ate) + 1):
		for i: int in _trocos.get(t, []):
			if bichos[i].x >= de and bichos[i].x <= ate:
				saida.append(i)
	saida.sort()
	return saida


## Os que se veem em [de, ate], do bando ou nao, por indice crescente.
func seen(bichos: Array[Fauna.Bicho], de: float, ate: float) -> PackedInt32Array:
	var saida := between(bichos, de, ate)
	for i in flock:
		if bichos[i].x >= de and bichos[i].x <= ate:
			saida.append(i)
	saida.sort()
	return saida


## O bicho `i` andou ate `x`: muda de troco se passou para outro.
func moved(i: int, x: float) -> void:
	var t := _de(x)
	if t == _troco[i]:
		return
	var velho: Array = _trocos[_troco[i]]
	velho.erase(i)
	_entrar(i, t)


func _entrar(i: int, t: int) -> void:
	_troco[i] = t
	if not _trocos.has(t):
		_trocos[t] = []
	(_trocos[t] as Array).append(i)


static func _de(x: float) -> int:
	return floori(x / LARGO)
