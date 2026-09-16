# tests/scripts_load_test.gd — todos os scripts de src/ compilam (§64).
#
# O portao que faltava, e a falta dele custou uma PR inteira: o gdformat le o
# FORMATO, o gdlint le o ESTILO e o G4 le os NUMEROS — nenhum dos tres abre o
# motor, e por isso nenhum dos tres ve um erro de compilacao. A suite tambem
# nao: ela toca nos sistemas de src/sim/, e um script de src/world/ ou de
# src/ui/ so e carregado por quem abre a cena de jogo, que e o jogo.
#
# Resultado: dois scripts com erro de analise — uma chamada com um argumento a
# mais, uma variavel sem tipo inferivel — passaram os cinco portoes de verde e
# so se viam a correr o jogo, que ficava sem faixas e sem painel.
#
# Isto e o minimo que fecha esse buraco: carrega cada .gd de src/, um a um, e
# chumba com o nome dos que nao carregam. Nao prova que o jogo esta certo —
# prova que ele chega a existir.
extends GdUnitTestSuite

const Rules := preload("res://tools/lint_rules.gd")


func test_todos_os_scripts_de_src_compilam() -> void:
	var partidos: Array[String] = []
	for f in Rules.gd_files("res://src"):
		if ResourceLoader.load(f, "Script") == null:
			partidos.append("%s: nao compila" % f)
	assert_array(partidos).override_failure_message("\n".join(partidos)).is_empty()
