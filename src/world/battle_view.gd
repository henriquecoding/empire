# src/world/battle_view.gd — o combate que se ve entre os corpos (§07, §24, §50).
#
# Um no por cima das tres faixas, com o que nao pertence a corpo nenhum: as
# flechas no ar e cravadas, e o que fica de uma morte. E tambem quem da corda
# ao relogio do CombatFx, que as poses de toda a gente leem.
#
# Ouve a §46 e nao inventa sinal nenhum (regra 7): o `attack_launched` diz quem
# bateu e se acertou; o `creature_died` e o `unit_died` dizem quem caiu, e onde.
# O golpe de longe so se sente quando a flecha chega — e por isso o ImpactView
# deixa os arqueiros para este no, que lhe entrega o golpe a chegada. O tiro de
# quem se conduz e a excepcao: acerta ja, com o traco dourado do CombatView.
#
# Descartavel (§45): nada aqui volta para a simulacao.
class_name BattleView
extends Node2D

## Onde o arco esta no corpo de quem dispara, em px a contar dos pes.
const ARCO := Vector2(10.0, -30.0)
## Para onde uma flecha aponta no corpo de quem a leva: um pouco acima do meio.
const PEITO := -0.15
## Uma falha cai entre estes px ao lado do alvo, para um lado ou para o outro.
const FALHA_PX := Vector2(16.0, 32.0)
const LADOS: Array[float] = [-1.0, 1.0]
## Uma criatura vista ha mais do que isto ja nao esta ali para ser seguida.
const VISTA_S := 0.25
## O peso de uma flecha a chegar: um golpe de longe empurra menos.
const FLECHA := StrikePose.Style.RANGED
## §24: o tremor do Ariete a acertar. O do muro a cair e da Game.
const ARIETE_TRAUMA := 0.6
const CERCO := &"siege"

var _flechas := Volley.new()
var _mortes := DeathBurst.new()
var _impactos: ImpactView


func _ready() -> void:
	CombatFx.reset()
	_impactos = get_parent().get_node_or_null(^"Impactos") as ImpactView
	EventBus.attack_launched.connect(_no_ataque)
	EventBus.creature_died.connect(_na_morte_de_criatura)
	EventBus.unit_died.connect(_na_morte_de_tropa)
	EventBus.building_damaged.connect(_na_dentada)


func _process(delta: float) -> void:
	CombatFx.advance(delta)
	for chegada in _flechas.step(CombatFx.clock, _onde):
		if _impactos != null:
			var sentido: float = chegada[Volley.SENTIDO]
			_impactos.hit(chegada[Volley.ALVO], sentido, false, StrikePose.strength(FLECHA))
	_mortes.step(delta, CombatFx.clock)
	queue_redraw()


func _draw() -> void:
	_flechas.draw(self, CombatFx.clock)
	_mortes.draw(self, CombatFx.clock)


func arrows() -> Volley:
	return _flechas


func bursts() -> DeathBurst:
	return _mortes


## §46, `attack_launched(from_id, to_id, hit)`. Quem bate arma o golpe; quem
## dispara solta uma flecha, que acerta ou falha como a simulacao ja decidiu.
func _no_ataque(from_id: int, to_id: int, acertou: bool) -> void:
	var estilo := CombatFx.style_of(from_id)
	CombatFx.attacked(from_id, estilo)
	# O tiro de quem se conduz acerta ja (ADR 0045) e tem o traco do CombatView.
	if estilo != StrikePose.Style.RANGED or from_id == Assume.driven():
		return
	var i := SimLoop.units.index_of(from_id)
	var alvo := _onde(to_id)
	if i == UnitSystem.NENHUM or alvo == Vector2.INF:
		return
	var x := Smoothing.x_of(Smoothing.Group.UNITS, from_id, SimLoop.units.xs[i])
	var chao := WorldPalette.ground_of(int(SimLoop.units.bands[i]))
	var lado := ImpactView.aim(x, alvo.x)
	var de := Vector2(x + lado * ARCO.x, chao + ARCO.y)
	var desvio := 0.0
	if not acertou:
		desvio = RngService.float_range(RngService.VISUAL, FALHA_PX.x, FALHA_PX.y)
		desvio *= LADOS[RngService.int_range(RngService.VISUAL, 0, 1)]
		alvo = Vector2(alvo.x, chao)
	_flechas.launch(de, to_id, alvo, acertou, CombatFx.clock, desvio)


## A criatura saiu das colunas neste tick; o ultimo desenho dela ficou no
## CombatFx, e e esse que se desfaz — no sitio e com a cor que tinha.
func _na_morte_de_criatura(creature_id: int, _x: float, _faixa: int) -> void:
	var visto := LastSeen.seen(creature_id)
	if visto.is_empty():
		return
	var sorteio := func(de: float, ate: float) -> float:
		return RngService.float_range(RngService.VISUAL, de, ate)
	_mortes.burst(visto, CombatFx.side(creature_id), CombatFx.clock, sorteio)


## Uma tropa fica no chao ate ao amanhecer (§16): cai para o lado do golpe, e o
## po levanta onde ela cai.
func _na_morte_de_tropa(unit_id: int, x: float, faixa: int, _larga: PackedStringArray) -> void:
	CombatFx.fell(unit_id, CombatFx.side(unit_id))
	_mortes.dust(Vector2(x, WorldPalette.ground_of(faixa)), CombatFx.clock)


## §24: "screen shake so para o muro a cair e o Ariete a acertar". O §46 diz que
## a obra levou, e nao quem lhe bateu: pergunta-se as colunas quem esta nela.
func _na_dentada(building_id: int, _ratio: float) -> void:
	if not Preferences.on(Preferences.SCREEN_SHAKE):
		return
	var bichos := SimLoop.creatures
	for c in bichos.count():
		if bichos.target_slots[c] != building_id:
			continue
		var dados: CreatureData = CombatFx.table(&"creatures").get(bichos.data_ids[c])
		if dados != null and dados.tags.has(CERCO):
			get_tree().call_group(&"jogo", &"shake", ARIETE_TRAUMA)
			return


## Onde esta AGORA o corpo `id`, para uma flecha o seguir: a criatura pelo seu
## ultimo desenho, a tropa pelo x que se ve. Vector2.INF se ja nao ha corpo.
func _onde(id: int) -> Vector2:
	var visto := LastSeen.seen(id)
	if not visto.is_empty() and CombatFx.clock - float(visto[LastSeen.QUANDO]) < VISTA_S:
		var caixa: Rect2 = visto[LastSeen.CAIXA]
		return caixa.get_center() + Vector2(0.0, caixa.size.y * PEITO)
	var i := SimLoop.units.index_of(id)
	if i == UnitSystem.NENHUM:
		return Vector2.INF
	var x := Smoothing.x_of(Smoothing.Group.UNITS, id, SimLoop.units.xs[i])
	return Vector2(x, WorldPalette.ground_of(int(SimLoop.units.bands[i])) + ARCO.y)
