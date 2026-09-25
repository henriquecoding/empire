# src/core/preferences.gd — o que o jogador escolhe e nao e o jogo (§26, §45).
#
# A §45 separa as duas coisas numa frase: "preferencia de sessao, nao estado de
# jogo. Vai para user://settings.cfg." Nao entra no save, nao entra na semente,
# e nada da simulacao a le — muda o que se VE, nunca o que acontece.
#
# Hoje sao duas, e sao as duas que o §26 poe na lista com a palavra
# "obrigatorio": desligar o tremor de ecra e os claroes (fotossensibilidade). O
# §24 ja o prometia na linha do tremor — "com opcao de desligar (§26)".
#
# O ficheiro le-se com a regra da ADR 0007, e nao com o ConfigFile: o ConfigFile
# desserializa Object(...) e Resource(...), que e a mesma porta que a ADR fecha
# no save. Aqui grava-se um dicionario de tipos base com store_var(_, false), le-se
# com get_var(false), e valida-se campo a campo. O portao G6 guarda os dois
# ficheiros (tools/lint_rules.gd).
#
# Uma instancia por ficheiro, e uma partilhada para o jogo. Um teste faz a dele
# com outro caminho, e assim nunca escreve por cima das de quem o corre.
class_name Preferences
extends RefCounted

## O caminho da §45.
const FICHEIRO := "user://settings.cfg"

const SCREEN_SHAKE := &"screen_shake"
const FLASHES := &"flashes"
const CAPTIONS := &"captions"
## A duracao do dia do §26, em segundos. Zero e a do clock.csv.
const DAY_SECONDS := &"day_seconds"
## O contraste (1 e o da §80) e o modo para daltonismo (0 e nenhum), do §26.
const CONTRAST := &"contrast"
const COLORBLIND := &"colorblind"
## O idioma escolhido na pausa (§27). Vazio e "o do sistema", como a boot fazia.
const LANGUAGE := &"language"
## Os idiomas que o strings.csv tem (§27). A boot e a pausa leem esta lista.
const LANGUAGES := ["pt_PT", "en"]

## As que existem, e o valor com que o jogo vem. O tremor e os claroes ligados: o
## §24 desenha o jogo com eles, e quem precisa de os tirar tira. As legendas de
## som desligadas: sao para quem precisa delas, e liga-as (GB-22).
const POR_OMISSAO := {
	SCREEN_SHAKE: true,
	FLASHES: true,
	CAPTIONS: false,
	DAY_SECONDS: 0.0,
	CONTRAST: 1.0,
	COLORBLIND: 0,
	LANGUAGE: "",
}

static var _partilhadas: Preferences

var path: String
var _valores: Dictionary = {}


func _init(caminho: String = FICHEIRO) -> void:
	path = caminho
	_valores = _ler()


## As do jogo, lidas a pedido e na primeira utilizacao (AGENTS.md, regra 8b).
static func shared() -> Preferences:
	if _partilhadas == null:
		_partilhadas = Preferences.new()
	return _partilhadas


## Troca as do jogo. Existe para um teste por as dele no lugar das de quem corre
## a suite; null volta a ler as do ficheiro da §45 na proxima pergunta.
static func set_shared(outras: Preferences) -> void:
	_partilhadas = outras


## Atalho para quem so quer saber: o tremor e os claroes perguntam isto a cada
## vez que acontecem, e nao guardam copia — mudar na pausa vale ja.
static func on(chave: StringName) -> bool:
	return shared().enabled(chave)


func enabled(chave: StringName) -> bool:
	return bool(_valores.get(chave, POR_OMISSAO.get(chave, true)))


## Muda e grava. Devolve falso se a chave nao existe ou o ficheiro nao se
## escreveu — o valor novo vale nesta sessao na mesma, que e o que o jogador
## acabou de pedir.
func set_enabled(chave: StringName, ligado: bool) -> bool:
	if typeof(POR_OMISSAO.get(chave)) != TYPE_BOOL:
		return false
	_valores[chave] = ligado
	return _gravar()


func number(chave: StringName) -> float:
	return float(_valores.get(chave, POR_OMISSAO.get(chave, 0.0)))


## Grava um numero com o tipo que a preferencia tem: um modo e um inteiro, uma
## duracao e um real, e o ficheiro guarda-os assim.
func set_number(chave: StringName, valor: float) -> bool:
	var tipo := typeof(POR_OMISSAO.get(chave))
	if tipo == TYPE_INT:
		_valores[chave] = int(valor)
	elif tipo == TYPE_FLOAT:
		_valores[chave] = valor
	else:
		return false
	return _gravar()


func text(chave: StringName) -> String:
	return str(_valores.get(chave, POR_OMISSAO.get(chave, "")))


func set_text(chave: StringName, valor: String) -> bool:
	if typeof(POR_OMISSAO.get(chave)) != TYPE_STRING:
		return false
	_valores[chave] = valor
	return _gravar()


## Campo a campo: uma chave desconhecida ou um tipo errado ignoram-se, e o resto
## le-se. Degrada em vez de recusar (ADR 0007).
func _ler() -> Dictionary:
	var limpo := {}
	if not FileAccess.file_exists(path):
		return limpo
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return limpo
	var cru: Variant = f.get_var(false)  # false = allow_objects desligado. ADR 0007.
	f.close()
	if typeof(cru) != TYPE_DICTIONARY:
		return limpo
	for chave: StringName in POR_OMISSAO:
		var valor: Variant = (cru as Dictionary).get(String(chave))
		if typeof(valor) == typeof(POR_OMISSAO[chave]):
			limpo[chave] = valor
	return limpo


## Escreve para um temporario e renomeia, como o save: renomear e atomico, e uma
## preferencia a meio de escrita nao pode levar as outras.
func _gravar() -> bool:
	var dados := {}
	for chave: StringName in _valores:
		dados[String(chave)] = _valores[chave]
	var temporario := path + ".tmp"
	var f := FileAccess.open(temporario, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(dados, false)  # false = allow_objects desligado. ADR 0007.
	f.close()
	var de := ProjectSettings.globalize_path(temporario)
	return DirAccess.rename_absolute(de, ProjectSettings.globalize_path(path)) == OK
