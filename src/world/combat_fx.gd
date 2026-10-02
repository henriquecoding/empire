# src/world/combat_fx.gd — o que um corpo mostra de um combate que ja aconteceu.
#
# A memoria do ecra para o golpe: quem atacou e quando, quem levou e de que
# lado, quem caiu. Os tres desenhadores de corpos (UnitArtBatch, BandView e o
# ImpactView) leem daqui a MESMA pose, e e por isso que isto e estatico como o
# Smoothing — a mesma gravacao para todos, e nenhum a inventar a sua.
#
# O que um golpe faz ao corpo, pela ordem em que acontece (a "Art of Screenshake"
# da Vlambeer e o hitstop das Capcom, medidos no PR):
#
#   1 · quem bate prepara-se e avanca (StrikePose)
#   2 · no impacto, quem bate fica parado no frame do golpe e quem leva treme
#       no sitio — o hitstop, por corpo e nao do jogo todo: numa noite de
#       trezentas pancadas, parar o jogo a cada uma era um soluco continuo
#   3 · quem levou pisca a branco (§24, 80 ms) e e empurrado 3 px (§24) por uma
#       mola que o devolve ao sitio
#
# O empurrao e SO do ecra, e e o que a Q-084 pedia: a posicao continua a ser a
# da simulacao (§45), e a mola acaba sempre nela. Descartavel: se isto se
# perder, perdeu-se uma animacao e nada mais.
class_name CombatFx
extends RefCounted

## §24: "3 px de knockback" — o empurrao de um golpe normal, em px.
const RECUO_PX := 3.0
## A mola que o devolve: e^(-amortece t) cos(freq t). Assenta em ~150 ms.
const MOLA := {"amortece": 18.0, "freq": 38.0}
## O tremor do hitstop: um pixel para cada lado, trinta vezes por segundo, por
## `s` segundos a cada unidade de forca (50 ms num golpe normal, 90 no pesado).
const TREME := {"px": 1.0, "hz": 30.0, "s": 0.05}
## §24: o flash de 80 ms. Metade cheio, metade a apagar-se.
const FLASH_S := 0.08
## Quem leva e apertado na direccao do golpe, e solta-se depressa.
const AMASSA := {"quanto": 0.14, "solta": 14.0, "dura": 0.25}
## Quem cai, cai em QUEDA_S, para o lado para onde foi empurrado.
const QUEDA_S := 0.3
## O que passou disto ja nao mexe em nada e sai da memoria.
const ESQUECE_S := 2.0
## Um cooldown que SOBE e um ataque que acabou de sair (o muro nao tem sinal).
const SALTO := 0.05

static var clock := 0.0
static var _ataques: Dictionary = {}  # id -> [t, paragem]
static var _golpes: Dictionary = {}  # id -> [t, sentido, forca, paragem]
static var _quedas: Dictionary = {}  # id -> [t, sentido]
static var _cooldowns: Dictionary = {}  # id -> [t, o ultimo cooldown visto]
static var _vistos: Dictionary = {}  # id -> [t, caixa, forma, cor]
static var _tabelas: Dictionary = {}
static var _poda := 0.0


static func reset() -> void:
	clock = 0.0
	_ataques.clear()
	_golpes.clear()
	_quedas.clear()
	_cooldowns.clear()
	_vistos.clear()
	_poda = 0.0


static func advance(delta: float) -> void:
	clock += delta
	if clock - _poda < 1.0:
		return
	_poda = clock
	for memoria: Dictionary in [_ataques, _golpes, _cooldowns, _vistos]:
		for id in memoria.keys():
			if clock - float(memoria[id][0]) > ESQUECE_S:
				memoria.erase(id)


## Um corpo que saiu das colunas: a queda dele ja nao se desenha.
static func forget(id: int) -> void:
	_quedas.erase(id)
	_cooldowns.erase(id)


## Um ataque saiu agora. Quem bate fica no frame do impacto `hold` do estilo.
static func attacked(id: int, estilo: StrikePose.Style) -> void:
	_ataques[id] = [clock, StrikePose.hold(estilo)]


## O cooldown deste frame. Se subiu, o ataque saiu — e a unica maneira de saber
## que uma criatura bateu num MURO, que nao tem `attack_launched` (§46).
static func observe(id: int, cooldown: float, estilo: StrikePose.Style) -> void:
	var antes: float = _cooldowns.get(id, [clock, cooldown])[1]
	if cooldown > antes + SALTO and clock - float(_ataques.get(id, [-INF])[0]) > SALTO:
		attacked(id, estilo)
	_cooldowns[id] = [clock, cooldown]


## Um golpe chegou a `id`, vindo do lado `sentido`. `atraso` e quanto falta para
## a arma la chegar no ecra: a pancada sente-se quando o golpe esta esticado.
static func struck(id: int, sentido: float, forca: float, atraso: float = 0.0) -> void:
	_golpes[id] = [clock + atraso, sentido, forca, TREME.s * forca]


## De que lado veio o ultimo golpe que `id` levou (1 se nao levou nenhum): e para
## esse lado que uma morte espalha e que um corpo cai.
static func side(id: int) -> float:
	var sentido: float = _golpes.get(id, [0.0, 1.0])[1]
	return sentido if not is_zero_approx(sentido) else 1.0


## Uma tropa caiu. Escreve sempre: uma ressuscitada (§16) que volte a cair, cai
## outra vez, e nao aparece ja deitada.
static func fell(id: int, sentido: float) -> void:
	_quedas[id] = [clock, sentido]


## Quanto tempo desde o ultimo ataque de `id`, com o hitstop: durante a paragem
## o corpo fica no fim do golpe, que e o frame do impacto.
static func since_attack(id: int) -> float:
	if not _ataques.has(id):
		return StrikePose.NUNCA
	var desde := clock - float(_ataques[id][0])
	var paragem: float = _ataques[id][1]
	if desde < StrikePose.STRIKE_S:
		return desde
	if desde < StrikePose.STRIKE_S + paragem:
		return StrikePose.STRIKE_S * 0.999
	return desde - paragem


## A pose inteira de um corpo neste frame: (dx, escala x, escala y, arma). `falta`
## e o cooldown de quem esta engajado, e `frente` o lado para onde ele bate.
static func body(id: int, estilo: StrikePose.Style, falta: float, frente: float) -> Vector4:
	var desde := since_attack(id)
	var dx := frente * StrikePose.lunge(estilo, desde, falta) + recoil(id)
	var escala := StrikePose.stretch(estilo, desde, falta) * squash(id)
	return Vector4(dx, escala.x, escala.y, StrikePose.swing(estilo, desde, falta))


## O empurrao de quem levou, em px de x. Durante o hitstop treme no sitio; depois
## a mola leva-o e trá-lo de volta.
static func recoil(id: int) -> float:
	if not _golpes.has(id):
		return 0.0
	var g: Array = _golpes[id]
	var dt := clock - float(g[0])
	if dt < 0.0:
		return 0.0
	var forca: float = g[2]
	if dt < float(g[3]):
		return TREME.px * signf(sin(dt * TAU * TREME.hz) + 0.001)
	dt -= float(g[3])
	var mola := exp(-MOLA.amortece * dt) * cos(MOLA.freq * dt)
	return RECUO_PX * forca * float(g[1]) * mola


## O aperto de quem levou: mais estreito e mais alto, e solta-se.
static func squash(id: int) -> Vector2:
	if not _golpes.has(id):
		return Vector2.ONE
	var dt := clock - float(_golpes[id][0])
	if dt < 0.0 or dt > AMASSA.dura:
		return Vector2.ONE
	var k: float = AMASSA.quanto * float(_golpes[id][2]) * exp(-AMASSA.solta * dt)
	return Vector2(1.0 - k, 1.0 + k * WorldPalette.MEIA)


## O branco do §24, de 1 a 0. Desligado nas opcoes (§26, fotossensibilidade).
static func flash(id: int) -> float:
	if not _golpes.has(id) or not Preferences.on(Preferences.FLASHES):
		return 0.0
	var dt := clock - float(_golpes[id][0])
	if dt < 0.0 or dt >= FLASH_S:
		return 0.0
	return minf(1.0, 2.0 * (1.0 - dt / FLASH_S))


## O angulo de quem caiu (rad), do lado para onde foi empurrado. Um baque com um
## pequeno ressalto: e o que diz "morreu" a qualquer distancia.
static func fall(id: int) -> float:
	if not _quedas.has(id):
		return 0.0
	var p := clampf((clock - float(_quedas[id][0])) / QUEDA_S, 0.0, 1.0)
	var queda := 1.0 - pow(1.0 - p, 3.0)
	queda -= sin(p * PI) * 0.08 if p > 0.7 else 0.0
	return float(_quedas[id][1]) * PI * WorldPalette.MEIA * queda


## Para que lado olha a tropa `id`, que esta em `x` a lutar: para quem esta a
## bater, e nao para onde andou da ultima vez — um arqueiro de costas para a
## criatura que esta a matar nao se le. `antes` se o alvo nao se ve.
static func facing(id: int, x: float, antes: float) -> float:
	var alvo := SimLoop.creatures.index_of(SimLoop.combat.target_of(id))
	if alvo == CreatureSystem.NENHUM:
		return antes
	var para := SimLoop.creatures.xs[alvo]
	return antes if is_equal_approx(para, x) else signf(para - x)


## O ultimo desenho de uma criatura, para a morte a poder desfazer no sitio
## onde estava: o `creature_died` traz o x, e a forma ja saiu das colunas.
static func remember(id: int, caixa: Rect2, forma: int, cor: Color) -> void:
	_vistos[id] = [clock, caixa, forma, cor]


static func seen(id: int) -> Array:
	return _vistos.get(id, [])


## O estilo de quem tem este id, tropa ou criatura (os ids sao do mesmo
## contador, §45). Sem corpo, e corpo-a-corpo.
static func style_of(id: int) -> StrikePose.Style:
	if SimLoop.state == null:
		return StrikePose.Style.MELEE
	var i := SimLoop.units.index_of(id)
	if i != UnitSystem.NENHUM:
		return StrikePose.of_unit(table(&"units").get(SimLoop.units.data_ids[i]))
	var c := SimLoop.creatures.index_of(id)
	if c != CreatureSystem.NENHUM:
		return StrikePose.of_creature(table(&"creatures").get(SimLoop.creatures.data_ids[c]))
	return StrikePose.Style.MELEE


## Os dados por id, a pedido (AGENTS.md, regra 8b): o primeiro a perguntar
## carrega, e os desenhadores todos partilham a mesma tabela.
static func table(qual: StringName) -> Dictionary:
	if not _tabelas.has(qual):
		_tabelas[qual] = SimFactory.by_id(qual)
	return _tabelas[qual]
