# src/sim/systems/campaign_memory.gd — o que a campanha lembra de uma regiao para a
# seguinte (§16, §79; Q-143, CONT-02).
#
# A travessia levava as Sementes, os segredos, o plano, o saco e a fase da classe,
# e zerava o resto: a Divida da Candeia, os povos soltos, retidos e perdidos, e o
# treino do herdeiro. O epilogo (§79) le exatamente a divida e os povos — e uma
# campanha que os zera a cada regiao "lava" as consequencias sem que isso seja
# regra (auditoria de 27/09, N2). A opcao mais simples e mais reversivel: a
# travessia leva-os tal e qual. Fica local o que e da noite desta regiao: as
# recusas por dia, as ofertas ja usadas e a massa da Podridao.
#
# So a travessia os leva. A derrota guarda o que o §16 enumera, e isto nao esta la.
#
# Puro: recebe os sistemas, devolve e le um dicionario em tipos base.
class_name CampaignMemory
extends RefCounted

const DIVIDA := &"campaign_debt"
const SOLTOS := &"campaign_released"
const RETIDOS := &"campaign_kept"
const PERDIDOS := &"campaign_lost"
const TREINO := &"campaign_heir_days"
const DONO := &"campaign_heir_owner"


## Se a memoria vai. Entre regioes, sempre. Depois da ultima, so no Turno: "a
## campanha seguinte comeca com a tua Divida... e com as tuas seis decisoes"; a
## Uniao e o Dominio acabam (§79).
static func carries(ultima: bool, fim: StringName) -> bool:
	return not ultima or fim == Epilogue.TURNO


## O que atravessa, desta regiao.
static func of(divida: DebtLedger, colheita: HarvestSystem, herdeiro: Succession) -> Dictionary:
	return {
		DIVIDA: divida.debt,
		SOLTOS: colheita.released,
		RETIDOS: colheita.kept,
		PERDIDOS: colheita.lost,
		TREINO: herdeiro.days,
		DONO: herdeiro.owner,
	}


## A regiao nova recebe-o. Um legado sem estes campos (uma derrota, ou de antes do
## CONT-02) nao muda nada.
static func apply(
	d: Dictionary, divida: DebtLedger, colheita: HarvestSystem, herdeiro: Succession
) -> void:
	if not d.has(DIVIDA):
		return
	divida.debt = int(d[DIVIDA])
	colheita.released = PackedStringArray(d.get(SOLTOS, PackedStringArray()))
	colheita.kept = PackedStringArray(d.get(RETIDOS, PackedStringArray()))
	colheita.lost = PackedStringArray(d.get(PERDIDOS, PackedStringArray()))
	herdeiro.days = int(d.get(TREINO, 0))
	herdeiro.owner = int(d.get(DONO, Succession.NENHUM))
