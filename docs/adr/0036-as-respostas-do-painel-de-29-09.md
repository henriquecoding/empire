# ADR 0036 — As respostas do painel de 29/09/2026 entram no repositório

- Estado: aceite
- Data: 2026-09-29
- Secção do dossiê: várias (§08, §09, §13, §15, §16, §22, §24, §58, §74, §75, §77, §79)
- Complementa: ADR 0026, ADR 0027

## Contexto
O dono respondeu a 69 perguntas no painel (`/painel/`, ADR 0026): 27 aprovações de proposta, 39 respostas próprias e
três adiadas (Q-081, Q-112, Q-147). Pediu que se implementasse tudo sobre a `main` e que se abrisse e fundisse o PR.
Várias respostas pedem sistemas inteiros (*«gere todo esse sistema»*, *«faça uma densa pesquisa e elabore algo
concreto»*, *«deve ser desenvolvido e bem feito»*), e duas dizem não ter entendido a pergunta.

## Decisão
**Cada resposta aplica-se inteira, como na ADR 0027: dados, código, testes e o texto do dossiê que ela contradiz.**

- As que pediam sistema têm-no: as migrações do save (Q-091, `SaveMigrations`), a Semente Real com as fontes e os
  gastos todos (Q-095), o Sino de Vigia (Q-100, `Ward`), o ânimo do reino (Q-102, `Spirit`, com pesquisa em
  `docs/recovery/PESQUISA-MORAL-2026-09-29.md`), os vassalos e a marcha (Q-103, Q-146, ADR 0035), as tocas da caça
  (Q-106, Q-120, `Burrows`), as moedas que as tropas guardam (Q-107, Q-111, `Gleaning`), o escudeiro (Q-114,
  `Squire`), o soldo em atraso (Q-144), o armazenamento de cada personagem jogável (Q-153, `Storage`) e o fim pelo
  Lume (Q-156, `Lume`). As consequências das ofertas (Q-101) têm pesquisa em
  `docs/recovery/PESQUISA-OFERTAS-2026-09-29.md` e um teste que as prova.
- Onde duas respostas se contrariam aplica-se a mais recente e a mais específica, e a outra leitura vai ao dono: a
  travessia aprovada (Q-135) contra *«o rei nunca sai para longe do reino»* (Q-146) deu a marcha da ADR 0035, a
  confirmar na Q-159.
- Onde a resposta não cabia nos portões, aplica-se o mais perto que cabe e pergunta-se: o crescimento exponencial da
  noite (Q-151) começa depois da noite 10 e não da 5, porque o §66 é o portão da Fase 1 (Q-157).
- As duas que o dono não entendeu (Q-098, Q-104) reescrevem-se em palavras simples, com número novo (Q-160, Q-161),
  para o painel as mostrar outra vez por decidir.
- No `QUESTIONS.md` as 32 que estavam abertas passam para *"Decididas pelo dono no painel (29/09/2026)"*; as 34 das
  duas auditorias ficam no sítio, com a decisão por cima. O que ficou por decidir são as Q-157 a Q-163.
- As edições ao dossiê estão em `docs/dossie-painel-correcoes.md` (P21 a P31).

## Alternativas consideradas
Deixar os sistemas grandes para tickets e aplicar só os números: o painel diria «aplicada» a respostas que pedem o
sistema inteiro. Rejeitado, como na ADR 0027.

## Consequências
O painel mostra as 66 como aplicadas e as sete novas por decidir. A versão do save sobe para 2, com a migração no
mesmo commit (ADR 0007). A suite passa a 1002 casos, com três saltados, cada um com a razão escrita.
