# src/world/wall_site.gd — um sitio de muro, como o segmento o autora (§10, §21).
#
# A escada inteira do §10 — os cinco niveis, os dois caminhos, os slots de
# contacto — e o que cada degrau pede alem das moedas (§74): a conquista, o
# Lenho Amargo e o "unico por imperio". Nenhum numero esta aqui: sai tudo de
# walls.csv e economy.csv. Vive fora do Greybox para que quem monta uma regiao
# de teste monte o MESMO muro.
class_name WallSite
extends RefCounted

const MURO := &"stakes"
const POSTO_MURO := &"wall"
const CANTEIRO := &"farm"


## O sitio, montado e por publicar.
static func slot(x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = MURO
	vaga.blocks = true
	vaga.job_id = POSTO_MURO
	var curva := SimFactory.curve()
	for nivel in SimFactory.walls_by_level():
		vaga.costs.append(nivel.cost)
		# O §55 nao da build_work as muralhas: 2 s por moeda, como os edificios
		# (Q-064, reversivel).
		vaga.works.append(float(nivel.cost) * seconds_per_coin())
		vaga.healths.append(nivel.max_health_b)
		vaga.healths_a.append(nivel.max_health_a)
		vaga.posts_a.append(nivel.guard_posts_a)
		vaga.posts_b.append(nivel.guard_posts_b)
		vaga.contacts.append(nivel.contact_slots)
		vaga.conquests.append(String(nivel.requires_conquest))
		vaga.unique.append(int(nivel.unique_per_kingdom))
		# §74: um Lenho dispensa a conquista do nivel dele; o bastiao pede os seus.
		var lenho := 1 if nivel.level == curva.bitter_wood_wall_level else 0
		vaga.woods.append(curva.bitter_wood_bastion_cost if nivel.unique_per_kingdom else lenho)
		vaga.width = maxf(vaga.width, float(nivel.shadow_width))
	# §10: o nivel 1 e a base comum aos dois caminhos, e a escolha e do jogador.
	# Enquanto a roda do rei nao existir (Q-067) fica a fortificacao (Q-070).
	vaga.path = BuildSlot.Path.FORTIFICACAO
	return vaga


## A regra proposta dos edificios — build_work por moeda de custo, a do canteiro
## — e a unica que o repositorio escreve (Q-064).
static func seconds_per_coin() -> float:
	var canteiro := Registry.entry(&"buildings", CANTEIRO) as BuildingData
	return canteiro.build_work / float(canteiro.cost)
