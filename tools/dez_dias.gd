# tools/dez_dias.gd — o criterio de saida da Fase 1, varrido (F1-16, §66).
#
# Fora do jogo: `tools/` e `tests/` estao no exclude_filter do export.
#
# O §66 pede uma coisa e o seu contrario: "sobreviver 10 dias e POSSIVEL e NAO E
# TRIVIAL". Duas metades, e nenhuma se le num numero sozinho — leem-se numa
# tabela de defesas, onde se ve a partir de onde se aguenta e ate onde se cai.
# E isso que isto imprime, e e sobre isto que se afina.
#
#     godot --headless --path . scenes/tests/dez_dias.tscn
extends Node

const Harness := preload("res://tests/sim_harness.gd")
const Campaign := preload("res://tests/support/campaign.gd")

const DIAS := 10
## As defesas varridas: nivel do muro, torre de arqueiros, torre ALTA, arqueiros.
## Nao sao balanceamento — sao as combinacoes que um jogador pode ter ao decimo
## dia, e a pergunta e a partir de qual delas se aguenta.
const DEFESAS := [
	[1, false, false, 6],
	[1, true, false, 6],
	[2, true, false, 8],
	[3, true, false, 10],
	[1, false, true, 6],
	[2, true, true, 8],
	[3, true, true, 10],
	[4, true, true, 12],
]
const LINHA := "  %4d | %5s | %5s | %3d | %8s | %6d | %5d | %6.2f"


func _ready() -> void:
	print("\n§66 — dez dias no cenario fechado, com a tabela de invocacao inteira")
	print("  muro | torre | alta  | arq | aguentou | mortes | muros | nucleo")
	for d in DEFESAS:
		_correr(d[0], d[1], d[2], d[3])
	print("\nO §66 quer as duas: uma linha a aguentar e uma a cair.")
	get_tree().quit()


func _correr(nivel: int, torre: bool, alta: bool, arqueiros: int) -> void:
	var h := Harness.new()
	h.wall_level = nivel
	h.tower = torre
	h.high_tower = alta
	h.archers = arqueiros
	# A tabela inteira, e nao so Rastejantes: o §66 mede o JOGO, e e o Alado do
	# dia 4 e o Cavador do dia 10 que fazem a curva subir (§07). O crawlers_only
	# e do §07, que e um microteste de combate e outra pergunta.
	h.crawlers_only = false
	var r := Campaign.new().run(h, DIAS)
	h.stop()
	print(
		(
			LINHA
			% [
				nivel,
				"sim" if torre else "nao",
				"sim" if alta else "nao",
				arqueiros,
				"sim" if r[Campaign.AGUENTOU] else "caiu %d" % r[Campaign.CAIU],
				r[Campaign.MORTES],
				r[Campaign.MUROS],
				r[Campaign.VIDA],
			]
		)
	)
