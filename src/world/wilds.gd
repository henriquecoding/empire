# src/world/wilds.gd — o que cresce e o que vive numa regiao, pela semente.
#
# Ate aqui o campo entre o horizonte e o caminho era uma faixa lisa, e todas as
# regioes da campanha tinham a mesma. Isto enche-o, e enche-o de maneira
# diferente em cada bioma (biomes.csv) e em cada regiao: a regiao N e o troco N
# de um mundo que nao acaba — o ruido e amostrado a partir de N * TROCO, e por
# isso atravessar para a regiao seguinte (Q-135) e chegar a terra nova.
#
# Duas tecnicas, as que a geracao procedural usa para isto:
#   · Grelha com tremor (jittered grid): cada camada de flora tem um passo; em
#     cada celula ha no maximo uma planta, num sitio tremido dentro dela. Da o
#     espacamento minimo do Poisson sem o custo, e as celulas estao presas ao
#     mundo — a mesma celula da sempre a mesma planta, venha de onde vier.
#   · Densidade por ruido continuo (RngService.noise): onde o ruido e alto ha
#     bosque, onde e baixo ha clareira. Cada camada tem o seu limiar — a erva
#     cresce em quase todo o lado, o arbusto so onde o bosque e cerrado.
#
# Nada disto entra na simulacao nem no save: e cenario (src/world/).
class_name Wilds
extends RefCounted

enum Plant {
	GRASS,
	TALL_GRASS,
	FLOWER,
	FERN,
	BUSH,
	REED,
	ROCK,
	DRY_SHRUB,
	MUSHROOM,
	STUMP,
	SAPLING,
	FAR_PINE,
	FAR_OAK
}
## Nenhum e caca: coelho, veado e javali sao do HuntingSystem, e um bicho de
## cenario com a cara de um que se caca era uma mentira (o passaro branco do
## Kingdom Two Crowns, que foge e nao se caca, e a regra).
enum Animal { SONGBIRD, CROW, BUTTERFLY, FIREFLY, BIRD, BAT, GULL }

## Cada planta: tipo, x, fundo (0 a frente, 1 no horizonte) e variante (0..1).
const PLANTA := 4
## Cada bicho: tipo, x e variante.
const BICHO := 3
const TROCO := 100000.0
const BIOMA_POR_OMISSAO := &"ancient_forest"
const SAL := {"campo": 11, "horizonte": 23, "fauna": 37, "noite": 41}
## O tremor fica dentro da celula e longe das bordas: e o espacamento minimo.
const TREMOR := {"de": 0.15, "largo": 0.7}
## Quanto acima do limiar o ruido tem de ir para a planta ser certa, e o minimo
## de probabilidade logo acima dele — sem isto a borda de um bosque e uma linha.
const ORLA := {"largo": 0.35, "piso": 0.15}
## O ruido do motor anda em [-0,75, 0,65]; isto abre-o a [0, 1].
const RUIDO := {"frequencia": 0.0021, "oitavas": 3, "ganho": 0.8}

## Por bioma, as camadas do campo: (tipo, passo em px, limiar de densidade).
const CAMPO := {
	&"ancient_forest":
	[
		[Plant.TALL_GRASS, 16.0, 0.15],
		[Plant.FERN, 30.0, 0.35],
		[Plant.BUSH, 84.0, 0.45],
		[Plant.MUSHROOM, 64.0, 0.55],
		[Plant.FLOWER, 46.0, 0.5],
		[Plant.STUMP, 300.0, 0.5],
	],
	&"coast": [[Plant.TALL_GRASS, 18.0, 0.2], [Plant.REED, 36.0, 0.45], [Plant.ROCK, 110.0, 0.4]],
	&"canyon": [[Plant.ROCK, 42.0, 0.2], [Plant.DRY_SHRUB, 52.0, 0.35], [Plant.GRASS, 26.0, 0.5]],
	&"floodplain":
	[
		[Plant.GRASS, 12.0, 0.1],
		[Plant.FLOWER, 24.0, 0.3],
		[Plant.REED, 44.0, 0.55],
		[Plant.BUSH, 110.0, 0.5],
		[Plant.SAPLING, 220.0, 0.55],
	],
	&"volcanic": [[Plant.ROCK, 34.0, 0.2], [Plant.DRY_SHRUB, 72.0, 0.5], [Plant.STUMP, 190.0, 0.6]],
	&"subterranean":
	[[Plant.MUSHROOM, 28.0, 0.3], [Plant.FERN, 48.0, 0.45], [Plant.ROCK, 80.0, 0.4]],
}

## A linha de arvores do horizonte, na mesma forma.
const HORIZONTE := {
	&"ancient_forest": [[Plant.FAR_OAK, 34.0, 0.25], [Plant.FAR_PINE, 22.0, 0.4]],
	&"coast": [[Plant.FAR_PINE, 64.0, 0.6]],
	&"canyon": [[Plant.FAR_PINE, 90.0, 0.7]],
	&"floodplain": [[Plant.FAR_OAK, 38.0, 0.35]],
	&"volcanic": [[Plant.FAR_PINE, 110.0, 0.75]],
	&"subterranean": [[Plant.FAR_OAK, 52.0, 0.5]],
}

## Os bichos de cada bioma: (tipo, quantos por mil px). O pardal pousa num
## arbusto e por isso nao esta aqui — nasce dos arbustos (POUSO).
const FAUNA := {
	&"ancient_forest":
	[
		Animal.BUTTERFLY,
		1.5,
		Animal.CROW,
		0.8,
		Animal.FIREFLY,
		6.0,
		Animal.BIRD,
		2.0,
		Animal.BAT,
		1.0
	],
	&"coast": [Animal.GULL, 1.5, Animal.BUTTERFLY, 0.5, Animal.FIREFLY, 2.0, Animal.BIRD, 1.5],
	&"canyon": [Animal.CROW, 1.2, Animal.BIRD, 1.5, Animal.BAT, 1.5, Animal.FIREFLY, 1.0],
	&"floodplain":
	[Animal.BUTTERFLY, 3.0, Animal.CROW, 0.8, Animal.FIREFLY, 10.0, Animal.BIRD, 2.5],
	&"volcanic": [Animal.CROW, 1.5, Animal.BAT, 2.0, Animal.BIRD, 1.0],
	&"subterranean": [Animal.BAT, 3.0, Animal.FIREFLY, 3.0, Animal.BUTTERFLY, 0.5],
}
const POUSO := 0.5
const MIL := 1000.0
const MEIO := 0.5
## Terraria: ha noites de enxame e noites de poucos. Quanto dos pirilampos se ve.
const ENXAME := {"de": 0.3, "ate": 1.0}


## A densidade do bosque em x, de 0 a 1, para `ruido` ja semeado.
static func density(ruido: Noise, x: float) -> float:
	return clampf(MEIO + ruido.get_noise_1d(x) * RUIDO.ganho, 0.0, 1.0)


## O ruido do bosque para esta semente. Um so para todas as camadas: e isso que
## poe o feto e o arbusto no mesmo bosque, e a clareira vazia dos dois.
static func woods() -> FastNoiseLite:
	return RngService.noise(SAL.campo, RUIDO.frequencia, RUIDO.oitavas)


## O bioma de uma tabela, ou o de omissao se o bioma nao tiver entrada nela.
static func table(tabelas: Dictionary, bioma: StringName) -> Array:
	return tabelas.get(bioma, tabelas[BIOMA_POR_OMISSAO])


## As plantas de `camadas` entre `a` e `b`, em quadruplos (tipo, x, fundo,
## variante), das de tras para as da frente. `regiao` desloca o ruido.
static func plants(
	camadas: Array, a: float, b: float, regiao: int, sal: int, ruido: Noise
) -> PackedFloat32Array:
	var achadas: Array[PackedFloat32Array] = []
	var desvio := float(regiao) * TROCO
	for n in camadas.size():
		var camada: Array = camadas[n]
		var passo: float = camada[1]
		for celula in range(floori(a / passo), floori(b / passo) + 1):
			var d := RngService.scatter(hash([sal, regiao, n, celula]), PLANTA)
			var x := (float(celula) + TREMOR.de + d[0] * TREMOR.largo) * passo
			if x < a or x >= b:
				continue
			var acima := density(ruido, x + desvio) - float(camada[2])
			if acima < 0.0 or d[1] > ORLA.piso + acima / ORLA.largo:
				continue
			achadas.append(PackedFloat32Array([camada[0], floorf(x), d[2], d[PLANTA - 1]]))
	achadas.sort_custom(
		func(p: PackedFloat32Array, q: PackedFloat32Array) -> bool: return p[2] > q[2]
	)
	var saida := PackedFloat32Array()
	for p in achadas:
		saida.append_array(p)
	return saida


## Os bichos entre `a` e `b`, em triplos (tipo, x, variante). Os pardais nascem
## nos arbustos de `plantas`, os outros espalhados.
static func animals(
	tabela: Array, a: float, b: float, regiao: int, plantas: PackedFloat32Array
) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	for i in range(0, plantas.size(), PLANTA):
		if int(plantas[i]) == Plant.BUSH and plantas[i + PLANTA - 1] < POUSO:
			saida.append_array(
				PackedFloat32Array([Animal.SONGBIRD, plantas[i + 1], plantas[i + 2]])
			)
	var lista := tabela
	for k in range(0, lista.size(), 2):
		var quantos := roundi(float(lista[k + 1]) * (b - a) / MIL)
		for j in quantos:
			var d := RngService.scatter(hash([SAL.fauna, regiao, lista[k], j]), 2)
			saida.append_array(PackedFloat32Array([lista[k], lerpf(a, b, d[0]), d[1]]))
	return saida


## Quanto do enxame de pirilampos se ve na noite `dia` (Terraria: umas noites
## muitos, outras poucos). A mesma noite da sempre o mesmo.
static func swarm(dia: int) -> float:
	var d := RngService.scatter(hash([SAL.noite, dia]), 1)
	return lerpf(ENXAME.de, ENXAME.ate, d[0])


## O bioma da regiao em que se esta, pelo plano da campanha (Q-135).
static func biome_now() -> StringName:
	var estado := SimLoop.state
	if estado == null:
		return BIOMA_POR_OMISSAO
	var regioes := estado.chapters.regions
	if estado.region < 0 or estado.region >= regioes.size():
		return BIOMA_POR_OMISSAO
	return StringName(regioes[estado.region])
