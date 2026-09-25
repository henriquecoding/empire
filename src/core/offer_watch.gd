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
	rot.state.mass *= debt.mass_mult_permanent
	offers.dusk()
	_pausa = 0.0
	if debt.tender():
		tender.dusk(rot.position_x())


## A alvorada leva o Zelador com ela.
func dawn() -> void:
	tender.dawn()


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


## As oito chaves da §75, com o que o jogo hoje sabe. Portoes, tesouraria,
## povos e sucessor ainda nao existem e valem zero: uma condicao sobre eles
## nunca se cumpre, e e isso que os deixa de fora (Q-099).
func facts(amargueiros: AmargueiroSystem) -> Dictionary:
	var marcos := 0
	for i in amargueiros.count():
		if amargueiros.fates[i] == AmargueiroSystem.Fate.MARKER:
			marcos += 1
	return {
		&"gate": 0,
		&"treasury": 0,
		&"named": titles.size(),
		&"marker": marcos,
		&"peoples": 0,
		&"successor": 0,
		&"debt": debt.debt,
		&"biome": &"",
	}


func to_dict() -> Dictionary:
	return {
		&"offer": offers.to_dict(),
		&"debt": debt.to_dict(),
		&"tender": tender.to_dict(),
		&"pause": _pausa,
		&"spoken": spoken,
		&"reveals": reveals,
	}


func from_dict(d: Dictionary) -> void:
	offers.from_dict(d.get(&"offer", {}))
	debt.from_dict(d.get(&"debt", {}))
	tender.from_dict(d.get(&"tender", {}))
	_pausa = d.get(&"pause", _pausa)
	spoken = d.get(&"spoken", spoken)
	reveals = d.get(&"reveals", reveals)


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
		&"rot_detours", &"skip_night":
			rot.retreat()
		&"rot_ends":
			debt.ended = true
			rot.retreat()
		&"reveal_chapter":
			reveals += int(o.effect_value)
	EventBus.queue(&"rot_fed", [maxf(0.0, antes - rot.mass()), o.id])
