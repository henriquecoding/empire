# src/world/greybox.gd — o segmento zero em formas simples (GB-01, Q-048).
#
# As nove cenas de segmento nao sobreviveram ao ZIP recuperado (Q-048), e sem
# elas nao ha onde jogar. Isto e o substituto honesto: a mesma REGIAO que o §21
# descreve — seis ecras de 640 px, dois slots de construcao e uma passagem por
# segmento — montada em codigo a partir de data/source/segments.csv em vez de
# autorada numa cena.
#
# Nenhum numero de conteudo esta aqui (sai de segments.csv, buildings.csv e
# walls.csv). O que ESTA aqui sao posicoes, que sao autoria de nivel (§21: "o
# gerador escolhe segmentos; o segmento decide onde se pode construir"). Quando o
# GB-01 trouxer a cena a serio, isto desaparece e fica a mesma chamada.
class_name Greybox
extends RefCounted

const SEGMENTO := &"enramados_start_base_01"
## §21: uma regiao tem 4 a 6 ecras. Seis dao espaco as duas muralhas de cada lado.
const ECRAS := 6
const BRAVIAS_ECRAS := 6  # de terra brava para la de cada base (Q-154)

const CANTEIRO := &"farm"
const PESQUEIRO := &"fishery"
const GALINHEIRO := &"henhouse"
const TREINO := &"training_house"
const COZINHA := &"kitchen"
const CELEIRO := &"granary"
const TORRE := &"archer_tower"
const TORRE_ALTA := &"high_tower"
const ESCUDEIRO := &"squire"

# Posicoes, relativas ao nucleo. Sao autoria de nivel e nao balanceamento: sao a
# resposta a "onde", e o §21 diz que essa resposta e do segmento.
# O nucleo tem 480 px; o resto a volta dele, de dentro para fora (§25: 3:30).
const MUROS_X := [-1300.0, -600.0, 600.0, 1300.0]
# A Casa de Treino e unica por imperio; do outro lado, a cozinha do cozinheiro (§09).
const TREINOS_X := [-300.0]
const COZINHAS_X := [300.0]
# O celeiro do §06 (circuito 2) fica FORA do muro de fora: a decisao de o pôr a
# render e tambem a de mandar o cozinheiro ao sitio arriscado (§21).
const CELEIROS_X := [1450.0]
# E a casa do herdeiro (§15) do outro lado, a oeste: o rei novo nasce la (Q-133).
const HERDEIROS_X := [-1450.0]
const CANTEIROS_X := [-520.0, -420.0, 420.0, 520.0]
const TORRES_X := [-680.0, 680.0]
const GALINHEIROS_X := [-820.0, 820.0]
# UM pesqueiro, e por duas razoes que coincidem: o segmento tem uma agua e nao
# duas (segments.csv, coluna `resource`), e com ele a regiao fica com as SETE
# fontes do perfil `balanced` do §06 — quatro canteiros, dois galinheiros e um
# pesqueiro. E isso que faz do dia da asfixia medido aqui um numero sobre ESTE
# jogo e nao sobre um slider. Fica entre a torre alta e o muro de fora.
const PESQUEIROS_X := [1200.0]
const TORRES_ALTAS_X := [-1100.0, 1100.0]
const PASSAGENS_X := [-950.0, 950.0]
# Os segredos do segmento, pelo `location` de secrets.csv. §25: ao minuto 2:00 a
# estatua meio enterrada; ao 11:00, a camara atras da passagem de fora, com a
# Semente Real. E a bifurcacao a leste onde cai o capitulo revelado (§83).
const SEGREDOS_X := {&"under_vegetation": 360.0, &"behind_passage": -1180.0}
const CAMARA_W := 64.0
const BIFURCACAO_X := 1800.0
const RUINA_X := -360.0  # §79: o diario 1, "numa ruina dentro das tuas muralhas"
# §25: gente por recrutar, ao preco do §07 (1, 3 e 4), e nunca dentro de um sitio
# de obra (auditoria de 26/09, D5). Q-110 (o dono, 29/09/2026): "os vagabundos nao
# sao meus trabalhadores, devo procura-los em acampamentos; ao iniciar o imperio
# tera algumas tropas sem funcoes". Os dois ao pe do castelo ja sao teus; os
# outros dois estao nos acampamentos, fora das muralhas de fora.
const VAGABUNDOS_X := [-230.0, 230.0, -1650.0, 1650.0]
const JA_TEUS := 2
const ARQUEIROS_X := [-740.0, -180.0, 180.0]
const LANCEIROS_X := [-990.0, 1040.0]
const ACAMPAMENTOS_X := [-1650.0, 1650.0]  # o vagabundo de cada alvorada (Q-122)
# §83: "Um pouco a esquerda, fora do muro, esta uma arvore preta com uma cara na
# casca." Logo depois da estacaria de dentro, entre a torre e o galinheiro, com a
# escala de uma tropa (§22).
const AMARGUEIRO_VELHO_X := -750.0
const AMARGUEIRO_VELHO_ESCALA := 2

const POSTO_CANTEIRO := &"farm"
const POSTO_TORRE := &"tower"
const MEU_IMPERIO := 1
const MEIO := 0.5


## Um jogo novo: a regiao e quem la vive. Devolve o id do monarca.
static func build() -> int:
	region()
	var faixa := int(Band.Kind.SURFACE)
	var x := SimLoop.core_x + AMARGUEIRO_VELHO_X
	SimLoop.night.amargueiros.plant_old(x, faixa, AMARGUEIRO_VELHO_ESCALA)
	return _gente()


## SO o que o segmento autora: a largura, os sitios de obra e as passagens
## (§21). E o que se volta a montar ao retomar um save — a gente vem do
## ficheiro, e chama-la outra vez gastava ids que o save ja tinha dado (§45).
static func region() -> void:
	SimLoop.builds.clear()
	var largura := float((Registry.entry(&"segments", SEGMENTO) as SegmentData).width_px)
	SimLoop.world_width = largura * ECRAS
	SimLoop.wild_px = largura * BRAVIAS_ECRAS  # o mapa muito mais largo (Q-154)
	SimLoop.core_x = SimLoop.world_width * MEIO
	SimLoop.passages = _deslocadas(PASSAGENS_X)
	SimLoop.field.camps = _deslocadas(ACAMPAMENTOS_X)
	_segredos()

	_nucleo()
	for x in MUROS_X:
		_muro(SimLoop.core_x + x)
	for x in CANTEIROS_X:
		_edificio(SimLoop.core_x + x, CANTEIRO, POSTO_CANTEIRO)
	for x in GALINHEIROS_X:
		_edificio(SimLoop.core_x + x, GALINHEIRO, &"")
	for x in PESQUEIROS_X:
		_edificio(SimLoop.core_x + x, PESQUEIRO, &"")
	for x in TREINOS_X:
		_edificio(SimLoop.core_x + x, TREINO, &"")
	for x in COZINHAS_X:
		_edificio(SimLoop.core_x + x, COZINHA, &"")
	# §07: "a torre nao da dano — da certeza". A alta atinge a camada aerea, e o
	# §07 obriga-a a partir do dia 4 (o Alado): ha sitio para ela desde o dia 1.
	for x in TORRES_X:
		_edificio(SimLoop.core_x + x, TORRE, POSTO_TORRE)
	for x in TORRES_ALTAS_X:
		_edificio(SimLoop.core_x + x, TORRE_ALTA, POSTO_TORRE)
	for x in CELEIROS_X:
		_edificio(SimLoop.core_x + x, CELEIRO, &"")
	Cavities.author()  # o subsolo e a boca das passagens (P-I)
	for x in HERDEIROS_X:  # depois dos de antes: os ids deles nao mudam (§45)
		_edificio(SimLoop.core_x + x, Succession.CASA, &"")
	Campfires.author()  # as fogueiras do archote (Q-029)
	Wards.author()  # os sinos que afastam o Zelador (Q-100)
	BowRacks.author()  # e a banca do arco, por ultimo (Q-165)


static func _segredos() -> void:
	SimLoop.secrets.clear()
	for recurso in Registry.entries(&"lore/secrets"):
		var dados := recurso as SecretData
		var x: float = dados.place_px if dados.place_px else SEGREDOS_X.get(dados.location, NAN)
		if not is_nan(x):  # cada estatua tem o seu sitio (Q-016)
			SimLoop.secrets.post(dados, SimLoop.core_x + x, CAMARA_W)
	SimLoop.secrets.chapters.append(SimLoop.core_x + BIFURCACAO_X)
	for recurso in Registry.entries(SimFactory.TABELA_DIARIOS):
		var diario := recurso as JournalData
		if diario.where_kind == ChapterPlan.RUINA:
			SimLoop.secrets.post_journal(diario.id, SimLoop.core_x + RUINA_X, CAMARA_W)


## Se o bioma deste segmento sustenta este edificio (§06, §21): sem exigencia cabe
## em qualquer lado; com ela, so onde o segmento tem esse recurso.
static func cabe_no_bioma(dados: BuildingData) -> bool:
	if dados.requires_biome_feature.is_empty():
		return true
	return dados.requires_biome_feature == recurso()


## O recurso que o segmento desta regiao oferece (§21, coluna `resource`).
static func recurso() -> StringName:
	return (Registry.entry(&"segments", SEGMENTO) as SegmentData).resource


## O castelo-arvore. Nao e construido nem destruido pelo jogador (§10) — nasce
## de pe, e se cair, cai a partida. Trava as criaturas porque e o que elas vem
## procurar: sem isto atravessavam-no como se fosse um desenho.
static func _nucleo() -> void:
	var dados := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	var vaga := slot_of(dados, SimLoop.core_x)
	vaga.blocks = true
	SimLoop.builds.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()


## Um sitio de muro, vazio. Os cinco niveis do §10 sao os cinco degraus da
## escada, e sobe-se um de cada vez largando moedas em cima dele (§55).
static func _muro(x: float) -> void:
	# A escada do §10 e o que cada degrau pede alem das moedas (§74) vivem no
	# WallSite, para que quem monta uma regiao de teste monte o mesmo muro.
	SimLoop.builds.post(WallSite.slot(x))


## O §06 da tres edificios um bioma obrigatorio — pesqueiro/agua, corte de
## madeira/bosque, poco de minerio/rocha — e ate aqui o requires_biome_feature
## nao era lido por ninguem. Quem o le e quem POE: um sitio de obra que o bioma
## nao sustenta nao chega a existir, e por isso nao ha um `if` disto no tick.
static func _edificio(x: float, id: StringName, posto: StringName) -> void:
	var dados := Registry.entry(&"buildings", id) as BuildingData
	if not cabe_no_bioma(dados):
		return
	var vaga := slot_of(dados, x)
	vaga.job_id = posto
	vaga.job_slots = dados.job_slots
	SimLoop.builds.post(vaga)


static func slot_of(dados: BuildingData, x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = dados.id
	vaga.width = float(dados.width_px)
	vaga.yield_per_day = dados.yield_per_day
	vaga.razed_by_rot = dados.destroyed_by_rot_trail
	vaga.effects = dados.effect_params
	vaga.effects_b = dados.variant_params  # a outra variante da melhoria (Q-136)
	vaga.costs = PackedInt32Array([dados.cost])
	vaga.works = PackedFloat32Array([dados.build_work])
	vaga.healths = PackedInt32Array([dados.max_health])
	vaga.contacts = PackedInt32Array([dados.contact_slots])
	return vaga


## O monarca ao centro, com o que o §06 lhe da a partida, e os vagabundos
## espalhados. Eles nao sao teus: sao o minuto 0:20 a espera de acontecer (§25).
static func people() -> int:
	return _gente()


static func _gente() -> int:
	var estado := SimLoop.state
	var monarca := Registry.entry(&"units", &"monarch") as UnitData
	var rei := SimLoop.units.spawn(estado, monarca, MEU_IMPERIO, SimLoop.core_x)
	SimLoop.king_id = rei
	SimLoop.units.carried_coins[SimLoop.units.index_of(rei)] = SimFactory.curve().start_coins

	_por_recrutar(&"vagrant", VAGABUNDOS_X)
	for k in JA_TEUS:  # os primeiros, sem funcao, ja sao teus (Q-110)
		SimLoop.units.owners[SimLoop.units.index_of(rei + 1 + k)] = MEU_IMPERIO
	_por_recrutar(&"archer", ARQUEIROS_X)
	_por_recrutar(&"spearman", LANCEIROS_X)
	# §08: "Escudeiro acompanha e apanha moedas caidas" — nasce com o Monarca, e
	# por ultimo: os ids de quem ja la estava nao mudam (os saves e os testes).
	SimLoop.units.spawn(estado, Registry.entry(&"units", ESCUDEIRO), MEU_IMPERIO, SimLoop.core_x)
	return rei


## Gente que ainda nao e de ninguem. Passa a ser tua quando o saco dela chegar
## ao recruit_cost do §07 — e por isso um arqueiro custa tres moedas e nao uma.
static func _por_recrutar(id: StringName, posicoes: Array) -> void:
	var dados := Registry.entry(&"units", id) as UnitData
	for x in posicoes:
		SimLoop.units.spawn(SimLoop.state, dados, RecruitSystem.SEM_DONO, SimLoop.core_x + x)


## Um PackedFloat32Array nao e expressao constante em GDScript: as posicoes acima sao
## Array e passam por aqui. A coluna que o SimLoop guarda e lida a cada tick.
static func _deslocadas(xs: Array) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for x in xs:
		saida.append(SimLoop.core_x + x)
	return saida
