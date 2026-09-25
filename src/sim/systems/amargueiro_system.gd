# src/sim/systems/amargueiro_system.gd — quem fica no campo cria raiz (§74).
#
# Uma tropa tua que morre fora das muralhas levanta-se na Alvorada como arvore
# e alimenta a noite seguinte. Tres destinos, pelo Verbo 1: cortar (moedas na
# base, depois de uma noite de pe; rende Lenho Amargo), consagrar (Semente Real;
# vira Marco) ou deixar (pesa para sempre). Puro, em colunas como as tropas.
#
# O que NAO esta aqui: pagar a Semente Real (nao ha ainda quem a guarde — o
# consecrate() e a regra, e o saco e de quem chama); gastar o Lenho na muralha
# de nivel 4 (§74, walls.csv); a raiz que tapa a passagem no subsolo (Ato III,
# §79); e o nome, que e o XIII-05 — ate la ninguem e nomeado.
class_name AmargueiroSystem
extends RefCounted

enum Fate { STANDING, FELLING, MARKER }
enum { EV_RAIZ, EV_SUMIU, EV_PAGA, EV_CORTE, EV_CORTADA }

const NENHUM := -1
const CHAVE := &"kind"
const ID := &"id"
const X := &"x"
const QUANTO := &"amount"
const NOMEADO := &"named"

const CORTAR := &"fell"
const CONSAGRAR := &"consecrate"
## A tag de quem vale o minimo (§74, regra 3: "escala 1 e vagabundo"). Q-086.
const CARNE_BARATA := &"worker"

var ids: PackedInt32Array = PackedInt32Array()
var xs: PackedFloat32Array = PackedFloat32Array()
var bands: PackedByteArray = PackedByteArray()
var tiers: PackedByteArray = PackedByteArray()
var named: PackedByteArray = PackedByteArray()
var nights: PackedInt32Array = PackedInt32Array()
var fates: PackedByteArray = PackedByteArray()
var paid: PackedInt32Array = PackedInt32Array()
var progress: PackedFloat32Array = PackedFloat32Array()
var widths: PackedFloat32Array = PackedFloat32Array()

## O Lenho Amargo: um inteiro e nao uma moeda — nao tem preco (§74, regra 1).
var bitter_wood: int = 0

var _perfil: RotProfile
var _cortar: AmargueiroData
var _consagrar: AmargueiroData
var _tropas: Dictionary


func _init(perfil: RotProfile, destinos: Dictionary, tropas: Dictionary) -> void:
	_perfil = perfil
	_cortar = destinos[CORTAR]
	_consagrar = destinos[CONSAGRAR]
	_tropas = tropas


func count() -> int:
	return ids.size()


func index_of(tree_id: int) -> int:
	return ids.find(tree_id)


## Quantas arvores de pe pesam na massa (§74). Um Marco ja nao pesa; uma arvore
## com a serra dentro ainda pesa, porque ainda esta de pe.
func standing(de_nome: bool) -> int:
	var n := 0
	for i in ids.size():
		if fates[i] != Fate.MARKER and bool(named[i]) == de_nome:
			n += 1
	return n


## Terreno consagrado, em intervalos de x. E o que a Podridao le para abrandar
## (§05) e o que a raiz le para nao nascer.
func markers() -> Array[Vector2]:
	var saida: Array[Vector2] = []
	var r := float(_consagrar.protect_radius_px)
	for i in ids.size():
		if fates[i] == Fate.MARKER:
			saida.append(Vector2(xs[i] - r, xs[i] + r))
	return saida


## A Alvorada. Quem ja estava de pe aguentou mais uma noite; quem morreu desde
## ontem cria raiz ou desaparece, e sai das colunas das tropas de uma vez.
## `nomeados` sao os ids das tropas com nome (§76), vazio ate ao XIII-05.
func at_dawn(
	estado: GameState,
	unidades: UnitSystem,
	obras: BuildSystem,
	core_x: float,
	nomeados: Dictionary = {}
) -> Array[Dictionary]:
	for i in ids.size():
		if fates[i] != Fate.MARKER:
			nights[i] += 1
	var mortos := Array(unidades.ids).filter(
		func(u: int) -> bool: return not unidades.alive(unidades.index_of(u))
	)
	mortos.sort()  # por id, e nao pela ordem das colunas (§42)
	var dentro := inside(obras, core_x)
	var eventos: Array[Dictionary] = []
	for unit_id in mortos:
		var i := unidades.index_of(unit_id)
		var faixa := unidades.bands[i]
		if faixa == Band.Kind.AERIAL:
			faixa = Band.Kind.SURFACE  # nao ha corpos no ar: as voadoras caem
		var x := unidades.xs[i]
		if unidades.owners[i] != RecruitSystem.SEM_DONO and _cria_raiz(x, faixa, dentro):
			var dados: UnitData = _tropas[unidades.data_ids[i]]
			var tree_id := _nascer(estado, x, faixa, dados, nomeados.has(unit_id))
			eventos.append({CHAVE: EV_RAIZ, ID: tree_id, X: x, NOMEADO: nomeados.has(unit_id)})
		else:
			eventos.append({CHAVE: EV_SUMIU, ID: unit_id, X: x})
		unidades.remove(unit_id)
	return eventos


## O "dentro das muralhas": do bordo de fora do muro de pe mais afastado de um
## lado do nucleo ao do outro. Quem cai em cima do muro caiu dentro (Q-086).
func inside(obras: BuildSystem, core_x: float) -> Vector2:
	var dentro := Vector2(core_x, core_x)
	for vaga in obras.standing():
		if not vaga.blocks or not vaga.two_paths() or vaga.band != Band.Kind.SURFACE:
			continue
		dentro.x = minf(dentro.x, vaga.x - vaga.width * BuildSystem.METADE)
		dentro.y = maxf(dentro.y, vaga.x + vaga.width * BuildSystem.METADE)
	return dentro


## Verdadeiro se esta arvore ja aceita este destino. Cortar pede uma noite de pe
## e a segunda alvorada (regra 2); consagrar pode ser logo na primeira.
func ready_for(tree_id: int, destino: StringName) -> bool:
	var i := index_of(tree_id)
	if i == NENHUM or fates[i] != Fate.STANDING:
		return false
	var d := _cortar if destino == CORTAR else _consagrar
	return nights[i] >= maxi(d.nights_standing_required, d.from_dawn - 1)


## Quanto Lenho renderia cortada — o que a cara na casca vale (§74, regra 3).
func wood_of(tree_id: int) -> int:
	var i := index_of(tree_id)
	return _rende(i) if i != NENHUM else 0


## Quanto custa a serra, em moedas (§74). O preco que o rei ve em cima da arvore.
func fell_cost() -> int:
	return _cortar.cost_coins


## Consagrar (§74). Quem chama ja cobrou a Semente Real; aqui e a regra.
func consecrate(tree_id: int) -> bool:
	if not ready_for(tree_id, CONSAGRAR):
		return false
	fates[index_of(tree_id)] = Fate.MARKER
	return true


## Todos os ticks, a seguir ao movimento: as moedas pousadas na base de uma
## arvore que ja aceita a serra pagam o corte, e o corte anda com quem la esta
## — a mesma regra de presenca do §55 (Q-064).
func tick(delta: float, unidades: UnitSystem, moedas: CoinSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var cortadas := PackedInt32Array()
	for i in ids.size():
		if fates[i] == Fate.STANDING and ready_for(ids[i], CORTAR):
			_pagar(i, moedas, eventos)
		elif fates[i] == Fate.FELLING:
			progress[i] += delta * _maos(i, unidades)
			if progress[i] >= _cortar.work_seconds:
				cortadas.append(ids[i])
	for tree_id in cortadas:
		var i := index_of(tree_id)
		bitter_wood += _rende(i)
		eventos.append({CHAVE: EV_CORTADA, ID: tree_id, X: xs[i], QUANTO: _rende(i)})
		_tirar(i)
	return eventos


func to_dict() -> Dictionary:
	var d := Columns.to_dict(self)
	d[&"bitter_wood"] = bitter_wood
	return d


func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)
	bitter_wood = d.get(&"bitter_wood", bitter_wood)


func _cria_raiz(x: float, faixa: int, dentro: Vector2) -> bool:
	for m in markers():
		if x >= m.x and x <= m.y:
			return false
	if faixa == Band.Kind.UNDERGROUND:
		return _perfil.amargueiro_roots_underground
	return _perfil.amargueiro_roots_outside_walls and (x < dentro.x or x > dentro.y)


func _nascer(estado: GameState, x: float, faixa: int, dados: UnitData, nome: bool) -> int:
	var tree_id := estado.take_id()
	ids.append(tree_id)
	xs.append(x)
	bands.append(faixa)
	var escala := 1 if dados.tags.has(CARNE_BARATA) else dados.scale_tier
	tiers.append(clampi(escala, 1, _cortar.yield_by_tier.size()))
	named.append(int(nome))
	nights.append(0)
	fates.append(Fate.STANDING)
	paid.append(0)
	progress.append(0.0)
	widths.append(float(dados.shadow_width))
	return tree_id


func _pagar(i: int, moedas: CoinSystem, eventos: Array[Dictionary]) -> void:
	var valor := moedas.take_within(xs[i], bands[i], widths[i] * BuildSystem.METADE)
	if valor == 0:
		return
	paid[i] += valor
	eventos.append({CHAVE: EV_PAGA, ID: ids[i], X: xs[i], QUANTO: valor})
	if paid[i] >= _cortar.cost_coins:
		paid[i] -= _cortar.cost_coins
		fates[i] = Fate.FELLING
		eventos.append({CHAVE: EV_CORTE, ID: ids[i], X: xs[i], QUANTO: _cortar.cost_coins})


func _maos(i: int, unidades: UnitSystem) -> int:
	var maos := 0
	var raio := widths[i] * BuildSystem.METADE
	for u in unidades.count():
		var tua := unidades.owners[u] != RecruitSystem.SEM_DONO and unidades.alive(u)
		if tua and unidades.bands[u] == bands[i] and absf(unidades.xs[u] - xs[i]) <= raio:
			maos += 1
	return maos


func _rende(i: int) -> int:
	return _cortar.yield_named if named[i] else _cortar.yield_by_tier[tiers[i] - 1]


func _tirar(i: int) -> void:
	for nome in Columns.names(self):
		var coluna: Variant = get(nome)
		coluna.remove_at(i)
		set(nome, coluna)
