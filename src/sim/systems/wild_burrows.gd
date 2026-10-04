# src/sim/systems/wild_burrows.gd — as tocas das terras geradas (Q-217, ADR 0058).
#
# O dono, a 03/10/2026: «eles devem spawnar logo ao lado do meu imperio dos dois lados e
# depois de forma mais organica e aleatoriamente pelo mundo». Como no Kingdom, a caca
# vive para la das tuas muralhas: cada segmento de trilho que nasce ao andar traz as
# suas tocas, nos sitios que o segmento tem (a floresta tem arvores, o lago tem agua,
# Q-150), com ate `per_segment_max` tocas de cada bicho. O primeiro segmento de cada lado
# garante caca pequena, nao uma toca de todas as especies (ADR 0062).
#
# Puro e sem sorteio proprio: os numeros chegam de fora (o RngService.scatter pelo sitio),
# e o mesmo segmento da as mesmas tocas venha o rei quando vier.
class_name WildBurrows
extends RefCounted

## Quantos sorteios um segmento gasta: um por bicho e tres por toca.
const SORTEIOS := 40
const MAX_BICHOS := 8
const POR_TOCA := 3
## O que um segmento deixa livre nas pontas, e a volta do assunto dele (o acampamento, a
## ruina, a boca da masmorra), para a toca nao lhe ficar em cima.
const MARGEM_PX := 40.0
const SUJEITO_PX := 72.0
## O chao minimo entre duas tocas: a toca ao dobro e o bicho a escala dele (Q-218).
const FOLGA_PX := 192.0
const METADE := 0.5
## As chaves de cada toca.
const X := &"x"
const SITIO := &"source"
const BICHO := &"game"

## Os sitios de onde a caca sai em cada tipo de segmento (Q-150): autoria de nivel, como
## os sitios das tocas de casa (HuntWatch.SITIOS). Os povos, as fortalezas, os limiares e
## as bordas nao tem caca.
const SITIOS := {
	&"empty": [&"bush", &"rock", &"hole"],
	&"forest": [&"tree", &"bush", &"hole"],
	&"water": [&"lake", &"bush"],
	&"ruin": [&"rock", &"hole"],
	&"vagrant_camp": [&"bush"],
	&"mercenary_camp": [&"bush"],
}


## As tocas do segmento que comeca em `inicio`, com `largura` px, de tipo `tipo` e o
## assunto em `sujeito`. `bichos` sao os do bioma dele, do mais miudo para o mais caro;
## `garantido` poe uma primeira toca, nunca obriga todas as especies a coexistirem.
static func draw(
	inicio: float,
	largura: float,
	sujeito: float,
	tipo: StringName,
	bichos: Array[WildlifeData],
	sorteios: PackedFloat32Array,
	garantido: bool
) -> Array[Dictionary]:
	var tocas: Array[Dictionary] = []
	var sitios: Array = SITIOS.get(tipo, [])
	if sitios.is_empty() or sorteios.size() < SORTEIOS or largura <= 0.0:
		return tocas
	for b in mini(bichos.size(), MAX_BICHOS):
		var dados := bichos[b]
		var dele := _sitios_de(dados, sitios)
		if dados.per_segment_max <= 0 or dele.is_empty():
			continue
		var n := mini(floori(sorteios[b] * float(dados.per_segment_max + 1)), dados.per_segment_max)
		if garantido and tocas.is_empty():
			n = maxi(n, 1)
		for _k in n:
			var j := MAX_BICHOS + POR_TOCA * tocas.size()
			if j + POR_TOCA > sorteios.size():
				break
			var sitio: StringName = dele[mini(floori(sorteios[j] * dele.size()), dele.size() - 1)]
			var order := -INF if garantido and tocas.is_empty() else sorteios[j + 1]
			tocas.append({BICHO: dados.id, SITIO: sitio, &"ordem": order})
	return _por_no_chao(tocas, inicio, largura, sujeito, sorteios)


## Os sitios de `dados` que o segmento tem, pela ordem do bicho.
static func _sitios_de(dados: WildlifeData, sitios: Array) -> Array[StringName]:
	var saida: Array[StringName] = []
	for s in dados.sources:
		if sitios.has(s):
			saida.append(s)
	return saida


## Cada toca numa fatia do chao livre, misturadas pela ordem sorteada, com FOLGA_PX entre
## vizinhas; as que nao cabem ficam de fora.
static func _por_no_chao(
	tocas: Array[Dictionary],
	inicio: float,
	largura: float,
	sujeito: float,
	sorteios: PackedFloat32Array
) -> Array[Dictionary]:
	var a := inicio + MARGEM_PX
	var b := inicio + largura - MARGEM_PX
	var buraco := Vector2(clampf(sujeito - SUJEITO_PX, a, b), clampf(sujeito + SUJEITO_PX, a, b))
	var livre := (b - a) - (buraco.y - buraco.x)
	var n := mini(tocas.size(), floori(livre / FOLGA_PX))
	var saida: Array[Dictionary] = []
	tocas.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p[&"ordem"] < q[&"ordem"])
	var fatia := livre / float(maxi(n, 1))
	for k in n:
		var u := sorteios[MAX_BICHOS + POR_TOCA * k + 2]
		var t := float(k) * fatia + FOLGA_PX * METADE + u * (fatia - FOLGA_PX)
		var x := a + t
		if x >= buraco.x:
			x += buraco.y - buraco.x
		var toca := tocas[k]
		toca.erase(&"ordem")
		toca[X] = x
		saida.append(toca)
	return saida
