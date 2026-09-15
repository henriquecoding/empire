# src/world/outline.gd — o contorno de cada forma do Silhouette (§22, §80).
#
# O Silhouette diz o QUE uma coisa e; isto diz como ela se desenha. Sao contas e
# nao `draw_` nenhum — o mesmo que o WorldPalette faz com as cores e o
# WorldLight com a luz — e por isso um teste mede uma silhueta sem abrir uma
# janela, que e o que o `outline_test.gd` faz.
#
# Cada forma e uma LISTA DE NUMEROS, e nao um bloco de codigo: pares x, y em
# CENTESIMOS da caixa, x da esquerda para a direita e y do topo para o chao.
# Escrever assim custa um terco das linhas, deixa a forma ler-se de uma vez —
# e sobretudo torna evidente o defeito que mais custa aqui: uma forma que sai da
# caixa tapa a tropa que esta a frente dela, e um numero entre 0 e 100 nao sai
# de lado nenhum.
#
# Duas regras mandam em tudo:
#
#   1 · Nenhuma forma sai da caixa. A caixa e o contrato com quem escolhe a
#       altura, e o greybox existe para se ver o que se passa (§67, GB-03).
#   2 · Duas formas nunca desenham a mesma coisa. E a leitura a 1 bit do §80:
#       com a noite castanha, a meio de uma noite o contorno e tudo o que ha, e
#       duas coisas com o mesmo contorno sao uma so.
#
# As MARCAS — o que uma tropa leva na mao — sao a excepcao a regra 1, e de
# proposito: uma arma sai do corpo, e por isso os numeros delas passam de 100 e
# descem abaixo de zero. Ficam em linha aberta e nao em poligono, porque uma
# lanca e um risco e nao uma massa.
class_name Outline
extends RefCounted

## Em que escala os contornos estao escritos. Centesimos e nao fraccoes por uma
## razao de leitura: `0.41, 1.0, 0.41, 0.58` ocupa o dobro de `41, 100, 41, 58`
## e uma forma que precisa de quatro linhas deixa de se ver como uma forma.
const CENTO := 100.0

## Um muro sem nivel ainda tem ameias. Zero dentes deixava um rectangulo — que e
## exactamente o que ninguem distingue de um canteiro.
const DENTES_MIN := 2

## Que fatia de cada vao e dente; o resto e o intervalo. E a que altura da
## parede o dente comeca.
const DENTE_CHEIO := 0.55
const DENTE_ALTO := 0.25

const C_CAIXA := [0, 0, 100, 0, 100, 100, 0, 100]

## Tronco fino, copa larga. §11 da-lhe a faixa aerea e diz porque: "e justamente
## por isso que ela vai ler-se como monumental".
const C_COPA := [41, 100, 41, 58, 0, 58, 18, 12, 50, 0, 82, 12, 100, 58, 59, 58, 59, 100]

## §07: "a torre nao da dano — da certeza". O que se ve e a plataforma de onde
## se dispara, mais larga do que o fuste que a segura.
const C_TORRE := [18, 100, 18, 18, 0, 18, 0, 0, 100, 0, 100, 18, 82, 18, 82, 100]

## A torre alta (§10): fuste mais estreito, plataforma mais acima, e o mastro
## que passa dela. E a obra que chega onde o Alado voa, e ve-se que chega.
const C_MASTRO := [
	28, 100, 28, 32, 0, 32, 0, 22, 38, 22, 50, 0, 62, 22, 100, 22, 100, 32, 72, 32, 72, 100
]

## Producao: duas aguas, e o beiral passa das paredes. E o telhado do §22 — "a
## silhueta do telhado nao muda nunca".
const C_TELHADO := [12, 100, 12, 45, 0, 45, 50, 0, 100, 45, 88, 45, 88, 100]

## Conversao: caixa baixa e chamine alta. O §06 chama-lhe circuito 2 — o que
## entra e materia e o que sai e outra coisa.
const C_CHAMINE := [0, 100, 0, 45, 60, 45, 60, 0, 80, 0, 80, 45, 100, 45, 100, 100]

## Oficio: uma agua so, inclinada. Nao ha aqui simetria nenhuma de proposito — e
## o que a separa do telhado de producao a qualquer distancia.
const C_OFICINA := [0, 100, 0, 55, 100, 0, 100, 100]

## Treino: de onde sai gente, e por isso leva bandeira (§10, a Casa de Treino).
const C_ESTANDARTE := [
	0, 100, 0, 55, 45, 55, 45, 0, 55, 0, 100, 14, 55, 28, 55, 55, 100, 55, 100, 100
]

const C_ABOBADA := [0, 100, 0, 50, 15, 15, 50, 0, 85, 15, 100, 50, 100, 100]

## O Rastejante: baixo, largo e aos bocados. Sao muitos e sao pequenos (§25).
const C_RASTEJO := [0, 100, 20, 0, 42, 35, 58, 35, 80, 0, 100, 100]

## O Alado: corpo estreito e duas asas abertas. §07 — "obriga a torre alta".
const C_ASA := [36, 100, 36, 50, 0, 0, 30, 62, 50, 35, 70, 62, 100, 0, 64, 50, 64, 100]

## O Bruto: ombros largos e cabeca pequena. O que se le dele e o peso.
const C_BRUTO := [12, 100, 12, 35, 0, 28, 22, 0, 78, 0, 100, 28, 88, 35, 88, 100]

## O Cavador: um bico. Vem pelo subsolo e sobe pela passagem antes de bater
## (Q-075), e o que o anuncia e a cabeca em cunha.
const C_BROCA := [0, 100, 0, 45, 50, 0, 100, 45, 100, 100]

## O Ariete de lodo: uma viga deitada. O §07 da-lhe `walls_only` — ele nao olha
## para ninguem, vai ao muro.
const C_ARIETE := [0, 50, 18, 0, 82, 0, 100, 50, 82, 100, 18, 100]

## O Devorador: alto, de coroa serrada. §74 chama-lhe `climbable` — e para se
## subir a ele, e por isso le-se como terreno e nao como bicho.
const C_COLOSSO := [0, 100, 0, 35, 20, 0, 35, 25, 50, 5, 65, 25, 80, 0, 100, 35, 100, 100]

## O Zelador: fino, de capuz, e sem nada nas maos. §75 — nao bate em ninguem;
## leva um nomeado e vai-se embora. A forma diz "nao e para matar".
const C_ZELADOR := [0, 100, 0, 35, 20, 12, 50, 0, 80, 12, 100, 35, 100, 100]

## A tabela, sem um numero la dentro: as formas acima, uma por linha. O muro nao
## esta aqui porque nao e fixo — os dentes dele contam-se (§55).
const FORMAS := {
	Silhouette.Form.CAIXA: C_CAIXA,
	Silhouette.Form.COPA: C_COPA,
	Silhouette.Form.TORRE: C_TORRE,
	Silhouette.Form.MASTRO: C_MASTRO,
	Silhouette.Form.TELHADO: C_TELHADO,
	Silhouette.Form.CHAMINE: C_CHAMINE,
	Silhouette.Form.OFICINA: C_OFICINA,
	Silhouette.Form.ESTANDARTE: C_ESTANDARTE,
	Silhouette.Form.ABOBADA: C_ABOBADA,
	Silhouette.Form.RASTEJO: C_RASTEJO,
	Silhouette.Form.ASA: C_ASA,
	Silhouette.Form.BRUTO: C_BRUTO,
	Silhouette.Form.BROCA: C_BROCA,
	Silhouette.Form.ARIETE: C_ARIETE,
	Silhouette.Form.COLOSSO: C_COLOSSO,
	Silhouette.Form.ZELADOR: C_ZELADOR,
}

## As marcas, no mesmo alfabeto. O ombro e o x = 100, e a arma vai para fora
## dele: o arco abre a frente, a haste passa por cima da cabeca, a viga do
## Ariete atravessa o corpo todo.
const MARCAS := {
	Silhouette.Mark.ARCO: [100, 8, 155, 30, 100, 60],
	Silhouette.Mark.HASTE: [100, 100, 125, -45],
	Silhouette.Mark.LAMINA: [100, 30, 150, -5],
	Silhouette.Mark.FERRAMENTA: [100, 75, 145, -15, 105, -20],
	Silhouette.Mark.MACA: [115, 40, 160, 15],
	Silhouette.Mark.VIGA: [0, 50, 180, 45],
	Silhouette.Mark.VOO: [-20, -5, 50, 18, 120, -5],
}


## O contorno de uma forma dentro de uma caixa. `dentes` so conta para o muro: e
## o numero de slots de contacto do nivel (§55), e mais nada o le.
static func shape(forma: Silhouette.Form, caixa: Rect2, dentes: int) -> PackedVector2Array:
	if forma == Silhouette.Form.AMEIA:
		return _ameia(caixa, dentes)
	return _mapear(caixa, FORMAS.get(forma, C_CAIXA))


## O que uma tropa leva na mao, em linha aberta. `sentido` e -1 ou 1: a arma fica
## do lado para onde ela vai, e sem isso nao se percebe para onde uma tropa esta
## virada — que e metade do que ha para ler numa noite.
static func mark(marca: Silhouette.Mark, caixa: Rect2, sentido: float) -> PackedVector2Array:
	var pontos := _mapear(caixa, MARCAS.get(marca, []))
	if sentido >= 0.0:
		return pontos
	# Espelhar em vez de escrever cada marca duas vezes: uma arma virada ao
	# contrario e a mesma arma, e duas listas divergiam no primeiro acerto.
	var eixo := caixa.get_center().x
	for i in pontos.size():
		pontos[i] = Vector2(eixo + eixo - pontos[i].x, pontos[i].y)
	return pontos


## O muro, com um dente por atacante que engaja (§55). Conta-se de longe, e e a
## unica coisa do §10 que o greybox consegue dizer sem um numero no ecra.
static func _ameia(c: Rect2, dentes: int) -> PackedVector2Array:
	var n := maxi(dentes, DENTES_MIN)
	var base := c.position.y + c.size.y * DENTE_ALTO
	var vao := c.size.x / float(n)
	var pontos := PackedVector2Array([Vector2(c.position.x, c.end.y)])
	for i in n:
		var esq := c.position.x + vao * float(i)
		var dir := esq + vao * DENTE_CHEIO
		pontos.append(Vector2(esq, base))
		pontos.append(Vector2(esq, c.position.y))
		pontos.append(Vector2(dir, c.position.y))
		pontos.append(Vector2(dir, base))
	pontos.append(Vector2(c.end.x, base))
	pontos.append(c.end)
	return pontos


## Os pares de centesimos, postos na caixa. E o unico sitio do ficheiro onde um
## numero vira pixel.
static func _mapear(c: Rect2, centesimos: Array) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	var i := 0
	while i + 1 < centesimos.size():
		var x := float(centesimos[i]) / CENTO * c.size.x
		var y := float(centesimos[i + 1]) / CENTO * c.size.y
		pontos.append(c.position + Vector2(x, y))
		i += 2
	return pontos
