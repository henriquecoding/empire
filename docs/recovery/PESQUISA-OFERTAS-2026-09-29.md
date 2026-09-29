# A Oferta e as consequências de escolher — pesquisa e desenho (Q-101)

_29 de setembro de 2026. Pedido do dono no painel, na Q-101 (a recusar todas as ofertas, a defesa do décimo dia cai
ao dia 9): «Faça uma pesquisa e embase todo esse sistema, há sempre consequências das escolhas feitas.»_

## A pergunta

A §75 dá à Podridão uma voz: uma oferta por noite, com preço e efeito; aceitar sobe a Dívida da Candeia (que nunca
desce); recusar custa +8 de massa por recusa nas últimas cinco noites, até +40. Medido pelo `dez_dias`, a defesa que
fecha a Fase 1 aguenta dez noites com a mancha calada e **cai ao dia 9–10 a recusar tudo**. A Q-101 perguntava se o
§66 deve valer para quem recusa sempre.

## O que outros jogos fazem com pactos

| Jogo | O pacto | O que recusar custa | O que serve aqui |
|---|---|---|---|
| **Inscryption** | Sacrificar cartas por poder. | Nada imediato: perdes o poder que não compraste. | A recusa é uma escolha tão pesada como aceitar — **mas só se o mundo continuar a apertar**. |
| **Darkest Dungeon** (relíquias, cursos) | Curiosidades que dão e tiram. | Não há custo em ignorar. | O contrário do que o dono pede: ignorar sem custo torna a escolha vazia. |
| **Faustian bargains** no *roguelike* (Hades — *Pact of Punishment*; Slay the Spire — Neow) | Troca-se dificuldade por recompensa, antes da corrida. | Jogar sem o pacto é o modo normal. | O pacto como **seletor de dificuldade**: quem recusa escolhe a curva base, quem aceita escolhe outra. |
| **Frostpunk** (leis) | Cada lei dá e tira; algumas bifurcam a partida. | Não assinar deixa a crise por resolver. | **Recusar é também uma decisão com efeito**: a crise não espera. |
| **Kingdom Two Crowns** (a Greed) | Não negocia; só aperta com o tempo. | — | A pressão de fundo existe sempre, com ou sem pacto. |
| **Cultist Simulator** | Cada acordo tem um preço permanente. | Recusar é possível, mas o relógio corre. | A **dívida que nunca desce** — é a §75. |

**O que se tira:** num jogo de pactos com pressão contínua, recusar sempre tem de ter preço, senão a oferta é
decoração; e aceitar tem de ter preço, senão é um *power-up*. A §75 já tem os dois lados. O que faltava era dizer, no
teste do §66, qual dos dois é o jogo de referência.

## A decisão

1. **O §66 mede-se com a voz calada** — a curva da §74 sozinha, que é o que o F1-16 afinou — e continua a ser o portão:
   a defesa do décimo dia aguenta dez noites inteiras.
2. **Recusar tudo tem consequência, e agora é um teste e não uma pergunta aberta**: com a voz a cobrar todas as
   recusas, a mesma defesa **cai** (`test_recusar_todas_as_ofertas_tem_consequencia`). Deixou de ser um teste saltado:
   é a regra do dono, «há sempre consequências das escolhas feitas».
3. **As ofertas passaram a ter mais por onde pegar** (Q-099): com o herdeiro, o Marco, a escora e a classe ligados,
   uma noite oferece mais do que moedas e nomes — e o que se aceita tira sempre alguma coisa ao reino, que não volta.
4. **Nada de números mexidos para calar a medição**: o imposto das recusas continua a ser o da §75 (+8 por recusa, até
   +40), e a Dívida continua a só subir.

## O que fica para o playtest

- Se a curva de quem recusa tudo deve ser «cai ao dia 9–10» ou mais branda: é o `refusal_mass` e o `refusal_cap`
  (rot.csv), e mexer-lhes é uma decisão de dificuldade, não uma correcção.
- Se as ofertas devem aparecer mais cedo quando o jogador recusa muito (a voz insiste), ou mais tarde (a voz desiste).
