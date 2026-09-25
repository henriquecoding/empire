# src/world/impact_view.gd — ver um golpe acontecer (§24, §50).
#
# O §24 poe isto na lista de juice "que nao e opcional", e a razao ve-se numa
# noite do greybox: rectangulos parados, e uma barra de vida a encolher sem que
# nada no ecra diga que houve pancada. O §07 e explicito sobre o que NAO se
# pode fazer — "sem numeros no ecra, nada de dano em texto" —, e por isso o que
# resta e o corpo a dizer que foi atingido.
#
# A linha do §24, tal e qual: "Impacto — flash branco de 80 ms, 3 px de
# knockback, particula de 4 px na direcao do golpe."
#
# Duas das tres. O knockback de 3 px mexe numa POSICAO, e posicoes sao a
# simulacao (§45): empurrar um corpo daqui tirava-o da fila de contacto do §50
# sem que o §50 desse por isso, e um empurrao que o save nao conhece torna a
# partida irreproduzivel (§61). Fica para quem lhe der numero em data/ e sistema
# em src/sim/ — ver docs/QUESTIONS.md, Q-084.
#
# Um no, com estado, e isso e deliberado: 80 ms sao TEMPO, e tempo nao se deriva
# do estado da simulacao. E o mesmo que a `game.gd` ja faz com o tremor de ecra
# do §24. Descartavel na acepcao do §45 — se isto se perder, nao se perdeu nada.
class_name ImpactView
extends Node2D

## §24: 80 ms. E o unico numero desta lista que o dossie escreve.
const FLASH_S := 0.08
## A particula do §24: 4 px, e quanto ela se afasta enquanto o flash dura. Sao
## greybox como as alturas do Silhouette: leem a direcao e vao-se com o ART-01.
const PARTICULA := 4.0
const AVANCO := 28.0
const MEIA := 0.5

## Um golpe guardado: [alvo, sentido, quanto falta, e-obra]. Guarda o ID e nao a
## posicao — o corpo anda durante os 80 ms, e um flash parado ao lado dele nao
## e um flash, e um risco branco no chao.
##
## A ultima casa existe porque ha DOIS espacos de id: os corpos vem do contador
## do §45 e um sitio de obra vem do indice do BuildSystem, e o 3 de um e o 3 do
## outro. Sem ela, uma dentada no muro piscava um vagabundo do outro lado.
const ALVO := 0
const SENTIDO := 1
const RESTA := 2
const OBRA := 3

## Uma obra nao leva particula: o `building_damaged` da o quanto, nao o de onde,
## e uma particula com direcao inventada mentia sobre de que lado vem a dentada.
const SEM_SENTIDO := 0.0

## Uma obra pisca a CONTORNO e um corpo pisca cheio, e a razao mediu-se numa
## captura: o castelo-arvore tem 480 px de largo por 370 de alto e, cheio de
## branco, tapava um terco do ecra — 176 000 pixeis a gritar por uma dentada de
## 4 de dano. O §24 escreve o flash a pensar num corpo, e um corpo a escala 2 tem
## 32 px. Numa obra o que diz "esta a ser comida" e a orla dela.
const ORLA := WorldPalette.CONTORNO * 2.0

## Um corpo que ja nao esta em campo. Devolve-se uma caixa vazia e nao um nulo:
## quem desenha ja tem de olhar para o tamanho, e assim nao olha duas vezes.
const SEM_CORPO := Rect2()

var _golpes: Array[Array] = []
var _tabelas: Dictionary = {}


func _ready() -> void:
	EventBus.attack_launched.connect(_no_golpe)
	EventBus.building_damaged.connect(_na_dentada)


## Marca um golpe que acertou. Publico para se poder medir sem esperar por
## frames nem por uma noite — a mesma razao do `advance()` da camara.
func hit(target_id: int, sentido: float, obra: bool = false) -> void:
	_golpes.append([target_id, sentido, FLASH_S, obra])


func count() -> int:
	return _golpes.size()


## O ultimo golpe marcado, para quem o queira conferir sem olhar para o ecra.
## Devolve vazio quando nao ha nenhum — nao rebenta, porque quem pergunta esta a
## medir e nao a desenhar.
func last() -> Array:
	return _golpes[-1] if not _golpes.is_empty() else []


## Envelhece o que esta no ecra. Um golpe dura FLASH_S e mais nada: nao ha
## acumulacao, nao ha lista a crescer, e uma noite de trezentas pancadas deixa
## no maximo as que couberam nos ultimos 80 ms.
func advance(delta: float) -> void:
	if _golpes.is_empty():
		return
	var vivos: Array[Array] = []
	for golpe in _golpes:
		golpe[RESTA] -= delta
		if golpe[RESTA] > 0.0:
			vivos.append(golpe)
	_golpes = vivos
	queue_redraw()


## Para que lado atravessou o golpe: do atacante para quem levou. Dois corpos no
## mesmo x ficam a direita, como a arma parada do BandView — um sentido zero
## punha a particula dentro do corpo, que e onde ela nao se ve.
static func aim(de_x: float, para_x: float) -> float:
	if is_equal_approx(de_x, para_x):
		return 1.0
	return signf(para_x - de_x)


func _process(delta: float) -> void:
	advance(delta)


## §46, `attack_launched(from_id, to_id, hit)`. So o que ACERTA pisca: o §07 da
## ao arqueiro em campo aberto uma precisao de 0,34, e piscar as falhas dizia
## que ele acertou duas vezes em tres.
func _no_golpe(from_id: int, to_id: int, acertou: bool) -> void:
	if not acertou:
		return
	var de := _caixa_de(from_id)
	var para := _caixa_de(to_id)
	if para.size == Vector2.ZERO:
		return
	var sentido := 1.0
	if de.size != Vector2.ZERO:
		sentido = aim(de.get_center().x, para.get_center().x)
	hit(to_id, sentido)


## §46, `building_damaged(building_id, ratio)`. E o sinal que uma noite do
## greybox emite as centenas e que nao se via em lado nenhum: o castelo-arvore
## perdia 420 de vida e o ecra ficava igual. O §10 diz que se ele cair cai a
## partida — quem esta a ser comido tem de piscar.
func _na_dentada(building_id: int, _ratio: float) -> void:
	_golpes.append([building_id, SEM_SENTIDO, FLASH_S, true])


## Com os claroes desligados (§26, "obrigatorio para fotossensibilidade") fica a
## particula: 4 px a afastar-se nao sao um clarao, e sao a unica coisa que diz de
## que lado veio o golpe (GB-13).
func _draw() -> void:
	var clarao := Preferences.on(Preferences.FLASHES)
	for golpe in _golpes:
		if golpe[OBRA]:
			if clarao:
				_obra_atingida(golpe[ALVO])
			continue
		var caixa := _caixa_de(golpe[ALVO])
		if caixa.size == Vector2.ZERO:
			continue
		if clarao:
			draw_rect(caixa, WorldPalette.FLASH)
		_particula(caixa, golpe[SENTIDO], golpe[RESTA])


## A orla de uma obra que acabou de levar uma dentada. A forma vem do BuildView
## — a mesma que ela tem no ecra — e nao daqui: dois sitios a decidir a forma de
## um muro davam dois muros.
func _obra_atingida(slot_id: int) -> void:
	var i := SimLoop.builds.index_of(slot_id)
	if i == BuildSystem.NENHUM:
		return
	var vaga := SimLoop.builds.slots[i]
	var forma := Silhouette.of_slot(vaga, _tabela(&"buildings"))
	var pontos := BuildView.drawn_shape(vaga, forma)
	if pontos.size() < 2:
		return
	pontos.append(pontos[0])
	draw_polyline(pontos, WorldPalette.FLASH, ORLA)


## A particula sai do lado por onde o golpe entrou e afasta-se com o flash. E a
## unica coisa no ecra que diz DE ONDE veio a pancada — o corpo so diz que a
## levou, e numa linha com gente dos dois lados isso nao chega.
func _particula(caixa: Rect2, sentido: float, resta: float) -> void:
	var andado := (1.0 - resta / FLASH_S) * AVANCO
	var centro := caixa.get_center()
	var x := centro.x + sentido * (caixa.size.x * MEIA + andado)
	var canto := Vector2(x - PARTICULA * MEIA, centro.y)
	draw_rect(Rect2(canto, Vector2(PARTICULA, PARTICULA)), WorldPalette.FLASH)


## A caixa de um corpo AGORA, ou SEM_CORPO se ja nao ha corpo nenhum. Os ids
## saem todos do mesmo contador do §45, e por isso um alvo tanto pode ser tropa
## como criatura: pergunta-se aos dois, por esta ordem.
func _caixa_de(id: int) -> Rect2:
	var i := SimLoop.units.index_of(id)
	if i != UnitSystem.NENHUM:
		var tropa: UnitData = _tabela(&"units").get(SimLoop.units.data_ids[i])
		var x := Smoothing.x_of(Smoothing.Group.UNITS, id, SimLoop.units.xs[i])
		return _caixa(x, SimLoop.units.bands[i], tropa)
	var c := SimLoop.creatures.index_of(id)
	if c != UnitSystem.NENHUM:
		var bicho: CreatureData = _tabela(&"creatures").get(SimLoop.creatures.data_ids[c])
		var em := Smoothing.x_of(Smoothing.Group.CREATURES, id, SimLoop.creatures.xs[c])
		return _caixa(em, SimLoop.creatures.bands[c], bicho)
	return SEM_CORPO


## O mesmo rectangulo que o BandView desenha, e nao um parecido: o flash e o
## corpo a piscar, e um flash com outra altura era um segundo corpo por cima.
func _caixa(x: float, faixa: int, dados: Resource) -> Rect2:
	if dados == null:
		return SEM_CORPO
	var escala: int = dados.get(&"scale_tier")
	var alto := WorldPalette.DEGRAU * maxi(1, escala)
	return Silhouette.body_box(Silhouette.Form.CAIXA, x, faixa, alto)


## A pedido, na primeira utilizacao (AGENTS.md, regra 8b): este no e filho da
## cena de jogo e o _ready() dele corre antes do Registry.load_all() dela.
func _tabela(qual: StringName) -> Dictionary:
	if not _tabelas.has(qual):
		_tabelas[qual] = SimFactory.by_id(qual)
	return _tabelas[qual]
