# ADR 0037 — O relatório Kingdom de 29/09/2026 aplicado

- Estado: aceite
- Data: 2026-09-29
- Secção do dossiê: várias (§07, §09, §13, §16, §24, §25, §62, §66)
- Complementa: ADR 0035, ADR 0036

## Contexto
O relatório `docs/recovery/ANALISE-KINGDOM-2026-09-29.md` comparou a `main` com o Kingdom (Classic, New Lands, Two
Crowns, Eighties) e trouxe nove propostas de jogo (K1 a K9), o desenho de um recomeço do zero e nove perguntas
(Q-A a Q-I). O dono respondeu *«aplique o relatório»*. O relatório ordena o trabalho em etapas e por prioridade (secção
5), e marca cada mecânica nova como decisão do dono. O `AGENTS.md` não deixa inventar mecânicas nem tocar em `art/` e
`audio/`.

## Decisão
**Aplica-se o roteiro nas prioridades P0 e P1 e no que é só apresentação; o resto entra no `QUESTIONS.md` como o
relatório o escreveu, com o que se aprendeu ao aplicá-lo.**

- Etapa 0 — recomeçar do zero pela pausa (Q-164): `FreshStart` apaga os três saves e o legado, tudo ou nada, e mantém
  as opções; `FreshStartPanel` pergunta com o foco em Cancelar e diz o que se perde.
- Etapa 1 — a banca do arco (K1, P0, Q-165): uma casa de ofício do `TrainingSystem`, com o preço do arco
  (`craft_cost` 2) em vez do do ofício. O piloto da vistoria arma-se pelos caminhos reais (CONT-05): compra o arco à
  tarde e decreta a Chamada às Armas com gente livre; a contabilidade ganha a coluna da gente armada.
- Etapa 2 — o cerco do §13 (K6, P1, Q-166, fecha a Q-159): firmeza de fortaleza que persiste entre marchas, baixas no
  fluxo `combat` e o reconhecimento na bifurcação. O save sobe para a versão 3, com a migração no mesmo commit (ADR
  0007). Os sons mínimos (K9, P1) ficam por fazer: são gravações em `audio/`.
- Da etapa 3, só a lua do pico (K8 pequeno), que é apresentação: cheia na véspera da noite funda, vermelha nela.
- Os números novos são propostas (`_proposed`), cada um com a regra na nota.
- As outras seis perguntas do relatório (Q-B, Q-C, Q-D, Q-E, Q-G, Q-H) entram abertas, como Q-167 a Q-172.

## Alternativas consideradas
Aplicar também as P2 (K2, K3, K4, K5, K7) com números propostos. Rejeitado. O K4 muda uma decisão anterior do dono (a
corrida da Q-149) e o K5 outras duas (os acampamentos das Q-110 e Q-122). O K3 é uma decisão de tom e depende do K1. O
próprio relatório diz que o K2 se mede antes de se escrever. E o K7 não cabe na ruína que já existe: reparar pede
construtores (Q-108), e a Casa de Treino, de onde eles saem, pode ser uma das ruínas, o que deixaria o jogo novo sem
maneira de a levantar. O *«aplique o relatório»* aprova o roteiro, não as escolhas que o relatório deixou ao dono; e
cada uma destas pode ser aprovada sozinha no painel.

## Consequências
A marcha deixa de ganhar sempre: com três, a primeira fortaleza fica de pé, e o teste da marcha no jogo passa a marchar
até ela cair. A vistoria mede pela primeira vez a gente armada, e mostra que, das seis moedas, o piloto nunca tem saco
à tarde e o rei cai ao dia 4 sem levantar a banca. O CONT-05 continua parcial, com essa medição escrita.
