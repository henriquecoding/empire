# src/core/save_file.gd — gravar um save como uma transacao (§62, ADR 0007, BUG-01).
#
# Escreve-se para um temporario e so depois se renomeia: renomear e atomico, escrever
# nao e. Mas um rename bem-sucedido nao prova que o temporario ficou inteiro — o
# relatorio de auditoria de 06/10/2026 gravou com o disco a meio e o save passou a
# metade, ilegivel, com o `save()` a devolver true. Agora o temporario so substitui o
# save se o motor disse que escreveu tudo, se tem o tamanho que os dados pedem e se se
# volta a ler. Qualquer falha deixa o save anterior intacto e devolve false.
#
# NUNCA load() NEM ResourceLoader aqui: store_var(..., false) e get_var(false), como
# no SaveService. O portao G6 guarda os dois ficheiros.
class_name SaveFile
extends RefCounted

## O store_var escreve o tamanho dos dados em 4 bytes antes deles.
const PREFIXO := 4


## Grava `dados` em `final`. Verdadeiro so com o ficheiro novo inteiro no sitio.
static func write(final: String, dados: Dictionary) -> bool:
	var temporario := final + ".tmp"
	var f := FileAccess.open(temporario, FileAccess.WRITE)
	if f == null:
		push_error("save: nao abre %s (%d)" % [temporario, FileAccess.get_open_error()])
		return false
	var escrito := f.store_var(dados, false)  # false = allow_objects desligado. ADR 0007.
	var erro := f.get_error()
	f.close()
	var esperado := var_to_bytes(dados).size() + PREFIXO
	var mudou := ERR_FILE_CORRUPT
	if escrito and erro == OK and confirmed(temporario, esperado, dados):
		mudou = DirAccess.rename_absolute(
			ProjectSettings.globalize_path(temporario), ProjectSettings.globalize_path(final)
		)
	if mudou != OK:
		push_error("save: %s nao chegou a %s (%d, %d)" % [temporario, final, erro, mudou])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporario))
		return false
	return true


## Se o ficheiro em `caminho` tem os `esperado` bytes e se le de volta como estes dados.
static func confirmed(caminho: String, esperado: int, dados: Dictionary) -> bool:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return false
	if f.get_length() != esperado:
		f.close()
		return false
	var lido: Variant = f.get_var(false)  # false = allow_objects. ADR 0007.
	f.close()
	if typeof(lido) != TYPE_DICTIONARY:
		return false
	for chave: StringName in [&"save_version", &"autosave_seq", &"seed"]:
		if (lido as Dictionary).get(chave) != dados.get(chave):
			return false
	return true
