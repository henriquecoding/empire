# src/world/creature_view.gd — os bichos da noite, desenhados (§07, §24, §51, §80).
#
# Saiu do BandView para ele caber nas 250 linhas com o golpe que se ve. O que a
# noite traz so se ve dentro de uma luz: as tuas (as obras que alumiam e o
# archote) e o Lume roxo na base dela (ADR 0034). Fora, o corpo e silhueta — a
# mesma cor com a luz que chega ao chao (§80), e nao uma cor nova.
#
# Cada bicho leva a pose do golpe (StrikePose, CombatFx): arma-se nos ultimos
# instantes do cooldown de quem esta engajado, avanca quando bate, e e empurrado
# e pisca quando leva. Com pele (CreatureSkins) a animacao `attack` acompanha o
# golpe; sem ela, e o contorno que se estica.
class_name CreatureView
extends RefCounted

var _skins := CreatureSkins.new()
var _dados: Dictionary = {}


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
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var id := bichos.ids[i]
		var x := Smoothing.x_of(Smoothing.Group.CREATURES, id, bichos.xs[i])
		if not visible.has_point(Vector2(x, visible.get_center().y)):
			continue
		var estilo := StrikePose.of_creature(dados)
		CombatFx.observe(id, bichos.cooldowns[i], estilo)
		var frente := facing(bichos, i)
		var falta := bichos.cooldowns[i] if bichos.engaged(i) else StrikePose.NUNCA
		var pose := CombatFx.body(id, estilo, falta, frente)
		var caixa := stretched(Silhouette.body_box(forma, x + pose.x, int(band), alto), pose)
		var allied := SimLoop.field.song.allies.has(id)
		var aceso := WorldLight.seen(x, luzes) or allied
		var corpo := luz.body(WorldPalette.BICHO, x)
		var cor := ClassEffects.ALLY if allied else WorldLight.reveal(corpo, aceso, chao)
		LastSeen.remember(id, caixa, forma, cor)
		var view := {
			"foot": Vector2(x + pose.x, WorldPalette.ground_of(int(band))),
			"lit": ClassEffects.ALLY if allied else luz.body(Color.WHITE, x),
			"hidden_tint": cor,
			"revealed": aceso,
			"pose": pose,
			"facing": frente,
			"falta": falta,
		}
		if not _skins.draw_on(canvas, bichos, i, view, tempo):
			_contorno(
				canvas, caixa, forma, cor.lerp(Color.WHITE, CombatFx.flash(id)), frente, tempo
			)
		if aceso:
			Gauge.health(
				canvas, caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i]))
			)
	_skins.forget_except(bichos.ids)


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
