# src/core/offer_desk.gd — a ponte entre a Oferta e o resto do jogo (§75).
#
# O OfferSystem decide quando o prato esta pago; isto decide o resto, que toca
# em sistemas que ele nao conhece: QUANDO a mancha fala (a 300 px da muralha
# mais exterior, na janela depois do crepusculo), o sorteio no fluxo `rot`
# (§42), cobrar o preco que nao e moeda, aplicar o efeito, e devolver ao chao o
# que sobrou no prato. Le o SimLoop como as vistas o leem: e chamado de dentro
# do passo, depois de o mundo estar montado (regra 8b).
class_name OfferDesk
extends RefCounted

const FONTE := &"offer"
const FONTE_ZELADOR := &"tender"
## O sitio do capitulo que a oferta revela: a bifurcacao do segmento de abertura
## (§83). Vai no `found` do GameState como um segredo achado (Q-089).
const CAPITULO := "chapter_site"


## Um passo, a seguir ao movimento. Devolve as moedas a largar (o Verbo 1 e do
## SimLoop): o prato que caducou, ou o troco de um prato pago a mais.
static func tick(delta: float, noite: NightWatch) -> Array[Dictionary]:
	var ofertas := noite.offers
	var rot := noite.rot
	var dia := SimLoop.state.day
	if rot.active():
		ofertas.night_time += delta
		if ofertas.can_speak(dia) and _chegou(noite):
			_falar(noite, dia)
	_zelador(noite)
	var larga: Array[Dictionary] = []
	for e in ofertas.tick(delta, SimLoop.coins, dia):
		if int(e[OfferSystem.CHAVE]) == OfferSystem.EV_PAGO:
			e = ofertas.settle(_cobrar(noite, ofertas.offer()), dia)
		if int(e[OfferSystem.CHAVE]) == OfferSystem.EV_ACEITE:
			_dar(noite, e[OfferSystem.OFERTA])
		if e.has(OfferSystem.QUANTO) and int(e[OfferSystem.CHAVE]) >= OfferSystem.EV_ACEITE:
			if int(e[OfferSystem.QUANTO]) > 0:
				larga.append(_moedas(e))
	return larga


## O estado autoritativo visto pela gramatica da §75. So o que existe: a
## tesouraria e o saco do rei; Marcos contam-se no campo; nomes, nos vivos. O
## resto vale zero.
static func context(noite: NightWatch) -> Dictionary:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var saco := SimLoop.units.carried_coins[rei] if rei != UnitSystem.NENHUM else 0
	return {
		&"day": SimLoop.state.day,
		&"treasury": saco,
		&"marker": noite.trees.markers().size(),
		&"named": noite.names.named_count(),
	}


## A distancia da frente da mancha ao bordo de fora da muralha do lado dela. Sem
## muralha, o bordo e o nucleo. Fala na janela: nunca antes do inicio, e no fim
## fala onde estiver.
static func _chegou(noite: NightWatch) -> bool:
	var perfil := SimFactory.rot_profile()
	var janela := perfil.offer_window_after_dusk
	var t := noite.offers.night_time
	if t < janela.x or t > janela.y:
		return false
	return absf(_frente(noite) - _bordo(noite)) <= perfil.offer_trigger_px


static func _frente(noite: NightWatch) -> float:
	var rot := noite.rot
	return rot.position_x() - rot.state.side * rot.state.width * BuildSystem.METADE


static func _bordo(noite: NightWatch) -> float:
	var dentro := Walls.inside(SimLoop.builds, SimLoop.core_x)
	return dentro.y if noite.rot.state.side > 0 else dentro.x


static func _falar(noite: NightWatch, dia: int) -> void:
	# So se diz a oferta cujo preco existe agora: o §75 so a deixa caducar se o
	# preco deixar de existir "a meio" (Q-087).
	var elegiveis := noite.offers.eligible(context(noite)).filter(_ha_preco)
	var largura := _largura_do_prato()
	if elegiveis.is_empty() or largura <= 0.0:
		noite.offers.spoken_day = dia  # calou-se: e a oferta desta noite
		return
	var o := OfferSystem.cheapest(elegiveis)
	if noite.offers.ever_spoke():
		o = elegiveis[RngService.int_range(&"rot", 0, elegiveis.size() - 1)]
	noite.offers.open(o, dia, _frente(noite), largura)


## "Do tamanho de um slot de construcao" (§75): o de um sitio de muralha.
static func _largura_do_prato() -> float:
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths():
			return vaga.width
	return 0.0


static func _ha_preco(o: OfferData) -> bool:
	if o.effect_kind == &"reveal_chapter":
		# So ha o que mostrar se houver um capitulo escondido e ainda por ver.
		return not SimLoop.secrets.chapters.is_empty() and not SimLoop.state.found.has(CAPITULO)
	if o.price_kind == &"troops_below_health":
		return not (
			OfferSystem.below_health(SimLoop.units, o.price_amount, SimLoop.king_id).is_empty()
		)
	return true


## O preco que nao e moeda. Falso quando deixou de existir — caduca (§75).
static func _cobrar(noite: NightWatch, o: OfferData) -> bool:
	var unidades := SimLoop.units
	match o.price_kind:
		&"treasury_all":
			var rei := unidades.index_of(SimLoop.king_id)
			if rei == UnitSystem.NENHUM or unidades.carried_coins[rei] <= 0:
				return false
			EventBus.queue(&"coin_spent", [unidades.carried_coins[rei], FONTE])
			unidades.carried_coins[rei] = 0
		&"troops_below_health":
			var saem := OfferSystem.below_health(unidades, o.price_amount, SimLoop.king_id)
			if saem.is_empty():
				return false
			for unit_id in saem:
				EventBus.queue(&"unit_fled", [unit_id, FONTE])
				unidades.remove(unit_id)
		&"marker":
			var marco := noite.trees.fates.find(AmargueiroSystem.Fate.MARKER)
			if marco == -1:
				return false
			noite.trees.remove_at(marco)
	EventBus.queue(&"coin_spent", [noite.offers.needed(), FONTE])
	return true


static func _dar(noite: NightWatch, offer_id: StringName) -> void:
	var o := Registry.entry(&"rot/offers", offer_id) as OfferData
	var antes := noite.rot.mass()
	match o.effect_kind:
		&"rot_pause":
			noite.rot.pause(o.effect_value)
			EventBus.queue(&"rot_slowed", [0.0, FONTE])
		&"mass_mult":
			noite.rot.scale_mass(o.effect_value)
		&"skip_night":
			noite.skip(SimLoop.state, SimLoop.creatures)
		&"reveal_chapter":
			SimLoop.state.found.append(CAPITULO)
		&"seed_royal":
			SimLoop.state.royal_seeds += int(o.effect_value)
			EventBus.queue(&"seed_royal_gained", [int(o.effect_value), FONTE])
	EventBus.queue(&"rot_fed", [maxf(0.0, antes - noite.rot.mass()), offer_id])


## "Se o Zelador chegar ao nucleo, leva uma tropa nomeada" (§75). Leva a de id
## mais baixo — a mais antiga (§42) — e vai-se com ela. Sem nomeados, espera.
static func _zelador(noite: NightWatch) -> void:
	var nucleo := _nucleo()
	var bichos := SimLoop.creatures
	for c in range(bichos.count() - 1, -1, -1):
		var dados := Registry.entry(&"creatures", bichos.data_ids[c]) as CreatureData
		if not dados.steals_named or nucleo == null:
			continue
		if absf(bichos.xs[c] - nucleo.x) > nucleo.width * BuildSystem.METADE:
			continue
		var levados := PackedInt32Array(noite.names.titles_of.keys())
		if levados.is_empty():
			continue
		levados.sort()
		EventBus.queue(&"unit_fled", [levados[0], FONTE_ZELADOR])
		SimLoop.units.remove(levados[0])
		noite.names.bury(SimLoop.state, SimLoop.units)
		EventBus.queue(&"creature_died", [bichos.ids[c], bichos.xs[c], int(bichos.bands[c])])
		bichos.remove(bichos.ids[c])


static func _nucleo() -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga
	return null


static func _moedas(e: Dictionary) -> Dictionary:
	return {
		EventRelay.ONDE: e[OfferSystem.X],
		EventRelay.FAIXA: Band.Kind.SURFACE,
		EventRelay.QUANTO: e[OfferSystem.QUANTO],
		EventRelay.PORQUE: FONTE,
	}
