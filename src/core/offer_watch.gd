# src/core/offer_watch.gd — a voz da Podridao: a oferta, a divida, e o que a
# oferta da (§75).
#
# A NightWatch tem a mancha; isto tem o que ela diz. Vive a parte pela mesma
# razao que a NightWatch vive fora do SimLoop: nao e um passo do §43, e o que o
# passo 2 faz — e sao tres pontas (falar, cobrar, dar) que cresciam la dentro.
#
# A ponte que a pureza obriga: o sorteio da oferta sai do fluxo `rot` (§42), os
# factos da gramatica juntam-se aqui a partir de sistemas que nao se conhecem,
# e o rot_fed da §46 — "alimentar", que a §75 diz ter finalmente interface —
# sai quando uma oferta e aceite.
class_name OfferWatch
extends RefCounted

## §83, minuto 17:00: a primeira oferta da campanha e a mais barata, de proposito
## — "Nada. So quero ver.", uma moeda. Ensina o gesto, e e a unica sem nada de mau.
const PRIMEIRA := &"just_looking"

var offers: OfferSystem
var debt: DebtLedger
## O Zelador (§75): so anda com a Divida no limiar tender_from_debt.
var tender: Tender
## unit_id -> chave do titulo (§76). Quem o escreve e o sistema dos nomes; aqui
## so se le, para saber quem pode pagar uma oferta de nomes.
var titles: Dictionary = {}
## Quantas vezes ela ja falou nesta campanha. A primeira e a do §83.
var spoken: int = 0
## Capitulos por revelar (§77): o que "Nada. So quero ver." da. O XIII-07 gasta-os.
var reveals: int = 0
## "Um herdeiro": a ganancia a zero ate este dia, e a que volta depois (§15, Q-099).
var greed_until: int = 0
var greed_kept: int = 0

var _moedas: CoinSystem
var _tropas: UnitSystem
var _obras: BuildSystem
var _dados_tropas: Dictionary
var _pausa: float = 0.0


## As mesmas colunas da NightWatch: e nelas que o preco cai e de onde sai.
func _init(moedas: CoinSystem, tropas: UnitSystem, obras: BuildSystem) -> void:
	offers = SimFactory.offers()
	debt = DebtLedger.new(SimFactory.rot_profile())
	tender = SimFactory.tender()
	_dados_tropas = SimFactory.by_id(&"units")
	_moedas = moedas
	_tropas = tropas
	_obras = obras


## Ao crepusculo, antes de ela nascer. Falso quando a decima segunda foi aceite:
## "a Podridao nao volta a nascer" (§75).
func before_spawn(rot: RotSystem, dia: int) -> bool:
	if debt.ended:
		return false
	rot.refusals = debt.refusals(dia)
	return true


## Depois de nascer: o que e permanente pesa ja, e a noite volta a ter voz.
func after_spawn(rot: RotSystem) -> void:
	rot.state.mass += debt.collect()  # o que a noite saltada nao gastou (Q-040)
	rot.state.mass += debt.lume_mass()  # o que o Lume ja comeu (ADR 0034)
	rot.state.mass *= debt.mass_mult_permanent  # o permanente pesa sobre a noite inteira
	offers.dusk()
	_pausa = 0.0
	if debt.tender():
		tender.dusk(rot.position_x())


## A alvorada leva o Zelador com ela, e acaba a ganancia a zero quando e o dia.
func dawn(dia: int = 0) -> void:
	tender.dawn()
	if greed_until > 0 and dia >= greed_until and SimLoop.state != null:
		SimLoop.state.greed = greed_kept
		greed_until = 0


## Verdadeiro enquanto a mancha esta parada por uma oferta ("a mancha para 25 s").
func paused(delta: float) -> bool:
	if _pausa <= 0.0:
		return false
	_pausa -= delta
	return true


## Todos os ticks. Fala quando e a hora, e fecha o prato quando alguem paga ou
## quando o tempo acaba. O prato continua a contar mesmo com a mancha recolhida.
func tick(
	delta: float, rot: RotSystem, dia: int, mundo: Vector2, amargueiros: AmargueiroSystem
) -> void:
	if rot.active():
		var lado := 1 if rot.position_x() >= mundo.x else -1
		var muro := OfferSystem.outer_wall(_obras, mundo.x, lado)
		if offers.due(delta, rot.position_x(), muro):
			_abrir(rot, dia, mundo.x, amargueiros)
	if tender.tick(delta, rot.position_x(), mundo.x, _raio_do_nucleo(), _obras):
		tender.take(_tropas, titles, _dados_tropas)
	var fim := offers.tick(delta, _moedas, _tropas, titles)
	if fim.is_empty():
		return
	if fim[OfferSystem.CHAVE] == OfferSystem.EV_CADUCA:
		debt.refuse(dia)
		return
	_aceite(rot, dia)


## As chaves da §75, com o que o jogo hoje sabe. Os portoes ainda nao existem e
## valem zero: uma condicao sobre eles nunca se cumpre (Q-099, Q-147).
func facts(amargueiros: AmargueiroSystem) -> Dictionary:
	var marcos := 0
	for i in amargueiros.count():
		if amargueiros.fates[i] == AmargueiroSystem.Fate.MARKER:
			marcos += 1
	var factos := {&"gate": 0, &"named": titles.size(), &"marker": marcos, &"debt": debt.debt}
	factos.merge(OfferToll.facts() if SimLoop.state != null else {})
	return factos


func to_dict() -> Dictionary:
	return {
		&"offer": offers.to_dict(),
		&"debt": debt.to_dict(),
		&"tender": tender.to_dict(),
		&"pause": _pausa,
		&"spoken": spoken,
		&"reveals": reveals,
		&"greed": [greed_until, greed_kept],
	}


func from_dict(d: Dictionary) -> void:
	offers.from_dict(d.get(&"offer", {}))
	debt.from_dict(d.get(&"debt", {}))
	tender.from_dict(d.get(&"tender", {}))
	_pausa = d.get(&"pause", _pausa)
	spoken = d.get(&"spoken", spoken)
	reveals = d.get(&"reveals", reveals)
	var ganancia: Array = d.get(&"greed", [0, 0])
	greed_until = int(ganancia[0])
	greed_kept = int(ganancia[1])


## "Chegar ao nucleo" e entrar na meia largura do castelo-arvore (§10, §55).
func _raio_do_nucleo() -> float:
	for vaga in _obras.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga.width * BuildSystem.METADE
	return 0.0


func _abrir(rot: RotSystem, dia: int, nucleo: float, amargueiros: AmargueiroSystem) -> void:
	var lista := offers.candidates(facts(amargueiros), dia, debt.used)
	if lista.is_empty():
		offers.close_quietly()
		return
	var escolhida := lista[RngService.int_range(&"rot", 0, lista.size() - 1)]
	for o in lista:
		if spoken == 0 and o.id == PRIMEIRA:
			escolhida = o
	spoken += 1
	# O prato fica a borda da mancha, do lado do imperio (§75).
	var rumo := signf(nucleo - rot.position_x())
	var x := rot.position_x() + rumo * rot.state.width * BuildSystem.METADE
	offers.open(escolhida, x, int(Band.Kind.SURFACE))


func _aceite(rot: RotSystem, dia: int) -> void:
	var o := offers.offer()
	if not OfferToll.take(o.price_kind):
		return  # o preco ja nao existe (a escora desmontada, o Marco perdido): nada se da
	debt.incur(o.debt_delta)
	debt.accept(dia)
	if o.once_per_campaign:
		debt.remember(o.id)
	var antes := rot.mass()
	match o.effect_kind:
		&"rot_pause":
			_pausa = o.effect_value
		&"mass_mult":
			rot.state.mass *= o.effect_value
		&"mass_mult_permanent":
			debt.mass_mult_permanent *= o.effect_value
			rot.state.mass *= o.effect_value
		&"rot_detours":
			rot.retreat()
		&"skip_night":
			debt.carry(rot.mass())  # saltar tem peso: vem na noite seguinte (Q-040)
			rot.retreat()
		&"rot_ends":
			debt.ended = true
			rot.retreat()
		&"reveal_chapter":
			reveals += int(o.effect_value)
		&"seed_royal":
			SimLoop.state.royal_seeds += int(o.effect_value)
			EventBus.queue(&"seed_royal_gained", [int(o.effect_value), o.id])  # §46, Q-095
		&"greed_zero_days":
			greed_kept = SimLoop.state.greed if greed_until == 0 else greed_kept
			greed_until = dia + o.effect_days
			SimLoop.state.greed = 0
		&"control_rot_tonight":
			rot.retreat()  # a mancha e tua esta noite, e vai-se (§75)
	EventBus.queue(&"rot_fed", [maxf(0.0, antes - rot.mass()), o.id])
