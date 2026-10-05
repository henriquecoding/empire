# src/core/forest_work.gd — abater, limpar e o que a floresta da a quem esta perto
# (ADR 0070).
#
# Como no Kingdom: o monarca larga uma moeda numa arvore e um construtor livre vai
# abate-la. O tronco da moedas ao cair e deixa o cepo; a flora comum a volta sai com
# ele, e a clareira le-se. So se paga havendo um construtor, e so depois de fundar:
# antes, a moeda cai no chao como sempre. A moeda vai primeiro para uma obra, se a
# arvore estiver no sitio de uma: a obra decide, e quando o andaime se levanta limpa
# o chao dela sem dar moeda (como a fundacao, ADR 0066).
#
# As duas regras de influencia (Influence) leem a floresta de pe a cada passo: o bosque
# apoia a coleta nas provisoes, e a floresta abriga a toca do veado. Cortar sem olhar
# pode custar as duas — e o painel diz isso antes da moeda sair (ForestGuide).
class_name ForestWork
extends RefCounted

const MADEIRA := &"wood"
const CORTE := &"tree"
const MEIO := 0.5


## Uma moeda do rei numa arvore de pe, sem obra a apanha-la: marca-a para abater.
static func mark(largada: Dictionary) -> bool:
	if int(largada[EventRelay.FAIXA]) != Band.Kind.SURFACE or not _founded():
		return false
	var x: float = largada[EventRelay.ONDE]
	var obras := SimLoop.builds
	if CoinTarget.slot_at(obras, x, Band.Kind.SURFACE, SimLoop.state) != CoinTarget.NENHUM:
		return false
	var regras := ForestWatch.rules()
	var w := SimLoop.field.woodland
	var i := w.nearest(x, regras.tree_reach_px)
	var pago := int(largada[EventRelay.QUANTO])
	if i < 0 or w.states[i] != Woodland.State.STANDING or pago < regras.fell_cost:
		return false
	if not WallCrew.available(SimLoop.units, Band.Kind.SURFACE, obras.crew_owner):
		return false
	w.mark(i)
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	if rei >= 0:
		SimLoop.units.carried_coins[rei] += pago - regras.fell_cost
	EventBus.queue(&"coin_spent", [regras.fell_cost, CORTE])
	return true


## De dia, cada construtor sem posto vai a arvore marcada mais perto dele.
static func plan(field: FieldWork, units: UnitSystem, daylight: bool) -> void:
	var w := field.woodland
	var marcadas := w.marked()
	if not daylight or marcadas.is_empty():
		return
	for i in units.count():
		if not _free_builder(units, i):
			continue
		var melhor := -1
		for m in marcadas:
			if melhor < 0 or absf(w.xs[m] - units.xs[i]) < absf(w.xs[melhor] - units.xs[i]):
				melhor = m
		units.set_target_x(units.ids[i], w.xs[melhor])


## O trabalho do passo: os troncos que caem, e o chao das obras que se levantam.
static func work(field: FieldWork, units: UnitSystem, delta: float, daylight: bool) -> void:
	var w := field.woodland
	_clear_built(w)
	var chave := Vector2i(w.revision, field.hunting.burrows.xs.size())
	if chave != w.shelter_key:  # so quando a floresta ou as tocas mudam
		w.shelter_key = chave
		field.hunting.unsheltered = unsheltered(field)
	if not daylight:
		return
	var regras := ForestWatch.rules()
	for m in w.marked():
		var maos := 0
		for i in units.count():
			if _builder(units, i) and absf(units.xs[i] - w.xs[m]) <= regras.tree_reach_px:
				maos += 1
		var especie := Registry.entry(&"flora", StringName(w.species[m])) as FloraData
		if maos > 0 and w.chop(m, delta * maos, especie.fell_work_s):
			if especie.fell_coins > 0:
				SimLoop.drop_coin(w.xs[m], Band.Kind.SURFACE, especie.fell_coins, MADEIRA)


## Quantas moedas a mais a coleta pode dar hoje pelo bosque a volta das provisoes.
static func forage_bonus() -> int:
	var o := SimLoop.arrival
	if SimLoop.field == null or not o.active:
		return 0
	var regras := ForestWatch.rules()
	var tem := support(o.cache_x, regras.grove_feeds_radius, Influence.FORAGE)
	return Influence.bonus(
		tem, regras.grove_feeds_min, regras.grove_feeds_bonus, regras.grove_feeds_cap
	)


## Quantas arvores com a etiqueta `tag` ha de pe a `radius` de `x`.
static func support(x: float, radius: float, tag: StringName) -> int:
	var kinds := Influence.kinds(ForestWatch.flora(), tag)
	return SimLoop.field.woodland.count_near(x, radius, kinds)


## As tocas que vivem de arvores e ficaram sem abrigo: nao dao bicho enquanto assim.
static func unsheltered(field: FieldWork) -> Array[float]:
	var saida: Array[float] = []
	var w := field.woodland
	if not w.generated:
		return saida
	var regras := ForestWatch.rules()
	var abrigo := Influence.kinds(ForestWatch.flora(), Influence.SHELTER)
	var tocas := field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] != String(ForestWatch.ARVORE):
			continue
		if w.count_near(tocas.xs[k], regras.shelter_radius, abrigo) < regras.shelter_min:
			saida.append(tocas.xs[k])
	return saida


## O chao de cada obra que ja se levantou fica limpo, uma vez, sem moeda.
static func _clear_built(w: Woodland) -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.band != Band.Kind.SURFACE or w.cleared_slots.has(vaga.id):
			continue
		if vaga.level == 0 and vaga.state == BuildSlot.State.EMPTY:
			continue
		w.cleared_slots[vaga.id] = true
		w.clear(vaga.x - vaga.width * MEIO, vaga.x + vaga.width * MEIO)


static func _founded() -> bool:
	return not SimLoop.arrival.active or SimLoop.arrival.choice != &""


static func _builder(units: UnitSystem, i: int) -> bool:
	return (
		units.data_ids[i] == RepairWork.REPAIRER
		and units.alive(i)
		and units.healths[i] > 0
		and units.bands[i] == Band.Kind.SURFACE
		and units.owners[i] == SimLoop.builds.crew_owner
		and SimLoop.builds.crew_owner != RecruitSystem.SEM_DONO
	)


static func _free_builder(units: UnitSystem, i: int) -> bool:
	return (
		_builder(units, i)
		and units.job_ids[i] == UnitSystem.NENHUM
		and not units.ids[i] in SimLoop.builds.reserved
	)
