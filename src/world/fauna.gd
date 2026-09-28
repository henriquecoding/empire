# src/world/fauna.gd — os bichos de cenario de uma regiao, e o que cada um faz.
#
# Nao sao as criaturas da Podridao nem a caca do HuntingSystem: essas estao na
# simulacao. Estes sao cenario que se mexe, e nada do que fazem toca no jogo.
# Quatro maneiras de estar vivo:
#   · POISO — o pardal no arbusto. O rei chega perto, ele levanta voo para longe
#     e, quando o rei se vai, volta ao mesmo arbusto (Kingdom Two Crowns).
#   · CHAO  — o corvo no caminho: anda, para, e se o rei vem, voa e pousa longe.
#   · PAIRA — borboleta, pirilampo, morcego, gaivota: um oito a volta de casa.
#   · BANDO — os passaros do ceu, pelo Flock.
# As decisoes (parar ou andar, para onde) saem do RngService.scatter() com a
# chave do bicho e o numero da decisao: nada de fluxo gasto.
class_name Fauna
extends RefCounted

enum State { IDLE, WALK, FLEE, RETURN }
enum Modo { POISO, CHAO, PAIRA, BANDO }

const DIA := 1
const NOITE := 2
const SEMPRE := 3

## Por bicho, na ordem do Wilds.Animal: como vive, quando, e a que alturas tem
## casa (y de mundo; o pardal tira-a do arbusto e o corvo do chao).
const MODO := [Modo.POISO, Modo.CHAO, Modo.PAIRA, Modo.PAIRA, Modo.BANDO, Modo.PAIRA, Modo.PAIRA]
const TURNO := [DIA, DIA, DIA, NOITE, DIA, SEMPRE, DIA]
## A faixa de cada um (Band.Kind: 0 ar, 1 superficie, 2 subsolo), para a luz.
const FAIXA := [1, 1, 1, 1, 0, 2, 0]
const ALTURA := [
	[0.0, 0.0],
	[0.0, 0.0],
	[446.0, 486.0],
	[430.0, 500.0],
	[90.0, 250.0],
	[548.0, 596.0],
	[120.0, 260.0]
]
## O oito de quem paira: (roda em px, onda em px, voltas por segundo).
const OITO := {
	Wilds.Animal.BUTTERFLY: [40.0, 12.0, 0.7],
	Wilds.Animal.FIREFLY: [36.0, 16.0, 0.3],
	Wilds.Animal.BAT: [110.0, 14.0, 0.45],
	Wilds.Animal.GULL: [320.0, 30.0, 0.08],
}
## Quem se espanta com o rei: (medo em px, fuga em px/s).
const ESPANTO := {Wilds.Animal.SONGBIRD: [120.0, 150.0], Wilds.Animal.CROW: [110.0, 130.0]}
## O corvo a pe: px/s e ate onde vai de casa.
const PE := {"anda": 16.0, "roda": 70.0}

## O pardal pousa no cimo do arbusto: o pe do arbusto, a mesma conta do FloraArt.
const ARBUSTO_ALTO := 20.0
## Pastar ou andar: abaixo de `parar` fica, acima anda. A espera e em segundos.
const DECISAO := {"parar": 0.45, "min": 1.5, "max": 6.0}
## Fugir leva a `alcance` vezes o medo, e dura `segundos`; voa-se a `subida`
## px/s ate `teto` (y de mundo).
const FUGA := {"alcance": 2.0, "segundos": 3.0, "subida": 80.0, "teto": 330.0, "volta": 0.6}
## O rumo do bando: da volta a regiao devagar, a meia altura do ceu.
const RUMO := {"ritmo": 0.035, "largo": 0.42, "alto": 170.0, "onda": 40.0}
const PASSADA := 0.12
const ESQUERDA := -1.0
const MEIO := 0.5


class Bicho:
	extends RefCounted
	var kind: int = 0
	var key: int = 0
	var x: float = 0.0
	var y: float = 0.0
	var home: Vector2 = Vector2.ZERO
	var target: float = 0.0
	var vx: float = 0.0
	var timer: float = 0.0
	var phase: float = 0.0
	var variant: float = 0.0
	var facing: float = 1.0
	var state: int = State.IDLE
	var decisions: int = 0
	var flock_index: int = -1


var bichos: Array[Bicho] = []
var bando := Flock.new()
var _tempo := 0.0
var _centro := 0.0
var _largura := 0.0


## Quanto de um bicho se ve com `escuro` (0 de dia, 1 de noite).
static func presence(kind: int, escuro: float) -> float:
	match int(TURNO[kind]):
		DIA:
			return 1.0 - escuro
		NOITE:
			return escuro
	return 1.0


## Solta os bichos de `lista` (triplos do Wilds) numa regiao de `largura`.
func populate(lista: PackedFloat32Array, largura: float) -> void:
	bichos.clear()
	bando = Flock.new()
	_largura = largura
	_centro = largura * MEIO
	for i in range(0, lista.size(), Wilds.BICHO):
		bichos.append(_novo(i, int(lista[i]), lista[i + 1], lista[i + 2]))


## Um passo. `rei_x` so assusta quem esta no chao se `rei_aqui` (o rei a superficie).
func tick(delta: float, rei_x: float, rei_aqui: bool) -> void:
	_tempo += delta
	if bando.size() > 0:
		var rumo := Vector2(
			_centro + sin(_tempo * RUMO.ritmo * TAU) * _largura * RUMO.largo,
			RUMO.alto + sin(_tempo * RUMO.ritmo * TAU * 2) * RUMO.onda
		)
		bando.step(delta, rumo)
	for b in bichos:
		match int(MODO[b.kind]):
			Modo.POISO:
				_poiso(b, ESPANTO[b.kind], delta, rei_x, rei_aqui)
			Modo.CHAO:
				_chao(b, ESPANTO[b.kind], delta, rei_x, rei_aqui)
			Modo.PAIRA:
				_paira(b, OITO[b.kind], delta)
			Modo.BANDO:
				var novo := bando.positions[b.flock_index]
				b.facing = signf(novo.x - b.x) if not is_equal_approx(novo.x, b.x) else b.facing
				b.x = novo.x
				b.y = novo.y
				b.phase += delta


func _novo(i: int, tipo: int, x: float, v: float) -> Bicho:
	var b := Bicho.new()
	b.kind = tipo
	b.key = hash([tipo, i])
	b.variant = v
	b.phase = v * TAU
	b.timer = v * DECISAO.max
	b.facing = 1.0 if v < MEIO else ESQUERDA
	var y := float(Band.GROUND_LINE)
	match int(MODO[tipo]):
		Modo.POISO:
			# A variante do pardal e o fundo do arbusto onde pousa.
			var pe := lerpf(WildsLayer.CAMPO_Y.frente, WildsLayer.CAMPO_Y.tras, v)
			y = floorf(pe) - ARBUSTO_ALTO
		Modo.PAIRA, Modo.BANDO:
			y = lerpf(ALTURA[tipo][0], ALTURA[tipo][1], v)
	b.x = x
	b.y = y
	b.home = Vector2(x, y)
	b.target = x
	if MODO[tipo] == Modo.BANDO:
		b.flock_index = bando.add(b.home, Vector2(b.facing * Flock.REGRAS.min, 0.0))
	return b


func _poiso(b: Bicho, espanto: Array, delta: float, rei_x: float, rei_aqui: bool) -> void:
	var perto := rei_aqui and absf(b.home.x - rei_x) < float(espanto[0])
	match b.state:
		State.IDLE:
			b.phase += delta
			if rei_aqui and absf(b.x - rei_x) < float(espanto[0]):
				var lado := signf(b.x - rei_x)
				b.vx = (lado if lado != 0.0 else b.facing) * float(espanto[1])
				b.facing = signf(b.vx)
				b.state = State.FLEE
				b.timer = FUGA.segundos
		State.FLEE:
			b.x += b.vx * delta
			b.y = maxf(b.y - FUGA.subida * delta, FUGA.teto)
			b.phase += delta
			b.timer -= delta
			if b.timer <= 0.0 and not perto:
				b.state = State.RETURN
		State.RETURN:
			var falta := b.home - Vector2(b.x, b.y)
			var passo := float(espanto[1]) * FUGA.volta * delta
			b.facing = signf(falta.x) if not is_zero_approx(falta.x) else b.facing
			b.phase += delta
			if perto:
				b.state = State.FLEE
				b.timer = FUGA.segundos
			elif falta.length() <= passo:
				b.x = b.home.x
				b.y = b.home.y
				b.state = State.IDLE
			else:
				var p := Vector2(b.x, b.y) + falta.normalized() * passo
				b.x = p.x
				b.y = p.y


func _chao(b: Bicho, espanto: Array, delta: float, rei_x: float, rei_aqui: bool) -> void:
	var medo := float(espanto[0])
	if rei_aqui and b.state != State.FLEE and absf(b.x - rei_x) < medo:
		var lado := signf(b.x - rei_x)
		b.state = State.FLEE
		b.target = b.x + (lado if lado != 0.0 else b.facing) * medo * FUGA.alcance
		b.timer = FUGA.segundos
	var chao := b.home.y
	if b.state != State.FLEE:
		b.y = minf(b.y + FUGA.subida * delta, chao)
	match b.state:
		State.IDLE:
			b.timer -= delta
			if b.timer <= 0.0:
				_decidir(b)
		State.WALK:
			if _passo(b, PE.anda, delta):
				_decidir(b)
		State.FLEE:
			b.timer -= delta
			b.y = maxf(b.y - FUGA.subida * delta, FUGA.teto)
			if _passo(b, float(espanto[1]), delta) or b.timer <= 0.0:
				b.home.x = b.x
				_decidir(b)


func _paira(b: Bicho, oito: Array, delta: float) -> void:
	b.phase += delta * float(oito[2]) * TAU
	var novo := b.home.x + sin(b.phase) * float(oito[0])
	if not is_equal_approx(novo, b.x):
		b.facing = signf(novo - b.x)
	b.x = novo
	b.y = b.home.y + sin(b.phase * 2 + b.variant * TAU) * float(oito[1])


func _passo(b: Bicho, velocidade: float, delta: float) -> bool:
	var falta := b.target - b.x
	if not is_zero_approx(falta):
		b.facing = signf(falta)
	var antes := b.x
	b.x = move_toward(b.x, b.target, velocidade * delta)
	b.phase += absf(b.x - antes) * PASSADA
	return is_equal_approx(b.x, b.target)


func _decidir(b: Bicho) -> void:
	var dados := RngService.scatter(hash([b.key, b.decisions]), 2)
	b.decisions += 1
	if dados[0] < DECISAO.parar:
		b.state = State.IDLE
		b.timer = lerpf(DECISAO.min, DECISAO.max, dados[1])
		return
	b.state = State.WALK
	b.target = clampf(b.home.x + (dados[1] * 2 - 1) * PE.roda, 0.0, _largura)
