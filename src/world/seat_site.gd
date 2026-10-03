# src/world/seat_site.gd — a sede: o nucleo como uma escada de estagios (ADR 0059).
#
# Ate 03/10/2026 o nucleo nascia castelo, de pe e com vida cheia (§10: "nao e construido
# nem destruido pelo jogador"). O plano do reino troca isso por uma fundacao: o monarca
# chega a uma Clareira, larga ali as moedas da fundacao e a sede sobe como sobe um muro
# — paga-se o degrau, quem esta presente levanta-o (§55), e o estagio de antes continua
# a servir enquanto o seguinte se ergue.
#
# Cada estagio de realm_stages.csv e um degrau: o preco, o trabalho, a vida, os slots de
# contacto e a largura. A largura do nivel 0 e a do marco onde a moeda da sede cai, e
# fica a mesma em todos os estagios (BuildSlot.catch_half): a volta do castelo grande
# continua a haver gente por recrutar. Vive fora do Greybox para que quem monta uma
# regiao de teste monte a MESMA sede.
class_name SeatSite
extends RefCounted


## A sede por fundar — a Clareira —, montada e por publicar.
static func slot(x: float) -> BuildSlot:
	var dados := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = BuildSlot.NUCLEO
	vaga.blocks = true  # trava as criaturas: e o que elas vem procurar
	vaga.razed_by_rot = dados.destroyed_by_rot_trail
	for estagio in RulesFactory.realm_stages():
		vaga.widths.append(float(estagio.width_px))
		if estagio.order == RealmLadder.CLAREIRA:
			continue
		vaga.costs.append(estagio.cost)
		vaga.works.append(estagio.build_work)
		vaga.healths.append(estagio.max_health)
		vaga.contacts.append(estagio.contact_slots)
	vaga.fit()
	return vaga
