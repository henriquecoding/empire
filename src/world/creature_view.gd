# src/world/creature_view.gd — os bichos da noite, desenhados (§07, §24, §51, §80).
#
# Saiu do BandView para ele caber nas 250 linhas com o golpe que se ve. O que a
# noite traz so se ve dentro de uma luz: as tuas (as obras que alumiam e o
# archote) e o Lume roxo na base dela (ADR 0034). Fora, o corpo e silhueta — a
# mesma cor com a luz que chega ao chao (§80), e nao uma cor nova.
#
# Cada bicho leva a pose do golpe (StrikePose, CombatFx): arma-se nos ultimos
# instantes do cooldown de quem esta engajado, avanca quando bate, e e empurrado
# e pisca quando leva. Quem o desenha e o Bestiary (ADR 0049): as sete criaturas
# numa familia so, cada uma com a sua forma e o seu porte, e os olhos acesos em
# roxo mesmo no escuro — e no escuro e so isso que se ve delas (ADR 0048). Uma
# forma que o bestiario nao conheca fica no contorno do Outline.
class_name CreatureView
extends RefCounted

## Meia largura da maior (o Devorador, Q-219): a que tem so o rabo no ecra tambem se ve.
const MEIA_MAIOR := 140.0
const METADE := 0.5

var _dados: Dictionary = {}
## O ultimo x de cada bicho: e por ele que se sabe se anda.
var _xs: Dictionary = {}
var _olhos := PackedColorArray()
var _aliado := PackedColorArray()


func draw_on(
	canvas: CanvasItem,
	band: Band.Kind,
	luz: Lighting,
	luzes: Array[Vector2],
	chao: float,
	tempo: float
) -> void:
	if _dados.is_empty():
		_dados = SimFactory.by_id(&"creatures")
		var perfil := SimFactory.rot_profile()
		var roxo := WorldLight.stops(perfil)
		var ambar := WorldLight.fire_stops(perfil)
		_olhos = PackedColorArray([roxo[1], roxo[2]])  # roxo e dela (ADR 0034)
		_aliado = PackedColorArray([ambar[1], ambar[2]])  # o encantado e teu
	var bichos := SimLoop.creatures
	var visible := PresentationBounds.of(canvas)
	for i in bichos.count():
		if bichos.bands[i] != int(band):
			continue
		var dados: CreatureData = _dados.get(bichos.data_ids[i])
		if dados == null:
			continue
		# A forma e o porte sao a diferenca entre "vem ai uma coisa" e "vem ai um
		# Ariete de lodo, e eu tenho o muro do lado errado" (§07, §51).
		var forma := Silhouette.of_creature(dados)
		var id := bichos.ids[i]
		var x := Smoothing.x_of(Smoothing.Group.CREATURES, id, bichos.xs[i])
		var anda := 0.0 if is_equal_approx(float(_xs.get(id, x)), x) else 1.0
		_xs[id] = x
		if not PresentationBounds.sees(visible, x, MEIA_MAIOR):
			continue
		var estilo := StrikePose.of_creature(dados)
		CombatFx.observe(id, bichos.cooldowns[i], estilo)
		var frente := facing(bichos, i)
		var falta := bichos.cooldowns[i] if bichos.engaged(i) else StrikePose.NUNCA
		var pose := CombatFx.body(id, estilo, falta, frente)
		var caixa := stretched(_caixa(forma, dados, x + pose.x, int(band)), pose)
		var allied := SimLoop.field.song.allies.has(id)
		var aceso := WorldLight.seen(x, luzes) or allied
		var corpo := luz.body(WorldPalette.BICHO, x)
		var cor := ClassEffects.ALLY if allied else WorldLight.reveal(corpo, aceso, chao)
		LastSeen.remember(id, caixa, forma, cor, frente)
		var branco := CombatFx.flash(id)
		Shadow.drop(canvas, x + pose.x, int(band), dados.shadow_width * METADE, 0.0, 0.0)  # Q-219
		if RenewalBeasts.handles(forma):
			var tint := WorldLight.reveal(luz.on(x), aceso, chao)
			if allied:
				tint = WorldPalette.tint(tint, ClassEffects.ALLY)
			(
				RenewalBeasts
				. draw(
					canvas,
					forma,
					caixa,
					frente,
					{
						"time": tempo + float(id) * Bestiary.DESFASE,
						"moving": anda > 0.0 or forma == Silhouette.Form.ASA,
						"tint": tint,
						"flash": branco,
					}
				)
			)
		elif Bestiary.handles(forma):
			var pintar := func(c: Color) -> Color:
				if allied:
					return WorldPalette.tint(c, ClassEffects.ALLY)
				return WorldLight.reveal(luz.body(c, x), aceso, chao)
			var tons := Bestiary.tones(forma, pintar)
			var olhos := _aliado if allied else _olhos
			var t := tempo + float(id) * Bestiary.DESFASE
			Bestiary.draw(canvas, forma, caixa, tons, olhos, t, frente, anda, pose.w)
			if branco > 0.0:
				Bestiary.silhouette(canvas, forma, caixa, Color(1.0, 1.0, 1.0, branco), frente, t)
		else:
			_contorno(canvas, caixa, forma, cor.lerp(Color.WHITE, branco), frente, tempo)
		if aceso:
			Gauge.health(
				canvas, caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i]))
			)
	for id in _xs.keys():
		if id not in bichos.ids:
			_xs.erase(id)


## A caixa de um bicho: a do bestiario, ou a do Silhouette para quem la nao esta.
static func _caixa(forma: Silhouette.Form, dados: CreatureData, x: float, faixa: int) -> Rect2:
	if Bestiary.handles(forma):
		return Bestiary.box(forma, x, faixa)
	var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
	return Silhouette.body_box(forma, x, faixa, alto)


## Uma caixa esticada pela pose (CombatFx.body), com os pes onde estavam.
static func stretched(caixa: Rect2, pose: Vector4) -> Rect2:
	var tamanho := Vector2(caixa.size.x * pose.y, caixa.size.y * pose.z)
	var canto := Vector2(
		caixa.get_center().x - tamanho.x * WorldPalette.MEIA, caixa.end.y - tamanho.y
	)
	return Rect2(canto, tamanho)


## Para onde um bicho olha: para quem bate, para a obra que come, ou para onde
## vai. Nunca zero — um bicho de lado nenhum nao se espelha.
static func facing(bichos: CreatureSystem, i: int) -> float:
	var para := bichos.goal_xs[i]
	var u := SimLoop.units.index_of(bichos.target_ids[i])
	if u != UnitSystem.NENHUM:
		para = SimLoop.units.xs[u]
	else:
		var k := SimLoop.builds.index_of(bichos.target_slots[i])
		if k != BuildSystem.NENHUM:
			para = SimLoop.builds.slots[k].x
	var lado := signf(para - bichos.xs[i])
	return lado if lado != 0.0 else 1.0


## O bicho sem pele: o contorno e o que o faz mexer. As formas olham para a
## direita, e quem vai para a esquerda e espelhado em volta do meio.
static func _contorno(
	canvas: CanvasItem,
	caixa: Rect2,
	forma: Silhouette.Form,
	cor: Color,
	frente: float,
	tempo: float
) -> void:
	var centro := caixa.get_center().x
	canvas.draw_set_transform_matrix(
		Transform2D(0.0, Vector2(frente, 1.0), 0.0, Vector2(centro - centro * frente, 0.0))
	)
	canvas.draw_colored_polygon(Outline.shape(forma, caixa, 0), cor)
	CreatureArt.draw_on(canvas, caixa, forma, cor, tempo)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
