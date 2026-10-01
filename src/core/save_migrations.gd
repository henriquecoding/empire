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
const CURRENT := 6
const ANTES_DOS_REINOS := 5
## A ultima versao de antes do mundo continuo (Q-173): o passo dela da as terras geradas.
const ANTES_DO_MUNDO := 3
## A ultima versao de antes das respostas do painel de 30/09/2026 (ADR 0041).
const ANTES_DAS_CLASSES := 4


## Leva `dados` (a moldura inteira do save) ate CURRENT. Devolve o dicionario
## migrado; o de entrada nao muda.
static func migrate(dados: Dictionary) -> Dictionary:
	var d := dados.duplicate(true)
	var versao := int(d.get(&"save_version", CURRENT))
	while versao < CURRENT:
		match versao:
			1:
				_de_1_para_2(d)
			2:
				_de_2_para_3(d)
			ANTES_DO_MUNDO:
				_de_3_para_4(d)
			ANTES_DAS_CLASSES:
				SaveMigrationsV5.apply(d)
			ANTES_DOS_REINOS:
				SaveMigrationsV6.apply(d)
		versao += 1
		d[&"save_version"] = versao
	return d


## v2 — o painel de 28 e 29/09/2026: a duracao do dia (Q-091, GB-24), as tocas da
## caca (Q-106), o reino e os vassalos (Q-103), a escolha da sucessao (Q-146), o
## escudeiro (Q-114), quem desertou (Q-144), e os archotes que passam para o
## armazenamento do rei (Q-153). Tudo com o valor que da o jogo antigo.
static func _de_1_para_2(d: Dictionary) -> void:
	if not d.get(&"state", {}) is Dictionary or not d.get(&"world", {}) is Dictionary:
		return  # nao e um save: o SaveService recusa-o a seguir, como antes
	var estado := _dict(d, &"state")
	if not estado.has(&"day_seconds"):
		estado[&"day_seconds"] = 0.0  # zero e "a do clock.csv", como antes do slider
	d[&"state"] = estado
	var mundo := _dict(d, &"world")
	if mundo.is_empty():
		return
	var caca := _dict(mundo, &"hunting")
	if caca.has(&"pending"):
		caca.erase(&"pending")  # o stock do dia por vagas deu lugar as tocas
		caca[&"rabbits"] = []
	mundo[&"hunting"] = caca
	if not mundo.has(&"realm"):
		mundo[&"realm"] = {}
	var sucessao := _dict(mundo, &"succession")
	if not sucessao.has(&"declined"):
		sucessao[&"declined"] = false
	mundo[&"succession"] = sucessao
	var soldo := _dict(mundo, &"upkeep")
	if not soldo.has(&"resting"):
		soldo[&"resting"] = {}
	mundo[&"upkeep"] = soldo
	var classes := _dict(mundo, &"classes")
	if not classes.has(&"squire"):
		classes[&"squire"] = {}
	var archote := _dict(mundo, &"torch")
	if not classes.has(&"storage"):
		var levados := int(archote.get(&"torches", 0))
		classes[&"storage"] = {&"kind": &"royal_belt", &"items": {&"torch": levados}}
	archote.erase(&"torches")
	mundo[&"torch"] = archote
	mundo[&"classes"] = classes
	d[&"world"] = mundo


## v3 — o relatorio Kingdom de 29/09 (Q-166): o cerco. A marcha guarda a firmeza que
## ja tirou a cada fortaleza; um save de antes nao tirou nenhuma. Um reino vazio (sem
## marcha nunca gravada) fica vazio: a marcha nasce sem cerco.
static func _de_2_para_3(d: Dictionary) -> void:
	var mundo := _dict(d, &"world")
	var reino := _dict(mundo, &"realm")
	if reino.is_empty():
		return
	var marcha := _dict(reino, &"march")
	if not marcha.has(&"sieges"):
		marcha[&"sieges"] = {}
	reino[&"march"] = marcha
	mundo[&"realm"] = reino
	d[&"world"] = mundo


## v4 — o mundo continuo (Q-173, ADR 0038): as terras geradas ao andar. Um save de antes
## nao gerou nenhuma; o plano faz-se de novo pela semente, e gera-se ao andar.
static func _de_3_para_4(d: Dictionary) -> void:
	var mundo := _dict(d, &"world")
	if mundo.is_empty() or mundo.has(&"wilds"):
		return
	mundo[&"wilds"] = {}
	d[&"world"] = mundo


## O dicionario em `chave`, ou um vazio: um save estragado ou de fora nao pode
## rebentar a migracao ao atribuir outro tipo a um Dictionary (§62, ADR 0007).
static func _dict(d: Dictionary, chave: StringName) -> Dictionary:
	var valor: Variant = d.get(chave, {})
	return valor if valor is Dictionary else {}
