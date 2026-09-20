# src/world/build_view.gd — as obras desenhadas pela forma delas (§25, §55).
#
# Saiu do BandView por duas razoes, e a segunda e a que interessa: o ficheiro
# passava das 250 linhas do §28, e um sitio de obra tem quatro estados que se
# leem de maneiras diferentes — por construir, em andaime, de pe, em ruina — e
# isso merece um ficheiro onde se veem os quatro seguidos.
#
# O que mudou com o Silhouette: ate aqui uma obra era um rectangulo cinzento e
# o que a distinguia de outra era a largura. Agora e a FORMA — o telhado de
# duas aguas de um canteiro, a plataforma de uma torre, o mastro da torre alta,
# os dentes de um muro. O §22 escreve porque: "a paleta muda com a hora do dia e
# com o LUT; a silhueta do telhado nao muda nunca".
#
# E o §25 explica o estado vazio: "a silhueta e o convite. Nao ha botao
# construir". Um sitio por construir desenha-se em contorno, com a altura e a
# forma do que la vai caber — e por isso o convite passa a dizer O QUE se
# constroi ali, e nao so que se pode construir alguma coisa.
class_name BuildView
extends RefCounted

## Quanto resta de uma obra caida, em fraccao da altura que ela tinha. Uma ruina
## desenhada a altura inteira lia-se como uma obra de pe — e a unica ruina que o
## jogo tem hoje e a que acaba a partida (§10, Q-076).
const RUINA := 0.30

const MEIA := 0.5


## Todas as obras desta faixa. `edificios` e a tabela de BuildingData por id,
## montada uma vez por quem desenha.
static func draw_on(
	canvas: CanvasItem, faixa: Band.Kind, edificios: Dictionary, luz: Lighting
) -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.band != faixa:
			continue
		var bounds := PresentationBounds.of(canvas)
		var extent := vaga.width
		if vaga.x + extent < bounds.position.x or vaga.x - extent > bounds.end.x:
			continue
		if BuildingSkins.draw_on(canvas, vaga, luz):
			continue
		_obra(canvas, vaga, Silhouette.of_slot(vaga, edificios), luz, vaga.x)


static func _obra(
	canvas: CanvasItem, vaga: BuildSlot, forma: Silhouette.Form, luz: Lighting, x: float
) -> void:
	var caixa := drawn_box(vaga, forma)
	if vaga.standing():
		_massa(canvas, forma, caixa, vaga, luz.body(WorldPalette.OBRA, x))
		Gauge.health(canvas, caixa, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
		return
	if vaga.state == BuildSlot.State.RUIN:
		_massa(canvas, forma, caixa, vaga, luz.body(WorldPalette.VAZIO, x))
		return
	if vaga.state != BuildSlot.State.EMPTY:
		# Em andaime: a forma do que vem, ja cheia, mas na cor da madeira. §55 —
		# "a obra existe quando uma moeda cai", e a partir dai ve-se o que sera.
		_massa(canvas, forma, caixa, vaga, luz.body(WorldPalette.ANDAIME, x))
		return
	_convite(canvas, vaga, forma, luz, caixa)


## A caixa que esta obra ocupa no ecra AGORA, no estado em que esta. E publica
## porque nao e so o desenho que precisa dela: o PriceTag pousa o preco em cima
## do que se ve, e adivinhar esse topo era ter duas respostas para uma pergunta
## que so tem uma.
static func drawn_box(vaga: BuildSlot, forma: Silhouette.Form) -> Rect2:
	if vaga.standing():
		return _caixa(vaga, forma, vaga.level)
	if vaga.state == BuildSlot.State.RUIN:
		return _rente(_caixa(vaga, forma, maxi(1, vaga.level)))
	if vaga.state != BuildSlot.State.EMPTY:
		return _caixa(vaga, forma, vaga.level + 1)
	# §25: "a silhueta e o convite" — o sitio vazio mostra o TOPO da escada, e nao
	# o primeiro degrau: um sitio de muro promete o Bastiao, nao a estacaria.
	return _caixa(vaga, forma, maxi(1, vaga.costs.size()))


## O contorno que esta obra tem no ecra agora: a caixa dela, na forma dela, com
## os dentes que o nivel lhe da. Publico pela mesma razao que o `drawn_box` — o
## ImpactView pisca a obra atingida (§24) e tem de piscar a MESMA forma, senao o
## que se ve e uma segunda muralha por cima da primeira.
static func drawn_shape(vaga: BuildSlot, forma: Silhouette.Form) -> PackedVector2Array:
	return Outline.shape(forma, drawn_box(vaga, forma), _dentes(vaga))


## §25: "a silhueta e o convite". Contorno, na caixa do topo da escada — um
## sitio de muro mostra o Bastiao que pode vir a ser, e nao a estacaria.
static func _convite(
	canvas: CanvasItem, vaga: BuildSlot, forma: Silhouette.Form, luz: Lighting, fantasma: Rect2
) -> void:
	var pontos := Outline.shape(forma, fantasma, _dentes(vaga))
	pontos.append(pontos[0])
	var cor := luz.body(WorldPalette.VAZIO, vaga.x)
	canvas.draw_polyline(pontos, cor, WorldPalette.CONTORNO)
	Gauge.paid(canvas, fantasma, vaga)


## O que ficou de pe depois de cair. A mesma forma, rente ao chao: reconhece-se
## o que era, e ve-se que ja nao e.
static func _rente(inteira: Rect2) -> Rect2:
	var alto := inteira.size.y * RUINA
	return Rect2(Vector2(inteira.position.x, inteira.end.y - alto), Vector2(inteira.size.x, alto))


## A forma cheia. O `draw_colored_polygon` do Godot triangula o que recebe, e por
## isso um tronco, uns dentes ou um mastro — que sao concavos — entram inteiros.
##
## Por cima dela vem o StructureArt: a forma diz o QUE e, e ele diz como e por
## dentro — tronco e copa, fiadas e ameias, plataforma e seteiras. A ordem
## importa e nao se inverte: o detalhe assenta na massa, nunca a substitui.
static func _massa(
	canvas: CanvasItem, forma: Silhouette.Form, caixa: Rect2, vaga: BuildSlot, cor: Color
) -> void:
	var dentes := _dentes(vaga)
	canvas.draw_colored_polygon(Outline.shape(forma, caixa, dentes), cor)
	StructureArt.draw_on(canvas, forma, caixa, vaga, cor, dentes)


## A caixa de uma obra no nivel que ela tem. A largura vem de data/ — o
## `width_px` do §10 —, e so a altura e do greybox.
static func _caixa(vaga: BuildSlot, forma: Silhouette.Form, nivel: int) -> Rect2:
	var alto := Silhouette.height(forma, nivel)
	var chao := WorldPalette.ground_of(int(vaga.band))
	return Rect2(Vector2(vaga.x - vaga.width * MEIA, chao - alto), Vector2(vaga.width, alto))


## Quantos dentes leva a silhueta deste muro: os slots de contacto do nivel em
## que ele esta (§55), ou os do primeiro degrau enquanto ele nao existe — que e
## o que o convite promete a quem lhe largar as primeiras moedas.
static func _dentes(vaga: BuildSlot) -> int:
	if vaga.level > 0:
		return vaga.contact_slots()
	return vaga.contacts[0] if not vaga.contacts.is_empty() else 0
