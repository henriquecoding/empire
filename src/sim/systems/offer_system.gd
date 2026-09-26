# src/sim/systems/offer_system.gd — a Oferta, uma por noite (§75).
#
# A mancha chega a offer_trigger_px da muralha mais exterior, entre x e y
# segundos depois do crepusculo, e fala: uma frase no mundo e um prato no chao,
# a borda dela. Aceitar e o Verbo 1 — o preco tem de CAIR no prato: moedas
# atiradas, a tropa levada ate la. Recusar e nao fazer nada: passam
# offer_seconds, o prato afunda-se, e conta como recusa. Sem meias-aceitacoes.
#
# Uma por noite, mesmo com duas manchas (D-05): quem pergunta e a noite, e nao a
# mancha. O sorteio entre as elegiveis vem de fora, do fluxo `rot` (§42).
#
# Puro. O que a oferta DA — pausar, cortar massa, fechar o ciclo — e da
# NightWatch, que tem a mancha; aqui decide-se se foi paga.
#
# So entram nas candidatas as ofertas cujo preco se pode pagar e cujo efeito
# existe hoje (PRECOS, EFEITOS). As outras dependem de portoes, tesouraria,
# capitulos, sucessor e povos, que ainda nao ha — ver a Q-099.
class_name OfferSystem
extends RefCounted

enum Phase { WAITING, OPEN, DONE }

const PRECOS: Array[StringName] = [
	&"coins", &"troops_below_health", &"named_troop", &"everything_named"
]
## "Revela um Capitulo" guarda-se como revelacao por fazer: e o XIII-07 que a
## gasta, e a oferta nao espera por ele para existir (§83, minuto 18:00).
const EFEITOS: Array[StringName] = [
	&"rot_pause",
	&"mass_mult",
	&"mass_mult_permanent",
	&"rot_detours",
	&"skip_night",
	&"rot_ends",
	&"reveal_chapter",
]
## O monarca nao e uma tropa: nenhum preco o leva (§75 fala em tropas).
const REI := &"king"

const EV_ACEITE := 0
const EV_CADUCA := 1

const CHAVE := &"kind"
const OFERTA := &"offer"
const SAEM := &"units_taken"
const MOEDAS := &"coins_taken"

var phase: Phase = Phase.WAITING
var offer_id: StringName = &""
var plate_x: float = 0.0
var band: int = int(Band.Kind.SURFACE)
var left: float = 0.0
var since_dusk: float = 0.0

var _perfil: RotProfile
var _ofertas: Array[OfferData] = []
var _por_id: Dictionary = {}
var _tropas: Dictionary


## As ofertas entram por id, para que o sorteio sobre as candidatas seja sempre
## sobre a mesma ordem (§42).
func _init(perfil: RotProfile, ofertas: Array[OfferData], tropas: Dictionary) -> void:
	_perfil = perfil
	_tropas = tropas
	_ofertas = ofertas.duplicate()
	_ofertas.sort_custom(
		func(a: OfferData, b: OfferData) -> bool: return String(a.id) < String(b.id)
	)
	for o in _ofertas:
		_por_id[o.id] = o


## Uma noite nova, e com ela a voz.
func dusk() -> void:
	phase = Phase.WAITING
	offer_id = &""
	left = 0.0
	since_dusk = 0.0


## Verdadeiro no tick em que ela deve falar: perto da muralha dentro da janela,
## ou no fim da janela, esteja onde estiver. Uma vez por noite.
func due(delta: float, rot_x: float, muro_x: float) -> bool:
	if phase != Phase.WAITING:
		return false
	since_dusk += delta
	var janela := _perfil.offer_window_after_dusk
	if since_dusk < janela.x:
		return false
	return absf(rot_x - muro_x) <= _perfil.offer_trigger_px or since_dusk >= janela.y


## As elegiveis esta noite (§75) que hoje se podem pagar e cumprir, por id.
func candidates(factos: Dictionary, dia: int, usadas: PackedStringArray) -> Array[OfferData]:
	var saida: Array[OfferData] = []
	for o in _ofertas:
		if not PRECOS.has(o.price_kind) or not EFEITOS.has(o.effect_kind):
			continue
		if OfferRules.eligible(o, factos, dia, usadas):
			saida.append(o)
	return saida


func open(oferta: OfferData, x: float, faixa: int) -> void:
	phase = Phase.OPEN
	offer_id = oferta.id
	plate_x = x
	band = faixa
	left = _perfil.offer_seconds


## Nenhuma candidata: a noite fica calada. Nao e uma recusa — ninguem recusou.
func close_quietly() -> void:
	phase = Phase.DONE


func offer() -> OfferData:
	return _por_id.get(offer_id)


## Enquanto o prato esta no chao. Devolve vazio, ou o fim: aceite, com o que o
## preco levou, ou caducada — que conta como recusa. `titulos` e unit_id -> chave
## do titulo (§76): so quem tem nome paga uma oferta de nomes.
func tick(
	delta: float, moedas: CoinSystem, unidades: UnitSystem, titulos: Dictionary
) -> Dictionary:
	if phase != Phase.OPEN:
		return {}
	left -= delta
	var oferta := offer()
	var pago := OfferPrice.pay(oferta, self, moedas, unidades, titulos, _tropas)
	if not pago.is_empty():
		phase = Phase.DONE
		pago[CHAVE] = EV_ACEITE
		pago[OFERTA] = offer_id
		return pago
	if left > 0.0:
		return {}
	phase = Phase.DONE
	return {CHAVE: EV_CADUCA, OFERTA: offer_id}


## Se x cai dentro do prato, nesta faixa. So conta o que cai la dentro (§75).
func in_plate(x: float, faixa: int) -> bool:
	return faixa == band and absf(x - plate_x) <= _perfil.offer_plate_px * BuildSystem.METADE


## A muralha mais exterior do lado `lado` (-1 ou +1) do nucleo: a obra de pe que
## trava e esta mais longe dele. Sem muralha, o proprio nucleo.
static func outer_wall(obras: BuildSystem, nucleo: float, lado: int) -> float:
	var x := nucleo
	for vaga in obras.slots:
		if not vaga.blocks or not vaga.holds() or vaga.band != Band.Kind.SURFACE:
			continue
		if signf(vaga.x - nucleo) == float(lado) and absf(vaga.x - nucleo) > absf(x - nucleo):
			x = vaga.x
	return x


func to_dict() -> Dictionary:
	return {
		&"phase": int(phase),
		&"offer": offer_id,
		&"plate_x": plate_x,
		&"band": band,
		&"left": left,
		&"since_dusk": since_dusk,
	}


func from_dict(d: Dictionary) -> void:
	phase = d.get(&"phase", int(phase)) as Phase
	offer_id = d.get(&"offer", offer_id)
	plate_x = d.get(&"plate_x", plate_x)
	band = d.get(&"band", band)
	left = d.get(&"left", left)
	since_dusk = d.get(&"since_dusk", since_dusk)
