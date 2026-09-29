# O ânimo do reino — pesquisa e desenho (Q-102)

_29 de setembro de 2026. Pedido do dono no painel: «Gosto desse sistema de moral, faça uma densa pesquisa e
elabore algo concreto que faça sentido ao meu jogo.» O que se segue é a pesquisa (o que outros jogos fazem, e o que
disso serve este), a regra que saiu dela, e onde está no código._

## O que já havia

- **Moral por tropa (§07).** Fugir abaixo de 30% de vida, a brecha que põe a fugir quem é fraco e barato, e o raio
  do rei (260 px) dentro do qual ninguém foge. Está no `MoraleSystem` e funciona.
- **Um moral do império que ninguém tinha.** O §74 e o §76 escrevem *«serrá-lo tira 1 ponto de moral ao império
  durante 2 dias»* — o `amargueiros.csv` tinha até `morale_cost` e `morale_days` —, mas não havia império com moral
  onde tirar o ponto. O evento saía do `AmargueiroSystem.harvest()` e era deitado fora.
- **Nove bonificações de títulos (§76)** e só uma ligada (+1 de vida máxima).

## O que a pesquisa mostrou

| Jogo | Como funciona | O que serve aqui | O que não serve |
|---|---|---|---|
| **RimWorld** (humor) | Cada acontecimento deixa um *pensamento* com peso e prazo; o humor é a base mais a soma dos pensamentos vivos; abaixo de limiares há colapsos. | A forma: **memórias com peso e prazo**. Explica-se sozinha — sabe-se sempre porque é que o ânimo está onde está —, volta à base quando as memórias passam, e é determinista. | Os colapsos individuais: aqui a moral por tropa já é o §07. |
| **Stronghold** (popularidade) | A popularidade sobe e desce com comida, impostos, religião; acima de 50 chega gente nova, abaixo vai-se embora. | **Quem chega depende de como se vive.** Liga-se ao acampamento de vagabundos (Q-122) sem sistema novo. | Os impostos e as rações: o §02 não tem inventário. |
| **Frostpunk** (esperança e descontentamento) | Duas barras que as leis e os acontecimentos mexem; nos extremos, o jogo acaba ou abre crises. | **Efeitos por limiar**, e não por fórmula contínua: o jogador lê três estados, não um número. | Uma segunda barra e o fim por descontentamento: seriam dois sistemas de derrota a sobrepor-se ao §16. |
| **Mount & Blade** (moral do grupo) | Sobe com vitórias, desce com salários em atraso e baixas; baixa demais, há deserções. | **O que o mexe é o que o jogador já decide**: a noite ganha, os mortos, o soldo. E o soldo em atraso já tem deserção (Q-144). | A variedade de comida (não há cozinha que alimente). |
| **Total War** (moral em batalha) | Moral por unidade com baixas, flancos, general por perto. | Já é o §07 (o raio do rei é o general). O ânimo do reino só **desloca o limiar** de fuga. | O resto é táctico, e o §07 escolheu ser legível antes de emocionante. |
| **Darkest Dungeon** (stress) | Stress acumula e transforma-se em aflição ou virtude. | Nada de novo: seria um terceiro medidor. | A aleatoriedade das aflições: o §42 quer tudo reproduzível. |
| **Kingdom Two Crowns** | Não tem moral; os súbditos são mecânicos. | O que *não* fazer: nenhum recurso novo para gerir, nenhum menu. | — |

**Três regras saem disto, e são as do jogo:**

1. **Memórias com peso e prazo.** Cada acontecimento deixa uma memória; o ânimo é a base (50) mais as memórias vivas,
   entre 0 e 100. Sem números inventados à mão para cada caso: um peso e um prazo por chave, em `economy.csv`.
2. **Três estados, três efeitos que já existem.** Abatido (abaixo de 35), sereno, animado (acima de 65). Abatido: foge-se
   com 30% mais vida, a produção rende −10% e não chega ninguém aos acampamentos. Animado: foge-se com 20% menos, +10%
   e chega mais um vagabundo por alvorada.
3. **Um espelho do que o jogador já decide.** O ânimo não pede gestão própria: sobe com a noite ganha e com povos
   conquistados, desce com mortos, desertores, soldo por pagar, árvores com nome serradas e povos perdidos.

## A tabela

| Chave | Quando | Peso | Dias | Origem |
|---|---|---:|---:|---|
| `night_survived` | a alvorada a seguir a uma noite | +4 | 3 | proposta |
| `night_clean` | e ninguém morreu nela | +2 | 3 | proposta |
| `troop_died` | uma tropa tua morre | −2 | 2 | proposta |
| `named_died` | uma tropa com nome morre (§76) | −6 | 4 | proposta |
| `king_died` | o rei morre e o herdeiro assume | −10 | 5 | proposta |
| `deserted` | alguém deserta por soldo (Q-144) | −3 | 3 | proposta |
| `wages_owed` | a alvorada com soldo em atraso | −5 | 2 | proposta |
| `named_tree_felled` | um Amargueiro com nome é serrado | −1 | 2 | **§74, §76** |
| `vassal_won` | um povo passa a vassalo (Q-103) | +8 | 5 | proposta |
| `vassal_lost` | um vassalo é consumido | −8 | 5 | proposta |

## E as bonificações dos títulos

Das nove do §76 ligam-se as que já têm sistema: **+1 de vida** (já estava), **não foge** (`MoraleSystem`), **+10% de
cadência** e **+2 de dano contra cerco** (`TitlePerks`, lido pelo `CombatSystem`). As outras cinco — arrastar ao dobro,
metade da comida, imune a encantamento, a arma sobe um nível, não entra em pânico no Lume — esperam pelos sistemas que
as leem (arrastar corpos, comida, encantamento, armas, pânico), e continuam escritas em `titles.csv`.

## Onde está

- `src/sim/systems/spirit.gd` — o ânimo, puro: memórias, valor, nível, save.
- `src/core/spirit_watch.gd` — ouve o catálogo da §46 e escreve as memórias.
- `MoraleSystem.spirit`, `EconomySystem.spirit`, `Camps.dawn(..., animo)` — os três efeitos.
- `src/sim/systems/title_perks.gd` — as bonificações de título no combate.
- `tests/animo_test.gd` — as regras, e o painel a mostrá-lo (`ÂNIMO n`).

Todos os números estão em `_proposed`, excepto o −1 durante 2 dias da árvore com nome, que é do dossiê.
