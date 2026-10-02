# ADR 0041 — As respostas do painel de 30/09/2026

- **Estado:** aceite, em curso (30/09/2026)
- **Contexto:** o dono respondeu a 26 perguntas no painel (Q-150, Q-157 a Q-182). O `AGENTS.md` manda aplicar o
  que foi decidido, pela opção mais simples e reversível, e registar o resto em `docs/QUESTIONS.md`.

## Decisão

Aplica-se por respostas inteiras, uma por commit, cada uma com teste:

- **Q-158** — a Colheita Forçada custa 3 de base, e compensa.
- **Q-162** — trocar de classe (§08): o Verbo 2 sobre uma tropa passa-a ao corpo jogável, na escala 3; a tropa fica
  na 2 e o rei na 4 (`UnitSystem.pilot`, `Roster`, `Assume`).
- **Q-150** — o rei anda até `king_leash_px` para lá da região de casa; a caça nasce de arbustos, árvores, lagos,
  rochas e buracos (`wildlife.csv`, `sources`).
- **Q-168** — a tropa armada que cai larga a arma e foge como trabalhador (`Disarm`).
- **Q-167** — a coroa no chão, recuperável até à alvorada (`CrownDrop`, `rules.csv`).
- **Q-163** — as tropas levam aljava; a banca do arco repõe-na na alvorada, do saco do rei (`Supply`).
- **Q-169** — o cavalo de tração: compra-se no estábulo, anda a 1,7×, galopa a 2,1×, e os alforges levam 20 moedas
  e archotes (`Mount`); a pé corre-se a 1,8×.
- **Q-157, Q-160, Q-161, Q-164, Q-165, Q-166, Q-173, Q-181** — ficam como estão.

O save passa à **versão 5** (`SaveMigrationsV5`): quem se conduz, as classes, as tocas por sítio, a coroa, as
aljavas e o cavalo entram com o valor que reproduz o jogo antigo.

## Continuação pela ADR 0043

Q-170, Q-171, Q-172, Q-174, Q-175, Q-176, Q-177, Q-178, Q-179, Q-180 e Q-182 têm a resposta registada em
`docs/QUESTIONS.md` (*"Respondidas no painel (30/09/2026) — por aplicar"*) e continuam no painel à espera de
implementação na data desta ADR. A ADR 0043 integra este lote e documenta o estado actual.

## Consequências

- Os números novos (a aljava de 30, 12 flechas por moeda, o estábulo de 120 px) são medidos ou propostos e estão
  marcados no `_proposed`/`_notes` das tabelas; o banco de ensaio do §66 recebe as aljavas cheias, como recebe o saco
  cheio do soldo.
- Reversível resposta a resposta: cada uma é um commit.
