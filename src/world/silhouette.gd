# src/world/silhouette.gd — o que cada coisa e, em forma (§22, §24, §55).
#
# O greybox desenhava tudo com o mesmo rectangulo e mudava-lhe a cor pelo
# ESTADO: verde e meu, vermelho esta a lutar, cinzento e uma obra. A cor diz o
# que se passa e nao diz o QUE E — e por isso um canteiro, uma torre e o
# castelo-arvore eram o mesmo cinzento em larguras diferentes, e quem olhava
# para o ecra tinha de adivinhar.
#
# O §22 ja tinha escrito onde e que a identidade de uma coisa vive: "a paleta
# muda com a hora do dia e com o LUT; a silhueta do telhado nao muda nunca". Com
# a noite castanha do §80 isso deixa de ser conselho de arte e passa a ser a
# unica coisa que resta — a meio de uma noite, tudo o que se ve e o contorno.
# Este ficheiro e o vocabulario dessas formas, e o Outline e quem as desenha.
#
# A classificacao NAO esta escrita aqui: sai da coluna `category` de
# buildings.csv, das `tags` de creatures.csv e do `weapon_kind` de units.csv. Um
# `if id == "archer_tower"` espalhado pelo desenho era conteudo dentro de codigo,
# e no dia em que aparecesse a sexta obra de defesa ninguem se lembrava dele.
#
# As ALTURAS, essas, estao aqui, e sao a unica coisa deste ficheiro que o dossie
# nao decide: sao greybox como o `WorldPalette.DEGRAU` e desaparecem com a arte
# (ART-01, ART-02). Nao mudam nada na simulacao — ver a Q-079.
class_name Silhouette
extends RefCounted

## As formas. Uma por categoria de `buildings.csv`, mais o muro, mais uma por
## criatura. CAIXA e a resposta de quem nao soube dizer o que ali esta: fica um
## rectangulo, que e o que o greybox ja era.
enum Form {
	CAIXA,
	COPA,  # core — o castelo-arvore, e a copa entra na faixa aerea (§10, §11)
	AMEIA,  # o muro — um dente por slot de contacto (§24, §55)
	TORRE,  # defense — de onde se dispara com certeza (§07, §10)
	MASTRO,  # defense + anti_air — a torre alta, a que chega ao Alado (§10)
	TELHADO,  # production — rende por fase (§06, §49)
	CHAMINE,  # conversion — transforma uma materia noutra (§06)
	OFICINA,  # craft — um oficio trabalha aqui (§09)
	ESTANDARTE,  # training — de onde sai gente treinada (§10)
	ABOBADA,  # special — herdeiro, santuario, estabulo (§10, §15)
	RASTEJO,  # swarm — o Rastejante, baixo e largo
	ASA,  # flyer — o Alado, que so a torre alta alcanca
	BRUTO,  # heavy — o Bruto, ombros e massa
	BROCA,  # burrows — o Cavador, que vem por baixo (§11)
	ARIETE,  # siege — o Ariete de lodo, que so quer o muro (§07)
	COLOSSO,  # colossal — o Devorador, que se escala (§74)
	ZELADOR,  # no_attack — o que nao bate e leva um nomeado (§75, §76)
}

## O que uma tropa leva na mao. E o que separa um arqueiro de um lanceiro a dez
## passos — o corpo dos dois e o mesmo rectangulo, e continua a ser.
enum Mark {
	NENHUMA,
	ARCO,  # bow
	HASTE,  # spear, lance
	LAMINA,  # sword, greatsword, dagger
	FERRAMENTA,  # hammer, pick, hoe
	MACA,  # club
	VIGA,  # ram
	VOO,  # sem arma, mas voa (tag `flyer`)
}

## As formas que uma OBRA pode tomar. As outras sao corpos, e um corpo nao tem
## nivel nem altura de obra — tem o `scale_tier` do §22.
const OBRAS: Array[Form] = [
	Form.CAIXA,
	Form.COPA,
	Form.AMEIA,
	Form.TORRE,
	Form.MASTRO,
	Form.TELHADO,
	Form.CHAMINE,
	Form.OFICINA,
	Form.ESTANDARTE,
	Form.ABOBADA,
]

## As tags e as colunas que a classificacao le. Escritas uma vez para que uma
## mudanca no CSV chumbe aqui, e nao silenciosamente no ecra.
const ANTIAEREA := &"anti_air"
const VOADORA := &"flyer"

## Categoria -> forma. E a coluna `category` de buildings.csv, inteira.
const POR_CATEGORIA := {
	&"core": Form.COPA,
	&"defense": Form.TORRE,
	&"production": Form.TELHADO,
	&"conversion": Form.CHAMINE,
	&"craft": Form.OFICINA,
	&"training": Form.ESTANDARTE,
	&"special": Form.ABOBADA,
}

## Tag -> forma, pela ordem por que se pergunta. A primeira que bate ganha: o
## Ariete de lodo e `rot|siege` e o Devorador e `rot|colossal`, e a tag `rot`
## nao esta aqui de proposito — ela e o que TODAS teem em comum.
const POR_TAG: Array[Array] = [
	[&"swarm", Form.RASTEJO],
	[VOADORA, Form.ASA],
	[&"heavy", Form.BRUTO],
	[&"burrows", Form.BROCA],
	[&"siege", Form.ARIETE],
	[&"colossal", Form.COLOSSO],
	[&"no_attack", Form.ZELADOR],
]

## Arma -> marca. E a coluna `weapon_kind` de units.csv, inteira.
const POR_ARMA := {
	&"bow": Mark.ARCO,
	&"spear": Mark.HASTE,
	&"lance": Mark.HASTE,
	&"sword": Mark.LAMINA,
	&"greatsword": Mark.LAMINA,
	&"dagger": Mark.LAMINA,
	&"hammer": Mark.FERRAMENTA,
	&"pick": Mark.FERRAMENTA,
	&"hoe": Mark.FERRAMENTA,
	&"club": Mark.MACA,
	&"ram": Mark.VIGA,
}

## Altura de cada obra, em DEGRAUS do §01 — 16 px, metade de uma pessoa. Le-se
## em pessoas: um canteiro da pelo ombro, uma torre e cinco pessoas, a torre
## alta e oito. Sao numeros de greybox e nao de balanceamento (Q-079).
const DEGRAUS := {
	Form.CAIXA: 1.5,
	Form.TELHADO: 2.0,
	Form.ABOBADA: 2.5,
	Form.CHAMINE: 3.0,
	Form.OFICINA: 3.0,
	Form.ESTANDARTE: 3.5,
	Form.TORRE: 5.0,
	Form.MASTRO: 8.0,
}

## O PORTE de um corpo: quanto ele mede de largo e de alto, em fraccoes da
## altura que o `scale_tier` do §22 lhe da. E a metade da leitura que o contorno
## sozinho nao faz — um Rastejante e um Zelador podiam ter o mesmo contorno e
## continuavam a separar-se por um ser baixo e largo e o outro fino e alto.
##
## O por omissao — meia largura, altura inteira — e o que o greybox ja fazia com
## toda a gente, e continua a ser o de uma tropa: uma pessoa e uma pessoa.
const PORTE_BASE := Vector2(0.5, 1.0)
const PORTE := {
	Form.RASTEJO: Vector2(1.25, 0.55),  # rente ao chao, e muitos
	Form.ASA: Vector2(1.30, 0.80),  # as asas abertas ocupam mais do que o corpo
	Form.BRUTO: Vector2(0.90, 1.00),
	Form.BROCA: Vector2(0.60, 1.00),
	Form.ARIETE: Vector2(1.45, 0.50),  # uma viga deitada, e nada mais
	Form.COLOSSO: Vector2(0.75, 1.30),  # o unico que passa da sua propria escala
	Form.ZELADOR: Vector2(0.35, 1.05),  # fino: nao vem bater, vem levar alguem
}

## Quanto o muro cresce por nivel, em degraus. O nivel 1 e uma estacaria pela
## cintura e o Bastiao passa dos tres metros — e o §25 quer que a subida se
## veja, nao que se leia num contador.
const DEGRAU_POR_NIVEL := 1.2
const DEGRAU_BASE_MURO := 0.8

## Quanto a copa sobe ACIMA do fundo da faixa aerea. §11: "a copa da arvore
## colossal do castelo" entra na faixa aerea, e por isso a altura dela nao e uma
## escolha de escala — e a geometria das faixas, que ja esta no Band.
const COPA_NA_AEREA := 0.25


## A forma de um sitio de obra. `edificios` e a tabela de BuildingData por id,
## montada uma vez por quem desenha — um Registry por obra e por frame era a
## pesquisa de recurso que o §63 conta como custo.
static func of_slot(vaga: BuildSlot, edificios: Dictionary) -> Form:
	# O muro nao esta em buildings.csv: esta em walls.csv, e o que o distingue no
	# mundo e ter os dois caminhos do §10. Perguntar pelo id era escolher um dos
	# cinco niveis e esquecer os outros quatro.
	if vaga.two_paths():
		return Form.AMEIA
	var dados: BuildingData = edificios.get(vaga.kind)
	return of_building(dados) if dados != null else Form.CAIXA


static func of_building(dados: BuildingData) -> Form:
	if dados == null:
		return Form.CAIXA
	# §10: a torre alta e a unica obra que se distingue de outra da mesma
	# categoria pelo que FAZ, e o que ela faz esta escrito na tag.
	if dados.tags.has(ANTIAEREA):
		return Form.MASTRO
	return POR_CATEGORIA.get(dados.category, Form.CAIXA)


static func of_creature(dados: CreatureData) -> Form:
	if dados == null:
		return Form.CAIXA
	for par in POR_TAG:
		if dados.tags.has(par[0]):
			return par[1]
	return Form.CAIXA


## O que uma tropa leva na mao. Sem arma nao ha marca — um vagabundo tem as maos
## vazias e e isso que o distingue de toda a gente (§25, minuto 0:20).
static func of_unit(dados: UnitData) -> Mark:
	if dados == null:
		return Mark.NENHUMA
	if dados.weapon_kind.is_empty():
		return Mark.VOO if dados.tags.has(VOADORA) else Mark.NENHUMA
	return POR_ARMA.get(dados.weapon_kind, Mark.NENHUMA)


## A altura de uma obra, em px. O nivel so conta para o muro: um canteiro de
## nivel 1 e o unico canteiro que existe, e um sitio por construir — nivel 0 —
## tem a altura do que la vai caber, senao nao havia silhueta para convidar
## ninguem (§25: "a silhueta e o convite").
static func height(forma: Form, nivel: int) -> float:
	if forma == Form.COPA:
		return WorldPalette.ground_of(int(Band.Kind.SURFACE)) - _topo_da_copa()
	if forma == Form.AMEIA:
		var degraus := DEGRAU_BASE_MURO + DEGRAU_POR_NIVEL * float(maxi(1, nivel))
		return degraus * WorldPalette.DEGRAU
	return float(DEGRAUS.get(forma, DEGRAUS[Form.CAIXA])) * WorldPalette.DEGRAU


## A caixa de um corpo pousado na linha de chao da sua faixa, com o porte da sua
## forma. `alto` e a altura do §22 — DEGRAU x scale_tier — e e ela que manda: o
## porte reparte-a em largura e altura, e nao a substitui.
static func body_box(forma: Form, x: float, faixa: int, alto: float) -> Rect2:
	var porte: Vector2 = PORTE.get(forma, PORTE_BASE)
	var tamanho := Vector2(alto * porte.x, alto * porte.y)
	var chao := WorldPalette.ground_of(faixa)
	return Rect2(Vector2(x - tamanho.x * WorldPalette.MEIA, chao - tamanho.y), tamanho)


## Onde a copa acaba, em y. Entra na faixa aerea o suficiente para se ver que
## entrou, e nao mais: uma copa colada ao topo do ecra deixava de ter ceu por
## cima e o §11 pede o contrario — "espaco entre os dois".
static func _topo_da_copa() -> float:
	return float(Band.AERIAL_BOTTOM) * (1.0 - COPA_NA_AEREA)
