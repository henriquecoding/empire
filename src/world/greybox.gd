# src/world/greybox.gd — o segmento zero em formas simples (GB-01, Q-048).
#
# As nove cenas de segmento nao sobreviveram ao ZIP recuperado (Q-048), e sem
# elas nao ha onde jogar. Isto e o substituto honesto: a mesma REGIAO que o §21
# descreve — seis ecras de 640 px, dois slots de construcao e uma passagem por
# segmento — montada em codigo a partir de data/source/segments.csv em vez de
# autorada numa cena.
#
# Nenhum numero de conteudo esta escrito aqui: a largura do segmento, quantos
# slots e quantas passagens saem do SegmentData; os custos, as vidas e os
# trabalhos saem de buildings.csv e walls.csv. O que ESTA aqui sao posicoes —
# onde fica cada coisa dentro da regiao — e isso e autoria de nivel, que e
# exatamente o que um segmento e (§21: "o gerador escolhe segmentos; o segmento
# decide onde se pode construir").
#
# Quando o GB-01 trouxer a cena a serio, este ficheiro desaparece e o que fica
# e a mesma chamada: alguem enche o SimLoop de slots, passagens e gente.
class_name Greybox
extends RefCounted

const SEGMENTO := &"enramados_start_base_01"
## §21: uma regiao tem 4 a 6 ecras. Seis e o limite de cima, e e o que da espaco
## para as duas muralhas de cada lado caberem sem se encostarem ao nucleo.
const ECRAS := 6

const MURO := &"stakes"
const NUCLEO := &"core"
const CANTEIRO := &"farm"
const GALINHEIRO := &"henhouse"
const TREINO := &"training_house"

# Posicoes, relativas ao nucleo. Sao autoria de nivel e nao balanceamento: sao a
# resposta a "onde", e o §21 diz que essa resposta e do segmento.
# O nucleo tem 480 px de largura (buildings.csv) e ocupa +-240. O resto poe-se a
# volta dele de dentro para fora, e a muralha de dentro cabe no ecra a partir do
# nucleo: o §25 quer a estacaria vista ao minuto 3:30, nao procurada.
const MUROS_X := [-1300.0, -600.0, 600.0, 1300.0]
const TREINOS_X := [-300.0, 300.0]
const CANTEIROS_X := [-520.0, -420.0, 420.0, 520.0]
const GALINHEIROS_X := [-760.0, 760.0]
const PASSAGENS_X := [-950.0, 950.0]
# §25: ao minuto 0:20 um vagabundo, ao minuto 1:10 "um segundo vagabundo COM
# ARCO", e a noite 1 e ganha pelos arqueiros. Sao gente por recrutar, e o que os
# distingue e o preco que o §07 lhes da: 1, 3 e 4.
const VAGABUNDOS_X := [-240.0, 320.0, 780.0, 1240.0]
const ARQUEIROS_X := [-620.0, -180.0, 520.0]
const LANCEIROS_X := [-1100.0, 1000.0]

const POSTO_MURO := &"wall"
const POSTO_CANTEIRO := &"farm"
const MEU_IMPERIO := 1
const MEIO := 0.5


## Monta a regiao dentro do SimLoop e devolve o id do monarca.
static func build() -> int:
	var largura := float((Registry.entry(&"segments", SEGMENTO) as SegmentData).width_px)
	SimLoop.world_width = largura * ECRAS
	SimLoop.core_x = SimLoop.world_width * MEIO
	SimLoop.passages = _deslocadas(PASSAGENS_X)

	_nucleo()
	for x in MUROS_X:
		_muro(SimLoop.core_x + x)
	for x in CANTEIROS_X:
		_edificio(SimLoop.core_x + x, CANTEIRO, POSTO_CANTEIRO)
	for x in GALINHEIROS_X:
		_edificio(SimLoop.core_x + x, GALINHEIRO, &"")
	for x in TREINOS_X:
		_edificio(SimLoop.core_x + x, TREINO, &"")

	return _gente()


## O castelo-arvore. Nao e construido nem destruido pelo jogador (§10) — nasce
## de pe, e se cair, cai a partida. Trava as criaturas porque e o que elas vem
## procurar: sem isto atravessavam-no como se fosse um desenho.
static func _nucleo() -> void:
	var dados := Registry.entry(&"buildings", NUCLEO) as BuildingData
	var vaga := _do_edificio(dados, SimLoop.core_x)
	vaga.blocks = true
	SimLoop.builds.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()


## Um sitio de muro, vazio. Os cinco niveis do §10 sao os cinco degraus da
## escada, e sobe-se um de cada vez largando moedas em cima dele (§55).
static func _muro(x: float) -> void:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = MURO
	vaga.blocks = true
	vaga.job_id = POSTO_MURO
	for recurso in Registry.entries(&"walls"):
		var nivel := recurso as WallData
		vaga.costs.append(nivel.cost)
		# O §55 nao da build_work as muralhas. A regra proposta dos edificios —
		# 2 s por moeda de custo — e a unica que o repositorio escreve, e e
		# reversivel: ver docs/QUESTIONS.md, Q-064.
		vaga.works.append(float(nivel.cost) * _segundos_por_moeda())
		vaga.healths.append(nivel.max_health_b)
		vaga.width = maxf(vaga.width, float(nivel.shadow_width))
		vaga.job_slots = maxi(vaga.job_slots, nivel.guard_posts_a)
	SimLoop.builds.post(vaga)


static func _edificio(x: float, id: StringName, posto: StringName) -> void:
	var dados := Registry.entry(&"buildings", id) as BuildingData
	var vaga := _do_edificio(dados, x)
	vaga.job_id = posto
	vaga.job_slots = dados.job_slots
	SimLoop.builds.post(vaga)


static func _do_edificio(dados: BuildingData, x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = dados.id
	vaga.width = float(dados.width_px)
	vaga.yield_per_day = dados.yield_per_day
	vaga.razed_by_rot = dados.destroyed_by_rot_trail
	vaga.costs = PackedInt32Array([dados.cost])
	vaga.works = PackedFloat32Array([dados.build_work])
	vaga.healths = PackedInt32Array([dados.max_health])
	return vaga


## O monarca ao centro, com o que o §06 lhe da a partida, e os vagabundos
## espalhados. Eles nao sao teus: sao o minuto 0:20 a espera de acontecer (§25).
static func _gente() -> int:
	var estado := SimLoop.state
	var monarca := Registry.entry(&"units", &"monarch") as UnitData
	var rei := SimLoop.units.spawn(estado, monarca, MEU_IMPERIO, SimLoop.core_x)
	SimLoop.king_id = rei
	SimLoop.units.carried_coins[SimLoop.units.index_of(rei)] = SimFactory.curve().start_coins

	_por_recrutar(&"vagrant", VAGABUNDOS_X)
	_por_recrutar(&"archer", ARQUEIROS_X)
	_por_recrutar(&"spearman", LANCEIROS_X)
	return rei


## Gente que ainda nao e de ninguem. Passa a ser tua quando o saco dela chegar
## ao recruit_cost do §07 — e por isso um arqueiro custa tres moedas e nao uma.
static func _por_recrutar(id: StringName, posicoes: Array) -> void:
	var dados := Registry.entry(&"units", id) as UnitData
	for x in posicoes:
		SimLoop.units.spawn(SimLoop.state, dados, RecruitSystem.SEM_DONO, SimLoop.core_x + x)


## A regra proposta de buildings.csv, lida do proprio CSV em vez de repetida:
## build_work = 2 s x custo. Sai do canteiro, que e o edificio mais barato.
static func _segundos_por_moeda() -> float:
	var canteiro := Registry.entry(&"buildings", CANTEIRO) as BuildingData
	return canteiro.build_work / float(canteiro.cost)


## Um PackedFloat32Array nao e expressao constante em GDScript, e por isso as
## posicoes acima sao Array e passam por aqui. A coluna que o SimLoop guarda e
## que e compacta — e onde ela e lida, e a cada tick.
static func _deslocadas(xs: Array) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for x in xs:
		saida.append(SimLoop.core_x + x)
	return saida
