# 02 — Referência · Kingdom, desmontado peça a peça

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Para superares o Kingdom precisas de saber exatamente porque é que ele funciona. Thomas van den Berg e Marco Bancale acertaram em coisas que parecem acidentais e não são — e falharam em coisas que ninguém corrigiu em oito anos.

## As sete decisões que o fazem funcionar

1. Uma única açãoO jogador só faz uma coisa: largar moedas. Contratar, construir, melhorar, alimentar — tudo é a mesma ação, mudando só o alvo. Van den Berg: "em vez de só um botão para saltar, temos só um botão para pagar." O que roubar: a moeda como verbo universal.

## A moeda é física, não um número

Cada moeda é uma moeda no saco. O saco tem capacidade real; as moedas caem no chão quando morres; os inimigos roubam-nas. Isto transforma economia em objeto tangível e elimina praticamente toda a UI.

## O mundo é unidimensional

Esquerda e direita, sem plataformas. O custo que ele próprio reconhece: as táticas de posicionamento ficam limitadas a um eixo, e armas de área comportam-se mal quando os inimigos se empilham. É aqui que entras: a tua segunda camada (§11) resolve exatamente esta limitação.

## Cidadãos previsíveis, não inteligentes

Um algoritmo de atribuição de trabalho top-down: os postos pedem gente, a gente é distribuída, os trabalhadores são "ligeiramente omniscientes". Van den Berg é explícito: "é importante que sejam previsíveis, porque não tens controlo direto sobre eles." Não há behavior trees. Há regras legíveis.

## O roguelike serve a produção, não o género

Ele admite: "é uma forma eficaz de escalar automaticamente a dificuldade", reutiliza assets e elimina saves complexos. Em Two Crowns recuaram — o sistema de decay mantém a maior parte do construído porque "descobrimos que há grande satisfação em construir de forma permanente."

## Zero tutorial, zero UI

Tudo é ensinado por afordância visual e por perda. Funciona porque o vocabulário é minúsculo. Com 48 mecânicas, tu não podes fazer isto — precisas de um sistema de descoberta desenhado (§17 e §25).

## O ciclo tem ritmo de respiração

Manhã (expandir), meio-dia (os portais detetam), tarde (recuar), crepúsculo (posicionar), noite (sobreviver). O sino da manhã marca o início social do dia. Nada interrompe o ritmo do sol exceto as ondas de contra-ataque.

## Os números reais do Two Crowns — referência de escala, não modelo

Estes são os valores publicados do jogo que queres superar. Usa-os para uma coisa só: calibrar a escala. A estrutura da tua economia é diferente da dele (§06) — o Kingdom não tem casas de produção, não tem conversão de matéria em capacidade, não tem comércio, não tem manutenção de tropas nem ganância. O que vale a pena herdar é a legibilidade destes números, não a forma como se ganham.

| Item | Custo KTC | Item | Custo KTC |
| --- | --- | --- | --- |
| Arco | 2 | Barricada | 1 |
| Martelo | 3 | Muro de madeira | 3 |
| Foice | 4 | Muro de pedra | 5 |
| Escudo | 4 | Muro de castelo | 8 |
| Espada | 12 | Muro de ferro | 12 |
| Plataforma elevada | 3 | Fogueira (nível 1) | 3 |
| Torre de vigia | 6 | Aldeia (nível 3) | 9 |
| Torre de defesa | 9 | Castelo (nível 6) | 18 |
| Quinta (dia) | 3 | Casa de quinta | 8 |
| Barril de fogo | 5 | Catapulta | 6 |


- **Capacidade de moedas** — Camponês 2 · Trabalhador 2 · Escudeiro 5 · Arqueiro 11 · Cavaleiro 11 · Agricultor 14
- **Rendimentos de caça** — Coelho 1 · Veado 3 (exige 2 acertos de arqueiro) · Javali 29 · Pesca 1
- **Banqueiro** — 7% de juro diário, com teto de 8 moedas/dia
- **Precisão do arqueiro** — ≈ 1/3 em campo aberto · ≈ 100% dentro de torre
- **Estação** — 16 dias · rotação completa de 4 estações = 64 dias
- **Resistência ao decay** — Muro 1: 2 dias · 2: 4 · 3: 8 · 4: 12 · 5: 20

> **A leitura que interessa**
>
> Repara na compressão: o custo total de subir de barricada a muro de ferro é 29 moedas, e a espada sozinha custa 12. Kingdom mantém quase toda a economia dentro de uma gama de 1 a 30. Isso é deliberado — números pequenos são legíveis quando são objetos físicos no chão. Herda a escala, não a estrutura. Se as tuas muralhas chegarem às 65 moedas (§10), o saco e o transporte têm de acompanhar, e é por isso que existe o cavalo de tração (§12). Mas onde o Kingdom tem uma linha reta entre moeda e coisa, tu tens três circuitos com decisões pelo meio — é aí que os dois jogos divergem, e é aí que o teu ganha.

## Onde o Kingdom falha — e é aí que entras

| Falha admitida | Consequência | A tua resposta |
| --- | --- | --- |
| Economia desequilibra no late game | Van den Berg: "alguns jogadores ficam ricos demais". O desafio desaparece. | Sorvedouros permanentes: ganância do rei, dívida com mercenários, manutenção de tropas (§06, §14, §15) |
| Táticas num só eixo | Combate vira acumulação, não posicionamento | Duas camadas verticais + tropas voadoras (§11) |
| Unidades sem identidade | "Arqueiro n.º 7" é descartável | Classes jogáveis, ofícios que evoluem, tropas que se tornam personagens (§08, §09) |
| Repetição entre corridas | O meio do jogo arrasta | Fortalezas conquistáveis que dão habilidades, kits de arquitetura e mapas (§13) |
| Zero narrativa | Nada a descobrir além de mecânica | 12 diários de campanha, dois epílogos, segredos que ensinam (§17) |
| Sem controlo de foco | Inimigos empilham-se e as flechas desperdiçam-se | O arqueiro marca alvos; as tropas priorizam-nos (§07, §08) |

