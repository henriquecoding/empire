# src/world/world_light.gd — a luz do §80, e a candeia do §74 (F1-17).
#
# O §80 poe a luz no centro da composicao e da-lhe tres regras, e as tres estao
# aqui porque as tres sao contas e nao desenho:
#
#   1 · "Tres paragens, nunca um gradiente." Nucleo, meio, bordo — e depois
#       dissolve para o ambiente com dither. As cores estao em rot.csv.
#   2 · "Uma luz domina por ecra. Se duas competem, o ecra le plano." Com as
#       mesmas paragens, dominar e alcancar mais longe: a candeia de raio maior
#       tem o nucleo e o meio dela mais longe do que qualquer outra luz.
#   3 · "Perto da luz ve-se cor e volume; longe ve-se silhueta." E o §74 diz o
#       que isso quer dizer em jogo: "dentro do raio ve-se o que a Podridao
#       invocou; fora, nao."
#
# Aqui nao ha `draw_` nenhum, como no WorldPalette: sao cores e contas, e quem
# desenha e o BandView. E nao ha aqui nenhum numero de balanceamento — o raio, as
# tres paragens e o dither saem todos do RotProfile.
class_name WorldLight
extends RefCounted

## §80: tres, e nunca um gradiente. E o tamanho do array que stops() devolve, e
## e por isso uma constante e nao um comentario.
const PARAGENS := 3

## Quantos px de arco cada quadrado do dither ocupa. Dois quadrados por par —
## um aceso, um nao — e o passo do anel e por isso o dobro da celula.
const POR_CELULA := 2.0

const MEIA := 0.5

## §75, a tabela da Divida: quantas faixas a candeia ilumina a partir de cada
## limiar de debt_tiers — 1, faixa e meia, 2, o ecra inteiro. O indice e quantos
## limiares ja foram passados (DebtLedger.tier()). Nunca aparece como numero:
## e isto que o jogador ve em vez dele.
const FAIXAS_POR_LIMIAR := [1.0, 1.5, 2.0, 3.0, 3.0]
## A faixa da mancha e uma; o resto reparte-se pelas duas vizinhas.
const VIZINHAS := 2.0


## O raio da candeia neste dia (§74): base + por_dia * dia, com teto. O dia 0 —
## que e o que um mundo por comecar tem — da o raio da base, e nao zero.
static func radius(perfil: RotProfile, dia: int) -> float:
	var raio := perfil.lantern_radius_base + perfil.lantern_radius_per_day * float(maxi(dia, 0))
	return minf(raio, perfil.lantern_radius_max)


## Que fraccao do raio chega a uma faixa que nao e a da mancha, com a Divida
## neste limiar. Zero no principio: "a candeia ilumina 1 faixa" (§75).
static func debt_reach(limiar: int) -> float:
	var faixas: float = FAIXAS_POR_LIMIAR[clampi(limiar, 0, FAIXAS_POR_LIMIAR.size() - 1)]
	return clampf((faixas - 1.0) / VIZINHAS, 0.0, 1.0)


## As tres paragens, do bordo para o nucleo — que e a ordem por que se pintam,
## uma por cima da outra. Fora dessa ordem sao tres discos e nao uma luz.
static func stops(perfil: RotProfile) -> PackedColorArray:
	return PackedColorArray(
		[
			Color.html(perfil.lantern_tint_edge),
			Color.html(perfil.lantern_tint_mid),
			Color.html(perfil.lantern_tint),
		]
	)


## As paragens do fogo que e teu (ADR 0034): ambar, onde o Lume e roxo.
static func fire_stops(perfil: RotProfile) -> PackedColorArray:
	return PackedColorArray(
		[
			Color.html(perfil.fire_tint_edge),
			Color.html(perfil.fire_tint_mid),
			Color.html(perfil.fire_tint),
		]
	)


## O raio de cada paragem, do bordo para o nucleo: o bordo e o raio inteiro e as
## de dentro sao fraccoes iguais dele. Nao ha aqui numero nenhum a afinar — sao
## PARAGENS partes de um raio que vem de data/.
static func stop_radius(raio: float, paragem: int) -> float:
	return raio * float(PARAGENS - paragem) / float(PARAGENS)


## Onde fica cada quadrado do dither que dissolve o bordo para o ambiente (§80).
## Sao pontos sobre a circunferencia, de POR_CELULA em POR_CELULA de arco com um
## intervalo do mesmo tamanho pelo meio — o padrao de dois estados que um dither
## e, e nao uma rampa de alfa, que era o gradiente que o §80 recusa.
static func dither(centro: Vector2, raio: float, celula: float) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	if raio <= 0.0 or celula <= 0.0:
		return pontos
	var passo := celula * POR_CELULA
	var quantos := int(TAU * raio / passo)
	for i in quantos:
		var a := TAU * float(i) / float(quantos)
		pontos.append(centro + Vector2(cos(a), sin(a)) * raio - Vector2(celula, celula) * MEIA)
	return pontos


## §74: "dentro do raio ve-se o que a Podridao invocou; fora, nao". E a pergunta
## por criatura, e mede-se em x porque o mundo e uma linha (§11).
static func lit(x: float, centro: float, raio: float) -> bool:
	return absf(x - centro) <= raio


## A mesma pergunta com resposta continua: quanto da luz chega a este x — 1 no
## centro, 0 no bordo e fora dele. O lit() responde sim ou nao porque o §74 e uma
## regra de jogo e uma regra de jogo nao tem meios-termos; isto responde por
## graus porque o §80 e de composicao, e "perto da luz ve-se cor e volume" e uma
## gradacao e nao um interruptor.
static func reach(x: float, centro: float, raio: float) -> float:
	if raio <= 0.0:
		return 0.0
	return clampf(1.0 - absf(x - centro) / raio, 0.0, 1.0)


## §80: "uma luz domina por ecra". Com as mesmas paragens, a que alcanca mais
## longe e mais forte a QUALQUER distancia — o nucleo e o meio dela chegam onde
## a outra ja e bordo. Empatar nao chega: duas luzes iguais competem.
##
## Uma luz com paragens proprias e mais fracas (`forca` < 1, o farol da Q-078) e
## outra conversa: domina-se se, a cada distancia a que as duas acendem, a
## paragem do Lume (roxo) for mais clara do que a do fogo (ambar) ja enfraquecido.
static func dominates(
	candeia: float, outra: float, forca: float = 1.0, perfil: RotProfile = null
) -> bool:
	if forca >= 1.0 or perfil == null:
		return candeia > outra
	var cores := stops(perfil)
	var fogo := fire_stops(perfil)
	for d in int(minf(candeia, outra)) + 1:
		var minha := cores[_paragem(candeia, d)].get_luminance()
		var dela := fogo[_paragem(outra, d)].get_luminance() * forca
		if minha <= dela:
			return false
	return true


## A paragem que acende a esta distancia de uma luz deste raio: 0 e o bordo.
static func _paragem(raio: float, d: float) -> int:
	for p in range(PARAGENS - 1, -1, -1):
		if d <= stop_radius(raio, p):
			return p
	return 0


## O raio da luz de uma obra, ou zero se ela nao tiver nenhuma. Le-se do
## effect_params do §10 — o farol tem `light_radius`, e as fogueiras (Q-029).
static func hearth_radius(vaga: BuildSlot) -> float:
	if not vaga.standing():
		return 0.0
	return float(vaga.effects.get(&"light_radius", 0.0))


## A forca das paragens de uma obra (Q-078): 1 e a da candeia; menos e mais
## fraca. Sem `light_strength` e a regra do §80, as mesmas tres paragens.
static func hearth_strength(vaga: BuildSlot) -> float:
	return float(vaga.effects.get(&"light_strength", 1.0))


## As tres paragens de uma luz com esta forca: as da candeia, escurecidas.
static func weakened(cores: PackedColorArray, forca: float) -> PackedColorArray:
	var saida := PackedColorArray()
	for cor in cores:
		saida.append(Color(cor.r * forca, cor.g * forca, cor.b * forca, cor.a))
	return saida


## A cor com que um corpo se ve. Aceso, e ele proprio; as escuras, e a silhueta
## que o §80 pede — e a silhueta nao e uma cor nova, e a mesma cor com a luz que
## chega ao chao. Inventar-lhe um valor proprio era escrever paleta em codigo, e
## a paleta e o ART-02.
static func reveal(cor: Color, aceso: bool, chao: float) -> Color:
	if aceso:
		return cor
	return WorldPalette.dim(cor, chao)


## Onde arde o Lume desta noite (ADR 0034): na base de onde a mancha nasceu, e nao
## em cima dela. A mancha anda; o Lume fica.
static func nest_x(rot: RotSystem) -> float:
	return rot.state.trail_from


## As tuas luzes de pe na superficie, em (x, raio): as obras com `light_radius`
## e o archote aceso do rei. E dentro delas que se ve o que a noite traz.
static func hearths(obras: BuildSystem, archote: Vector4 = Vector4.ZERO) -> Array[Vector2]:
	var luzes: Array[Vector2] = []
	for obra in obras.slots:
		var raio := hearth_radius(obra)
		if raio > 0.0 and obra.band == Band.Kind.SURFACE:
			luzes.append(Vector2(obra.x, raio))
	if archote.y > archote.x:
		luzes.append(Vector2((archote.x + archote.y) * MEIA, (archote.y - archote.x) * MEIA))
	return luzes


## Se este x esta dentro de alguma das luzes (x, raio).
static func seen(x: float, luzes: Array[Vector2]) -> bool:
	for l in luzes:
		if lit(x, l.x, l.y):
			return true
	return false
