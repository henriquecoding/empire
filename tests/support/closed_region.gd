# tests/support/closed_region.gd — a regiao fechada do §07, montada em codigo.
#
# E o greybox reduzido ao que a receita do §07 nomeia: "um muro, seis arqueiros".
# Nada de canteiros, de pesqueiro, de torre alta nem de vagabundos por recrutar —
# o `src/world/greybox.gd` tem tudo isso e e por isso que ele serve para JOGAR.
# Para AFINAR e preciso o contrario: um mundo onde so esta o que se esta a medir.
#
# Vive em tests/ e nao em src/world/ porque nao e um sitio onde se joga: e o
# banco de ensaio do §07, e nada no jogo o carrega. Sai do export com o resto da
# pasta.
#
# Nenhum numero de balanceamento esta aqui: a vida, os postos e os slots de
# contacto do muro saem de walls.csv, e os da torre e do nucleo de buildings.csv.
# O que ESTA aqui sao posicoes — a resposta a "onde", que o §21 da ao segmento —
# e sao as do greybox, para que o que se mede continue a ser sobre a mesma regiao.
extends RefCounted

const MEU_IMPERIO := 1
const SEGMENTO := &"enramados_start_base_01"
const ECRAS := 6
const MEIO := 0.5

## Medidas do nucleo para o flanco. A torre fica ATRAS do muro — o §07 diz que
## ela e o multiplicador e o muro o denominador, e um multiplicador do lado de
## fora era so mais uma coisa para as criaturas derrubarem primeiro.
const MURO_X := 600.0
const TORRE_X := 520.0
const TORRE_ALTA_X := 470.0
const TROPAS_X := 545.0
const ENTRE_TROPAS := 24.0
## Fora do muro, como no greybox: quem sobe do subsolo sobe onde a defesa o pode
## encontrar, e nao ja dentro do perimetro.
const PASSAGEM_X := 950.0

const MURO := &"stakes"
const TORRE := &"archer_tower"
## §07: "o Alado obriga a torre alta". E a unica obra que atinge a faixa aerea
## (Q-006), e por isso a unica que muda alguma coisa a partir do dia 4.
const TORRE_ALTA := &"high_tower"
const POSTO_MURO := &"wall"
const POSTO_TORRE := &"tower"


## Monta a regiao no SimLoop. `flanco` e o lado por onde a mancha vem esta noite;
## `ambos` poe muro nos dois, que e o que dias seguidos obrigam — cada noite
## sorteia o seu lado (§51); `niveis` sao os degraus do §10 em que cada muralha
## ja esta, porque dez dias de jogo sao dez dias a subi-la e o F1-16 tem de poder
## pôr o muro onde o jogador o teria posto.
##
## Um degrau por flanco, e nao um so para os dois: o Bastiao e "unico por
## imperio" (§10), e uma tabela que so soubesse pôr o mesmo degrau dos dois lados
## media sempre uma defesa que o jogo nao deixa ter. `niveis[0]` e a esquerda,
## `niveis[1]` a direita; com um valor so, os dois lados levam-no.
static func build(
	flanco: int,
	arqueiros: int,
	lanceiros: int,
	torres: Array[StringName],
	ambos: bool,
	niveis: PackedInt32Array
) -> void:
	SimLoop.builds.clear()
	var largura := float((Registry.entry(&"segments", SEGMENTO) as SegmentData).width_px)
	SimLoop.world_width = largura * ECRAS
	SimLoop.core_x = SimLoop.world_width * MEIO
	# §07: o Cavador "passa pela faixa subterranea", e sobe por uma passagem
	# (F1-09). Sem passagem nenhuma, o dia 10 — que e o dele — mede-se com ele
	# preso debaixo do chao, e o criterio do §66 acaba no dia 9 sem o dizer.
	# Ficam onde o greybox as poe: fora do muro, nos dois flancos.
	SimLoop.passages = PackedFloat32Array(
		[SimLoop.core_x - PASSAGEM_X, SimLoop.core_x + PASSAGEM_X]
	)

	_nucleo()
	for lado in [-1, 1] if ambos else [flanco]:
		_muro(lado, _degrau(niveis, lado))
		for id in torres:
			_torre(lado, id)
	_gente(flanco, arqueiros, lanceiros)


## O degrau deste flanco. Esquerda primeiro, porque e o lado negativo do eixo.
static func _degrau(niveis: PackedInt32Array, lado: int) -> int:
	if niveis.is_empty():
		return 1
	return niveis[0] if lado < 0 or niveis.size() == 1 else niveis[1]


## O castelo-arvore (§10): nasce de pe, nao se constroi, e se cair cai a partida.
## E o que as criaturas vem procurar — sem ele nao ha para onde caminharem.
static func _nucleo() -> void:
	var dados := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	var vaga := _vaga(dados, SimLoop.core_x)
	vaga.blocks = true
	SimLoop.builds.post(vaga)
	_levantar(vaga)


## O muro do §07, ja de pe. Nao se constroi durante o cenario: a economia esta
## fora da receita, e um muro por levantar media outra coisa.
static func _muro(flanco: int, nivel: int) -> void:
	var vaga := BuildSlot.new()
	vaga.x = SimLoop.core_x + flanco * MURO_X
	vaga.kind = MURO
	vaga.blocks = true
	vaga.job_id = POSTO_MURO
	for degrau in SimFactory.walls_by_level():
		vaga.costs.append(degrau.cost)
		vaga.healths.append(degrau.max_health_b)
		vaga.healths_a.append(degrau.max_health_a)
		vaga.posts_a.append(degrau.guard_posts_a)
		vaga.posts_b.append(degrau.guard_posts_b)
		vaga.contacts.append(degrau.contact_slots)
		vaga.width = maxf(vaga.width, float(degrau.shadow_width))
	vaga.path = BuildSlot.Path.FORTIFICACAO  # Q-070, como no greybox
	SimLoop.builds.post(vaga)
	_levantar(vaga, nivel)


## Uma torre por id. A alta fica um pouco mais para dentro do que a de arqueiros,
## para que as duas possam existir ao mesmo tempo sem se sobreporem no mesmo x.
static func _torre(flanco: int, id: StringName) -> void:
	var dados := Registry.entry(&"buildings", id) as BuildingData
	var recuo := TORRE_X if id == TORRE else TORRE_ALTA_X
	var vaga := _vaga(dados, SimLoop.core_x + flanco * recuo)
	vaga.job_id = POSTO_TORRE
	vaga.job_slots = dados.job_slots
	SimLoop.builds.post(vaga)
	_levantar(vaga)


static func _vaga(dados: BuildingData, x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.kind = dados.id
	vaga.width = float(dados.width_px)
	vaga.effects = dados.effect_params
	vaga.costs = PackedInt32Array([dados.cost])
	vaga.works = PackedFloat32Array([dados.build_work])
	vaga.healths = PackedInt32Array([dados.max_health])
	vaga.contacts = PackedInt32Array([dados.contact_slots])
	return vaga


## De pe e inteira. O nivel entra depois do post() porque e o post() que da o id,
## e a vida do degrau le-se da escada que ja la esta.
static func _levantar(vaga: BuildSlot, nivel: int = 1) -> void:
	vaga.level = clampi(nivel, 1, vaga.costs.size())
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()


## O monarca e quem defende, ja recrutados: o cenario comeca onde a decisao do
## jogador acabou. Recrutar seis arqueiros media a economia do §06 e nao o
## combate do §07 — e sao duas perguntas, com dois tickets.
static func _gente(flanco: int, arqueiros: int, lanceiros: int) -> void:
	var monarca := Registry.entry(&"units", &"monarch") as UnitData
	SimLoop.king_id = SimLoop.units.spawn(SimLoop.state, monarca, MEU_IMPERIO, SimLoop.core_x)
	# O saco cheio: a manutencao do §06 (Q-124) e paga pela economia, que e a
	# outra pergunta. Sem isto os arqueiros desertavam e a noite media a divida.
	SimLoop.units.carried_coins[SimLoop.units.index_of(SimLoop.king_id)] = monarca.coin_capacity
	_tropas(&"archer", arqueiros, flanco)
	_tropas(&"spearman", lanceiros, flanco)


## Atras do muro, espacadas PARA DENTRO. Ficam do lado ameacado porque e a
## proximidade que manda na atribuicao de posto (§52): postas do outro lado, o
## quadro dava-lhes o muro errado e o §07 media uma noite sem arqueiros.
##
## O sentido do espacamento nao e detalhe: a fila comecava a 55 px do muro e
## afastava-se dele, e por isso a quarta tropa em diante nascia do lado DE FORA
## — no caminho da mancha, e nao atras da muralha que a devia proteger. Com as
## seis do §07 ja acontecia; com as doze da defesa do decimo dia, metade.
static func _tropas(id: StringName, quantos: int, flanco: int) -> void:
	var dados := Registry.entry(&"units", id) as UnitData
	var base := SimLoop.core_x + flanco * TROPAS_X
	for k in quantos:
		SimLoop.units.spawn(SimLoop.state, dados, MEU_IMPERIO, base - flanco * k * ENTRE_TROPAS)
