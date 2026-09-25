# src/sim/state/game_state.gd — o estado autoritativo (§45).
#
# A regra: se esta aqui, e guardado no save e e determinista. Se esta num no, e
# derivado e descartavel. E essa fronteira que torna o save trivial.
#
# Puro: nao e Node, nao conhece o EventBus nem o RngService. O estado dos fluxos
# de aleatoriedade vive no save ao lado deste dicionario, nao dentro dele — a
# simulacao nao pode importar de src/core/ (§70).
#
# Duas notas sobre o que a §45 escreve e o que aqui esta:
#
# A §45 guarda `phase` e `phase_elapsed`; este guarda `day` e `clock_elapsed`.
# Nao e divergencia nova: a ADR 0006 ja escolheu o relogio do §30, que e dono de
# `day` e `elapsed`, contra o do §48, que e dono de `phase` e `phase_elapsed`.
# Guardar os dois seria guardar duas vezes a mesma informacao e abrir a porta a
# que divirjam — a razao pela qual a propria §45 recusa guardar o Y.
#
# As colecoes da §45 — units, creatures, buildings, coins_on_ground, corpses,
# rot, world, debt — entram com os sistemas que as escrevem (F1-03 e adiante).
# Nao estao aqui vazias por esquecimento: um campo que ninguem escreve e um
# campo que ninguem sabe migrar.
class_name GameState
extends RefCounted

var seed: int = 0
var tick: int = 0
var day: int = 1
var clock_elapsed: float = 0.0
## A duracao do dia que o jogador escolheu (§26, GB-24), em segundos. Zero e a do
## clock.csv — e e o que um save de antes disto carrega, porque era a que tinha.
var day_seconds: float = 0.0

## Contador unico e monotonico dos ids de instancia (§45). Comeca em 1 para que
## 0 nunca seja um id valido e sirva de "nenhum".
var next_id: int = 1


## Le um dicionario ja validado. Campos em falta ficam no valor por omissao e
## campos desconhecidos ignoram-se: um save de outra versao degrada em vez de
## recusar (§62).
static func from_dict(d: Dictionary) -> GameState:
	var estado := GameState.new()
	estado.seed = _inteiro(d, &"seed", estado.seed)
	estado.tick = _inteiro(d, &"tick", estado.tick)
	estado.day = _inteiro(d, &"day", estado.day)
	estado.next_id = _inteiro(d, &"next_id", estado.next_id)
	estado.clock_elapsed = _real(d, &"clock_elapsed", estado.clock_elapsed)
	estado.day_seconds = _real(d, &"day_seconds", estado.day_seconds)
	return estado


## Devolve o proximo id e avanca o contador. O unico sitio onde ids nascem.
func take_id() -> int:
	var id := next_id
	next_id += 1
	return id


## So tipos base, para o canal da ADR 0007. Nada aqui pode ser um Object.
func to_dict() -> Dictionary:
	return {
		&"seed": seed,
		&"tick": tick,
		&"day": day,
		&"clock_elapsed": clock_elapsed,
		&"day_seconds": day_seconds,
		&"next_id": next_id,
	}


static func _inteiro(d: Dictionary, chave: StringName, omissao: int) -> int:
	if d.has(chave) and typeof(d[chave]) == TYPE_INT:
		return d[chave]
	return omissao


static func _real(d: Dictionary, chave: StringName, omissao: float) -> float:
	if d.has(chave) and typeof(d[chave]) == TYPE_FLOAT:
		return d[chave]
	# Um int onde se espera um real e aceitavel e acontece: 0 escrito a mao.
	if d.has(chave) and typeof(d[chave]) == TYPE_INT:
		return float(d[chave])
	return omissao
