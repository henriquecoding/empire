# tools/night_test.gd — o que a scenes/tests/night_test.tscn corre (§66, F1-15).
#
# Fora do jogo: `tools/` e `tests/` estao os dois no exclude_filter do export, e
# a cena que isto anima esta agora tambem. Nao ha aqui nada que o jogador corra.
#
# O que isto e: a mesa de trabalho do F1-16. A suite responde SIM ou NAO a uma
# pergunta do §07; isto imprime a tabela inteira das dez noites, com torre e sem
# ela, que e o que se olha quando se vai mexer num numero de data/source/. O §07
# pede exatamente esta leitura: "ajusta ate a noite ser ganha com 1-2 mortes no
# dia 5 e perdida sem torre no dia 8".
#
#     godot --headless --path . scenes/tests/night_test.tscn
extends Node

const Harness := preload("res://tests/sim_harness.gd")

const DIAS := 10
## §66: "dez dias em menos de dez segundos". O alvo esta aqui para ser impresso
## ao lado da medicao — um numero sozinho nao diz se passou.
const ORCAMENTO_S := 10.0
const LINHA := "  %2d  | %7d | %6d | %6d | %8d | %5d | %s"


func _ready() -> void:
	_tabela(false)
	_tabela(true)
	_dez_dias()
	get_tree().quit()


## Uma coluna por noite, do dia 1 ao dia DIAS. Cada linha e uma corrida propria:
## o cenario do §07 e uma noite posta de pe, e nao um jogo que se arrasta.
func _tabela(torre: bool) -> void:
	var h := Harness.new()
	h.tower = torre
	print("\ncenario do §07 — um muro, %d arqueiros, %s" % [h.archers, _com(torre)])
	print("  dia | invoca | abate | mortes | ao  muro | muros | nucleo de pe")
	for dia in range(1, DIAS + 1):
		var r := h.night(dia)
		if not r[Harness.GUARDADO]:
			print("  %2d  | (o muro ficou fora do caminho da mancha)" % dia)
			continue
		print(
			(
				LINHA
				% [
					dia,
					r[Harness.INVOCADAS],
					r[Harness.ABATES],
					r[Harness.MORTES],
					r[Harness.CONTACTO],
					r[Harness.MUROS],
					"sim" if r[Harness.DE_PE] else "NAO",
				]
			)
		)
	h.stop()


## A medida do §66. Corre o cenario dos dois flancos — dez noites sao dez
## sorteios de lado (§51) — do dia 1 ao dia DIAS, sem parar.
func _dez_dias() -> void:
	var h := Harness.new()
	var s := h.days(DIAS)
	h.stop()
	print(
		(
			"\n§66: %d dias (%d s de jogo) em %.2f s de relogio — orcamento %.0f s · %s"
			% [
				DIAS,
				int(h.day_seconds() * DIAS),
				s,
				ORCAMENTO_S,
				"cabe" if s < ORCAMENTO_S else "NAO CABE"
			]
		)
	)


func _com(torre: bool) -> String:
	return "com torre de arqueiros" if torre else "sem torre"
