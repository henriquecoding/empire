# src/world/death_burst.gd — uma morte que se ve (§07, §50).
#
# O §07 escreve "nada desaparece silenciosamente — e assim que a perda ensina",
# e uma criatura desaparecia: o CombatSystem tira-a das colunas no tick em que
# morre, e no frame seguinte ja nao havia nada onde ela estava. E a "permanence"
# da Vlambeer ao contrario: o que morre tem de deixar rasto.
#
# Tres tempos, como um golpe que mata nos jogos que se leem bem:
#
#   1 · o corpo fica branco SEGURA_S no sitio — o hitstop de quem mata
#   2 · espalma-se contra o chao em DESFAZ_S
#   3 · os pedacos saltam para o lado para onde o golpe ia, batem no chao uma
#       vez e apagam-se
#
# Puro: o sorteio dos pedacos entra de fora (o fluxo visual, §42 — uma morte
# bonita nao pode mexer no que a semente reproduz), e o tempo tambem.
class_name DeathBurst
extends RefCounted

const SEGURA_S := 0.06
const DESFAZ_S := 0.2
const VIDA_S := 0.85
const GRAVIDADE := 640.0
## Quantos pedacos, pela area do corpo, e de que tamanho (px).
const PEDACOS := {"por_px2": 1.0 / 70.0, "min": 5, "max": 16, "lado_min": 2.0, "lado_max": 4.0}
## Para onde saltam: a direito do golpe, para cima, e espalhados.
const SALTO := {"vx": Vector2(30.0, 150.0), "espalha": 70.0, "vy": Vector2(140.0, 280.0)}
## Ao bater no chao perdem isto.
const RESSALTO := {"vy": -0.35, "vx": 0.5}
const PO := {"raio": Vector2(2.0, 9.0), "cor": Color(0.62, 0.55, 0.45, 0.5), "quantos": 3}
const BRANCO := Color(1.0, 1.0, 1.0, 0.9)

var _art := OriginalArt.new()
var _corpos: Array[Dictionary] = []
var _pedacos: Array[Dictionary] = []
var _po: Array[Dictionary] = []


## Uma criatura morreu como foi vista pela ultima vez (CombatFx.seen): dentro da
## caixa, com a forma, a cor e, se tinha pele, o perfil e o lado para onde olhava
## — e com pele, o que se ve e a animacao `die` dela, que de outro modo nunca
## chegava a passar: o corpo sai das colunas no tick em que morre.
## `sorteio(de, ate) -> float` e o fluxo visual.
func burst(visto: Array, sentido: float, agora: float, sorteio: Callable) -> void:
	var caixa: Rect2 = visto[1]
	var cor: Color = visto[3]
	var pele: Array = visto[4] if visto.size() > 4 else []
	var corpo := {"caixa": caixa, "forma": visto[2], "cor": cor, "t0": agora, "pele": pele}
	corpo["dura"] = SEGURA_S + DESFAZ_S
	if not pele.is_empty():
		corpo["dura"] = SEGURA_S + _art.action_seconds(pele[0], &"die") + DESFAZ_S
	_corpos.append(corpo)
	var area := caixa.size.x * caixa.size.y
	var n := clampi(int(area * PEDACOS.por_px2), PEDACOS.min, PEDACOS.max)
	for k in n:
		var p := Vector2(
			sorteio.call(caixa.position.x, caixa.end.x),
			sorteio.call(caixa.position.y, caixa.get_center().y)
		)
		var vx: float = sentido * sorteio.call(SALTO.vx.x, SALTO.vx.y)
		vx += sorteio.call(-SALTO.espalha, SALTO.espalha)
		var vy: float = -sorteio.call(SALTO.vy.x, SALTO.vy.y)
		var lado: float = sorteio.call(PEDACOS.lado_min, PEDACOS.lado_max)
		var tom := cor.darkened(0.35) if k % 3 == 0 else cor
		_pedacos.append(
			{
				"p": p,
				"v": Vector2(vx, vy),
				"lado": lado,
				"cor": tom,
				"chao": caixa.end.y,
				"t0": agora + SEGURA_S,
				"bateu": false
			}
		)
	dust(Vector2(caixa.get_center().x, caixa.end.y), agora)


## O po que levanta onde um corpo cai — de uma tropa, que fica no chao (§16).
func dust(pe: Vector2, agora: float) -> void:
	for k in PO.quantos:
		var dx := (float(k) - 1.0) * PO.raio.y
		_po.append({"p": pe + Vector2(dx, 0.0), "t0": agora + float(k) * 0.03})


## Os pedacos no ar e no chao: {p, v, lado, cor, chao, t0, bateu}. Para medir.
func pieces() -> Array[Dictionary]:
	return _pedacos


func live() -> int:
	return _corpos.size() + _pedacos.size() + _po.size()


func step(delta: float, agora: float) -> void:
	for pedaco in _pedacos:
		if agora < float(pedaco.t0):
			continue
		pedaco.v.y += GRAVIDADE * delta
		pedaco.p += pedaco.v * delta
		if pedaco.p.y >= pedaco.chao:
			pedaco.p.y = pedaco.chao
			if pedaco.bateu:
				pedaco.v = Vector2.ZERO
			else:
				pedaco.v = Vector2(pedaco.v.x * RESSALTO.vx, pedaco.v.y * RESSALTO.vy)
				pedaco.bateu = true
	_corpos = _corpos.filter(func(c: Dictionary) -> bool: return agora - c.t0 < SEGURA_S + DESFAZ_S)
	_pedacos = _pedacos.filter(func(p: Dictionary) -> bool: return agora - p.t0 < VIDA_S)
	_po = _po.filter(func(p: Dictionary) -> bool: return agora - p.t0 < VIDA_S)


func draw(canvas: CanvasItem, agora: float) -> void:
	for corpo in _corpos:
		if not corpo.pele.is_empty():
			_pele(canvas, corpo, agora)
			continue
		var dt := agora - float(corpo.t0)
		var caixa: Rect2 = corpo.caixa
		if dt < SEGURA_S:
			var branco: Color = BRANCO if Preferences.on(Preferences.FLASHES) else corpo.cor
			canvas.draw_colored_polygon(Outline.shape(corpo.forma, caixa, 0), branco)
			continue
		var p := clampf((dt - SEGURA_S) / DESFAZ_S, 0.0, 1.0)
		canvas.draw_colored_polygon(
			Outline.shape(corpo.forma, flatten(caixa, p), 0), Color(corpo.cor, 1.0 - p)
		)
	for pedaco in _pedacos:
		var dt := agora - float(pedaco.t0)
		if dt < 0.0:
			continue
		var alfa := clampf((VIDA_S - dt) / (VIDA_S * 0.4), 0.0, 1.0)
		var lado: float = pedaco.lado
		var canto: Vector2 = pedaco.p - Vector2(lado, lado) * WorldPalette.MEIA
		canvas.draw_rect(Rect2(canto, Vector2(lado, lado)), Color(pedaco.cor, alfa))
	for nuvem in _po:
		var dt := agora - float(nuvem.t0)
		if dt < 0.0:
			continue
		var p := dt / VIDA_S
		var cor: Color = PO.cor
		cor.a *= 1.0 - p
		canvas.draw_circle(nuvem.p, lerpf(PO.raio.x, PO.raio.y, sqrt(p)), cor)


## A morte com pele: branca no hitstop, depois a animacao `die`, e apaga-se.
func _pele(canvas: CanvasItem, corpo: Dictionary, agora: float) -> void:
	var perfil: StringName = corpo.pele[0]
	var caixa: Rect2 = corpo.caixa
	var pose := OriginalArt.posed(Vector2(caixa.get_center().x, caixa.end.y), corpo.pele[1])
	var dt := agora - float(corpo.t0)
	if dt < SEGURA_S:
		var branco: Color = BRANCO if Preferences.on(Preferences.FLASHES) else corpo.cor
		_art.mask_posed(canvas, perfil, branco, _art.frame_at(perfil, 0.0, &"die", false), pose)
		return
	var frame := _art.frame_at(perfil, dt - SEGURA_S, &"die", false)
	var alfa := clampf((float(corpo.dura) - dt) / DESFAZ_S, 0.0, 1.0)
	var tinta: Color = corpo.pele[2]
	tinta.a *= alfa
	if corpo.pele[3]:
		_art.draw_posed(canvas, perfil, tinta, frame, pose)
	else:
		_art.mask_posed(canvas, perfil, tinta, frame, pose)


## Um corpo espalmado contra o chao: baixa e alarga, com os pes onde estavam.
static func flatten(caixa: Rect2, p: float) -> Rect2:
	var alto := maxf(1.0, caixa.size.y * (1.0 - p))
	var largo := caixa.size.x * (1.0 + 0.3 * p)
	var x := caixa.get_center().x - largo * WorldPalette.MEIA
	return Rect2(x, caixa.end.y - alto, largo, alto)
