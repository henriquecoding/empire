# 07 — Combate · novo · O modelo de combate, com a matemática feita

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Esta secção não existia na v2, e é a mais perigosa de deixar por escrever. Num jogo de controlo indireto, o combate não pode ser emocionante — tem de ser legível. O jogador não comanda ninguém; só decide quem existe, onde está e o que traz vestido. Se ele não conseguir prever o resultado antes de a noite começar, o jogo parece aleatório.

## As quatro regras de resolução

**1 · Sem números no ecrã** — Nada de barras de vida flutuantes nem de dano em texto. O estado lê-se pelo sprite: a camada face muda para ferido abaixo de 50%, e o corpo pisca a branco 80 ms ao ser atingido. Vida é informação de silhueta, não de UI.

Herdado do Kingdom e formalizado: um arqueiro em campo aberto acerta ≈1/3 das flechas; dentro de torre, ≈100%. A torre não dá dano — dá certeza. É como se ensina posicionamento sem uma única linha de tutorial.

Tropas aliadas atravessam-se, com separação por steering. Colisão real entre 300 unidades é caro e produz empurrões que parecem bugs. A ocupação de linha é uma regra de dados, não de física (§20).

Toda a morte larga alguma coisa: arma (recolhível pelo Ferreiro n2), moedas transportadas, ou corpo (ressuscitável até ao amanhecer). Nada desaparece silenciosamente — é assim que a perda ensina.

## Tabela mestra de unidades

| Unidade | Custo | Vida | Dano | Interv. | DPS | Alcance | Nota |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Vagabundo | 1 | 10 | 0 | — | 0 | — | Base de tudo. Recrutado com uma moeda. |
| Arqueiro | 3 | 14 | 4 | 1,4 s | 2,9 | 200 px | De dia caça; de noite defende do muro |
| Lanceiro | 4 | 26 | 6 | 1,1 s | 5,5 | 28 px | Segura a linha. Não persegue. |
| Libélula (voadora) | 9 | 16 | 5 | 1,2 s | 4,2 | 40 px | Ignora a camada de solo. Só atacável por arqueiros e torres altas. |
| Berserker de Raiz | 12 | 40 | 12 | 0,9 s | 13,3 | 30 px | Avança sempre. Não recua nem com o muro caído. |
| Mercenário | variável | 34 | 11 | 1,0 s | 11,0 | 30 px | Não é leal. §14. |


### Criaturas da Podridão — a tabela de invocação

| Criatura | Massa | Vida | Dano | Interv. | Vel. | Aparece a partir do |
| --- | --- | --- | --- | --- | --- | --- |
| Rastejante | 8 | 10 | 4 | 1,2 s | 30 | Dia 1 |
| Alado | 14 | 14 | 5 | 1,1 s | 44 | Dia 4 — obriga a torre alta |
| Bruto | 22 | 32 | 9 | 1,3 s | 22 | Dia 7 |
| Cavador | 30 | 28 | 7 | 1,0 s | 26 | Dia 10 — passa pela faixa subterrânea |
| Aríete de lodo | 48 | 90 | 26 | 2,0 s | 16 | Dia 14 — só ataca muralha, ignora tropas |
| Consumidora | 120 | 260 | 30 | 1,8 s | 14 | Dia 20 — alvo do Trepador evoluído (§08) |


## Tempo até matar — a tabela que evita desastres

Segundos que uma unidade demora a matar cada criatura, já com a penalização de precisão do arqueiro em campo aberto. É esta tabela que diz se uma noite é sobrevivível antes de a jogares.

| Atacante | Rastejante | Alado | Bruto | Cavador | Aríete |
| --- | --- | --- | --- | --- | --- |
| Arqueiro (torre) | 4,2 s | 5,6 s | 11,2 s | 9,8 s | 32,2 s |
| Arqueiro (campo) | 12,6 s | 16,8 s | 33,6 s | 29,4 s | 96,6 s |
| Lanceiro | 2,2 s | 3,3 s | 6,6 s | 5,5 s | 16,5 s |
| Berserker | 0,9 s | 1,8 s | 2,7 s | 2,7 s | 7,2 s |
| Mercenário | 1,0 s | 2,0 s | 3,0 s | 3,0 s | 9,0 s |


> **A leitura de design que esta tabela obriga**
>
> Repara na coluna do Aríete: 96,6 segundos para um arqueiro em campo o abater — mais do que uma noite inteira. Isso não é um erro de balanceamento, é a mensagem: arqueiros não param aríetes. Só o muro fortificado (Caminho B, §10), o fosso de raízes ou o barril de fogo o fazem. Cada linha desta tabela tem de ensinar uma coisa dessas. Quando uma coluna não ensinar nada, a criatura é redundante — corta-a.

## Ocupação de linha — como 300 unidades cabem num eixo

O mundo é 1.5D, portanto o combate acontece numa linha. Sem regras, tudo se empilha num pixel. A solução não é física — é uma regra de dados:

- **Faixa de contacto** — Cada muro tem N slots de contacto (2 no nível 1, até 7 no Bastião). Só N atacantes engajam ao mesmo tempo.
- **Fila** — Os restantes esperam a 30–120 px, em posições estáveis atribuídas pelo sistema. Não empurram, não vibram.
- **Substituição** — Quando um atacante morre, o mais próximo da fila ocupa o slot em 0,4 s, com passo visível.
- **Alcance vertical** — Arqueiros em torre atingem a fila inteira dentro de 200 px, não só o slot ocupado. É por isso que a torre é o multiplicador e o muro é o denominador.
- **Marca do arqueiro** — A classe Arqueiro (§08) marca um alvo: todas as tropas aliadas passam a priorizá-lo. Resolve o desperdício de flechas em alvos já mortos — a falha explícita do Kingdom.

## Moral, fuga e a presença do rei

Um único modificador com raio, e três consequências:

- Muro cai → tropas com vida < 30% e custo ≤ 4 fogem para o núcleo.
- Rei em campo → nenhuma tropa foge dentro de um raio de 260 px. A defesa aguenta — e o rei pode morrer. É a decisão tática de maior risco do jogo.
- Impulso Vigília (§15) → ninguém foge esta noite, ao preço de −30% de vida em todas as tropas amanhã.

> **O que testar primeiro, na Fase 1**
>
> Antes de existir arte final, monta um cenário fechado: um muro, seis arqueiros, uma noite de 105 s, vagas de Rastejantes crescentes. Ajusta até a noite ser ganha com 1–2 mortes no dia 5 e perdida sem torre no dia 8. Este microteste é a fundação de todo o balanceamento posterior — e cabe num único ficheiro de teste automatizado (§31).
