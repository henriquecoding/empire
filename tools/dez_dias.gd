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
## As defesas varridas: degrau do muro esquerdo, degrau do direito, torre de
## arqueiros, torre ALTA, arqueiros. Nao sao balanceamento — sao as combinacoes
## que um jogador pode ter ao decimo dia, e a pergunta e a partir de qual delas
## se aguenta. So UM Bastiao: o §10 escreve-o "unico por imperio".
const DEFESAS := [
	[1, 1, false, false, 6],
	[2, 2, true, false, 8],
	[3, 3, true, true, 10],
	[4, 4, true, true, 12],
	[5, 4, false, false, 12],
	[5, 4, true, false, 12],
	[5, 4, false, true, 12],
	[5, 4, true, true, 6],
	[5, 4, true, true, 12],
]
const LINHA := "  %3d | %3d | %5s | %5s | %3d | %8s | %6d | %5d | %6.2f"
const NOITE := "  %4d | %6d | %5d | %6.2f"


func _ready() -> void:
	print("\n§66 — dez dias no cenario fechado, com a tabela de invocacao inteira")
	print("  esq | dir | torre | alta  | arq | aguentou | mortes | muros | nucleo")
	var ultima: Array[Dictionary] = []
	for d in DEFESAS:
		ultima = _correr(d[0], d[1], d[2], d[3], d[4])
	print("\nO §66 quer as duas: uma linha a aguentar e uma a cair.")
	# A ultima defesa da lista e a que aguenta, e e sobre ela que se afina: um
	# total de dez noites diz que ela chegou ao fim, e so a linha a linha diz a
	# que custo. Uma noite que nao custa nada nao esta afinada — esta desligada.
	print("\nA ultima defesa, noite a noite:")
	print("  dia | mortes | muros | nucleo")
	for n in ultima:
		print(NOITE % [n[Campaign.DIA], n[Campaign.MORTES], n[Campaign.MUROS], n[Campaign.VIDA]])
	# A tabela de cima recusa todas as ofertas (Q-101). A mesma ultima defesa, a
	# pagar as que custam moedas — e a politica de quem joga, e nao a do imposto.
	print("\nA ultima defesa, a pagar as ofertas que custam moedas (D8):")
	var d: Array = DEFESAS[DEFESAS.size() - 1]
	for n in _correr(d[0], d[1], d[2], d[3], d[4], true):
		print(NOITE % [n[Campaign.DIA], n[Campaign.MORTES], n[Campaign.MUROS], n[Campaign.VIDA]])
	get_tree().quit()


func _correr(
	esquerda: int, direita: int, torre: bool, alta: bool, arqueiros: int, paga := false
) -> Array[Dictionary]:
	var h := Harness.new()
	h.wall_levels = PackedInt32Array([esquerda, direita])
	h.tower = torre
	h.high_tower = alta
	h.archers = arqueiros
	# A tabela inteira, e nao so Rastejantes: o §66 mede o JOGO, e e o Alado do
	# dia 4 e o Cavador do dia 10 que fazem a curva subir (§07). O crawlers_only
	# e do §07, que e um microteste de combate e outra pergunta.
	h.crawlers_only = false
	var campanha := Campaign.new()
	campanha.pay_coin_offers = paga
	var r := campanha.run(h, DIAS)
	h.stop()
	print(
		(
			LINHA
			% [
				esquerda,
				direita,
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
	return r[Campaign.TABELA]
