# src/core/save_migrations.gd — as migracoes do save, uma por versao (§62, ADR 0007;
# Q-091, o dono a 29/09/2026: "gere todo esse sistema para que seja bem feito").
#
# A regra da ADR 0007 e "save_version desde a 1, com uma migracao por alteracao,
# no mesmo commit". Ate a Q-091 nao havia codigo de migracao nenhum, e os campos
# novos entravam pelo "campo em falta fica no valor por omissao" do from_dict: um
# save antigo carregava, mas ninguem sabia dizer o que lhe faltava nem desde quando.
#
# Cada passo leva um save da versao N a N+1 e escreve, explicitamente, o que essa
# versao acrescentou — com o valor que reproduz o comportamento antigo. Os passos
# correm por ordem, e um save de uma versao futura nao se toca (degrada, §62).
#
# Puro sobre dicionarios de tipos base: nunca instancia objectos (ADR 0007).
class_name SaveMigrations
extends RefCounted

## A versao que o jogo grava. Sobe com cada passo novo, no mesmo commit.
const CURRENT := 2


## Leva `dados` (a moldura inteira do save) ate CURRENT. Devolve o dicionario
## migrado; o de entrada nao muda.
static func migrate(dados: Dictionary) -> Dictionary:
	var d := dados.duplicate(true)
	var versao := int(d.get(&"save_version", CURRENT))
	while versao < CURRENT:
		match versao:
			1:
				_de_1_para_2(d)
		versao += 1
		d[&"save_version"] = versao
	return d


## v2 — o painel de 28 e 29/09/2026: a duracao do dia (Q-091, GB-24), as tocas da
## caca (Q-106), o reino e os vassalos (Q-103), a escolha da sucessao (Q-146), o
## escudeiro (Q-114), quem desertou (Q-144). Tudo com o valor que da o jogo antigo.
static func _de_1_para_2(d: Dictionary) -> void:
	var estado: Dictionary = d.get(&"state", {})
	if not estado.has(&"day_seconds"):
		estado[&"day_seconds"] = 0.0  # zero e "a do clock.csv", como antes do slider
	d[&"state"] = estado
	var mundo: Dictionary = d.get(&"world", {})
	if mundo.is_empty():
		return
	var caca: Dictionary = mundo.get(&"hunting", {})
	if caca.has(&"pending"):
		caca.erase(&"pending")  # o stock do dia por vagas deu lugar as tocas
		caca[&"rabbits"] = []
	mundo[&"hunting"] = caca
	if not mundo.has(&"realm"):
		mundo[&"realm"] = {}
	var sucessao: Dictionary = mundo.get(&"succession", {})
	if not sucessao.has(&"declined"):
		sucessao[&"declined"] = false
	mundo[&"succession"] = sucessao
	var soldo: Dictionary = mundo.get(&"upkeep", {})
	if not soldo.has(&"resting"):
		soldo[&"resting"] = {}
	mundo[&"upkeep"] = soldo
	var classes: Dictionary = mundo.get(&"classes", {})
	if not classes.has(&"squire"):
		classes[&"squire"] = {}
	mundo[&"classes"] = classes
	d[&"world"] = mundo
