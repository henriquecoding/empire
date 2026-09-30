# src/core/fresh_start.gd — recomecar do zero, a qualquer momento, pela pausa.
#
# O "Novo jogo" da derrota herda o legado (§16, Q-134): e decay, e nao reset. Isto
# e o outro botao, pedido pelo dono a 29/09 (Q-164, ADR 0037): apaga os tres saves e
# o legado, e o jogo seguinte nasce como o primeiro. As opcoes (§45) ficam — sao de
# quem joga, e nao da partida.
#
# Tudo ou nada. Apagar ficheiro a ficheiro deixava meia campanha apagada quando um
# deles ficava preso (no Windows, um ficheiro aberto nao sai). Primeiro renomeia-se
# cada um para a quarentena — renomear e atomico, e o SaveService e o LegacyStore so
# leem os nomes de origem —, e se um falhar os que ja foram voltam ao sitio. So com
# todos fora e que se apagam; um que nao saia fica inerte, e o wipe seguinte leva-o.
#
# Nao le save nenhum: so move e apaga. Nao ha load() aqui (ADR 0007).
class_name FreshStart
extends RefCounted

const TEMPORARIO := ".tmp"
const QUARENTENA := ".apagar"


## Apaga os saves e o legado, ou nada. Devolve falso se nada mudou.
static func wipe() -> bool:
	_varrer()  # o que um wipe anterior deixou em quarentena
	var fora: PackedStringArray = []
	for caminho in _do_jogo():
		if not FileAccess.file_exists(caminho):
			continue
		if _mover(caminho, caminho + QUARENTENA) != OK:
			for voltar in fora:
				_mover(voltar + QUARENTENA, voltar)
			return false
		fora.append(caminho)
	_varrer()
	LegacyStore.failed = false
	Pace.reset()
	return true


## Verdadeiro se nao ha nada para retomar nem para herdar.
static func clean() -> bool:
	for caminho in _do_jogo():
		if FileAccess.file_exists(caminho):
			return false
	return true


## O que o jogo le para retomar ou herdar, e os temporarios da escrita.
static func _do_jogo() -> PackedStringArray:
	var saida: PackedStringArray = []
	for slot in SaveService.SLOTS:
		saida.append(SaveService.caminho(slot))
		saida.append(SaveService.caminho(slot) + TEMPORARIO)
	saida.append(LegacyStore.PATH)
	saida.append(LegacyStore.PATH + TEMPORARIO)
	return saida


static func _varrer() -> void:
	for caminho in _do_jogo():
		if FileAccess.file_exists(caminho + QUARENTENA):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho + QUARENTENA))


static func _mover(de: String, para: String) -> Error:
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(de), ProjectSettings.globalize_path(para)
	)
