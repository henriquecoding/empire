# 74 — Ameaça · novo · A Podridão ganha uma candeia — e o combustível és tu

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A Podridão da v5.2 é meteorologia com orçamento: nasce, avança, gasta massa, recua. É melhor do que ondas, como diz a §05, mas tem um buraco que ninguém apontou — durante os 85 segundos da Manhã e os 85 da Tarde, não há nada que possas fazer em relação a hoje à noite. Constróis, colhes, recrutas. A noite é um número que já está decidido. Esta secção rouba a alavanca 2 da série e fecha esse buraco: a massa da noite passa a ser escrita pelo jogador, de dia, com os seus próprios mortos.

## A candeia

A Podridão passa a trazer uma luz. Uma só, quente, no meio da mancha. É a única coisa iluminada no campo à noite tirando as tuas fogueiras, e a mancha deixa de ser uma sombra que avança para ser alguém a atravessar o campo com uma lanterna. A leitura inverte-se, e é a inversão que faz o arrepio: a coisa que te vem matar é a única que traz luz.

- **Raio da luz** — 150 + 4 × dia px, com teto em 260. Dentro do raio vê-se o que a Podridão invocou; fora, não.
- **Cor** — Âmbar da paleta (família de 5 cores, §22). É a única fonte quente do campo que não é tua.
- **Estado** — O brilho é o mostrador da Dívida da Candeia (§75). Nunca aparece um número.
- **Vulnerabilidade** — Nenhuma. Continua a valer o §05: não pode ser morta em campo aberto, só impedida.

## O Amargueiro

Uma tropa que morre fora das muralhas e não é recolhida antes da alvorada cria raiz. Na Alvorada — a fase de 15 s em que a §05 já manda contar as perdas — o corpo levanta-se transformado numa árvore de madeira escura e resinosa, com a cara da tropa na casca. Não anda, não ataca, não pode ser destruída por dano. Fica ali, e alimenta a noite seguinte.

```gdscript
# v5.2 — §05
M = 60 + 26 * dia + 40 * fortalezas_conquistadas

# v6 — a Podridão come o que deixaste no campo
M = 40 + 18 * dia + 30 * fortalezas
  + 22 * amargueiros + 45 * amargueiros_nomeados
  + 8  * min(recusas_nos_ultimos_5_dias, 5)   # §75
```

A base e o termo do dia descem de propósito. O que a noite tem de duro deixa de vir do calendário e passa a vir de como jogaste.

| Estado do campo | Dia 5 | Dia 10 | Dia 20 | Contra a v5.2, ao dia 20 |
| --- | --- | --- | --- | --- |
| v5.2 (referência) | 190 | 320 | 580 | — |
| Campo limpo — 0 Amargueiros | 130 | 220 | 400 | −31% |
| 3 Amargueiros de pé | 196 | 286 | 466 | −20% |
| 8 Amargueiros de pé | 306 | 396 | 576 | −1% |
| 5 anónimos + 3 nomeados | 375 | 465 | 645 | +11% |


Todas as linhas assumem zero fortalezas conquistadas e zero recusas, para isolar o termo novo. Com três fortalezas ao dia 20 — o que é uma progressão normal — a v5.2 dá 700 e o campo limpo dá 490, e a vantagem do jogador cuidadoso mantém-se em −30%.

Um jogador que arrasta os seus mortos para dentro tem um jogo um terço mais leve do que a v5.2 prometia. Um jogador que os deixa no campo tem um jogo mais pesado. A curva de dificuldade deixa de ser uma reta que subiste no Excel e passa a ser uma consequência — e é uma consequência que se explica sozinha, sem tutorial, na primeira vez que um Amargueiro com a cara de alguém aparece à porta.

## Os três destinos de um Amargueiro

Sempre com o Verbo 1. A moeda que largas é que decide, e a decisão é a mesma que o Lenhador da série tem de tomar todos os dias sem perceber que a está a tomar.

| Destino | Como | Custo | Rende | Efeito na noite |
| --- | --- | --- | --- | --- |
| Cortar | Largar moedas na base, a partir da segunda alvorada. Vem um lenhador da serração (§06). 12 s de corte. | 6 moedas | 1 · 2 · 3 Lenho por escala · 5 se era nomeado | −22 (ou −45) de massa, a partir daí |
| Consagrar | Largar 1 Semente Real na base. Vira Marco de pedra. Pode fazer-se logo na primeira alvorada. | 1 Semente Real | Marco permanente | −22 de massa, e a Podridão abranda 40% num raio de 120 px (a regra de terreno consagrado da §05) |
| Deixar | Nada. | 0 | 0 | +22 (ou +45) de massa por noite, para sempre |


## As três regras que impedem isto de virar uma máquina de dinheiro

> **A falha que a primeira versão desta secção tinha**
>
> Um vagabundo custa 1 moeda a recrutar (units.csv). Se um Amargueiro rendesse três Lenhos vendáveis a 40 moedas, a jogada ótima do jogo passava a ser mandar vagabundos morrer lá fora de propósito: 1 moeda a entrar, 120 a sair. Um sistema de design que premeia matar os teus faz o contrário do que esta parte inteira quer. As três regras abaixo fecham-no, e o teste D-02 da §84 impede que volte a abrir.

| Regra | O quê | Porquê |
| --- | --- | --- |
| 1 · O Lenho não é moeda | Não se vende, não se troca, não tem preço. Só se constrói com ele. | Sem preço não há arbitragem. Acaba com a exploração na raiz, em vez de a tornar menos rentável. |
| 2 · Uma noite de pé | Um Amargueiro só pode ser cortado depois de ter aguentado uma noite inteira. Antes disso a serra não pega. | Pagas sempre os +22 de massa uma vez, por cada árvore. Sacrificar dez vagabundos é +220 na noite seguinte — a matemática do §84 mostra que isso mata um império do dia 6. |
| 3 · Rende o que a pessoa era | Escala 1 e vagabundo: 1 Lenho. Escala 2, tropa: 2. Escala 3, elite ou monarca: 3. Nomeado: 5. | A carne barata rende pouco e a cara rende muito — que é o inverso exato do incentivo perverso. |


> **Para que serve o Lenho Amargo, então**
>
> Para uma coisa só, e é grande. O walls.csv diz que a muralha de nível 4 tem requires_conquest: fornalha — sem conquistares a Fornalha não há muro de ferro, e a Fornalha é um povo de Fase 7. Um Lenho Amargo dispensa esse requisito por segmento. Constróis muro de nível 4 com os teus mortos, pagando na mesma as 36 moedas, dez fases antes de o poderes ter de outra maneira. O bastião de nível 5, que é único por império, custa 3 Lenhos além das 65 moedas.
>
> Não há penalização escondida e não há final mau por o fazeres. A única coisa que o jogo faz é mostrar-te a cara na casca antes de a serra entrar, e cobrar-te 1 ponto de moral do império durante 2 dias se a tropa tinha nome (§76) — porque toda a gente estava a ver.

## Onde o Amargueiro pode nascer, e onde não

- Fora das muralhas — cria raiz. É a regra.
- Dentro das muralhas — não cria. O corpo desaparece na alvorada e conta como perda normal. É o incentivo a arrastar os mortos para dentro, e reutiliza inteiro o gesto que a §16 já tem para o Santuário das Raízes.
- Na faixa subterrânea — cria raiz, e cresce ao contrário, para baixo. Bloqueia a passagem. Os Sob-Raiz têm um problema que os outros povos não têm, e isso é do Ato III (§79).
- Na faixa aérea — não há corpos na faixa aérea; as voadoras caem.
- Sobre terreno consagrado — não cria. Um Marco protege um raio de 120 px de novas raízes, o que faz dele defesa, economia e cemitério ao mesmo tempo.
- Fora da tua região e das adjacentes — cria raiz e fica lá, mas não conta para a tua massa. Um Amargueiro que deixaste a seis ecrãs de distância, numa campanha de conquista, não te persegue a casa. Conta para a massa de quem lá vive.

> **O que isto custa a construir**
>
> Um AmargueiroSystem pequeno pendurado no sinal de alvorada que o GameClock já emite (§48), um termo novo na fórmula do RotSystem (§51), um recurso Lenho Amargo na tabela da §44, um slot de destino no BuildSystem (§55, que já trata moeda física em slots pré-definidos), e um sprite de tronco por escala que reaproveita o slot face das personagens que já desenhaste. Estimativa: 11 h de código, 3 h de arte, e os dois testes que impedem a exploração voltar (D-02 e D-03) estão orçamentados na §84. É o melhor rácio da parte inteira.
