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
# contacto do muro saem de walls.csv, e os da torre de buildings.csv. O que ESTA
# aqui sao posicoes — a resposta a "onde", que o §21 da ao segmento — e sao as
# do greybox, para que o que se mede continue a ser sobre a mesma regiao.
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
const TROPAS_X := 545.0
const ENTRE_TROPAS := 24.0

const MURO := &"stakes"
const TORRE := &"archer_tower"
const POSTO_MURO := &"wall"
const POSTO_TORRE := &"tower"


## Monta a regiao no SimLoop. `flanco` e o lado por onde a mancha vem esta noite;
## `ambos` poe muro nos dois, que e o que dias seguidos obrigam — cada noite
## sorteia o seu lado (§51); `nivel` e o degrau do §10 em que a muralha ja esta,
## porque dez dias de jogo sao dez dias a subi-la e o F1-16 tem de poder pôr o
## muro onde o jogador o teria posto.
static func build(
	flanco: int, arqueiros: int, lanceiros: int, torre: bool, ambos: bool, nivel: int = 1
) -> void:
	SimLoop.builds.clear()
	var largura := float((Registry.entry(&"segments", SEGMENTO) as SegmentData).width_px)
	SimLoop.world_width = largura * ECRAS
	SimLoop.core_x = SimLoop.world_width * MEIO
	SimLoop.passages = PackedFloat32Array()

	_nucleo()
	for lado in [-1, 1] if ambos else [flanco]:
		_muro(lado, nivel)
		if torre:
			_torre(lado)
	_gente(flanco, arqueiros, lanceiros)


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


static func _torre(flanco: int) -> void:
	var dados := Registry.entry(&"buildings", TORRE) as BuildingData
	var vaga := _vaga(dados, SimLoop.core_x + flanco * TORRE_X)
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
	_tropas(&"archer", arqueiros, flanco)
	_tropas(&"spearman", lanceiros, flanco)


## Atras do muro, espacadas. Ficam do lado ameacado porque e a proximidade que
## manda na atribuicao de posto (§52): postas do outro lado, o quadro dava-lhes
## o muro errado e o §07 media uma noite sem arqueiros.
static func _tropas(id: StringName, quantos: int, flanco: int) -> void:
	var dados := Registry.entry(&"units", id) as UnitData
	var base := SimLoop.core_x + flanco * TROPAS_X
	for k in quantos:
		SimLoop.units.spawn(SimLoop.state, dados, MEU_IMPERIO, base + flanco * k * ENTRE_TROPAS)
