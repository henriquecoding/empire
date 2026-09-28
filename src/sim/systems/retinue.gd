# src/sim/systems/retinue.gd — quem e teu e nao tem posto, de dia (§25, Q-063).
#
# O §25 escrevia "o vagabundo segue-te" e o jogo fazia disso uma fila atras do
# rei, com toda a gente sem posto. O dono decidiu que o minuto 0:20 e como no
# Kingdom: New Lands (Q-063, 28/09/2026): a pessoa corre para a moeda que caiu
# perto dela, apanha-a, e a partir dai e tua e vai para a vila — o nucleo — e
# espera la ate haver trabalho para ela. Ninguem anda atras do rei, tirando o
# escudeiro (`follows_king`), que e o que o §08 lhe da.
#
# As posicoes sao ATRIBUIDAS e nao emergentes, por id crescente, como as da fila
# do §50: a volta do centro do nucleo, uma a direita e outra a esquerda, ao passo
# do follow_spacing_px — o mesmo espacamento de pessoa para pessoa que o jogo ja
# tem, e nao um segundo. De noite manda o Muster (Q-128), que corre depois disto.
#
# Puro e estatico: escreve alvos, e nao conhece o Registry.
class_name Retinue
extends RefCounted

const NENHUM := -1
## De que lado fica quem esta exactamente em cima do rei: atras, a esquerda.
const ATRAS := -1.0


## `seguem`: os ids de dados que andam atras do rei (a tag `follows_king`).
## `nucleo_x`: o centro do nucleo, onde espera quem nao tem posto.
static func place(
	unidades: UnitSystem,
	king_id: int,
	nucleo_x: float,
	seguem: Dictionary,
	distancia: float,
	espaco: float
) -> void:
	var rei := unidades.index_of(king_id)
	if rei == NENHUM or not unidades.alive(rei):
		return
	var dono := unidades.owners[rei]
	var atras := PackedInt32Array()
	var esperam := PackedInt32Array()
	for i in unidades.count():
		if unidades.ids[i] == king_id or unidades.owners[i] != dono or not unidades.alive(i):
			continue
		if unidades.job_ids[i] != UnitSystem.NENHUM:
			continue
		if seguem.has(unidades.data_ids[i]):
			atras.append(unidades.ids[i])
		else:
			esperam.append(unidades.ids[i])
	atras.sort()
	esperam.sort()
	var rei_x := unidades.xs[rei]
	for lugar in atras.size():
		var i := unidades.index_of(atras[lugar])
		var recuo := distancia + lugar * espaco
		unidades.set_target_x(atras[lugar], rei_x + _lado(unidades.xs[i], rei_x) * recuo)
	for lugar in esperam.size():
		unidades.set_target_x(esperam[lugar], nucleo_x + spot(lugar) * espaco)


## O lugar `k` a volta do centro, em passos: 0, +1, -1, +2, -2, ...
static func spot(k: int) -> float:
	if k == 0:
		return 0.0
	var passos := (k + 1) / 2
	return float(passos if k % 2 == 1 else -passos)


## De que lado do rei fica quem o segue: o lado em que ja esta.
static func _lado(x: float, rei_x: float) -> float:
	if is_equal_approx(x, rei_x):
		return ATRAS
	return signf(x - rei_x)
