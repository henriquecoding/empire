# src/core/legacy_store.gd — o ficheiro do legado, como uma transacao (§16, §62; CONT-01).
#
# O legado passa por toda a derrota e toda a travessia (Q-134, Q-135), e era a
# unica escrita do jogo sem temporario: `leave()` escrevia direto no legacy.save
# e apagava os tres slots mesmo quando o ficheiro nao abria, e o jogo novo
# gastava-o antes de ter um save seu. A auditoria de 27/09 (N7, N8) reproduziu
# as duas janelas: uma escrita falhada e um fecho a meio deixavam a campanha sem
# legado e sem save nenhum.
#
# O protocolo, por esta ordem, e cada passo so depois do anterior:
#   1. o legado escreve-se num temporario, le-se de volta e compara-se;
#   2. renomeia-se — renomear e atomico, escrever nao e;
#   3. so entao se apagam os slots da partida que acabou;
#   4. o jogo novo aplica-o a um mundo acabado de montar e grava o primeiro save;
#   5. so esse save o gasta: `settle()` ve um slot mais novo do que o legado.
# Um fecho entre dois passos repete o passo que faltava: aplicar a um mundo novo e
# idempotente, porque o mundo e novo de cada vez.
#
# A moldura leva versao e a sequencia de save em que nasceu. A sequencia e o que
# separa um slot de antes da derrota (que o passo 3 nao chegou a apagar) do
# primeiro save do jogo novo — e o SaveService numera a seguir a ela (`seq_floor()`).
#
# Sem load(): store_var/get_var(false), como os saves (ADR 0007).
class_name LegacyStore
extends RefCounted

const PATH := "user://saves/legacy.save"
const VERSION := 1
const VERSAO := &"legacy_version"
const SEQ := &"after_seq"
const LEGADO := &"legacy"

## Se o ultimo `leave()` falhou. O ecra do fim diz-o em vez de dizer "atravessada".
static var failed: bool = false


## Passos 1 a 3. Devolve falso — e deixa os slots onde estavam — se o legado nao
## ficou no disco tal e qual.
static func leave(legado: Dictionary) -> bool:
	var moldura := {VERSAO: VERSION, SEQ: SaveService.latest_seq(), LEGADO: legado}
	failed = not _escrever(moldura)
	if failed:
		return false
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)
	return true


## O legado a espera, sem o gastar ({} se nao ha). Um ficheiro de antes do CONT-01
## nao tem moldura: o dicionario e o proprio legado.
static func pending() -> Dictionary:
	var moldura := _ler(PATH)
	if moldura.has(VERSAO) and typeof(moldura.get(LEGADO)) == TYPE_DICTIONARY:
		return SaveMigrationsV6.rename(moldura[LEGADO])
	return SaveMigrationsV6.rename(moldura)


## A sequencia de save a partir da qual um slot e do jogo novo; 0 sem legado.
static func seq_floor() -> int:
	return int(_ler(PATH).get(SEQ, 0))


## Passo 5, e o passo 3 que um fecho interrompeu. Corre no arranque, antes de
## decidir se ha save para retomar: um slot mais novo do que o legado diz que o
## jogo novo ja o recebeu e gravou (gasta-o); um slot mais velho e da partida que
## acabou, e apaga-se como o `leave()` ja devia ter apagado.
static func settle() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var seq := seq_floor()
	if SaveService.latest_seq() > seq:
		discard()
		return
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


## Apaga o legado sem o aplicar. Para quem o gastou, e para os testes.
static func discard() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


static func _escrever(moldura: Dictionary) -> bool:
	var temporario := PATH + ".tmp"
	var f := FileAccess.open(temporario, FileAccess.WRITE)
	if f == null:
		push_error("legado: nao abre %s (%d)" % [temporario, FileAccess.get_open_error()])
		return false
	f.store_var(moldura, false)  # false = allow_objects desligado. ADR 0007.
	var erro := f.get_error()
	f.close()
	var mudou := ERR_FILE_CORRUPT
	if erro == OK and _ler(temporario) == moldura:
		mudou = DirAccess.rename_absolute(
			ProjectSettings.globalize_path(temporario), ProjectSettings.globalize_path(PATH)
		)
	if mudou != OK:
		push_error("legado: %s nao chegou a %s (%d, %d)" % [temporario, PATH, erro, mudou])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporario))
		return false
	return true


static func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var f := FileAccess.open(caminho, FileAccess.READ)
	var lido: Variant = f.get_var(false) if f != null else null  # allow_objects: ADR 0007
	return lido if typeof(lido) == TYPE_DICTIONARY else {}
