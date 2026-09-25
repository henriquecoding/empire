# src/sim/systems/offer_system.gd — a Oferta: uma por noite, no prato (§75).
#
# A mancha chega perto da muralha e fala. Aparece uma frase e um prato no chao;
# aceitar e o Verbo 1 dentro do prato, recusar e nao fazer nada. Passados os
# offer_seconds o prato afunda-se, o que la estava volta ao chao, e conta como
# recusa. As recusas das ultimas noites pesam na massa, com teto (§74, D-04).
#
# Puro. O sorteio entra de fora (o indice ja tirado do fluxo `rot`, §42), e o
# preco que nao e moeda e cobrado por quem chama: aqui decide-se QUANDO o prato
# esta pago, e quem chama diz se o preco ainda existia (settle).
class_name OfferSystem
extends RefCounted

enum { EV_ABRE, EV_PAGA, EV_PAGO, EV_ACEITE, EV_CADUCA }

const CHAVE := &"kind"
const OFERTA := &"offer"
const X := &"x"
const QUANTO := &"amount"
const SEM_OFERTA := &""
const MOEDAS := &"coins"
const ESCALARES: Array[StringName] = [
	&"offer_id", &"dish_x", &"dish_width", &"time_left", &"paid", &"spoken_day", &"night_time"
]

## O que o jogo ja sabe cobrar e dar (Q-087). Uma oferta cujo preco ou efeito
## ainda nao tem sistema nunca e sorteada — dar a Divida por nada era pior do
## que calar a voz. Esta lista e a lista do que falta, como um teste saltado.
const PRECOS_FEITOS: Array[StringName] = [
	&"coins", &"treasury_all", &"troops_below_health", &"marker"
]
const EFEITOS_FEITOS: Array[StringName] = [
	&"rot_pause", &"mass_mult", &"skip_night", &"seed_royal", &"reveal_chapter"
]

var debt: DebtLedger

## A oferta aberta, ou SEM_OFERTA. O prato e onde ela esta e quanto ja la caiu.
var offer_id: StringName = SEM_OFERTA
var dish_x: float = 0.0
var dish_width: float = 0.0
var time_left: float = 0.0
var paid: int = 0
## O dia da ultima noite em que ja houve oferta: uma por noite, mesmo com duas
## manchas (D-05).
var spoken_day: int = 0
## Os dias em que se recusou, desde a ultima aceitacao (§75: volta a zero).
var refused_days: PackedInt32Array = PackedInt32Array()
## As ofertas de uma vez por campanha ja aceites (Q-040).
var used: PackedStringArray = PackedStringArray()
## Segundos desde o crepusculo: a oferta cai entre offer_window_after_dusk.
var night_time: float = 0.0

var _perfil: RotProfile
var _ofertas: Array[OfferData] = []


## As ofertas entram por id crescente, uma vez: o sorteio escolhe um indice e a
## lista tem de ser a mesma em todas as maquinas (§42).
func _init(perfil: RotProfile, ofertas: Array[OfferData]) -> void:
	_perfil = perfil
	debt = DebtLedger.new(perfil)
	_ofertas = ofertas.duplicate()
	_ofertas.sort_custom(
		func(a: OfferData, b: OfferData) -> bool: return String(a.id) < String(b.id)
	)


func active() -> bool:
	return offer_id != SEM_OFERTA


func offer() -> OfferData:
	for o in _ofertas:
		if o.id == offer_id:
			return o
	return null


## As que podem ser ditas hoje. `ctx` e o estado autoritativo visto pela
## gramatica: day, treasury, marker, named, gate, peoples, successor, biome. A
## Divida junta-se aqui, e as de preco alto so entram com o primeiro limiar
## passado (§75: "as ofertas passam a incluir as de preco 3").
func eligible(ctx: Dictionary) -> Array[OfferData]:
	var com := ctx.duplicate()
	com[&"debt"] = debt.debt
	var saida: Array[OfferData] = []
	for o in _ofertas:
		if o.min_day > int(com.get(&"day", 0)) or not Requires.meets(o.requires, com):
			continue
		if o.once_per_campaign and used.has(String(o.id)):
			continue
		if o.debt_delta >= _perfil.debt_tiers[0] and debt.tier() == 0:
			continue
		if o.price_kind in PRECOS_FEITOS and o.effect_kind in EFEITOS_FEITOS:
			saida.append(o)
	return saida


## A primeira oferta da campanha e a mais barata, de proposito (§83, 17:00):
## menos Divida, depois preco em moedas, depois o menor, depois id. Ensina o
## gesto por uma moeda.
static func cheapest(lista: Array) -> OfferData:
	var melhor: OfferData = null
	for o: OfferData in lista:
		if melhor == null or _mais_barata(o, melhor):
			melhor = o
	return melhor


static func _mais_barata(a: OfferData, b: OfferData) -> bool:
	if a.debt_delta != b.debt_delta:
		return a.debt_delta < b.debt_delta
	if (a.price_kind == MOEDAS) != (b.price_kind == MOEDAS):
		return a.price_kind == MOEDAS  # um preco em moedas le-se; uma fraccao, nao
	if a.price_amount != b.price_amount:
		return a.price_amount < b.price_amount
	return String(a.id) < String(b.id)


## Verdadeiro se ja houve alguma oferta nesta campanha.
func ever_spoke() -> bool:
	return spoken_day != 0


## Verdadeiro se esta noite ainda nao falou.
func can_speak(dia: int) -> bool:
	return spoken_day != dia and not active()


## Abre a oferta: a frase e o prato. `largura` e a de um sitio de obra (§75).
func open(o: OfferData, dia: int, x: float, largura: float) -> Dictionary:
	offer_id = o.id
	spoken_day = dia
	dish_x = x
	dish_width = largura
	time_left = _perfil.offer_seconds
	paid = 0
	return {CHAVE: EV_ABRE, OFERTA: o.id, X: x}


## Quantas moedas fecham o prato. Uma oferta em moedas pede o numero dela; as
## outras pedem uma, que e o gesto de aceitar — o resto cobra quem chama (Q-087).
func needed() -> int:
	var o := offer()
	if o == null:
		return 0
	return maxi(1, int(o.price_amount)) if o.price_kind == MOEDAS else 1


## Todos os ticks. So conta o que cai no prato (§75: uma moeda solta perto da
## mancha nao faz nada). Pago, devolve EV_PAGO e espera pelo settle(); passado o
## tempo, caduca e devolve o que la estava.
func tick(delta: float, moedas: CoinSystem, dia: int) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	if not active():
		return eventos
	var caiu := moedas.take_within(dish_x, Band.Kind.SURFACE, dish_width * BuildSystem.METADE)
	if caiu > 0:
		paid += caiu
		eventos.append({CHAVE: EV_PAGA, OFERTA: offer_id, X: dish_x, QUANTO: caiu})
	if paid >= needed():
		eventos.append({CHAVE: EV_PAGO, OFERTA: offer_id, X: dish_x, QUANTO: needed()})
		return eventos
	time_left -= delta
	if time_left <= 0.0:
		eventos.append(_caducar(dia))
	return eventos


## Quem chama cobrou (ou nao) o preco que nao e moeda. Cobrado: a Divida sobe,
## as recusas voltam a zero, e o que sobrou no prato volta ao chao. Nao cobrado
## — o preco deixou de existir — caduca como recusa, sem penalizacao (§75).
func settle(cobrado: bool, dia: int) -> Dictionary:
	if not cobrado:
		return _caducar(dia)
	var o := offer()
	debt.add(o.debt_delta)
	refused_days = PackedInt32Array()
	if o.once_per_campaign:
		used.append(String(o.id))
	paid -= needed()
	var troco := {CHAVE: EV_ACEITE, OFERTA: o.id, X: dish_x, QUANTO: paid}
	offer_id = SEM_OFERTA
	paid = 0
	return troco


## Quantas recusas das ultimas refusal_window_days noites contam hoje (§74).
func refusals(dia: int) -> int:
	var n := 0
	for d in refused_days:
		if d > dia - _perfil.refusal_window_days:
			n += 1
	return n


## Quem paga "Da-me o que ja nao anda": as tropas tuas abaixo de `fraccao` da
## vida, por id crescente (§42). O rei nao e tropa que se de (`poupado`).
static func below_health(unidades: UnitSystem, fraccao: float, poupado: int) -> PackedInt32Array:
	var saida := PackedInt32Array()
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var vida := float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i]))
		if unidades.ids[i] != poupado and vida < fraccao:
			saida.append(unidades.ids[i])
	saida.sort()
	return saida


func to_dict() -> Dictionary:
	var d := Columns.to_dict(self)
	for chave in ESCALARES:
		d[chave] = get(chave)
	d[&"debt"] = debt.debt
	return d


func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)
	for chave in ESCALARES:
		set(chave, d.get(chave, get(chave)))
	offer_id = StringName(offer_id)
	debt.from_dict(d)


func _caducar(dia: int) -> Dictionary:
	refused_days.append(dia)
	var devolve := {CHAVE: EV_CADUCA, OFERTA: offer_id, X: dish_x, QUANTO: paid}
	offer_id = SEM_OFERTA
	paid = 0
	return devolve
