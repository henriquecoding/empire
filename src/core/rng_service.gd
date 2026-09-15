# src/core/rng_service.gd — a aleatoriedade inteira do jogo (§42).
#
# O unico ficheiro de src/ onde randi, randf e randomize podem aparecer; o
# portao G2 chumba em qualquer outro. Isso nao e zelo: e o que faz a promessa da
# semente do §21 — "uma semente reproduz tudo" — ser verdade em vez de intencao.
#
# Cinco fluxos deterministas e um livre. Cada consumidor usa sempre o mesmo, por
# nome, e por isso a ordem por que os sistemas correm nao lhes mexe na sequencia:
# o arqueiro falhar um tiro nao muda a criatura que a Podridao invoca.
#
# Os consumidores NAO recebem o gerador — pedem o valor, nomeando o fluxo. Assim
# nem o grep do G2 nem uma revisao precisam de confiar em ninguem.
#
# A parte que quase toda a gente esquece: guardar a semente nao chega. Quem grava
# a meio da noite 9 tem de retomar a sequencia onde ia, por isso o save leva o
# ESTADO de cada fluxo (snapshot), nao a semente. Sem isto, carregar muda a noite
# que se estava a jogar, e o defeito parece um fantasma.
extends Node

## Os cinco que afetam a simulacao, por ordem fixa. E um Array e nao as chaves
## de um Dictionary de proposito: a §42 proibe iterar um Dictionary quando o
## resultado afeta a simulacao, porque a ordem nao e garantida entre execucoes.
const DETERMINISTAS: Array[StringName] = [&"world", &"combat", &"rot", &"economy", &"ai"]

## Variante de prop, desfasamento de animacao, pitch, particulas. Nunca entra no
## save nem na simulacao: se um dia entrar, a semente deixa de reproduzir tudo.
const VISUAL := &"visual"

var _streams: Dictionary = {}
var _seed: int = 0
var _configurado: bool = false


## Semeia os cinco fluxos a partir da semente do mundo. Q-020: a §42 escrevia um
## XOR com constantes que nao sao hexadecimais; manda o codigo — hash do nome.
func configure(world_seed: int) -> void:
	_seed = world_seed
	_streams.clear()
	for fluxo in DETERMINISTAS:
		var r := RandomNumberGenerator.new()
		r.seed = hash(str(world_seed) + str(fluxo))
		_streams[fluxo] = r
	var livre := RandomNumberGenerator.new()
	livre.randomize()  # so o fluxo visual e livre
	_streams[VISUAL] = livre
	_configurado = true


## A semente do mundo. O §42 manda mostra-la no ecra de pausa e deixar copiar:
## e o melhor instrumento de depuracao e o melhor habito de comunidade de graca.
func world_seed() -> int:
	return _seed


## Um inteiro em [de, ate], inclusive.
func int_range(fluxo: StringName, de: int, ate: int) -> int:
	return _stream(fluxo).randi_range(de, ate)


## Um real em [de, ate].
func float_range(fluxo: StringName, de: float, ate: float) -> float:
	return _stream(fluxo).randf_range(de, ate)


## Um real em [0, 1).
func unit_float(fluxo: StringName) -> float:
	return _stream(fluxo).randf()


## Um elemento de opcoes. Array vazio devolve null — quem chama e que decide se
## isso e um caso legitimo (a Podridao sem massa para nada) ou um erro.
func escolher(fluxo: StringName, opcoes: Array) -> Variant:
	if opcoes.is_empty():
		return null
	return opcoes[int_range(fluxo, 0, opcoes.size() - 1)]


## O estado de cada fluxo determinista, para o save (§62). Chaves em String
## porque o save so leva tipos base e e lido com get_var(false).
func snapshot() -> Dictionary:
	var estados := {}
	for fluxo in DETERMINISTAS:
		estados[String(fluxo)] = _stream(fluxo).state
	return estados


## Retoma a sequencia onde ia. Um fluxo em falta fica onde esta em vez de
## rebentar: um save de uma versao anterior tem de degradar, nao recusar (§62).
func restore(estados: Dictionary) -> void:
	assert(_configurado, "restore() antes de configure(): nao ha fluxos a repor")
	for fluxo in DETERMINISTAS:
		var chave := String(fluxo)
		if estados.has(chave) and typeof(estados[chave]) == TYPE_INT:
			_streams[fluxo].state = estados[chave]


## So para testes e para o ecra de depuracao. Dentro de src/ ninguem lhe toca —
## chamar randi_range num gerador devolvido chumbaria no G2, e e de proposito.
func stream(fluxo: StringName) -> RandomNumberGenerator:
	return _stream(fluxo)


func _stream(fluxo: StringName) -> RandomNumberGenerator:
	assert(_configurado, "RngService.configure() ainda nao foi chamado")
	assert(_streams.has(fluxo), "fluxo RNG desconhecido: %s" % fluxo)
	return _streams[fluxo]
