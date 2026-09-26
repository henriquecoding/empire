# src/sim/systems/muster.gd — a formacao da noite (§05, §52; auditoria P-C).
#
# Ate a auditoria de 26/09 quem era teu e nao tinha posto seguia o rei para todo
# o lado, tambem de noite: para fora do muro, ou para o meio de um castelo de 480
# px enquanto as criaturas mordiam a borda dele (a vistoria perdia assim a noite
# 2). No Kingdom, quem nao tem trabalho espera na fogueira e os soldados vao para
# tras das muralhas.
#
# Do crepusculo a alvorada, quem e teu, esta vivo e nao tem posto forma-se: quem
# luta (dano > 0) na borda do nucleo do lado de onde a noite vem, para dentro, um
# a seguir ao outro; quem nao luta recolhe ao nucleo. Sem lado dito, todos ao
# nucleo. O escudeiro (`follows_king`) continua com o rei. Q-128.
#
# Puro e estatico: escreve alvos, como o RecruitSystem.follow, e corre depois dele.
class_name Muster
extends RefCounted

const NENHUM := -1


## `nucleo` e o centro (x) e a meia largura (y) do castelo-arvore; `lado` e -1, +1
## ou 0; `espaco` e o passo da fila (follow_spacing_px).
static func plan(
	unidades: UnitSystem, dados: Dictionary, rei: int, nucleo: Vector2, lado: int, espaco: float
) -> void:
	var dono := NENHUM
	var r := unidades.index_of(rei)
	if r != NENHUM:
		dono = unidades.owners[r]
	var lutam: Array[int] = []
	for i in unidades.count():
		if unidades.ids[i] == rei or unidades.owners[i] != dono or not unidades.alive(i):
			continue
		if unidades.job_ids[i] != UnitSystem.NENHUM:
			continue
		var perfil: UnitData = dados.get(unidades.data_ids[i])
		if perfil == null or perfil.tags.has(&"follows_king"):
			continue
		if perfil.damage > 0 and lado != 0:
			lutam.append(unidades.ids[i])
		else:
			unidades.set_target_x(unidades.ids[i], nucleo.x)
	lutam.sort()
	for k in lutam.size():
		var recuo := minf(k * espaco, nucleo.y)
		unidades.set_target_x(lutam[k], nucleo.x + lado * (nucleo.y - recuo))
