# src/core/intent_queue.gd — a fila de intencoes do §61.
#
# "A entrada nunca muda estado diretamente." O router de input nao chama
# drop_coin: enfileira uma INTENCAO, e o inicio do tick seguinte consome-a, pela
# ordem em que chegou.
#
# E o que faz o jogo determinista apesar de haver um humano: dada a mesma seed e
# a mesma sequencia de intencoes, a partida repete-se exatamente. E e isso que
# torna possivel gravar uma repeticao em 40 bytes por segundo (§61).
#
# Nao e Node e nao e autoload: e um objeto que o SimLoop tem. Quem escreve na
# fila e a camada de UI; quem a esvazia e o tick, e mais ninguem.
class_name IntentQueue
extends RefCounted

## Os verbos que chegam a simulacao. Os dois primeiros sao os Verbos 1 e 2 do
## §02; o terceiro e o gatilho direito do §24, que so o Arqueiro tem. O quarto e a
## duracao do dia do §26: muda a simulacao, e por isso entra pela fila como o
## resto — a pausa nao mexe no relogio (GB-24).
enum Kind { DROP_COIN, ASSUME, MARK_TARGET, DAY_LENGTH }

var _fila: Array[Array] = []


## Enfileira. Nao muda estado nenhum — e a regra inteira do §61.
func queue(tipo: Kind, args: Dictionary = {}) -> void:
	_fila.append([tipo, args])


## Tudo o que chegou, pela ordem de chegada, e esvazia. A fila e trocada antes
## de devolver: uma intencao gerada durante o consumo e servida no tick
## seguinte, como os eventos do §43, passo 11.
func take() -> Array[Array]:
	var pendentes := _fila
	_fila = []
	return pendentes


func pending() -> int:
	return _fila.size()


func clear() -> void:
	_fila = []
